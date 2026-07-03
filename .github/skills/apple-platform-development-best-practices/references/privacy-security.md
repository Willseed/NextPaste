# Privacy and Security

Reference rules for privacy and security review of native Apple platform (macOS, iOS, visionOS) code in NextPaste. Apply these rules when reviewing or writing changes that touch clipboard capture, persistence, networking, logging, diagnostics, sync, AI features, or any path that handles user content.

Cross-references:
- Platform-specific clipboard behavior, pasteboard privacy banners, and sandbox mechanics: see [platform-specific.md](platform-specific.md).
- Repository conventions and build/test commands: see the root skill `SKILL.md` and the repo's `copilot-instructions`.

## Rule classification

- **MUST** — security/privacy correctness. These are hard gates; violations block merge.
- **SHOULD** — recommended practice. Deviations require a documented reason.
- **PROJECT** — repository conventions specific to NextPaste.

Precedence: task requirements > mandatory security/privacy correctness (`MUST`) > repo conventions (`PROJECT`) > recommended practice (`SHOULD`). `PROJECT` rules must **never** justify insecure or privacy-violating code. If a convention conflicts with a `MUST`, the `MUST` wins.

## Authoritative sources

Official (authoritative for rule verification):
- Apple Developer — Keychain Services: https://developer.apple.com/documentation/security/keychain_services
- Apple Developer — Data Protection: https://developer.apple.com/documentation/security/data_protection
- Apple Developer — App Sandbox: https://developer.apple.com/documentation/security/app_sandbox
- Apple Developer — Privacy manifest (PrivacyInfo.xcprivacy): https://developer.apple.com/documentation/bundleresources/privacy_manifest
- Apple Developer — Required-Reason APIs: https://developer.apple.com/documentation/bundleresources/privacy_manifest/describing_use_of_required_reason_api
- Apple Developer — App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Apple Human Interface Guidelines — Privacy: https://developer.apple.com/design/human-interface-guidelines/privacy
- Apple Developer — CloudKit: https://developer.apple.com/documentation/cloudkit
- Apple Developer — URL Session: https://developer.apple.com/documentation/foundation/url_session

Community (recommendation only, not authoritative for gate decisions):
- OWASP Mobile Security Testing Guide: https://mas.owasp.org/
- CIS Apple macOS Benchmark: https://www.cisecurity.org/

When community guidance conflicts with Apple's documentation or the App Review Guidelines, the Apple source governs.

## Sensitive-data classification

Treat clipboard-derived data as the highest-sensitivity class in NextPaste. Review each of the following surfaces for sensitive-data exposure on every change:

| Surface | Sensitivity | Reason |
| --- | --- | --- |
| Clipboard contents (text, rich text, HTML) | **Highest** | May contain passwords, one-time codes, auth tokens, API keys, personal data, private messages, financial data. Assume secrets are present by default. |
| Image / file payloads | High | May contain scanned documents, screenshots of credentials, personal photos, attachments with PII. |
| Source-app attribution (pasteboard `org.nspasteboard.source` etc.) | Medium–High | Reveals which app the user copied from; can infer user activity. Collect only when required; keep on-device. |
| Search indexes (SwiftData/SQLite FTS) | High | Derived from clipboard contents; a leak equals a content leak. |
| Backups (`NSURLIsExcludedFromBackupKey`) | High | A device backup or Mac snapshot may exfiltrate clipboard history. Exclude sensitive stores unless sync is explicitly enabled. |
| Logs, trace events, crash reports | High | Diagnostics must never include raw content; see Logging and redaction. |
| Cloud sync records | High | Off-device copy of clipboard content; requires disclosure, consent, transport, and storage protections. |
| AI processing payloads | **Highest** | Any model invocation over clipboard data is an off-device transfer unless on-device; treat as cloud-class. |

`PROJECT`: NextPaste is local-first. SwiftData local store is the source of truth. Clipboard capture, storage, search, and retrieval must work offline without any network dependency.

## Clipboard privacy

`MUST` Treat clipboard contents as secrets. Never log, echo, print, or include raw clipboard text/image payloads in diagnostics, crash logs, analytics, or trace events.

`MUST` Do not send clipboard data to a remote service unless a product requirement explicitly requires it **and**: the behavior is disclosed to the user, the user has consented, the user has controls (enable/disable, per-content-type), and transport + storage protections are defined. Absent all four, the data stays on-device.

`MUST` Avoid persisting source-app metadata (which app the user copied from) unless a feature requires it. Where collected, keep it on-device and document the requirement.

