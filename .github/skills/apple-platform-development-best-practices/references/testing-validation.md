# Testing and Validation

This reference governs **truthful validation reporting** and the testing strategy for native Apple
platform (macOS, iOS, visionOS) development in the NextPaste repository. It is the single source
of truth for how to run, scope, and report builds, tests, and release gates.

## Authoritative sources

Official (authoritative, consult first):

- Apple Developer Docs — Swift Testing framework: https://developer.apple.com/documentation/testing
- Apple Developer Docs — XCTest: https://developer.apple.com/documentation/xctest
- Apple Developer Docs — xcodebuild: https://developer.apple.com/documentation/xcodebuild
- Apple Developer Docs — Testing plans and UI tests: https://developer.apple.com/documentation/xcode/testing
- WWDC — Meet the Swift Testing framework (WWDC24): https://developer.apple.com/videos/play/wwdc2024/10187
- WWDC — Migrate your tests to Swift Testing (WWDC24): https://developer.apple.com/videos/play/wwdc2024/10195

Community (recommendation only, not authoritative):

- Swift Testing open-source project: https://github.com/swiftlang/swift-testing
- Point-Free — Dependency injection and testable Swift: https://www.pointfree.co

Where community guidance conflicts with Apple Developer Docs, Apple Developer Docs wins.

## Rule classification

- **MUST** — hard gates for correctness of truthful validation reporting. Violating a MUST is a
  blocking defect. Repo conventions never justify skipping or falsifying validation.
- **SHOULD** — recommended practice for reliable, maintainable tests.
- **PROJECT** — repository conventions specific to `NextPaste.xcodeproj`.

Precedence: **task requirements > mandatory correctness (MUST) > repo conventions (PROJECT) >
recommended practice (SHOULD)**. Repo conventions must NOT justify skipped or lying validation.

## MUST rules (hard gates)

These are non-negotiable for truthful validation reporting.

1. **Never claim a build/test passed without actually running it successfully.** Report the exact
   command executed and the exact outcome (pass/fail, counts, warnings). If you did not run it, say
   so. "Build should pass" is not a validation result.
2. **Do not conceal failing tests.** Do not disable tests to obtain green. Do not remove valid
   tests. Do not weaken concurrency checks (`-strict-concurrency`, actor isolation, Sendable
   diagnostics). Do not suppress diagnostics instead of fixing their causes. Do not reduce warning
   levels to silence warnings.
3. **Do not modify signing identities or provisioning profiles** unless the task explicitly
   requires it. Do not commit or push unless requested.
4. **If validation cannot run**, report: the exact reason it could not run, the unexecuted command,
   what remains unverified, and an explicit statement that the change **cannot** be considered
   release-ready.
5. **A task is NOT release-ready** when any required validation is failing, blocked, skipped, or
   incomplete. A partial result must be labeled as partial.

## PROJECT: repository commands

This is an Xcode app project, **not** a SwiftPM package. Use `xcodebuild` against
`NextPaste.xcodeproj` and the single `NextPaste` scheme. These commands are authoritative; prefer
them before inventing schemes or destinations.

```bash
# Build the app for macOS
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build

# Run the full test suite
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test

# Run the Swift Testing unit target only
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test

# Run a single unit test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/NextPasteTests/example test

# Run a single UI test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/NextPasteUITests/testExample test
```

Targets:

- `NextPaste` — app target.
- `NextPasteTests` — unit tests, **Swift Testing** (`import Testing`, `@Suite`, `@Test`,
  `#expect`, `#require`).
- `NextPasteUITests` — UI automation, **XCTest** (`XCTestCase`, `XCUITest`).

Do NOT mix frameworks within a single target. Do NOT add a `Package.swift` for validation.

## Testing pyramid

Scope tests proportionally. Prefer the smallest reliable scope first, then escalate only when
broader scope is justified. Document the reason for any full regression.

1. **Targeted unit tests (pure logic).** Default. Fast, hermetic, no UI, no real system services.
2. **Targeted integration tests (cross-component).** When behavior crosses module boundaries
   (e.g., clipboard adapter → persistence, scheduler → monitor) and lower layers cannot prove the
   contract alone.
