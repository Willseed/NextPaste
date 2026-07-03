---
name: apple-platform-development-best-practices
description: Applies production-grade Swift, SwiftUI, AppKit, UIKit, concurrency, testing, privacy, accessibility, persistence, localization, performance, and platform-specific best practices when implementing or reviewing native macOS and iOS code. Use for Apple platform architecture, feature implementation, refactoring, debugging, code review, clipboard handling, local-first storage, release validation, and shared macOS/iOS Swift packages.
license: MIT
---

# Apple Platform Development Best Practices

Use this Skill when designing, implementing, reviewing, refactoring, testing, debugging, or
validating native Apple platform code (macOS, iOS, iPadOS, visionOS). It prevents AI-generated
code from introducing architectural inconsistencies, incorrect platform assumptions, data races,
lifecycle/cancellation bugs, privacy or App Store policy violations, insecure storage/logging,
Unicode corruption, inaccessible UI, persistence corruption, untestable code, and false
build/test claims.

This repository is **NextPaste**, a local-first clipboard app. Repository-specific facts are marked
**PROJECT**. When evidence is unavailable, record the assumption instead of inventing
configuration.

## When to activate

Activate for any change that touches: macOS apps, iOS/iPadOS apps, visionOS apps, SwiftUI views,
AppKit/UIKit interop, Swift concurrency, SwiftData/Core Data persistence, clipboard/pasteboard
behavior, local-first storage, shared macOS/iOS Swift code, tests, entitlements/privacy manifests,
or release validation.

## Rule classification

- **MUST** — required for compiler correctness, data-race safety, platform compatibility,
  security, privacy, data integrity, accessibility correctness, and truthful validation
  reporting. Violating a MUST is a defect.
- **SHOULD** — recommended engineering practice (maintainability, testability, clarity,
  performance, modularity, UX). Does not override established repository conventions without a
  concrete reason.
- **PROJECT** — conventions discovered in this repository (architecture, naming, persistence,
  testing framework, build commands, deployment targets).

**Precedence:** explicit task/user requirements → mandatory platform correctness and safety →
repository configuration and established conventions → recommended architectural practices.
Repository conventions never justify unsafe, insecure, inaccessible, or platform-invalid code.

## Repository adaptation (PROJECT facts)

Before relying on defaults, confirm against the repository. Findings at generation time:

- **Project type:** Xcode app project `NextPaste.xcodeproj` (not SwiftPM). Scheme `NextPaste`.
  Targets: `NextPaste` (app), `NextPasteTests` (Swift Testing), `NextPasteUITests` (XCTest).
  File-system-synchronized groups — add source under `NextPaste/`, `NextPasteTests/`,
  `NextPasteUITests/`.
- **Swift:** Swift 5 language mode (`SWIFT_VERSION = 5.0`). Do NOT assume Swift 6.
- **Default actor isolation:** `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Unannotated types are
  MainActor-isolated by default — reason about isolation explicitly; do not assume nonisolated.
- **Strict concurrency:** `SWIFT_STRICT_CONCURRENCY` not set → defaults to `minimal` in Swift 5.
  Do not weaken concurrency settings; do not claim strict concurrency is enforced.
- **Upcoming feature:** `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`.
- **Deployment targets:** macOS 26.5, iOS/iPadOS 26.5, visionOS (`XROS_DEPLOYMENT_TARGET`)
  26.5. Supported platforms: `iphoneos iphonesimulator macosx xros xrsimulator`.
  `TARGETED_DEVICE_FAMILY = "1,2,7"`.
- **Architecture:** SwiftUI `@main` app, SwiftData `@Model ClipItem`, `@Query` reads,
  `@Environment(\.modelContext)` writes, `@MainActor` services (`ClipboardMonitor`,
  `ClipboardCaptureService`). Pasteboard abstraction via `ClipboardPasteboardReader` struct.
  Scheduler abstraction `ClipboardMonitorScheduler`. `ImageClipFileStore` for image assets.
  Design system under `NextPaste/DesignSystem/`.
- **Persistence:** SwiftData `Schema([ClipItem.self])`, `ModelConfiguration(isStoredInMemoryOnly:)`
  for UI testing. Pinned-first, newest-first sort descriptors.
- **Observation:** `@Query`, `@Environment`, custom `EnvironmentKey`s (`appTheme`, `appMotion`).
  Do NOT mandate migration to the Observation framework.
- **Cross-platform UI:** `#if os(macOS)` / `#else NavigationStack` via a local
  `NavigationViewWrapper`. Preserve this pattern.
