#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'EOF'
Build, sign, notarize, and package NextPaste for a Homebrew Cask release.

Required environment:
  DEVELOPMENT_TEAM   Apple Developer Team ID used for Developer ID export.
  NOTARY_PROFILE     notarytool keychain profile created with `xcrun notarytool store-credentials`.

Optional environment:
  DEVELOPER_DIR          Xcode developer directory (defaults to /Applications/Xcode.app/Contents/Developer).
  RELEASE_OUTPUT_DIR     Output directory outside the repository (defaults to a temporary directory).
  RELEASE_TAG            GitHub release tag (defaults to v<MARKETING_VERSION>).
  ALLOW_DIRTY=1          Allow packaging from a dirty worktree.

The script does not create a Git tag, GitHub Release, or Homebrew tap. It emits
the notarized ZIP and a ready-to-publish Casks/nextpaste.rb file.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

if [[ $# -ne 0 ]]; then
    usage >&2
    exit 64
fi

for command in codesign ditto git lipo plutil shasum spctl xcodebuild xcrun; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "error: required command not found: $command" >&2
        exit 69
    fi
done

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
    echo "error: DEVELOPMENT_TEAM is required" >&2
    exit 64
fi

if [[ -z "${NOTARY_PROFILE:-}" ]]; then
    echo "error: NOTARY_PROFILE is required" >&2
    exit 64
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

if [[ "${ALLOW_DIRTY:-0}" != "1" ]] && [[ -n "$(git status --porcelain)" ]]; then
    echo "error: refusing to package a dirty worktree; commit the release state first" >&2
    exit 65
fi

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
if [[ ! -d "$DEVELOPER_DIR" ]]; then
    echo "error: Xcode developer directory not found: $DEVELOPER_DIR" >&2
    exit 69
fi

build_settings="$(
    xcodebuild \
        -project NextPaste.xcodeproj \
        -scheme NextPaste \
        -configuration Release \
        -destination 'generic/platform=macOS' \
        -showBuildSettings
)"

setting() {
    local key="$1"
    awk -F ' = ' -v key="$key" '$1 ~ "^[[:space:]]*" key "$" { print $2; exit }' <<<"$build_settings"
}

version="$(setting MARKETING_VERSION)"
build_number="$(setting CURRENT_PROJECT_VERSION)"
bundle_identifier="$(setting PRODUCT_BUNDLE_IDENTIFIER)"
minimum_macos="$(setting MACOSX_DEPLOYMENT_TARGET)"

if [[ -z "$version" || -z "$build_number" || -z "$bundle_identifier" || -z "$minimum_macos" ]]; then
    echo "error: could not resolve release build settings" >&2
    exit 70
fi

release_tag="${RELEASE_TAG:-v$version}"
homebrew_minimum_macos="${minimum_macos%.0}"
case "$homebrew_minimum_macos" in
    26) homebrew_macos_requirement=":tahoe" ;;
    15) homebrew_macos_requirement=":sequoia" ;;
    14) homebrew_macos_requirement=":sonoma" ;;
    13) homebrew_macos_requirement=":ventura" ;;
    12) homebrew_macos_requirement=":monterey" ;;
    11) homebrew_macos_requirement=":big_sur" ;;
    *)
        echo "error: unsupported Homebrew macOS requirement: $minimum_macos" >&2
        exit 64
        ;;