3. **Targeted UI tests (user-visible flows).** Only when lower layers cannot reliably prove
   user-visible behavior (launch, navigation, list interactions, clipboard capture entry points).
4. **Full regression.** Only at completion gates, release readiness, or when shared infrastructure,
   persistence, app launch, navigation, or cross-cutting interaction changes are involved. Always
   document why full regression is required for this change.

## Swift Testing vs XCTest

- **`NextPasteTests` → Swift Testing.** Use `import Testing`, `@Suite`, `@Test`, `#expect`,
  `#require`. Async tests are plain `async` functions; no `XCTestExpectation` is needed for
  await-based synchronization.
- **`NextPasteUITests` → XCTest.** Use `XCTestCase`, `setUp`/`tearDown`, `XCUITest`,
  `XCUIApplication`. Keep `import XCTest` only here.
- Do NOT `import XCTest` inside `NextPasteTests`. Do NOT `import Testing` inside
  `NextPasteUITests`.

### Swift Testing example (unit)

```swift
import Testing
import Foundation
@testable import NextPaste

@Suite("Clipboard adapter deduplication")
struct ClipboardAdapterDeduplicationTests {

    @Test("Duplicate change count is ignored")
    func duplicateChangeCountIgnored() async throws {
        let reader = StubPasteboardReader(changeCount: 5)
        let monitor = ClipboardMonitor(reader: reader, now: { Date() })
        let first = try #require(await monitor.nextEvent())
        let second = await monitor.nextEvent()
        #expect(first != nil)
        #expect(second == nil, "Same change count must not re-emit")
    }

    @Test("Emoji text is captured intact")
    func emojiCapturedIntact() async throws {
        let reader = StubPasteboardReader(text: "🫵🎉🐉")
        let monitor = ClipboardMonitor(reader: reader, now: { Date() })
        let event = try #require(await monitor.nextEvent())
        #expect(event.content == "🫵🎉🐉")
    }
}
```

### XCTest example (UI)

```swift
import XCTest

final class ClipboardListUITests: XCTestCase {

    func testListAppearsOnLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.collectionViews.firstMatch.waitForExistence(timeout: 5))
    }
}
```

## Determinism rules

Tests MUST be hermetic and deterministic.

- **MUST** not depend on the real system clipboard in unit tests. The repository ships
  `ClipboardPasteboardReader` as a testable adapter with a `.live` factory; inject a stub/fake
  reader instead of touching `UIPasteboard`/`NSPasteboard`. See
  [platform-specific.md](platform-specific.md).
- **MUST** not depend on test execution order. Each `@Test`/test method must be independently
  valid. Swift Testing may parallelize and shuffle.
- **MUST** not share mutable global state across tests. Construct fresh state per test.
- **MUST** not use arbitrary sleeps (`Thread.sleep`, `Task.sleep(_:)` with magic durations) to wait
  for synchronization. Use `async`/`await`, expectations, `Confirmation`, or polling helpers with
  a bounded timeout.
- **MUST** not depend on external network services. Stub network callers.
- **MUST** not write to production storage. Use in-memory stores and temporary directories.
- **SHOULD** perform explicit cleanup in `tearDown`/defer, even when using in-memory stores.
- **SHOULD** inject a controllable clock (`now: () -> Date`) and a controllable scheduler. The
  repository already injects `now: () -> Date` into `ClipboardMonitor` and uses
  `ClipboardMonitorScheduler` for the polling timer; inject fakes for both.

## Test doubles and dependency injection

Prefer protocol-based seams and injected closures over subclassing production types.

- **Stub** — returns canned data (e.g., `StubPasteboardReader` with fixed `changeCount`/`text`).
- **Fake** — lightweight working implementation (e.g., an in-memory `ModelContainer` via
  `SwiftDataTestSupport`).
- **Spy** — records calls for assertion (e.g., a spy that records emitted clipboard events).
- **Mock** — rare; prefer stubs/fakes/spies.

