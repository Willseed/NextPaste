# Homebrew Release

NextPaste is distributed through a project-owned Homebrew tap until it meets the notability
threshold for the official `homebrew/cask` repository. The initial installation command will be:

```bash
brew install --cask willseed/tap/nextpaste
```

The Cask installs a signed and notarized universal `NextPaste.app` from a versioned GitHub Release
ZIP. Do not publish unsigned builds, mutable download URLs, or assets that have not passed
Gatekeeper assessment.

## One-time Apple setup

1. Install a `Developer ID Application` certificate for the Apple Developer team in the login
   keychain. The certificate must include its private key.
2. Sign in to the team in Xcode and confirm the `NextPaste` target can use the intended bundle ID.
3. Create a keychain profile for `notarytool`. For example, with an App Store Connect API key:

   ```bash
   xcrun notarytool store-credentials NextPaste-notary \
     --key /absolute/path/to/AuthKey_KEYID.p8 \
     --key-id KEYID \
     --issuer ISSUER_UUID
   ```

4. Confirm both prerequisites without exposing private material:

   ```bash
   security find-identity -v -p codesigning
   xcrun notarytool history --keychain-profile NextPaste-notary
   ```

## Package a release

Start from a clean `main` worktree whose immutable commit has passed `Scripts/verify.sh` and the
matching GitHub `Verify` workflow. Set the Apple team and notary profile, then run:

```bash
DEVELOPMENT_TEAM=TEAMID \
NOTARY_PROFILE=NextPaste-notary \
Scripts/package-homebrew-release.sh
```

The script reads the version, build number, bundle ID, and minimum macOS version from the Release
build settings. It then:

1. archives and exports with Developer ID signing;
2. verifies the bundle metadata, universal architectures, signature, and Hardened Runtime;
3. submits the ZIP to Apple, waits for notarization, and staples the ticket;
4. runs `codesign`, `stapler`, and Gatekeeper validation;
5. emits `NextPaste-<version>.zip`, its SHA-256, and a complete `Casks/nextpaste.rb`.

All generated products are written outside the repository. Use `RELEASE_OUTPUT_DIR` when a stable
external path is preferred.

## Publish in order

1. Record the exact verified commit SHA and confirm `origin/main` still points to it.
2. Create an annotated `v<version>` tag that points to that SHA; never replace an existing tag.
3. Create the GitHub Release and upload the exact notarized `NextPaste-<version>.zip` emitted by the
   packaging script.
4. Create the public repository `Willseed/homebrew-tap` and copy the emitted file to
   `Casks/nextpaste.rb`.
5. In the tap repository, run the following checks before pushing:

   ```bash
   brew style Casks/nextpaste.rb
   brew audit --new --cask Casks/nextpaste.rb
   brew install --cask ./Casks/nextpaste.rb
   brew uninstall --cask nextpaste
   ```

6. Test the public path on a clean machine:

   ```bash
   brew install --cask willseed/tap/nextpaste
   spctl --assess --type execute --verbose=4 /Applications/NextPaste.app
   ```

Keep the GitHub Release asset immutable. For later versions, package a new asset, publish a new
tag and Release, then update only `version` and `sha256` in the tap's Cask.