- **Entitlements:** push (`aps-environment`), CloudKit (`com.apple.developer.icloud-services`).
  App Sandbox enabled (`ENABLE_APP_SANDBOX = YES`, resolved build setting). Do NOT modify signing
  identities/teams/provisioning.
- **Info.plist:** `UIBackgroundModes = [remote-notification]`.
- **Privacy manifest:** no `PrivacyInfo.xcprivacy` present — verify Required-Reason APIs apply.
- **Localization:** no `.strings`/`.xcstrings` found — project not yet localized; record assumption.
- **Build/test commands** (use these before inventing others):
  - Build: `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build`
  - All tests: `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test`
  - Unit target: `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test`
- **No SwiftLint, no repo scripts, no CI workflows.** Rely on Xcode diagnostics.

## Required workflow

Follow this six-phase workflow for every meaningful Apple-platform change.

### Phase 1 — Inspect before changing
Read relevant source/tests. Identify current architecture, data flow, and mutable-state owners.
Inspect deployment targets, Swift language mode, and concurrency settings. Search for existing
utilities/abstractions before adding new ones. Determine shared vs platform-specific code. Identify
actor/executor boundaries, lifecycle ownership, entitlements, permissions, sandbox constraints,
privacy manifests, and App Store restrictions. State assumptions when evidence is unavailable. Do
not replace established architecture for stylistic reasons.

### Phase 2 — Plan the smallest correct change
Before editing, define: intended behavior, data flow, state owner, dependency boundaries,
actor/thread boundaries, task lifetime and cancellation owner, macOS/iOS behavioral differences,
API availability requirements, persistence/migration impact, privacy and accessibility impact,
affected files, tests required, validation commands. Avoid unrelated refactoring. Preserve
compatibility unless the task explicitly permits a breaking change.

### Phase 3 — Implement
Implement only the planned change. Do not invent Apple APIs, framework types, entitlements,
privacy keys, background modes, build settings, scheme names, or platform behavior. Verify instead
of guessing.

### Phase 4 — Test and validate
Run the repository's relevant format, lint, build, test, and validation commands. Fix failures
caused by the change. Continue the inspect → fix → validate loop until all required checks pass or
an external blocker is clearly identified. Do not mark a task complete while a required gate fails.

### Phase 5 — Review the final diff
Check for: unrelated changes, dead code, temporary diagnostics, suppressed warnings, unsafe
concurrency workarounds, accidental signing changes, duplicated abstractions, privacy regressions,
and missing tests.

### Phase 6 — Report truthfully
Report exact commands and exact outcomes. Never claim a build or test passed unless it actually
ran and succeeded.

## Production Swift rules (summary)

- **MUST** Follow the Swift API Design Guidelines; prefer clear domain names over abbreviations.
- **MUST** Prefer value types unless identity, inheritance, ObjC interop, or shared mutable state
  requires reference semantics.
- **MUST** Avoid in production unless explicitly justified: force unwraps, `try!`, unsafe casts,
  implicitly unwrapped optionals, `fatalError`, `preconditionFailure` for recoverable input, empty
  catch blocks, silently discarded errors.
- **MUST** Handle errors intentionally with actionable diagnostics; never leak secrets; distinguish
  user-facing messages from internal diagnostics; preserve underlying errors where useful.
- **MUST** Remove dead code and temporary debugging code introduced by the change.
- **SHOULD** Use access control deliberately; document public APIs and non-obvious invariants.
- **SHOULD** Avoid speculative abstractions and single-implementation protocols without a real
  boundary or test seam.
- **SHOULD** Use explicit dependency injection; avoid hidden mutable global state and unnecessary
  singletons. Do not add third-party dependencies without explicit approval; prefer native APIs.

## Swift concurrency (summary)