Inject dependencies via initializers, not singletons. Inject `now: () -> Date`, scheduler, pasteboard
reader, and `ModelContext`. Existing support in the repo: `SwiftDataTestSupport`,
`DeterministicImageFixtureFactory`, `ImageTestFixtures`, `ClipboardWriterTestSupport`.

## Clocks and deterministic async tests

Inject `now: () -> Date` and a controllable scheduler to make time-based behavior deterministic.

- Advance a synthetic clock explicitly; assert ordering, debounce, and dedup windows without real
  waits.
- For polling timers, inject a scheduler that fires on demand instead of `Task.sleep`.
- For `async` sequences, consume events with `await` and bounded `Confirmation`/`XCTestExpectation`
  timeouts. Never spin on `Task.sleep` to wait for emission.

See [concurrency.md](concurrency.md) for the concurrency model
and cancellation semantics that these tests exercise, and [architecture.md](architecture.md) for
persistence boundaries.

## Actor and cancellation tests

Actor isolation and `Task` cancellation must be tested deterministically.

- **Actor isolation:** call `await` on actor methods from tests; assert serialized access by
  interleaving operations and observing a consistent in-state ordering. Use a controlled scheduler so
  task ordering is reproducible.
- **Cancellation:** use `Task.cancel()` (or `withTaskCancellationHandler`) and assert that
  cooperative cancellation points (`try Task.checkCancellation()`, `await` on cancellation-aware
  APIs) surface `CancellationError` or return a defined partial result. Assert cleanup ran (resources
  released, observers removed).
- **Lifecycle transitions:** start → pause → resume → stop, and assert no leaked observers and no
  stray emissions after stop.
- Do NOT rely on timing to prove cancellation. Drive cancellation explicitly and assert the result.

## Clipboard adapter tests (required cases)

Unit tests for the clipboard adapter MUST cover at minimum:

- Duplicate text (same change count, same content) — no re-emit.
- Same text, different representations (string vs RTF vs HTML) — dedup by content identity.
- Emoji text.
- Traditional Chinese text (e.g., "剪貼簿").
- Combining characters and composed/decomposed Unicode (NFC vs NFD) — assert the repo's exact text-equality dedup treats NFC and NFD forms as distinct clips (both stored); do not normalize before compare unless a future spec changes dedup semantics (and then store the original representation).
- Multiline text.
- Very long text (capacity/retention boundary).
- Empty pasteboard.
- Whitespace-only text.
- URLs.
- File URLs.
- Images (use `DeterministicImageFixtureFactory`/`ImageTestFixtures`).
- Multiple pasteboard items in one event.
- Unsupported formats — ignored gracefully, no crash.
- Malformed data — ignored gracefully, no crash.
- Repeated change counts — no duplicate emission.
- Rapid consecutive events — debounce/coalescing behavior asserted.
- App-generated writes — distinguished or handled per spec.
- Paused capture — events suppressed while paused.
- Resumed capture — capture resumes with current change count as baseline.
- Single deletion — recorded.
- Clear-all — recorded.
- Concurrent capture events — serialized, no lost events.
- Persistence failure — surface error, do not crash, do not lose the in-memory event.
- Cancellation — partial result or error, no leaked observers.
- Lifecycle transitions — start/pause/resume/stop covered.

## Persistence and migration tests

SwiftData is the source of truth. Persistence tests MUST:

- Make schema changes explicit. Add new `@Model` types to the schema in `NextPasteApp` and test the
  new container in isolation.
- Test migrations when schema evolves. Do not silently rely on lightweight migration.
- Handle partial writes — assert atomicity/rollback behavior for multi-step writes.
- Corrupted or missing records — assert recovery behavior, no crash.
- Uniqueness and ordering constraints — assert duplicate-record handling under concurrent capture
  and stable ordering by timestamp.
- Transactions — assert commit/rollback semantics through `modelContext`.
- Duplicate records under concurrent capture — dedup/merge behavior asserted.
- Blocking persistence off MainActor — assert persistence does not block the main actor; use
  `@MainActor` assertions and main-thread checker.
- Clear-history — deterministic and testable (assert all records removed, UI refreshes to empty).

