# Apple Platform Pre-Completion Review Checklist

Run every checkbox BEFORE declaring a task complete. Rule classes:
- **MUST** — hard requirements (correctness, safety, privacy, truthful reporting).
- **SHOULD** — recommended.
- **PROJECT** — repo conventions for NextPaste.

Precedence: task requirements > mandatory correctness/safety/privacy > repo conventions > recommended practice. Do not manufacture findings to fill categories.

## Authoritative sources
Apple Developer Docs, Apple Human Interface Guidelines (HIG), and App Review Guidelines are authoritative. For detail behind each section, see the sibling references: [concurrency.md](concurrency.md), [swiftui.md](swiftui.md), [platform-specific.md](platform-specific.md), [privacy-security.md](privacy-security.md), [testing-validation.md](testing-validation.md), and architecture.md.

## Implementation completion
- [ ] **MUST** Only the planned change is present; no unrelated refactor or drive-by edits.
- [ ] **MUST** All affected files identified and intentionally modified.
- [ ] **MUST** State, actor, and long-running task owners are defined for new code.
- [ ] **SHOULD** macOS / iOS / visionOS differences considered and isolated behind adapters.
- [ ] **MUST** API availability checked against deployment target (macOS 26.5 / iOS 26.5 / visionOS supported). Guard unavailable APIs with `if #available`.
- [ ] **PROJECT** Swift 5 mode and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` respected; do not assume Swift 6 language mode.

## Code review
- [ ] **MUST** No force unwraps (`!`), `try!`, or unsafe casts without documented justification.
- [ ] **MUST** Errors handled intentionally; no swallowed errors or `try?` that hide failures.
- [ ] **MUST** No dead code, temporary diagnostics, or suppressed warnings (`@unchecked` without proof, `// swiftlint:disable` blanket, `@_silgen_name`, etc.).
- [ ] **MUST** No accidental signing/entitlement changes. Entitlements only modified when the task explicitly requires it.
- [ ] **SHOULD** No duplicate or competing abstractions for an existing concept.
- [ ] **SHOULD** No broad `Any`/`AnyObject` erasure where a concrete type works.

## Concurrency (detail: [concurrency.md](concurrency.md))
- [ ] **MUST** All UI mutations performed on `MainActor`.
- [ ] **MUST** Shared mutable state has a single owner; no free-floating `var` across actors.
- [ ] **MUST** A service is not placed on `MainActor` solely to silence concurrency warnings.
- [ ] **MUST** Revalidate invariants and preconditions after every `await`.
- [ ] **MUST** No lock/`os_unfair_lock`/`NSLock` held across an `await` point.
- [ ] **MUST** No executor-blocking work (synchronous I/O, long computation) on `MainActor` or the cooperative executor.
- [ ] **MUST** Cancellation preserved and checked in long-running tasks; task handles stored when cancellation/continuation is required.
- [ ] **MUST** No `@unchecked Sendable` without a documented proof of thread safety.
- [ ] **MUST** `SWIFT_STRICT_CONCURRENCY` not weakened; prefer escalating, not downgrading.

## SwiftUI (detail: [swiftui.md](swiftui.md))
- [ ] **MUST** Views describe UI, not workflows; business logic lives in services/models.
- [ ] **MUST** No persistent dependencies constructed inside `body`.
- [ ] **MUST** No uncontrolled side effects in `body` (use `.task`, `.onChange`, `.onAppear` deliberately).
- [ ] **MUST** Stable list identity (`id:`) and no identifier churn causing reloads.
- [ ] **SHOULD** Bindings narrowed to the smallest writable scope.
- [ ] **MUST** loading / empty / error / retry states all handled for async content.
- [ ] **MUST** In-progress edits preserved across refresh; no silent overwrite of user input.
- [ ] **MUST** `.task` / `.task(id:)` cancellation semantics understood and relied on correctly.
- [ ] **SHOULD** No unnecessary `AnyView`; prefer concrete return types or `some View`.