- **MUST** Keep UI state and UI mutations on MainActor.
- **MUST** Define the owner of every shared mutable state; use actors where serialized ownership is
  appropriate; account for actor reentrancy across `await` (revalidate after suspension).
- **MUST** Never hold a lock across `await`; never block cooperative executor threads with sync
  sleeps, semaphore waits, large sync file ops, or expensive CPU work on MainActor.
- **MUST** Preserve cancellation through call chains; check cancellation in long loops, parsing,
  indexing, import, persistence, and batch ops; store task handles when cancellation/lifecycle
  control is needed.
- **MUST** Use checked continuations by default; guarantee exactly one resume on every path;
  handle callback duplication/absence/cancellation.
- **MUST** Treat `Sendable` warnings as design feedback; do not add `@unchecked Sendable` without a
  documented synchronization strategy and safety proof. Do not weaken strict concurrency to green.
- **PROJECT** Because `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, unannotated types default to
  MainActor isolation — verify isolation explicitly rather than assuming nonisolated.
- See [references/concurrency.md](references/concurrency.md) for detail.

## SwiftUI (summary)

- **MUST** Views primarily describe UI; business workflows belong in models/services/domain use
  cases. No persistent dependencies constructed in `body`; no uncontrolled side effects during
  body evaluation.
- **MUST** Use stable identity in lists; do not use mutable collection indexes as identity. Keep
  bindings narrow. Handle loading/empty/success/error/retry explicitly; preserve user edits during
  async refresh.
- **MUST** Use `task`/`task(id:)` intentionally and understand cancellation. Make navigation and
  presentation state explicit and restorable where required.
- **PROJECT** Prefer the observation mechanism already used (`@Query`, `@Environment`, custom
  `EnvironmentKey`s). Do NOT migrate between `ObservableObject` and Observation for style.
- See [references/swiftui.md](references/swiftui.md) for detail.

## macOS / iOS separation (summary)

- **MUST** Never assume identical platform capabilities. Keep shared domain logic platform-neutral;
  isolate AppKit/UIKit behavior in adapters; avoid scattered `#if os(...)` in domain logic.
- **MUST** Verify availability against declared deployment targets; use compile-time or runtime
  availability checks correctly; preserve platform-native interaction patterns.
- **MUST** Never claim a global shortcut, accessibility API, login item, helper, background
  service, or clipboard monitor is valid without considering deployment target, sandbox,
  entitlements, privacy prompts, lifecycle, and current App Store rules.
- **MUST** Never design iOS clipboard functionality as if the app can continuously monitor the
  system clipboard while inactive/suspended. Verify current pasteboard privacy/lifecycle for the
  repo's supported iOS version.
- See [references/platform-specific.md](references/platform-specific.md) for detail.

## Clipboard handling (summary)

- **MUST** Prevent app-generated clipboard writes from being captured repeatedly.
- **MUST** Do not depend solely on text equality when content type/representation matters; make
  deduplication semantics explicit; preserve deterministic ordering; handle concurrent capture
  atomically.
- **MUST** Never log clipboard contents. Never upload clipboard data without explicit product
  requirement, disclosure, consent, and a local-first fallback.
- **MUST** Never auto-discard content because it contains multiple lines, emoji, composed
  characters, combining marks, Traditional Chinese, CJK, RTL, or unusual Unicode. Avoid destructive
  trimming/normalization unless an explicit domain rule requires it.
- **MUST** Use a protocol/adapter so unit tests do not depend on the real system clipboard.
- **PROJECT** Pipeline: change detected (changeCount) → read payload → validate (`ClipValidation`)
  → dedupe (text equality / image hash+dimensions) → persist (insert + save, rollback on failure)
  → state update → refresh UI.
- See [references/platform-specific.md](references/platform-specific.md) (clipboard subsection).

## Unicode, localization, and text (summary)

- **MUST** Treat `String` as extended grapheme clusters; never integer-index into `String`; use
  `String.Index` and appropriate views. Preserve canonical equivalence unless product rules require
  normalization.
- **MUST** Use explicit UTF-8 when converting `String` to bytes; handle encoding failure
  intentionally.
- **MUST** Use localized user-facing strings; avoid concatenation that prevents correct
  localization; use pluralization/parameterized localization; keep storage identifiers separate
  from display text; use locale-aware formatting.