`MUST` Do not silently read the pasteboard in the background to infer user activity. Capture is driven by the documented core flow: `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.

`SHOULD` On macOS, prefer `NSPasteboard` concealed/private types handling so the app does not expose content to other processes unnecessarily. Cross-link: [platform-specific.md](platform-specific.md).

`SHOULD` On iOS, rely on user-initiated paste and pasteboard privacy banners; do not implement workarounds that defeat the system's pasteboard access prompts. Cross-link: [platform-specific.md](platform-specific.md).

`PROJECT` The core clipboard flow must remain: `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`. Changes must not break offline capture/storage/search/retrieval.

## Permissions, capabilities, and entitlements

`MUST` Request only the permissions, capabilities, and entitlements the feature actually needs. Do not add an entitlement, capability, or privacy-manifest declaration without verifying why it is required.

`MUST` Do not modify signing, team, or provisioning configuration. Record assumptions about the current signing state instead.

`PROJECT` Current entitlements (`NextPaste.entitlements`) are assumed: `aps-environment` (development) for push; `com.apple.developer.icloud-container-identifiers` (empty array); `com.apple.developer.icloud-services = [CloudKit]`. Cloud sync is configured but optional. Treat CloudKit as disabled unless the feature explicitly enables sync.

`PROJECT` `Info.plist` declares `UIBackgroundModes = [remote-notification]`. Do not add background modes without a verified feature requirement.

## Privacy manifests and Required-Reason APIs

`MUST` Verify the repo's privacy-manifest status against current App Store rules before shipping any change that introduces a Required-Reason API.

`PROJECT` No `PrivacyInfo.xcprivacy` is present in the repo at the time of writing. **Record this as an assumption and verify.** Likely applicable Required-Reason API categories include, at minimum:
- `NSPrivacyAccessedAPICategoryUserDefaults` (if `UserDefaults` is used)
- `NSPrivacyAccessedAPICategoryFileTimestamp` (if file timestamps are read)
- `NSPrivacyAccessedAPICategorySystemBootTime` (if boot time APIs are used)
- `NSPrivacyAccessedAPICategoryDiskSpace` (if disk space APIs are used)

`MUST` When a change adds or uses a Required-Reason API, add or update `PrivacyInfo.xcprivacy` with the matching reason string from Apple's published set. Do not invent reason strings.

`SHOULD` Add the privacy manifest before the first shipping build that exercises a Required-Reason API; do not defer past the App Review gate.

## Keychain and secrets

`MUST` Store credentials and small secrets in Keychain. Do **not** store secrets in `UserDefaults`, source code, `Info.plist`, committed config files, or hardcoded constants. `UserDefaults` is appropriate only for small, non-sensitive preferences; see [architecture.md](architecture.md#lightweight-user-preferences) for the preference-storage decision tree.

`MUST` `UserDefaults` must never contain clipboard contents, authentication data, tokens, credentials, or sensitive personal data. Treat clipboard-derived data as the highest-sensitivity class (see [Sensitive-data classification](#sensitive-data-classification)).

`MUST` Use the most restrictive Keychain accessibility class that satisfies the feature. Prefer `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` for non-biometric secrets, and `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` for secrets that must be inaccessible in the background.

`SHOULD` Prefer `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` for the highest-value secrets where passcode presence is acceptable.

`MUST` Do not log Keychain item data, query dictionaries that contain secret values, or error payloads that echo secret material. Log only the `OSStatus` code.

`SHOULD` Scope Keychain items with `kSecAttrAccessGroup` only when a shared keychain group is explicitly required; otherwise default to the app's keychain.

## Local storage

`MUST` Do not write secrets, tokens, or raw clipboard content to plain-text files in app-writable locations.

`MUST` For file-backed content on iOS, use the appropriate data-protection class. Write sensitive files with `.complete` file protection (`NSFileProtectionComplete`) unless a feature requires a weaker class — in which case document why.

`PROJECT` Deployment targets are macOS 26.5, iOS 26.5, and visionOS. iOS `NSFileProtectionType` applies on iOS/visionOS. Verify the protection class on every new file write of sensitive content.

`SHOULD` Use atomic writes (`FileManager` atomic APIs or `Data.write(to:options:)` with `.atomic`) for persistent stores to avoid torn writes of sensitive data.

`MUST` Exclude sensitive stores from backups where the content should not leave the device. Set `NSURLIsExcludedFromBackupKey` on URLs for clipboard-history stores unless cloud sync is explicitly enabled for that store.

`SHOULD` Keep SwiftData stores in the app's container and apply the most restrictive protection class appropriate to the deployment platform.

## Logging and redaction

`MUST` Never log any of: clipboard contents, passwords, passphrases, auth tokens, API keys, session IDs, personal data, signing secrets, Keychain item data, or anything derived from clipboard content.

`MUST` Redact sensitive data in diagnostics. When a diagnostic must reference sensitive data, log only a non-reversible marker (e.g., `[redacted]`, a content-length bucket, or a content-type tag) — never a truncation or masked substring of the secret (masked secrets can be recovered).

`MUST` Ensure trace and observability code respects the privacy boundary. The repo's `Debug/` subsystem (`RowActionTrace*`) must not carry clipboard-derived content in event state.

`PROJECT` Preserve the existing `RowActionTracePrivacy` redaction approach. `RowActionTracePrivacy.prohibitedPayloadKeys` rejects state keys such as `textContent`, `clipboardContent`, `payload`, `previewText`, `thumbnailDescription`, `ocrText`, and `generatedSummary`. New trace state keys that may carry clipboard-derived content must be added to `prohibitedPayloadKeys` (or never populated).

`SHOULD` Prefer redaction patterns that are additive to `RowActionTracePrivacy` rather than ad-hoc `String` filtering at call sites.

### Concrete redaction patterns

```swift
// DO: log a marker, not the content
logger.debug("clipboard captured type=\(uti) lengthBucket=\(lengthBucket(for: count))")