esac
output_dir="${RELEASE_OUTPUT_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/NextPaste-release.XXXXXX")}"
case "$output_dir" in
    "$repo_root"|"$repo_root"/*)
        echo "error: RELEASE_OUTPUT_DIR must be outside the repository" >&2
        exit 64
        ;;
    /*) ;;
    *)
        echo "error: unexpected RELEASE_OUTPUT_DIR value: $output_dir" >&2
        exit 64
        ;;
esac

archive_path="$output_dir/NextPaste.xcarchive"
export_path="$output_dir/export"
export_options="$output_dir/ExportOptions-DeveloperID.plist"
submission_zip="$output_dir/NextPaste-$version-notary-submission.zip"
release_zip="$output_dir/NextPaste-$version.zip"
cask_path="$output_dir/Casks/nextpaste.rb"

mkdir -p "$output_dir" "$export_path" "$(dirname "$cask_path")"
plutil -create xml1 "$export_options"
plutil -insert destination -string export "$export_options"
plutil -insert method -string developer-id "$export_options"
plutil -insert signingStyle -string automatic "$export_options"
plutil -insert teamID -string "$DEVELOPMENT_TEAM" "$export_options"

echo "Archiving NextPaste $version ($build_number)..."
xcodebuild \
    -project NextPaste.xcodeproj \
    -scheme NextPaste \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -archivePath "$archive_path" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    archive

echo "Exporting with Developer ID..."
xcodebuild \
    -exportArchive \
    -archivePath "$archive_path" \
    -exportPath "$export_path" \
    -exportOptionsPlist "$export_options"

app_path="$export_path/NextPaste.app"
if [[ ! -d "$app_path" ]]; then
    echo "error: exported application not found: $app_path" >&2
    exit 66
fi

actual_version="$(plutil -extract CFBundleShortVersionString raw "$app_path/Contents/Info.plist")"
actual_build="$(plutil -extract CFBundleVersion raw "$app_path/Contents/Info.plist")"
actual_bundle_identifier="$(plutil -extract CFBundleIdentifier raw "$app_path/Contents/Info.plist")"
actual_minimum_macos="$(plutil -extract LSMinimumSystemVersion raw "$app_path/Contents/Info.plist")"

if [[ "$actual_version" != "$version" || "$actual_build" != "$build_number" ]]; then
    echo "error: exported version $actual_version ($actual_build) does not match $version ($build_number)" >&2
    exit 65
fi

if [[ "$actual_bundle_identifier" != "$bundle_identifier" || "$actual_minimum_macos" != "$minimum_macos" ]]; then
    echo "error: exported bundle metadata does not match Release build settings" >&2
    exit 65
fi

codesign --verify --deep --strict --verbose=2 "$app_path"
signature_details="$(codesign -d --verbose=4 "$app_path" 2>&1)"
if ! grep -q 'flags=.*runtime' <<<"$signature_details"; then
    echo "error: exported application is not signed with Hardened Runtime" >&2
    exit 65
fi

architectures="$(lipo -archs "$app_path/Contents/MacOS/NextPaste")"
if [[ " $architectures " != *" arm64 "* || " $architectures " != *" x86_64 "* ]]; then
    echo "error: expected a universal arm64 and x86_64 executable; found: $architectures" >&2
    exit 65
fi

ditto -c -k --keepParent "$app_path" "$submission_zip"

echo "Submitting to Apple notarization service..."
xcrun notarytool submit "$submission_zip" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

xcrun stapler staple "$app_path"
xcrun stapler validate "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"
spctl --assess --type execute --verbose=4 "$app_path"

rm -f "$submission_zip" "$release_zip"
ditto -c -k --keepParent "$app_path" "$release_zip"
sha256="$(shasum -a 256 "$release_zip" | awk '{print $1}')"

cat >"$cask_path" <<EOF
cask "nextpaste" do
  version "$version"
  sha256 "$sha256"

  url "https://github.com/Willseed/NextPaste/releases/download/$release_tag/NextPaste-#{version}.zip"
  name "NextPaste"
  desc "Local-first clipboard history manager"
  homepage "https://github.com/Willseed/NextPaste"

  depends_on macos: $homebrew_macos_requirement

  app "NextPaste.app"
end
EOF

echo
echo "Release package: $release_zip"
echo "SHA-256:         $sha256"
echo "Homebrew Cask:   $cask_path"
echo "GitHub tag:      $release_tag"
echo
echo "Next: create the immutable tag and GitHub Release only after the repository verification gate passes."