- **SHOULD** Test with Traditional Chinese, English, emoji, composed/decomposed Unicode, multiline,
  mixed scripts, and RTL.
- **PROJECT** No String Catalogs/`.strings` found yet — preserve whatever localization mechanism the
  repo adopts.

## Persistence and local-first (summary)

- **MUST** Respect the persistence framework already selected (SwiftData). Keep domain logic
  independent from persistence implementation where practical. Make schema changes and migrations
  explicit; avoid destructive migrations by default; test migrations.
- **MUST** Handle partial writes, corrupted/missing records, uniqueness/ordering constraints, and
  duplicate records under concurrent capture. Keep blocking persistence off MainActor. Use atomic
  writes where applicable.
- **MUST** Never store credentials/secrets in plain text; use appropriate iOS data-protection
  options. Keep core functionality offline; treat cloud sync as optional unless explicitly required.
- **MUST** For cross-store destructive workflows (clear one/all, orphan cleanup) that touch both
  SwiftData records and image files: capture file references before record deletion, save
  `ModelContext` first, delete files only after a successful save, treat file-cleanup failures as
  idempotent recoverable debt, and never claim atomicity across SwiftData and the file system. See
  [references/architecture.md](references/architecture.md#cross-store-destructive-operations).
- **MUST** For lightweight non-sensitive preferences (e.g., pause/resume capture): use the
  smallest appropriate mechanism (`@AppStorage`/`UserDefaults` for view-local bindings, an
  injected typed store for service/test access, Keychain for secrets); never store clipboard
  contents or credentials in `UserDefaults`; define defaults, reset, and migration. See
  [references/architecture.md](references/architecture.md#lightweight-user-preferences).
- See [references/architecture.md](references/architecture.md).

## Security and privacy (summary)

- **MUST** Request only necessary permissions/capabilities/entitlements. Never add
  analytics/telemetry/networking/advertising/AI/third-party SDKs without explicit approval.
- **MUST** Never log clipboard contents, passwords, tokens, API keys, session IDs, personal data, or
  signing secrets. Redact sensitive data in diagnostics.
- **MUST** Use Keychain for credentials and small secrets; never store secrets in UserDefaults,
  source, Info.plist, or committed config. Respect App Sandbox and iOS data protection.
- **MUST** Review privacy manifests and Required-Reason API requirements; do not add
  entitlement/privacy declarations without verifying why they are required.
- **MUST** Provide clear deletion behavior for locally stored user content; do not send clipboard
  data to a remote service without explicit requirement, disclosure, consent, and transport/storage
  protections.
- See [references/privacy-security.md](references/privacy-security.md).

## Accessibility (summary)

- **MUST** Provide VoiceOver labels/values/hints/traits/actions/grouping where necessary; use
  semantic native controls instead of gesture-only replicas; logical focus order.
- **MUST** macOS: visible keyboard focus, full keyboard navigation for primary workflows, command
  discoverability. iOS: appropriate touch targets, Dynamic Type, VoiceOver, rotation, size
  classes.
- **MUST** Support Reduced Motion, Increased Contrast, Differentiate Without Color; never
  communicate state using color alone. Do not add redundant labels to controls whose native semantic
  label is already correct.
- See [references/review-checklist.md](references/review-checklist.md).

## Performance (summary)

- **MUST/SHOULD** Measurement-driven: avoid MainActor work, expensive `body` work, repeated
  fetches during rendering, loading entire histories when pagination fits, decoding full-resolution
  images for thumbnails. Respond to memory pressure; clean up timers/observers/tasks/delegates/
  streams. Do not claim a performance improvement without measurement when measurement is feasible.

## Testing and validation (summary)

- **MUST** Use Swift Testing (`NextPasteTests`) or XCTest (`NextPasteUITests`) per target; do not
  mix frameworks within a target.
- **MUST** Tests must be deterministic: no real clipboard, no test-order dependence, no shared
  mutable global state, no arbitrary sleeps, no external network, no production storage; use test
  doubles, DI, controllable clocks/schedulers, in-memory stores (`SwiftDataTestSupport`),
  temporary directories, explicit cleanup.
- **MUST** Run the repository's relevant format/lint/build/test commands; fix failures; never
  claim a build/test passed without running it; never disable tests or weaken warnings to obtain
  green.
- See [references/testing-validation.md](references/testing-validation.md).

## Build and validation gates

Run in order where applicable:

1. Format changed files.
2. Run linting (if any; none configured — rely on Xcode diagnostics).
3. Build all affected application and package targets.
4. Run affected unit tests.
5. Run broader tests when shared code changes.
6. Run integration tests.
7. Run relevant UI tests when workflows change.
8. Confirm no new compiler warnings.
9. Confirm no new concurrency warnings.
10. Confirm no new deprecation warnings.
11. Confirm deployment-target compatibility.
12. Confirm localization resources compile.
13. Confirm privacy manifests compile and package correctly if affected.
14. Review entitlements and capabilities if affected.
15. Review final diff for unrelated changes.
16. Report exact commands and results.

Never: claim tests passed without running them; conceal failing tests; disable tests to obtain
green; reduce warning levels; weaken concurrency checks; suppress diagnostics instead of fixing
causes; remove valid tests; modify signing/provisioning; commit or push unless requested. If
validation cannot run, report the exact reason, the unexecuted command, what remains unverified,
and whether the change is release-ready (it is not). A task is not release-ready while required
validation is failing, blocked, skipped, or incomplete.

## Code-review mode

When reviewing only (no implementation), classify findings as **Blocker / High / Medium / Low /
Suggestion**. Prioritize: incorrect platform assumptions → data loss → privacy/security exposure →
concurrency/lifecycle races → crashes → persistence corruption → permissions/entitlements →
accessibility regressions → missing tests → performance risks → maintainability. Each finding must
state: severity, file, line/symbol, concrete risk, triggering scenario, recommended correction,
and whether a regression test is required. Do not manufacture findings to fill categories; focus
on defects and risks, not stylistic preferences handled by formatting tools.

## Completion report

Produce a concise final report containing:

- Summary of changes
- Architecture decisions
- State ownership decisions
- Actor and task ownership decisions
- macOS/iOS differences considered
- Privacy and entitlement impact
- Accessibility impact
- Persistence or migration impact
- Files changed
- Tests added or updated
- Commands executed
- Build result
- Test result
- Remaining warnings
- Known limitations
- Unverified assumptions
- **Release-readiness status** — one of: `Release-ready` / `Not release-ready` / `Validation
  blocked`. Explain when not Release-ready.

### Skill-artifact tasks vs application release readiness

When the task scope is limited to non-application artifacts (e.g. Skill files, documentation,
governance, configuration that does not change app behavior), distinguish the two statuses:
- **Skill/artifact generation status** — `Release-ready` when the artifact's own static and
  consistency checks pass.
- **Application release status** — `Not evaluated` when no application build or test was executed
  (do not infer it from artifact checks). It becomes `Release-ready` only after the repository's
  build and test gates actually run and pass, or `Not release-ready` / `Validation blocked` if
  they fail or cannot run.
Never merge the two. A passing static check on Skill files does not make the application
release-ready.

## Reference files

- [references/architecture.md](references/architecture.md) — dependency direction, domain vs
  presentation, state/DI/lifecycle/navigation ownership, persistence boundaries, local-first.
- [references/concurrency.md](references/concurrency.md) — structured concurrency, actors, Sendable,
  cancellation, continuations, executor safety, retain cycles.
- [references/swiftui.md](references/swiftui.md) — state ownership matrix, identity, body purity,
  task/navigation, representables/coordinators, performance.
- [references/platform-specific.md](references/platform-specific.md) — macOS/iOS/visionOS lifecycle,
  sandbox, entitlements, pasteboard, App Store policy, dedicated clipboard subsection.
- [references/privacy-security.md](references/privacy-security.md) — sensitive-data classification,
  Keychain, logging/redaction, privacy manifests, network/AI/cloud boundaries, threat questions.
- [references/testing-validation.md](references/testing-validation.md) — testing pyramid, Swift
  Testing vs XCTest, doubles, deterministic async, clipboard adapter tests, xcodebuild discovery,
  release gates.
- [references/review-checklist.md](references/review-checklist.md) — concise pre-completion checklist.