// DON'T: log truncated/masked content — truncation can still leak
// logger.debug("preview=\(String(text.prefix(8)))…")   // FORBIDDEN

// DO: bucket numeric values
func lengthBucket(for count: Int) -> String {
    switch count {
    case 0:               return "empty"
    case 1...100:         return "xs"
    case 101...1_000:     return "s"
    case 1_001...10_000:  return "m"
    default:              return "l"
    }
}

// DO: tag content type without revealing content
logger.info("persist kind=\(kind) redacted=true")

// DO: for trace state, route through RowActionTracePrivacy
let safe = RowActionTracePrivacy.sanitizedState(rawState)
// never place raw clipboard content in `state`; keys like "textContent" are rejected.
```

`MUST` Crash reports (system or third-party) must not include clipboard content. If a crash reporter captures custom keys, do not attach content-derived values.

## Data protection, deletion, and lifecycle

`MUST` Provide clear deletion behavior for locally stored user content. Every persisted clipboard item must have a reachable delete path (single-item delete, clear-history, retention-limit, and/or app-uninstall cleanup).

`MUST` Deletion must be irrevocable from the UI's perspective — do not leave recoverable soft copies in logs, caches, or trace files.

`SHOULD` Apply retention limits (e.g., max item count, max age) to bound how long clipboard content persists on-device.

`MUST` When the user clears history or deletes an item, also delete derived artifacts for that item: search-index rows, thumbnails, cached previews, and (if sync is enabled) sync-deletion records that propagate the deletion.

## Backups

`MUST` Review every new persistent file/store for backup exposure. Ask: "Could a device backup or Mac snapshot include this sensitive file?" If yes and the content should not leave the device, set `NSURLIsExcludedFromBackupKey` or exclude via the protection class.

`SHOULD` Document, per store, whether it is backup-excluded and why. Prefer one decision per store rather than per-write decisions.

## Network boundaries

`MUST` Do not add networking to a path that previously worked offline. NextPaste is local-first; offline capture/storage/search/retrieval must continue to function with no network.

`MUST` Do not add analytics, telemetry, advertising, AI, or third-party SDKs without explicit approval. "Explicit approval" means a documented product requirement plus consent and disclosure.

`MUST` Every network call must be reviewable for whether it can carry clipboard content. If a network call is added anywhere near a clipboard code path, it must be audited for content leakage.

`SHOULD` Use `URLSession` with TLS (`https`) and certificate/pinning policy appropriate to the endpoint. Avoid cleartext `http` (`NSAllowsArbitraryLoads` must remain off).

`SHOULD` Restrict App Transport Security exceptions to verified, scoped needs.

## Cloud sync

`MUST` Before adding or modifying cloud sync, define conflict and deletion behavior: what happens on simultaneous edits, what happens on delete, how deletes propagate, and what the user sees when sync is off.

`PROJECT` CloudKit is configured (entitlement present) but treated as optional. Do not enable sync-by-default; require explicit user opt-in.

`MUST` Cloud sync of clipboard content is a remote transfer and requires the same four safeguards as any remote clipboard use: disclosure, consent, controls, and defined transport/storage protections.

`SHOULD` Prefer per-store sync toggles over a single global toggle so the user can keep the most sensitive content local.

## AI processing boundaries

`MUST` Do not route clipboard data to an AI service (cloud model or third-party API) without: an explicit product requirement, user-facing disclosure, user consent, an on-device fallback when the user declines, and defined transport/storage protections.

`MUST` On-device models (Foundation Models on supported OS versions) are preferred. An on-device path does **not** require remote disclosure, but still must not log or persist content beyond what the local store already permits.

`SHOULD` Tag AI-derived outputs (summaries, classifications) with the same sensitivity class as their source clipboard content; a summary can leak the original.

`PROJECT` The `RowActionTracePrivacy` prohibited key `generatedSummary` exists because AI-derived summaries are content-derived. Preserve this; do not log summaries.

## Analytics and telemetry

`MUST` Do not add analytics, telemetry, or crash-reporting SDKs without explicit approval.

`MUST` Any approved telemetry must not include clipboard content, source-app attribution, or anything derived from clipboard data. Log only structural events (e.g., "capture occurred", "delete tapped") with non-content payloads.

`SHOULD` Document each telemetry event's payload in the Validation Contract so reviewers can verify it contains no content.

## Threat-oriented review questions

Ask these questions for every change that touches clipboard, storage, logging, networking, sync, AI, or diagnostics. Any "yes" or "unsure" answer is a finding to resolve before merge.

**Logging / diagnostics**
- Can this code path log raw clipboard text, image data, or a truncation/mask of it?
- Does this trace event (`RowActionTrace*`) populate a state key not covered by `RowActionTracePrivacy.prohibitedPayloadKeys`?
- Could a crash report or error payload include content-derived data?
- Are redaction helpers used, or is ad-hoc string filtering at the call site?

**Storage / file protection**
- Is this sensitive file written with `.complete` file protection (iOS) or the most restrictive equivalent on macOS?
- Is the store excluded from backup if it should not leave the device?
- Are writes atomic to avoid torn writes of sensitive data?
- Could a backup or Time Machine snapshot include this file?

**Secrets**
- Are credentials/secrets stored in Keychain, not `UserDefaults`/source/`Info.plist`?
- Does any Keychain query log echo secret material or the query dictionary?

**Clipboard boundaries**
- Does any network call in this change risk leaking clipboard content?
- Is pasteboard access user-driven or consistent with the documented core flow?
- Does this collect source-app metadata unnecessarily?
- Could this path silently read the pasteboard in the background?

**Permissions / manifest**
- Does this change introduce a Required-Reason API (UserDefaults, FileTimestamp, SystemBootTime, DiskSpace, …) without an entry in `PrivacyInfo.xcprivacy`?
- Does this add an entitlement, capability, or background mode that is not justified?
- Is the repo's missing `PrivacyInfo.xcprivacy` accounted for in the review?

**Sync / AI / telemetry**
- Is clipboard content being sent to a remote service with disclosure + consent + controls + protections?
- Is an AI/cloud-model path gated by explicit consent with an on-device fallback?
- Does any new telemetry event payload contain content or content-derived values?
- Are conflict and deletion behavior defined before enabling sync?

**Deletion / lifecycle**
- Does deleted content have a reachable, irrevocable delete path?
- Are derived artifacts (search rows, thumbnails, previews) deleted with the item?
- Could trace files, caches, or logs retain deleted content?

## Review checklist (minimum)

- [ ] No clipboard content or content-derived data is logged, traced, or sent over the network without the four safeguards.
- [ ] Secrets are in Keychain; not in `UserDefaults`, source, `Info.plist`, or config.
- [ ] Sensitive iOS files use `.complete` protection; macOS respects App Sandbox.
- [ ] Backup exposure reviewed per store; `NSURLIsExcludedFromBackupKey` set where needed.
- [ ] `RowActionTracePrivacy` redaction preserved and extended for any new content-derived state key.
- [ ] Required-Reason APIs verified; `PrivacyInfo.xcprivacy` updated or its absence recorded.
- [ ] No new entitlement, capability, background mode, analytics, AI, or third-party SDK without justification and approval.
- [ ] Deletion paths exist and propagate to derived artifacts.
- [ ] Cloud sync conflict/deletion behavior defined before sync is enabled.
- [ ] Offline capture/storage/search/retrieval still work with no network.