Use `SwiftDataTestSupport` for an isolated in-memory `ModelContainer`. See
[architecture.md](architecture.md) and the repository's `ClipItem` schema.

## Preference storage tests (required cases)

When a change adds or modifies a lightweight user preference (see
[architecture.md](architecture.md#lightweight-user-preferences)), tests MUST cover at minimum:

- first-launch default value (no prior write).
- persisted value after relaunch.
- pause and resume transitions (for capture-paused preferences).
- invalid or legacy persisted values (defined recovery behavior).
- key migration when applicable (legacy key → new key, no value loss).
- reset-to-default behavior.
- multiple readers observing the same preference.
- prevention of duplicate writes or observation feedback loops.
- isolation between test runs (no contamination from prior tests).
- App Group suite behavior only when applicable (verify the suite is actually shared).

Tests MUST NOT use the developer's real `UserDefaults` domain. Use one of:

- a unique test suite (`UserDefaults(suiteName:)` with a per-test identifier, removed in
  teardown);
- an injected in-memory fake preference store;
- explicit cleanup in `defer`/`tearDown`.

- **MUST** not depend on test execution order. Construct fresh state per test.
- **MUST** not write to production `UserDefaults`.
- **PROJECT** Follow the target's framework: Swift Testing for `NextPasteTests`. Do not
  `import XCTest` in unit tests.

## Cross-store destructive operation tests (required cases)

When a change implements or modifies a cross-store destructive operation (see
[architecture.md](architecture.md#cross-store-destructive-operations)), tests MUST cover at
minimum:

- successful SwiftData deletion and file deletion.
- SwiftData save failure (records remain, files remain, operation not reported successful).
- file deletion failure after successful database save (committed deletion preserved,
  cleanup debt recorded or retryable, no false rollback claim).
- missing file (operation remains safe and idempotent; missing file classified as recoverable).
- already-deleted file (idempotent retry safe).
- file outside the controlled root (deletion rejected by `ImageClipFileStore`'s
  `pathEscapesRoot` guard).
- shared file still referenced by another record (file not deleted).
- duplicate file references (handled without double-delete or crash).
- repeated clear-all (second execution safe, no unrelated files deleted).
- empty database (clear-all is a no-op, no crash).
- cancellation before `ModelContext` save (no committed database deletion; file cleanup does
  not proceed).
- cancellation after database save (committed deletion preserved; remaining file cleanup
  becomes retryable cleanup debt).
- application interruption between database commit and file cleanup (later orphan cleanup
  recovers safely).
- partial cleanup (some files deleted, some failed; result reports the split correctly).
- orphan cleanup retry (idempotent; safe to run repeatedly).
- large deletion batch (does not block `MainActor`; processes incrementally when appropriate).
- deterministic UI completion state (UI reflects the committed database result, not a pending
  file-cleanup outcome).

Tests MUST:

- use test doubles for the file store (inject a fake `ImageClipFileStore` or wrap `FileManager`
  with an in-memory fake). Do not delete real user files.
- use temporary directories when real file I/O is required; clean up in `defer`/`tearDown`.
- use an isolated in-memory `ModelContainer` (`SwiftDataTestSupport`) where appropriate.
- not use arbitrary sleeps. Drive cancellation and async ordering explicitly.
- not depend on test execution order.

**PROJECT** The repository's single-clip delete (`ClipDeletionAction.delete`) follows the
preferred capture-before-delete ordering and logs file-cleanup failure via `NSLog`. Tests for
new destructive workflows should exercise the failure paths above and assert the
capture-before-delete invariant, not just the happy path.

## UI tests

Use UI tests only for user-visible flows lower layers cannot prove reliably.

- Launch, navigation, clipboard list rendering, paste/copy interactions, and lifecycle transitions
  of the capture pipeline entry points.
- The app uses a `-ui-testing` launch argument to switch to an in-memory `ModelContainer` (see
  `NextPasteApp.makeModelContainer`). UI tests MUST launch with `-ui-testing` so they do not touch
  production storage.
- Do NOT assert pure logic in UI tests that a unit test already covers — that duplicates cost and
  flakiness.

### Accessibility tests

- Assert VoiceOver labels and hints exist for interactive controls.
- Assert focus order is sensible (macOS keyboard tabbing, iOS VoiceOver swipes).
- Assert dynamic type / accessibility traits where applicable.
- Assert controls remain reachable with VoiceOver focused on the list and on the detail view.

## Localization tests

- **MUST** confirm localized resources compile for every supported locale (Traditional Chinese,
  English at minimum).
- Test display with: Traditional Chinese, English, emoji, composed/decomposed Unicode, multiline,
  mixed scripts, and RTL locales where applicable.
- Assert string interpolation does not break under translation (placeholders preserved, plurals
  handled).
- Do NOT hardcode user-facing strings in tests that compare against a single locale unless the test
  is explicitly locale-scoped.

## Scheme and destination discovery

Discover schemes and destinations before inventing them.

```bash
xcodebuild -project NextPaste.xcodeproj -list
```

- The single scheme is `NextPaste`. Prefer the PROJECT commands above before inventing schemes.
- Choose destinations matching `SUPPORTED_PLATFORMS`. Default to `platform=macOS`. Use an iOS
  simulator destination only when the change is iOS-specific and cannot be validated on macOS:
  `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=iOS Simulator,name=iPhone 16' test`.
- visionOS: validate on a visionOS simulator destination only when the change is visionOS-specific.

## SwiftPM validation

This repository is an **Xcode app project**, not a SwiftPM package. There is no `Package.swift`.
Do NOT add one for validation. If a SwiftPM package is ever introduced, add a dedicated validation
section then; until then, the PROJECT `xcodebuild` commands are the only build/test entry points.

## CI parity

No CI workflows are present in the repository. There is no checked-in SwiftLint and no repo-specific
lint script; rely on Xcode diagnostics.

- **SHOULD** run the same `xcodebuild` commands locally that a future CI pipeline would run, so
  local results match CI results.
- **MUST** not claim "CI passes" when no CI exists. State that CI is not configured and report the
  local command outcomes instead.
- **SHOULD** when CI is later added, keep CI steps identical to the PROJECT commands in this file.

## Warning validation

After building/testing, confirm:

- No new compiler warnings.
- No new concurrency warnings (Sendable, actor isolation, data races).
- No new deprecation warnings.
- Deployment-target compatibility — APIs used are available on macOS 26.5, iOS 26.5, and the
  configured visionOS target. The project uses Swift 5 mode with
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; do not silently weaken this.
- Localization resources compile.
- Privacy manifests (`PrivacyInfo.xcprivacy`) compile and package if affected.
- Review entitlements (`NextPaste.entitlements`) and capabilities if the change touches iCloud,
  push, or other entitlements.
- Review the final diff for unrelated changes before reporting completion.

## Release gates

A change is release-ready only when all applicable gates pass and exact commands + outcomes are
reported. Apply gates in order; escalate scope only when justified:

1. Format the changed code.
2. Lint — none configured in this repo; rely on Xcode diagnostics. (If a lint tool is added later,
   run it here.)
3. Build affected targets.
4. Run affected unit tests.
5. Run broader unit tests when shared code changes.
6. Run targeted integration tests when behavior crosses components.
7. Run relevant UI tests for user-visible changes.
8. No new compiler warnings.
9. No new concurrency warnings.
10. No new deprecation warnings.
11. Deployment-target compatibility confirmed.
12. Localization resources compile.
13. Privacy manifests compile/package if affected.
14. Review entitlements/capabilities if affected.
15. Review the final diff for unrelated changes.
16. Report exact commands and exact results.

If any gate fails or cannot run, the change is NOT release-ready. Report the failing gate, the
command, and the reason. Do not proceed to a later gate by skipping an earlier one.

## Reporting

Every validation report MUST include:

- The exact command(s) executed.
- The exact outcome (pass/fail, test counts, warnings/errors).
- The scope run (targeted unit / integration / UI / full regression) and the reason for that scope.
- Any gate that did not run and why.
- A clear release-ready / not-release-ready verdict.

Do not summarize validation with vague language ("looks good", "should pass"). Report facts.