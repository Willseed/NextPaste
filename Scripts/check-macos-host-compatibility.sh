#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_ROOT="$(cd -P "${SCRIPT_DIR}/.." && pwd -P)"
readonly PROJECT_PATH="${REPO_ROOT}/NextPaste.xcodeproj"
readonly MAXIMUM_MACOS_DEPLOYMENT_TARGET="26.0"
readonly TARGETS=(NextPaste NextPasteTests NextPasteUITests)
readonly CONFIGURATIONS=(Debug Release)

fail() {
  /bin/echo "error: macOS host compatibility validation failed: $*" >&2
  exit 1
}

version_is_at_most() {
  local required="$1"
  local available="$2"

  [[ "${required}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]] || return 2
  [[ "${available}" =~ ^[0-9]+([.][0-9]+){0,2}$ ]] || return 2

  /usr/bin/awk -v required="${required}" -v available="${available}" '
    BEGIN {
      split(required, requiredParts, ".")
      split(available, availableParts, ".")
      for (componentIndex = 1; componentIndex <= 3; componentIndex++) {
        requiredPart = requiredParts[componentIndex] + 0
        availablePart = availableParts[componentIndex] + 0
        if (requiredPart < availablePart) exit 0
        if (requiredPart > availablePart) exit 1
      }
      exit 0
    }
  '
}

if [[ "${1:-}" == "--self-test" ]]; then
  version_is_at_most 26.0 26.0
  version_is_at_most 26.0 26.4
  version_is_at_most 26.4 26.4.1
  ! version_is_at_most 26.5 26.4
  ! version_is_at_most 27.0 26.9
  /bin/echo "macOS host compatibility comparator self-test passed."
  exit 0
fi

[[ $# -le 1 ]] || fail "usage: Scripts/check-macos-host-compatibility.sh [report-path]"
[[ -d "${PROJECT_PATH}" ]] || fail "missing Xcode project: ${PROJECT_PATH}"

readonly XCODEBUILD="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}/usr/bin/xcodebuild"
[[ -x "${XCODEBUILD}" ]] || fail "full Xcode is unavailable: ${XCODEBUILD}"

host_version="$(/usr/bin/sw_vers -productVersion)"
version_is_at_most "${MAXIMUM_MACOS_DEPLOYMENT_TARGET}" "${host_version}" \
  || fail "host macOS ${host_version} is older than the repository's macOS ${MAXIMUM_MACOS_DEPLOYMENT_TARGET} support floor."

report_path="${1:-}"
if [[ -n "${report_path}" ]]; then
  /bin/mkdir -p "$(/usr/bin/dirname "${report_path}")"
  printf 'host\t%s\nmaximumDeploymentTarget\t%s\n' \
    "${host_version}" "${MAXIMUM_MACOS_DEPLOYMENT_TARGET}" > "${report_path}"
fi

for target in "${TARGETS[@]}"; do
  for configuration in "${CONFIGURATIONS[@]}"; do
    settings_path="$(/usr/bin/mktemp "${TMPDIR:-/tmp}/NextPaste-${target}-${configuration}-settings.XXXXXX.json")"
    trap '/bin/rm -f "${settings_path}"' EXIT

    "${XCODEBUILD}" \
      -project "${PROJECT_PATH}" \
      -target "${target}" \
      -configuration "${configuration}" \
      -sdk macosx \
      -showBuildSettings \
      -json > "${settings_path}"

    deployment_target="$(/usr/bin/plutil -extract 0.buildSettings.MACOSX_DEPLOYMENT_TARGET raw -o - "${settings_path}")" \
      || fail "${target} ${configuration} does not resolve MACOSX_DEPLOYMENT_TARGET."
    version_is_at_most "${deployment_target}" "${MAXIMUM_MACOS_DEPLOYMENT_TARGET}" \
      || fail "${target} ${configuration} resolves macOS ${deployment_target}; repository maximum is ${MAXIMUM_MACOS_DEPLOYMENT_TARGET}."
    version_is_at_most "${deployment_target}" "${host_version}" \
      || fail "${target} ${configuration} requires macOS ${deployment_target}, but this test host is ${host_version}."

    if [[ -n "${report_path}" ]]; then
      printf '%s\t%s\t%s\n' "${target}" "${configuration}" "${deployment_target}" >> "${report_path}"
    fi
    /bin/rm -f "${settings_path}"
    trap - EXIT
  done
done

/bin/echo "macOS host compatibility: passed (host=${host_version}, maximumDeploymentTarget=${MAXIMUM_MACOS_DEPLOYMENT_TARGET})"