## Platform differences (detail: [platform-specific.md](platform-specific.md))
- [ ] **MUST** Shared business logic is platform-neutral.
- [ ] **MUST** AppKit/UIKit isolated in adapters (e.g., `ClipboardPasteboardReader`); domain has no `#if os(...)`.
- [ ] **MUST** `#if os(macOS)` / `#if os(iOS)` checks correct and scoped to UI-only code.
- [ ] **MUST** Native interaction preserved (keyboard, trackpad, Touch/Magic Mouse, VoiceOver, context menus, drag-and-drop, multi-selection).
- [ ] **SHOULD** Platform HIG alignment documented where behavior diverges.

## Clipboard behavior (detail: [platform-specific.md](platform-specific.md))
- [ ] **MUST** App-generated writes are not re-captured (capture loop guard).
- [ ] **MUST** Dedup semantics explicit; ordering deterministic.
- [ ] **MUST** Concurrent capture is atomic; no interleaving races.
- [ ] **MUST** Clipboard contents never logged and never uploaded without explicit user consent + documented scope + local-first fallback.
- [ ] **MUST** No destructive trimming of emoji, combining marks, ZWJ sequences, CJK, RTL, or multiline content.
- [ ] **PROJECT** Unit tests use the adapter (`ClipboardPasteboardReader`), never the real system clipboard.

## Unicode (detail: spec section 12)
- [ ] **MUST** `String.Index` used, not integer indexing, for slicing/insertion.
- [ ] **MUST** UTF-8 used when encoding/decoding to bytes; UTF-16 surrogate pairs handled if bridged.
- [ ] **MUST** Emoji, combining marks, ZWJ, variation selectors, RTL, and CJK preserved across transforms.
- [ ] **MUST** User-facing strings localized; no concatenation that breaks localization (use `String(localized:)` / interpolated strings).

## Privacy/security (detail: [privacy-security.md](privacy-security.md))
- [ ] **MUST** Only necessary permissions requested; each justified.
- [ ] **MUST** No secrets in source, UserDefaults, Info.plist, or build settings; Keychain for credentials.
- [ ] **MUST** Clipboard contents never logged (PROJECT: local-first app).
- [ ] **MUST** No analytics, networking, AI, or 3rd-party SDK without explicit approval and documented scope.
- [ ] **MUST** `PrivacyInfo.xcprivacy` required-reason APIs verified when new APIs are used.
- [ ] **MUST** Deletion/retention behavior explicit; sensitive data excluded from backups (`NSURLIsExcludedFromBackupKey` / `URLResourceKey.isExcludedFromBackupKey`).
- [ ] **PROJECT** Do not modify code signing; entitlements (push + CloudKit) changed only when the task requires it.

## Persistence (detail: architecture.md)
- [ ] **MUST** Existing SwiftData store and schema preserved (`@Model ClipItem`); new `@Model` types registered in `NextPasteApp.ModelContainer`.
- [ ] **MUST** Schema changes and migrations explicit; no destructive migration by default.
- [ ] **MUST** Partial writes handled; corrupted/missing records fail safe.
- [ ] **MUST** Uniqueness and ordering constraints defined.
- [ ] **MUST** Blocking persistence off `MainActor`; SwiftData writes routed through `modelContext` with defined actor ownership.

## Preferences (detail: architecture.md#lightweight-user-preferences)
- [ ] **MUST** Is this value small and non-sensitive? Clipboard contents and credentials are NOT preferences.
- [ ] **MUST** Is `@AppStorage`/`UserDefaults` appropriate, or is a typed preference-store abstraction needed (multiple readers, business logic, migration, deterministic tests)?
- [ ] **MUST** Are keys centralized or strongly typed (no scattered raw string keys)?
- [ ] **MUST** Are defaults and reset-to-default semantics defined for every preference?
- [ ] **MUST** Is migration defined when renaming or changing the type of a persisted preference?
- [ ] **MUST** Are tests isolated from production `UserDefaults` (unique suite, injected fake, or explicit cleanup)?
- [ ] **MUST** Was privacy-manifest / `NSPrivacyAccessedAPICategoryUserDefaults` applicability verified before release?
- [ ] **SHOULD** Is runtime ownership separate from storage (e.g., paused/resumed state owned by a `@MainActor` service, not by the preference itself)?
- [ ] **SHOULD** App Group `UserDefaults` used only when multiple targets genuinely require sharing?

## Cross-store deletion (detail: architecture.md#cross-store-destructive-operations)
- [ ] **MUST** Are record and file ownership rules explicit (unique ownership, reference count, or stable storage design)?
- [ ] **MUST** Are file references captured before database deletion?
- [ ] **MUST** Does file deletion occur only after a successful SwiftData save?
- [ ] **MUST** Can retries run safely (idempotent cleanup)?
- [ ] **MUST** Are shared files protected (file not deleted if another record references it)?
- [ ] **MUST** Are paths constrained to the app-controlled root (`ImageClipFileStore` path-traversal guards)?
- [ ] **MUST** Are partial failures and cancellation defined (before commit, after commit, after termination)?
- [ ] **MUST** Is orphan cleanup tested and recoverable?
- [ ] **MUST** Does the UI reflect the committed database state, not a pending file-cleanup outcome?
- [ ] **MUST** Are sensitive paths and clipboard data excluded from logs?

## Accessibility (detail: spec section 15)
- [ ] **MUST** VoiceOver labels/hints/traits where controls lack intrinsic semantics.
- [ ] **MUST** Semantic native controls used over custom drawing where possible.
- [ ] **MUST** Logical focus order; visible keyboard focus on macOS.
- [ ] **MUST** Full keyboard navigation on macOS; minimum touch targets on iOS.
- [ ] **MUST** Dynamic Type and reduced motion respected; no color-only state indication.

## Tests (detail: [testing-validation.md](testing-validation.md))
- [ ] **MUST** Targeted tests added for the change; determinism enforced.
- [ ] **MUST** No real clipboard, `sleep`, global mutable state, or production storage in tests.
- [ ] **MUST** Test doubles, DI, and injectable clocks used for non-determinism sources.
- [ ] **MUST** Affected unit tests actually run (`NextPasteTests`, Swift Testing).
- [ ] **SHOULD** Broader tests run when shared infrastructure/persistence/navigation changes.
- [ ] **MUST** Regression test added for any fixed bug.
- [ ] **PROJECT** Follow the target's framework: Swift Testing for `NextPasteTests`, XCTest for `NextPasteUITests` — do not mix.

## Build and release readiness
- [ ] **MUST** Build command run: `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build`.
- [ ] **MUST** Test command run: `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` (or scoped `-only-testing:` selectors).
- [ ] **MUST** No new compiler, concurrency, or deprecation warnings introduced.
- [ ] **MUST** Deployment-target compatible; no unavailable API calls.
- [ ] **MUST** Localization resources compile; `PrivacyInfo.xcprivacy` compiles; entitlements reviewed if affected.
- [ ] **MUST** Final diff reviewed for unrelated changes; only planned edits remain.
- [ ] **MUST** Exact commands and results reported truthfully; status declared as one of: **Release-ready** / **Not release-ready** / **Validation blocked**.

## Code-review mode severity ordering
When reviewing findings, classify by severity before action:
1. **Blocker** — must fix before merge (data loss, privacy violation, crash, security).
2. **High** — likely correctness/safety issue; fix or document accepted risk.
3. **Medium** — should fix soon; tracked issue.
4. **Low** — minor; optional.
5. **Suggestion** — stylistic/nit; optional.

Prioritization order when findings compete for attention:
incorrect platform assumptions > data loss > privacy/security > concurrency & lifecycle races > crashes > persistence corruption > permissions/entitlements > accessibility > missing tests > performance > maintainability.

Do not invent findings to populate categories. An empty category is a valid review outcome.