# Automated Verification Map

This document maps the automated-acceptance brief supplied for the OCR, Settings, retention,
appearance, Pin-scroll, accessibility, and verification-infrastructure work to the current
repository. It is an evidence inventory, not a test-result report.

## Current truth state

As of 2026-07-11, the full verification command has **not** been executed against this worktree.
Consequently:

- No build, unit, integration, UI, localization, accessibility, or coverage result is claimed as
  passing here.
- Runtime totals, pass/fail/skip counts, `.xcresult` paths, and numeric code coverage are unknown.
- A mapped test means that executable evidence exists and is selected by the verification
  infrastructure; it does not mean that the test has passed in this worktree.
- Any partial or missing mapping blocks acceptance. It must be resolved with automation and then
  exercised by the full gate.

The status labels used below are:

| Status | Meaning |
| --- | --- |
| **Mapped — run pending** | A concrete XCTest, Swift Testing test, or XCUITest covers the requirement and is selected by the Test Plan/script, but the full gate has not run. |
| **Partial — run pending** | Automated evidence exists, but one or more assertions or required variants are absent. |
| **Pending — test absent** | No current automated test completely proves the requirement. |
| **Static-validated** | Configuration syntax/discovery or a dry run was checked without compiling or executing product tests. |

## Zero-manual-verification policy

Manual verification steps in this acceptance plan: **0**.

Manual app operation, visual inspection, the user's real clipboard/settings/database, and a
request for somebody else to “confirm” behavior are not acceptable substitutes. A row marked
partial or pending remains unfinished until an automated test covers it and `Scripts/verify.sh`
records a zero-failure, zero-skip result.

## Automated test architecture

| Boundary | Production path | Automated substitute or isolation | Evidence |
| --- | --- | --- | --- |
| OCR | `ImageTextRecognizing` implemented by the local-only `VisionImageTextRecognizer` actor | Deterministic immediate, controlled, cancellation-observing, and Debug UI-test recognizers | `ImageTextRecognizerTests`, `VisionImageTextRecognizerIntegrationTests`, `ImageTextRecognitionCoordinatorTests`, `ImageOCRContextMenuUITests` |
| Clipboard writes | `ClipboardTextWriting` / `SystemClipboardTextWriter` and `NSPasteboard` | UUID-named pasteboards; sentinel content; injected writer doubles | `ClipboardWriterTests`, `ImageTextRecognitionCoordinatorTests`, `ImageOCRContextMenuUITests` |
| Language, storage limit, appearance | Preference objects backed by injected `UserDefaults` | Unique `UserDefaults` suites in unit tests and one UUID suite per UI test | `AppLanguagePreferenceTests`, `HistoryLimitPreferenceTests`, `AppearancePreferenceTests`, `UITestLaunchEnvironment` |
| Clipboard-item storage | Local SwiftData is the product source of truth | In-memory ModelContainers, temporary stores, and a unique per-UI-test on-disk store URL | `SwiftDataTestSupport`, retention tests, `UITestLaunchEnvironment` |
| Image files | Local `ImageClipFileStore` | Unique temporary image roots / per-UI-test image directory | `ClipboardWriterTests`, `HistoryRetentionServiceTests`, `UITestLaunchEnvironment` |
| Pin scrolling | `PinScrollRequestState`, `HistoryViewportVisibility`, native Pin action, and real `scrollTo` path | Pure-state unit tests plus read-only Debug accessibility diagnostics updated by the product path | `PinScrollRequestStateTests`, `HistoryViewportVisibilityTests`, `PinScrollAutomationUITests` |
| UI launch state | Normal product scene and feature paths | Centralized Debug-only `-ui-testing` environment; complete environment tuple required | `DebugUITestLaunchEnvironment`, `UITestAppLauncher`, `UITestCase` |

Every XCUITest receives a unique identifier, defaults suite, SwiftData store URL, image-data
directory, and named pasteboard. `UITestCase` creates the environment before each test and removes
the defaults domain, pasteboard contents, and temporary directory during teardown. UI tests are
serialized by both the Test Plan (`parallelizable: false`) and the script
(`-parallel-testing-enabled NO`). The fake OCR boundary does not bypass the real context-menu
action, coordinator state machine, item validation, normalization, or pasteboard command.

The repository uses both XCTest/XCUITest and its pre-existing Swift Testing unit-test convention.
No third-party test framework is introduced.

## Test Plan and one-command gate

`NextPaste.xctestplan` is referenced by the shared `NextPaste` scheme and contains these named
configurations:

| Configuration | Script selection | Purpose |
| --- | --- | --- |
| `Unit` | `NextPasteTests`, excluding `VisionImageTextRecognizerIntegrationTests` | All unit, source-policy, localization-catalog, preference, store, and coordinator tests |
| `Integration` | Only `NextPasteTests/VisionImageTextRecognizerIntegrationTests` | Real Apple Vision smoke tests |
| `UI` | `NextPasteUITests`, non-parallel | All end-to-end XCUITests |

Code coverage and test timeouts are enabled in the Test Plan. Coverage is scoped to the
`NextPaste.app` target. The plan contains project-relative references only.

From the repository root, the authoritative full gate is:

```bash
Scripts/verify.sh
```

To retain the otherwise-temporary evidence at an explicit temporary location:

```bash
VERIFY_ARTIFACTS_DIR="${TMPDIR:-/tmp}/NextPasteVerification" Scripts/verify.sh
```

The non-executing configuration check is:

```bash
Scripts/verify.sh --dry-run
```

The script resolves a full Xcode installation, honors an already-valid `DEVELOPER_DIR`, uses
`set -euo pipefail`, and performs these exact phase selections:

```bash
# Preflight/discovery
xcodebuild -list -json -project NextPaste.xcodeproj
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -showTestPlans

# Debug product build (the script repeats this command with
# `-configuration Release` and `DebugBuild`/`ReleaseBuild` result names)
xcodebuild -quiet \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -configuration Debug \
  -derivedDataPath '<run-dir>/DerivedData' \
  -resultBundlePath '<run-dir>/DebugBuild.xcresult' \
  build

# Build app and both test targets once
xcodebuild -quiet \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -configuration Debug \
  -derivedDataPath '<run-dir>/DerivedData' \
  -resultBundlePath '<run-dir>/TestBuild.xcresult' \
  -testPlan NextPaste \
  -enableCodeCoverage YES \
  build-for-testing

# Before each test phase, the script runs the same selection with
# `-enumerate-tests -test-enumeration-style flat -test-enumeration-format json`
# and writes `<phase>-inventory.json`. The executed xcresult count must exactly
# equal that inventory count.

# Unit tests, including localization completeness
xcodebuild -quiet \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -testPlan NextPaste \
  -only-test-configuration Unit \
  -destination 'platform=macOS' \
  -configuration Debug \
  -derivedDataPath '<run-dir>/DerivedData' \
  -enableCodeCoverage YES \
  -resultBundlePath '<run-dir>/Unit.xcresult' \
  -only-testing:NextPasteTests \
  -skip-testing:NextPasteTests/VisionImageTextRecognizerIntegrationTests \
  test-without-building

# Real Vision integration tests
xcodebuild -quiet \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -testPlan NextPaste \
  -only-test-configuration Integration \
  -destination 'platform=macOS' \
  -configuration Debug \
  -derivedDataPath '<run-dir>/DerivedData' \
  -enableCodeCoverage YES \
  -resultBundlePath '<run-dir>/Integration.xcresult' \
  -only-testing:NextPasteTests/VisionImageTextRecognizerIntegrationTests \
  test-without-building

# All UI tests, serialized
xcodebuild -quiet \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -testPlan NextPaste \
  -only-test-configuration UI \
  -destination 'platform=macOS' \
  -configuration Debug \
  -derivedDataPath '<run-dir>/DerivedData' \
  -enableCodeCoverage YES \
  -resultBundlePath '<run-dir>/UI.xcresult' \
  -parallel-testing-enabled NO \
  -only-testing:NextPasteUITests \
  test-without-building

# Catalog parse check; semantic completeness runs in LocalizationCatalogTests
plutil -convert json -o /dev/null NextPaste/Localizable.xcstrings
```

`<run-dir>` is a fresh `mktemp` directory created by the script. `--dry-run` prints the actual
resolved Xcode binary and generated paths. Formatter and lint are reported truthfully as
“Project not configured”; the repository contains neither a formatter command/configuration nor
SwiftLint/repository lint configuration.

## Result and artifact contract

No artifacts listed here currently constitute a test result because the full gate has not run.
On a full run, the script creates the following under its printed run directory:

| Artifact | Purpose |
| --- | --- |
| `xcodebuild-list.json`, `test-plans.txt` | Project/scheme/Test Plan discovery evidence |
| `DebugBuild.xcresult`, `DebugBuild-build-summary.json` | Debug product build evidence |
| `ReleaseBuild.xcresult`, `ReleaseBuild-build-summary.json` | Release product build and test-surface isolation evidence |
| `TestBuild.xcresult`, `TestBuild-build-summary.json` | Build-for-testing evidence |
| `<phase>-inventory.json` | Xcode-enumerated test inventory that the phase must execute exactly |
| `Unit.xcresult`, `Unit-summary.json` | Unit and localization result evidence |
| `Integration.xcresult`, `Integration-summary.json` | Real Vision result evidence |
| `UI.xcresult`, `UI-summary.json` | XCUITest result evidence and attachments |
| `<phase>-coverage.txt`, `<phase>-coverage.json` | `xccov` target summary and machine-readable coverage |
| `<phase>-tests.json` | Detailed tests, emitted when a phase is not clean |

For every test phase, `xcresulttool` must report a `Passed` result, an executed count exactly equal
to Xcode's pre-run enumerated inventory, `passed == total`, zero failures, zero skips, and zero
expected failures. `xccov` must find `NextPaste.app` in every phase bundle. No minimum coverage
percentage is currently specified or enforced; numeric coverage
therefore remains pending until the gate runs. Each build result must also contain a complete
build summary with `status == succeeded` and `errorCount == 0`; missing summary fields fail closed.
DerivedData and `.xcresult` are written beneath the temporary run directory. The script rejects an
artifacts directory inside the repository and performs explicit preflight and postflight scans for
`DerivedData`, `build`, `.build`, `.xcresult`, `.xcarchive`, `.dSYM`, `.app`, and profiling output;
the gate does not rely on ignore rules hiding generated files.

No repository CI configuration was found. Therefore there is no CI run or CI artifact to claim,
and CI integration remains pending. The complete Test Plan and executable local gate are ready to
be invoked by a macOS CI job without weakening the local verification contract.

## Acceptance traceability

### A. Automation, isolation, and stability

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| A-01 | Every acceptance item is automated; no manual substitute | This map, `Scripts/check-test-hygiene.sh`, and `Scripts/verify.sh` identify and enforce the available evidence | **Partial — run pending.** The explicitly pending rows at the end of this document must be automated before acceptance. |
| A-02 | Use Apple test APIs and existing Swift Testing only | XCTest/XCUITest targets, Swift Testing unit target, Test Plan, Vision, NSPasteboard, UserDefaults, SwiftData | **Mapped — run pending.** |
| A-03 | Platform boundaries are injectable/testable | `ImageTextRecognizing`, `ClipboardTextWriting`, injected `UserDefaults`, in-memory/temporary SwiftData, `PinScrollRequestState` | **Mapped — run pending.** Names differ from the brief's examples but preserve the required seams. |
| A-04 | Test doubles replace only nondeterministic boundaries | `testImageOCRContextMenuCopiesRecognizedMultilineText`; `testImageOCRNoTextLeavesNamedPasteboardUnchanged`; `testImageOCRErrorIsLocalizedAndDoesNotModifyNamedPasteboard`; `testImageOCRLoadingTransitionsFromDisabledToRecognizedAction` | **Mapped — run pending.** These drive the real row/context-menu/coordinator/write path. |
| A-05 | Keep a real Apple Vision integration smoke test | `VisionImageTextRecognizerIntegrationTests` | **Mapped — run pending.** |
| A-06 | UI tests isolate defaults, data, pasteboard, and fixtures and clean up | `NextPasteUITests.testIsolatedLaunchExposesReadyMainWindow`; all tests inherit `UITestCase`; `UITestLaunchEnvironmentRegistry` setup/teardown | **Mapped — run pending.** |
| A-07 | Test-only state is Debug/UI-test-only and uses stable accessibility identifiers | `DebugUITestLaunchEnvironment`; `DebugUITestSurfaceIsolationTests`; `RelaunchStabilityTests.uiTestSurfacesRemainDebugOnly`; Debug-only seeder/probes; Release build | **Mapped — run pending.** Complete environment validation, not a bare launch argument, gates storage, monitor overrides, simulated failures, and probes; Release compiles the inert branches. |
| A-08 | Tests can run independently, repeatedly, and without fixed delays | Per-test UUID environment; `NativeSwipeTestSupportPolicyTests`; Pin source-policy tests; executable `Scripts/check-test-hygiene.sh` scans both targets and compares every UI-test `for`/`while` token against `Scripts/ui-test-loop-inventory.txt` | **Mapped — run pending.** The fail-closed gate rejects XCTest skips/expected failures, Swift Testing disabled/conditional/known-issue traits, fixed sleeps/run-loop pumping, commented tests, empty XCTest/Swift Testing functions, literal always-true assertions, and any unreviewed loop change. |
| A-09 | UI tests do not depend on a fixed window unless they set it | `UITestAppLauncher.WindowSizePreset`; every Pin-scroll XCUITest requests a deterministic preset | **Mapped — run pending.** |
| A-10 | No network dependency or user production state | Per-test local stores/pasteboards/defaults; `ClipboardImagePrivacyTests` local-only coverage | **Mapped — run pending.** |

### B. OCR core state: all 20 requested cases

| ID | OCR acceptance case | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| OCR-01 | Successful OCR returns valid text | `ImageTextRecognitionCoordinatorTests.successfulRecognitionWritesText` | **Mapped — run pending.** |
| OCR-02 | Leading/trailing whitespace is handled | `successfulRecognitionWritesText`; `ImageTextRecognizerTests.preservesRecognizedContentStructure` | **Mapped — run pending.** |
| OCR-03 | Multiline text is handled | `successfulRecognitionWritesText`; `preservesRecognizedContentStructure`; `normalizesLineEndings` | **Mapped — run pending.** |
| OCR-04 | Whitespace-only result becomes no text | `ImageTextRecognitionCoordinatorTests.whitespaceAndNoTextNeverWrite`; parameterized `ImageTextRecognizerTests.rejectsEmptyOrWhitespaceOnlyResults` | **Mapped — run pending.** |
| OCR-05 | Newline-only result becomes no text | Parameterized `rejectsEmptyOrWhitespaceOnlyResults` includes the dedicated `"\n\n"` fixture; `whitespaceAndNoTextNeverWrite` covers the coordinator result | **Mapped — run pending.** |
| OCR-06 | No recognition result (`nil`) | `whitespaceAndNoTextNeverWrite`; empty-fragment case of `rejectsEmptyOrWhitespaceOnlyResults` | **Mapped — run pending.** |
| OCR-07 | Recognizer throws | `ImageTextRecognitionCoordinatorTests.recognizerFailureDoesNotWriteAndCanRetry` | **Mapped — run pending.** |
| OCR-08 | OCR Task is cancelled | `cancellationIgnoresLateResult`; `removalPropagatesCancellationToRecognizer`; `cancelAllCancelsInflightAndClearsCache` | **Mapped — run pending.** |
| OCR-09 | Concurrent duplicate requests coalesce | `repeatedRequestsCoalesce` | **Mapped — run pending.** |
| OCR-10 | Valid cache prevents repeat recognition | `successfulResultIsCached` | **Mapped — run pending.** |
| OCR-11 | Changed image content invalidates old cache/request | `reconcileCancelsDeletedAndChangedFingerprintRequests`; `staleGenerationCannotOverwriteNewerRequest` | **Mapped — run pending.** |
| OCR-12 | Result arriving after item deletion is ignored | `cancellationIgnoresLateResult`; `currentItemValidationRejectsDeletedItem`; `cachedWriteRejectsExternallyDeletedItem` | **Mapped — run pending.** |
| OCR-13 | Old request cannot overwrite newer result | `staleGenerationCannotOverwriteNewerRequest`; `newestCrossItemCopyIntentWins`; `newestIntentWinsAcrossSuspendingCachedWrite` | **Mapped — run pending.** |
| OCR-14 | Result applies only to the same stable item ID | `currentItemValidationRejectsDeletedItem`; `newestCrossItemCopyIntentWins`; request identity assertions in `staleGenerationCannotOverwriteNewerRequest` | **Mapped — run pending.** |
| OCR-15 | Recognition failure is contained, not an unhandled exception | `recognizerFailureDoesNotWriteAndCanRetry`; `writerFailureDoesNotClaimSuccess` | **Mapped — run pending.** |
| OCR-16 | No-text does not create a copyable empty string | `whitespaceAndNoTextNeverWrite`; `ClipboardWriterTests.nonemptyTextWriterRejectsEmptyStringWithoutChangingInjectedPasteboard` | **Mapped — run pending.** |
| OCR-17 | Outer whitespace is removed correctly | `successfulRecognitionWritesText`; `preservesRecognizedContentStructure` | **Mapped — run pending.** |
| OCR-18 | Meaningful internal line breaks are retained | `successfulRecognitionWritesText`; `preservesRecognizedContentStructure`; `normalizesLineEndings` | **Mapped — run pending.** |
| OCR-19 | Expensive Vision recognition is proven not to run on MainActor | `VisionImageTextRecognizerIntegrationTests.expensiveVisionPerformHasANonMainActorExecutorBoundary` verifies that the synchronous `handler.perform` call is inside the `VisionImageTextRecognizer` actor implementation and that implementation is not `@MainActor` | **Mapped — run pending.** |
| OCR-20 | UI state updates complete safely on MainActor | `ImageTextRecognitionCoordinator` and its suite are `@MainActor`; `inflightRequestPublishesRecognizingBeforeCompletion` and terminal-state tests observe state transitions | **Mapped — run pending.** Compile-time actor isolation plus state-transition execution is the automated evidence. |

### C. Real Vision integration

| ID | Acceptance requirement | Automated evidence | Status |
| --- | --- | --- | --- |
| VIS-01 | Generate a deterministic high-contrast local image | `VisionImageTextRecognizerIntegrationTests.recognizesGeneratedBitmapText` / `LocalVisionImageFixture` | **Mapped — run pending.** |
| VIS-02 | Real `VNRecognizeTextRequest` completes with nonempty expected major tokens | `recognizesGeneratedBitmapText` canonicalizes the result and asserts `NEXTPASTE` and `7429` | **Mapped — run pending.** It intentionally avoids brittle full-string equality. |
| VIS-03 | Blank image safely yields no text | `returnsNoTextForBlankBitmap` | **Mapped — run pending.** |
| VIS-04 | Invalid image data safely throws | `invalidImageDataThrowsWithoutCrashing` | **Mapped — run pending.** |
| VIS-05 | Deployment/API availability is compatible | The integration suite and adapter compile in the macOS target; adapter guards `automaticallyDetectsLanguage` availability | **Mapped — run pending.** Build execution is still pending. |

### D. OCR context menu and pasteboard

| ID | Acceptance requirement | Automated evidence | Status |
| --- | --- | --- | --- |
| OCRUI-01 | Success: capture image, `rightClick()`, native Copy Image Text exists/enabled, exact multiline text reaches named pasteboard, nonempty | `ImageOCRContextMenuUITests.testImageOCRContextMenuCopiesRecognizedMultilineText` | **Mapped — run pending.** |
| OCRUI-02 | No text: action becomes absent/disabled and sentinel remains | `testImageOCRNoTextLeavesNamedPasteboardUnchanged` | **Mapped — run pending.** |
| OCRUI-03 | Error: app remains running, copy is unavailable, pasteboard unchanged, localized error shown | `testImageOCRErrorIsLocalizedAndDoesNotModifyNamedPasteboard` | **Mapped — run pending.** Uses Traditional Chinese assertions. |
| OCRUI-04 | In progress: disabled loading item, controlled completion, action becomes enabled | `testImageOCRLoadingTransitionsFromDisabledToRecognizedAction` | **Mapped — run pending.** |
| OCRUI-05 | Existing original-image Copy, Pin/Unpin, Delete still execute | `testImageContextMenuOriginalCopyPinUnpinAndDeleteActionsExecute`; `ClipboardImageRowActionsUITests.testImageContextMenuExposesIdleCopyTextAndPreservesExistingActions` | **Mapped — run pending.** |
| PB-01 | UI/App processes share one unique named pasteboard and clean it | All `UITestCase` tests via `UITestLaunchEnvironment`; OCR UI tests use `UITestAppLauncher.pasteboard(for:)` | **Mapped — run pending.** |
| PB-02 | Writer clears incompatible contents and writes `.string` readable as identical text | `ClipboardWriterTests.namedPasteboardWriterClearsPriorTypesAndWritesOnlyString`; `nonemptyTextWriterPreservesExactMultilineContentOnInjectedPasteboard` | **Mapped — run pending.** |
| PB-03 | Empty text is not written | `nonemptyTextWriterRejectsEmptyStringWithoutChangingInjectedPasteboard` | **Mapped — run pending.** |
| PB-04 | Whitespace-only text is not written | `nonemptyTextWriterRejectsWhitespaceWithoutChangingInjectedPasteboard` | **Mapped — run pending.** |
| PB-05 | Writer failure does not alter existing content | `simulatedNonemptyTextFailureLeavesInjectedPasteboardUnchanged`; OCR coordinator writer-failure cases | **Mapped — run pending.** |
| PB-06 | User general pasteboard is not a test dependency | OCR/UI tests and every `ClipboardWriterTests` text-copy case now use UUID named pasteboards with teardown clearing | **Mapped — run pending.** The prior `.general` writer fixtures were replaced by injected named pasteboards. |

### E. Language and localization

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| LANG-01 | `en_us` encodes/decodes | Parameterized `AppLanguagePreferenceTests.supportedLanguagesRoundTripThroughCodable` | **Mapped — run pending.** |
| LANG-02 | `zh_TW` encodes/decodes | `supportedLanguagesRoundTripThroughCodable` | **Mapped — run pending.** |
| LANG-03 | Unknown raw value falls back safely | `unknownLegacyValueFallsBackAndRepairsStorage` | **Mapped — run pending.** |
| LANG-04 | Missing defaults value selects default language | `missingValueDefaultsToEnglishAndRepairsStorage` | **Mapped — run pending.** |
| LANG-05 | Corrupt/non-string defaults value does not crash | `nonStringPersistedValueFallsBackWithoutCrashingAndRepairsStorage` | **Mapped — run pending.** |
| LANG-06 | Recreated preference reads the stored language | `bothSupportedLanguagesPersistAcrossInstances` | **Mapped — run pending.** |
| LANG-07 | Product raw values map to Apple locale/localization identifiers | `productRawValuesAndAppleMappingsAreStable` | **Mapped — run pending.** |
| LANG-08 | Feature localization keys have nonempty English and Traditional Chinese values | `LocalizationCatalogTests.featureKeysHaveConcreteEnglishAndTraditionalChineseValues` | **Mapped — run pending.** |
| LANGUI-01 | UI uses isolated defaults and finds the picker by stable identifier | `SettingsUITests.testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch`; `languagePopup` requires `app-language-picker` | **Mapped — run pending.** |
| LANGUI-02 | Select English and verify English UI | `testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` asserts the English picker value and the stable `app-language-description` element's English text | **Mapped — run pending.** |
| LANGUI-03 | Select Traditional Chinese and verify the same UI updates immediately | `testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` uses keyboard selection and asserts the same picker and description in Traditional Chinese | **Mapped — run pending.** |
| LANGUI-04 | Relaunch with the same suite and retain Traditional Chinese | `testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` performs the Chinese relaunch assertions | **Mapped — run pending.** |
| LANGUI-05 | Switch back to English, relaunch again, and retain English | `testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` switches back, terminates, relaunches, and reasserts the English picker and description | **Mapped — run pending.** |
| LOC-01 | Catalog contains all required branch keys | `LocalizationCatalogTests.stringCatalogContainsBranchFeatureLocalizationKeys` | **Mapped — run pending.** |
| LOC-02 | No missing/empty feature translation in either supported locale | `stringCatalogHasTranslatedValuesForProjectSupportedLocales`; `featureKeysHaveConcreteEnglishAndTraditionalChineseValues` | **Mapped — run pending.** Traditional Chinese completeness is intentionally scoped to the branch-owned `featureBilingualKeys`. |
| LOC-03 | Resource is included in the correct target and readable from the built bundle | `LocalizationCatalogTests.compiledAppBundleContainsEveryFeatureStringForBothLocales` locates the compiled `en.lproj` and `zh-Hant.lproj` in `Bundle(for: ClipItem.self)` and compares every feature key with the catalog | **Mapped — run pending.** |
| LOC-04 | Localization fallback never returns an empty string | `LocalizationCatalogTests.unknownLocaleFallsBackToANonemptyLocalizedValue` performs an unknown-locale bundle lookup | **Mapped — run pending.** |
| LOC-05 | Critical UI text is displayed in both locales | `SettingsUITests.testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` asserts the same language controls/text in both locales; `ImageOCRContextMenuUITests.testImageOCRErrorIsLocalizedAndDoesNotModifyNamedPasteboard` asserts Chinese OCR, retry, original-copy, Pin, and Delete labels while the English OCR tests assert the English surface | **Mapped — run pending.** |

### F. Storage-limit parsing, UI, persistence, and retention

#### Input policy and preference

| ID | Acceptance requirement | Automated evidence | Status |
| --- | --- | --- | --- |
| LIMIT-01 | Accept `1`, `2`, a middle value, `999`, and `1000` | Parameterized `HistoryLimitPreferenceTests.validValuesRemainUnchanged`; `commitAcceptsIntegersAndClampsOutOfRange` | **Mapped — run pending.** |
| LIMIT-02 | Accept surrounding whitespace on a valid integer | `commitAcceptsIntegersAndClampsOutOfRange` (`"  25  "`) | **Mapped — run pending.** |
| LIMIT-03 | Reject empty and whitespace-only drafts | `commitRestoresCurrentValueForEmptyOrUnparseableInput` | **Mapped — run pending.** |
| LIMIT-04 | Clamp `0`, `-1`, other negatives, `1001`, and larger integers | `constructionClampsOutsideRange`; `commitAcceptsIntegersAndClampsOutOfRange` | **Mapped — run pending.** |
| LIMIT-05 | Reject decimals (`1.0`, `1.5`) | `commitRestoresCurrentValueForEmptyOrUnparseableInput` | **Mapped — run pending.** |
| LIMIT-06 | Reject letters, alphanumeric, symbols, non-ASCII digits, and non-Int text | `commitRestoresCurrentValueForEmptyOrUnparseableInput` (`abc`, `12abc`, `#42`, `１２`, `NaN`, `∞`, signs) | **Mapped — run pending.** |
| LIMIT-07 | Safely clamp huge positive/negative integers | `commitAcceptsIntegersAndClampsOutOfRange` | **Mapped — run pending.** |
| LIMIT-08 | Invalid draft does not persist and restores the prior valid value | `commitRestoresCurrentValueForEmptyOrUnparseableInput` asserts `shouldPersist == false` and prior normalized text | **Mapped — run pending.** |
| LIMIT-09 | Slider/formal value remains an integer in `[1, 1000]` | Bounds/clamp tests; Settings slider uses `step: 1` and rounds into `HistoryLimit` | **Mapped — run pending.** |
| LIMIT-10 | UserDefaults never leaves an invalid formal value; corrupt legacy data repairs | `legacyNSNumberIntegersAreNormalized`; `fractionalOrNonfiniteLegacyNumbersRepairToDefault`; `persistedIntegerDataIsNormalizedAndRepaired`; migration/corrupt-data tests | **Mapped — run pending.** |
| LIMIT-11 | Recreated preference retains a legal value | `persistedLimitSurvivesNewInstance` | **Mapped — run pending.** |

#### Storage-limit UI

Current storage-limit UI evidence is distributed across the boundary/synchronization,
invalid-input/focus-loss, and real-retention tests named below.

| ID | Required XCUITest variant | Current assertion | Status / remaining gap |
| --- | --- | --- | --- |
| LIMITUI-01 | Type `1`, Return, Slider becomes minimum | `SettingsUITests.testHistoryLimitSliderAndFieldSynchronizeAtBoundariesAndIntermediateInteger` commits `1` through the TextField and asserts both controls | **Mapped — run pending.** |
| LIMITUI-02 | Type `1000`, Return, Slider becomes maximum | Exact field and slider value assertions | **Mapped — run pending.** |
| LIMITUI-03 | Type `0`, commit, legal recovery/clamp | `SettingsUITests.testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` asserts clamp to `1` in both controls | **Mapped — run pending.** |
| LIMITUI-04 | Type `1001`, commit, clamp to `1000` | Exact recovery assertion | **Mapped — run pending.** |
| LIMITUI-05 | Type a negative value; never make it formal | `testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` commits `-17` and asserts the legal value `1` | **Mapped — run pending.** |
| LIMITUI-06 | Type a decimal; never make it formal | `testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` keeps the Slider at `437` while editing `1.5`, then restores `437` on Return | **Mapped — run pending.** |
| LIMITUI-07 | Type letters; restore prior valid value | `letters` returns to `1000` | **Mapped — run pending.** |
| LIMITUI-08 | Clear the field; app remains running | `testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` clears the field, commits by Return and Tab, and asserts `.runningForeground` | **Mapped — run pending.** |
| LIMITUI-09 | Commit empty field; restore prior valid value | `testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` asserts restoration to the previous value after both Return and focus-loss commits | **Mapped — run pending.** |
| LIMITUI-10 | Slider change immediately updates field | Minimum and maximum normalized-position adjustments update the field | **Mapped — run pending.** |
| LIMITUI-11 | Slider never emits a fractional formal value | `testHistoryLimitSliderAndFieldSynchronizeAtBoundariesAndIntermediateInteger` adjusts to normalized position `0.5`, parses the accessibility value as `Int`, rejects a decimal point, and asserts matching field text | **Mapped — run pending.** |
| LIMITUI-12 | Relaunch retains the value | The same isolated suite relaunches and asserts `1` | **Mapped — run pending.** |

#### Retention/store behavior

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| RET-01 | Create more unpinned items than capacity and lower capacity | `HistoryRetentionServiceTests.overLimitRemovesOldestUnpinned`; UI storage-limit test | **Mapped — run pending.** |
| RET-02 | Remove the oldest unpinned items | `overLimitRemovesOldestUnpinned`; `enforceLimitActuallyDeletesItems` | **Mapped — run pending.** |
| RET-03 | Keep newest items | `retentionPreservesCanonicalNewestFirstOrder`; UI storage-limit test | **Mapped — run pending.** |
| RET-04 | Never remove pinned items | `pinnedItemsNeverCountTowardLimit`; `enforceLimitWithPinnedKeepsAllPinned`; `retentionDoesNotTrimPinnedAfterCapture` | **Mapped — run pending.** |
| RET-05 | Preserve canonical ordering | `deterministicOrderingRemovesConsistently`; `retentionPreservesCanonicalNewestFirstOrder` | **Mapped — run pending.** |
| RET-06 | Define behavior at limit `1` | `HistoryRetentionServiceTests.limitOneKeepsOnlyTheNewestUnpinnedItem`; pinned and UI limit-one cases | **Mapped — run pending.** |
| RET-07 | Define behavior at limit `1000` | `maximumLimitRemovesNothingWhenUnderLimit`; `maximumLimitTrimsOnlyTheSingleOldestItemFromOneThousandAndOne` | **Mapped — run pending.** |
| RET-08 | Pinned count equals limit | `enforceLimitWithPinnedKeepsAllPinned` uses two pinned items and limit two while separately limiting unpinned items | **Mapped — run pending.** Product policy explicitly excludes pinned items from capacity. |
| RET-09 | Pinned count exceeds limit | `pinnedCountAboveTheLimitStillPreservesEveryPinnedItem`; `pinnedItemsNeverCountTowardLimit` | **Mapped — run pending.** |
| RET-10 | Rapid consecutive capacity changes converge without a race | `rapidLimitChangesEndAtLatestValidCapacity` executes the serialized `@MainActor` service through multiple rapid limits and asserts the final latest valid capacity and ordering | **Mapped — run pending.** |
| RET-11 | Delete/save failure leaves rows and image/thumbnail files consistent | `saveFailureRollsBackAllPendingRetentionDeletes` currently proves row rollback | **Partial — run pending.** Image and thumbnail preservation on save failure still needs a direct assertion. |
| RET-12 | Capacity handling is not repeatedly run in View rendering | `HistoryRetentionServiceTests.SettingsViewDoesNotEnforceRetentionDuringBodyEvaluation` source-checks the `HistorySettingsTab` body/event-handler region and confirms enforcement exists only in `apply`; `HistoryRetentionHookTests` covers event boundaries | **Mapped — run pending.** |
| RET-13 | Trimming image items removes local files only after store save | `trimmingAnImageRemovesItsFilesAfterTheStoreSave` | **Mapped — run pending.** Additional local-file consistency evidence. |

### G. Appearance

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| APP-01 | Light encodes/decodes and persists | `AppearancePreferenceTests.lightRoundTripsThroughCodable`; parameterized `everyAppearanceModePersistsAcrossInstances` | **Mapped — run pending.** |
| APP-02 | Dark encodes/decodes and persists | `darkRoundTripsThroughCodable`; `persistedModeSurvivesNewInstance`; `everyAppearanceModePersistsAcrossInstances` | **Mapped — run pending.** |
| APP-03 | Follow System encodes/decodes and persists | `systemRoundTripsThroughCodable`; `everyAppearanceModePersistsAcrossInstances` | **Mapped — run pending.** |
| APP-04 | Unknown legacy value falls back | `invalidPersistedModeFallsBackToSystem` | **Mapped — run pending.** |
| APP-05 | Values map to SwiftUI `ColorScheme` and native AppKit appearance | `systemMapsToNilColorScheme`; `lightMapsToLightColorScheme`; `darkMapsToDarkColorScheme`; `appearanceModesMapToNativeAppKitAppearances` | **Mapped — run pending.** |
| APPUI-01 | Picker exposes System/Light/Dark and each choice updates the app | `SettingsUITests.testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight` proves option exposure plus Light/Dark switching | **Partial — run pending.** Follow System is exposed but not selected and verified across relaunch. |
| APPUI-02 | Root effective appearance is light/dark, based on real environment/AppKit state | `testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight` queries the `effective-appearance-main` environment probe for Light and Dark, including relaunches | **Mapped — run pending.** |
| APPUI-03 | Main list and Settings window receive the same appearance | `testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight` asserts `effective-appearance-main` and `effective-appearance-settings` together after each change/relaunch | **Mapped — run pending.** |
| APPUI-04 | Dark survives relaunch | `testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight` | **Mapped — run pending.** |
| APPUI-05 | Light survives a subsequent relaunch | `testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight` switches the dark-relaunched app to Light, relaunches again, and asserts both probes and picker | **Mapped — run pending.** |
| APPUI-06 | Appearance switching leaves the active window usable | The same test asserts the Settings window remains enabled and continues operating after changes | **Mapped — run pending.** |

### H. Pin-scroll coordinator and end-to-end behavior

#### Unit/state acceptance

| ID | Acceptance case | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| PIN-01 | Applied unpinned-to-pinned mutation creates a request | `PinScrollRequestStateTests.appliedPinCreatesStableIDRequest` | **Mapped — run pending.** |
| PIN-02 | Unpin creates no Pin-scroll request | `unpinAndNoOpDoNotRequestScrolling` | **Mapped — run pending.** |
| PIN-03 | Still-visible/no-op Pin avoids unnecessary scrolling | `unpinAndNoOpDoNotRequestScrolling`; `fullyVisibleTargetDoesNotScroll` | **Mapped — run pending.** |
| PIN-04 | Offscreen target requests scrolling | `offscreenLazyRowRequestsScroll` | **Mapped — run pending.** |
| PIN-05 | Request uses stable item ID | `appliedPinCreatesStableIDRequest`; `offscreenLazyRowRequestsScroll` | **Mapped — run pending.** |
| PIN-06 | Mutation/scroll identity never uses array index | `PinStateMutationSourcePolicyTests.testPinStateMutationStoreAcceptsItemIDAndDesiredStateNotRowIndex`; `testHomeViewPinUnpinProductionCallDoesNotUseRowIndexAsIdentity` | **Mapped — run pending.** |
| PIN-07 | Rapid Pin A/B/C retains only C | `rapidPinsABCOnlyRetainC`; `rapidPinsRetainLatestRequest` | **Mapped — run pending.** |
| PIN-08 | Stale A completion cannot consume C | `rapidPinsABCOnlyRetainC`; `rapidPinsRetainLatestRequest` | **Mapped — run pending.** |
| PIN-09 | Deleted target cancels request | `unavailableTargetCancelsRequest`; failed-outcome cancellation in `failedMutationOutcomesCancelOlderRequest` | **Mapped — run pending.** |
| PIN-10 | Search-hidden target does not scroll | `filteredTargetIsCancelled`; `clearingSearchDoesNotReviveCancelledRequest` | **Mapped — run pending.** |
| PIN-11 | Filter-hidden target does not scroll | `filterHiddenAppliedPinDoesNotRequestScrolling`; `filteredTargetIsCancelled`; `projectionReconciliationDistinguishesReorderFromFiltering`; filter XCUITest | **Mapped — run pending.** |
| PIN-12 | Clearing search follows the defined cancellation rule | `clearingSearchDoesNotReviveCancelledRequest` | **Mapped — run pending.** Defined behavior is “do not revive a cancelled request.” |
| PIN-13 | Wait until reordered projection is published | `projectionReconciliationDistinguishesReorderFromFiltering`; `pureReorderRequiresNewAggregateSnapshot` | **Mapped — run pending.** |
| PIN-14 | Missing row/layout does not scroll to a wrong row | `missingCurrentAggregateLayoutWaits`; `aggregateLayoutAvoidsOffscreenTargetCallbackDeadlock`; `HistoryViewportVisibilityTests.waitsForFirstLayoutPassBeforeMakingCorrectiveScrollDecision` | **Mapped — run pending.** Current-order aggregate geometry prevents both wrong-row scrolling and an unrealized-target deadlock. |
| PIN-15 | View disappearance invalidates stale request | `viewDisappearanceInvalidatesPendingRequest` | **Mapped — run pending.** |
| PIN-16 | Reduce Motion removes/reduces Pin-scroll animation | `ThemeContractTests.reduceMotionDisablesDesignSystemAnimations` proves the reduced policy returns no animation; `pinScrollUsesAppMotionAnimationPolicy` proves the production Pin-scroll call routes through that policy | **Mapped — run pending.** |
| PIN-17 | Window-size changes reevaluate visibility correctly | `windowResizeReevaluatesStableTargetVisibility` | **Mapped — run pending.** |
| PIN-18 | Repeated Pin of the same already-pinned item does not loop | `unpinAndNoOpDoNotRequestScrolling` | **Mapped — run pending.** |

`HistoryViewportVisibilityTests` method names referenced above are executable Swift Testing
functions; their descriptive `@Test` names are what Xcode normally presents in reports.

#### Pin-scroll XCUITest acceptance

The deterministic fixture contains 64 rows and every test launches a fresh store. Tests invoke
the real native Pin action; no test calls `scrollTo`.

| ID | End-to-end requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| PINUI-01 | Long list, deterministic window, native Pin, reordered stable-ID target automatically returns to viewport | `PinScrollAutomationUITests.testOffscreenPinAutoScrollsTheExactSameStableItemID` | **Mapped — run pending.** Asserts execution count, `scroll` decision, exact UUID, pinned state, and hittability. |
| PINUI-02 | Initially visible target emits no programmatic scroll | `testInitiallyVisiblePinDoesNotExecuteProgrammaticScroll` | **Mapped — run pending.** |
| PINUI-03 | Rapid A/B/C leaves C as latest target | `testRapidPinsAThenBThenCLeaveCLatest` performs all three native actions without terminal-decision waits, proves A/B/C all became pinned, and asserts C is the final stable-ID diagnostic target | **Mapped — run pending.** Stale-request consumption is additionally covered at unit level. |
| PINUI-04 | Pin then Delete removes the same stable target without a stale follow-up | `testPinThenDeleteRemovesTheSameTargetWithoutStaleScroll` waits for the real Pin scroll to settle, invokes native Delete, and asserts exact-ID removal, one completed scroll, no pending request, and app survival; unit test `unavailableTargetCancelsRequest` covers deletion before execution | **Mapped — run pending.** |
| PINUI-05 | Search-visible Pin target remains valid and auto-scrolls | `testSearchVisiblePinnedTargetRemainsInProjectionAndAutoScrolls` asserts the filtered projection, exact stable ID, one real scroll, and pinned state | **Mapped — run pending.** |
| PINUI-06 | Search-hidden target does not issue a stale extra scroll | `testSearchHidesPinnedTargetWithoutIssuingAStaleScroll` changes the native searchable projection immediately after Pin, then asserts target removal, exactly one completed Pin scroll, and no pending request | **Mapped — run pending.** |
| PINUI-07 | Distinct non-search filter state Pin behavior | `testUnpinnedFilterHidesPinnedTargetWithoutIssuingAStaleScroll` activates the real Unpinned filter, Pins through the native action, proves exact-target removal, zero scroll execution, and app survival | **Mapped — run pending.** |
| PINUI-08 | Unpin never triggers auto-scroll | `testUnpinNeverRequestsOrExecutesAutomaticScroll` | **Mapped — run pending.** |
| PINUI-09 | Native Pin action is accessibility-discoverable and uses the stable-ID mutation path | `testNativePinActionButtonIsAccessibleAndTriggersStableIDMutation` asserts identifier, accessible label, enabled/hittable state, native activation, exact UUID diagnostics, and pinned state | **Mapped — run pending.** |

### I. Accessibility and keyboard

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| AX-01 | Language picker is findable, enabled, and operable | `SettingsUITests.testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` and `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` require `app-language-picker`, assert enabled/hittable, and operate it by Space/arrows/Return | **Mapped — run pending.** |
| AX-02 | Storage-limit Slider has a nonempty label | `SettingsUITests.testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` finds `history-limit-slider` and uses `assertAccessibleControl` to require a nonempty label, enabled state, and hittability | **Mapped — run pending.** |
| AX-03 | Slider exposes the correct accessibility value | `testStorageLimitSynchronizesSliderAndFieldAndTrimsOnlyOldestUnpinnedRows` asserts values `1000` and `1` | **Mapped — run pending.** |
| AX-04 | Storage-limit TextField has a nonempty label | `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` requires `history-limit-field` and explicitly asserts its nonempty label, enabled state, and hittability | **Mapped — run pending.** |
| AX-05 | Appearance picker is present in the accessibility tree | `testCommandCommaOpensSingleSettingsWindowAndExposesRequiredTabs`; `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` requires `appearance-picker` and operates it by keyboard | **Mapped — run pending.** |
| AX-06 | OCR context-menu option has localized names | English assertions in the OCR success/regression tests; `testImageOCRErrorIsLocalizedAndDoesNotModifyNamedPasteboard` asserts Traditional Chinese Copy Image Text, failure, retry, Copy Original Image, Pin, and Delete labels | **Mapped — run pending.** |
| AX-07 | Disabled OCR states expose disabled items | OCR no-text, error, and loading UI tests | **Mapped — run pending.** |
| AX-08 | Pin action is discoverable with stable identifier/label | `ClipRowActionsUITests.testRowActionsExposeKeyboardReachableControlsAndVoiceOverLabels`; `ClipboardImageRowActionsUITests.testT064ImageRowActionUXBaselinePreservedLabelsIconsAccessibilitySwipe` | **Mapped — run pending.** |
| AX-09 | Image item has an appropriate description | `ClipboardImageRowActionsUITests.testCapturedImageDisplaysThumbnailSurface` | **Mapped — run pending.** |
| AX-10 | Decorative icons do not create duplicate VoiceOver elements | `ThemeContractTests.decorativeControlSymbolsAreAccessibilityHidden`; OCR context-menu descendant assertion; per-tab accessibility audits | **Mapped — run pending.** |
| AX-11 | New Settings controls work through keyboard focus order | `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` proves language/appearance focus survives updates, Tab moves Record→Clear and Slider→Field through public focus probes, and Space/Return operates applicable controls | **Mapped — run pending.** |
| AX-12 | Apple accessibility audit runs when supported, otherwise explicit assertions cover the same surface | `SettingsUITests.testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` runs `performAccessibilityAudit(for: .sufficientElementDescription)` after explicit control assertions | **Mapped — run pending.** |
| KEY-01 | Tab moves focus away from the active Settings field and commits on focus loss | `testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` proves commit; `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` identifies the next focused control as Clear Shortcut or Storage Limit Field through public SwiftUI focus probes | **Mapped — run pending.** |
| KEY-02 | Return commits storage-limit input | Storage-limit UI test uses Return for `1000`, invalid letters, and `1001` | **Mapped — run pending.** |
| KEY-03 | Space/Return activates the focused applicable Settings control | `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` uses Space to open identified pop-up controls and Return to choose values | **Mapped — run pending.** |
| KEY-04 | Escape dismisses the context menu | OCR and image-context-menu UI tests press Escape; `testImageContextMenuExposesIdleCopyTextAndPreservesExistingActions` asserts disappearance | **Mapped — run pending.** |
| KEY-05 | Keyboard Pin reaches the Pin/scroll logic | No current XCUITest owns the native row-action button through keyboard focus and activates it with Return | **Pending — test absent.** Pointer activation and accessibility discoverability are covered by PINUI-09. |
| KEY-06 | Language change does not lose focus into an unusable state | `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` changes language by keyboard in both directions through the same identified picker and continues operating it after each locale update | **Mapped — run pending.** |
| KEY-07 | Appearance change leaves current window operable | Appearance test performs successive picker operations after each change | **Mapped — run pending.** |

### J. Regression, policy, and infrastructure gates

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| REG-01 | Run every existing unit test | Unit phase selects all `NextPasteTests` except the suite moved to Integration | **Mapped — run pending.** Full phase not run. |
| REG-02 | Run every Vision integration test | Integration phase selects the entire Vision suite | **Mapped — run pending.** Full phase not run. |
| REG-03 | Run every existing/new UI test | UI phase selects all `NextPasteUITests` | **Mapped — run pending.** Full phase not run. |
| REG-04 | No runtime skips or expected failures | `summarize_xcresult` fails the script if either count is nonzero | **Mapped — run pending.** |
| REG-05 | No `XCTSkip` or `XCTExpectFailure` left in source | `Scripts/check-test-hygiene.sh`, invoked by `Scripts/verify.sh` | **Static-validated.** Current executable scan passed. |
| REG-06 | No fixed sleeps used for UI synchronization | Repository-wide test-source scan in `Scripts/check-test-hygiene.sh`; selected source-policy tests | **Static-validated.** The scan rejects `Task.sleep`, `Thread.sleep`, `sleep`, `usleep`, `DispatchQueue.main.asyncAfter`, and run-loop pumping. |
| REG-07 | No commented-out failure, empty test, always-true assertion, or unjustified retry | `Scripts/check-test-hygiene.sh` scans both test roots, detects empty XCTest and Swift Testing functions, and requires an exact reviewed UI-test loop-token inventory | **Static-validated.** Current executable scan passed. |
| INFRA-01 | Shared Test Plan has Unit, Integration, UI, timeouts, and coverage | `NextPaste.xctestplan`; fail-closed script checks exact configuration/target counts, identities, coverage target, timeouts, and serialized UI execution | **Static-validated.** Plan parses and is discoverable; execution pending. |
| INFRA-02 | Test Plan has no personal absolute path | Project-relative `container:NextPaste.xcodeproj` references only | **Static-validated.** |
| INFRA-03 | One script runs formatter status, lint status, artifact preflight/postflight, Debug/Release builds, Xcode test enumeration, all test phases, localization, `.xcresult`, strict build/test summaries, and coverage | `Scripts/verify.sh` | **Static-validated.** `bash -n` and dry run succeeded; full command not run. |
| INFRA-04 | Formatter/lint handling is truthful | Script emits “Project not configured” for both | **Static-validated.** No formatter/lint config was found. |
| INFRA-05 | Results are not committed | Fresh external temp run directory plus mandatory repository artifact preflight/postflight | **Mapped — run pending.** |
| INFRA-06 | Repository CI executes the complete verification gate | No CI configuration currently exists | **Pending — test absent.** A macOS CI job must invoke `Scripts/verify.sh` and retain its external result artifacts. |

## Completion-gate ledger

This ledger mirrors the brief's 18 completion gates. “Pending” is deliberate; no test execution
has been inferred.

| Gate | Required completion condition | Current state |
| --- | --- | --- |
| 1 | App build succeeds | **Pending full run.** |
| 2 | All existing unit tests pass | **Pending full run.** |
| 3 | All new unit tests pass | **Pending full run.** |
| 4 | Vision integration tests pass | **Pending full run.** |
| 5 | All XCUITests pass | **Pending full run.** |
| 6 | Localization automated checks pass | **Mapped, including compiled-bundle and fallback checks; pending full run.** |
| 7 | OCR context menu is exercised with `rightClick()` | **Mapped; run pending.** |
| 8 | OCR copy is checked through an isolated test pasteboard | **Mapped; run pending.** |
| 9 | Language switching and relaunch persistence are automated | **Mapped in both directions; pending full run.** |
| 10 | Every storage-limit boundary and invalid UI input is automated | **Mapped; pending full run.** |
| 11 | Slider/TextField bidirectional synchronization is automated | **Mapped at both boundaries and an intermediate integer; pending full run.** |
| 12 | Appearance switching and relaunch persistence are automated | **Partial: Light and Dark are mapped; Follow System and native relaunch application remain pending.** |
| 13 | Actual Pin-triggered list auto-scroll is proven by XCUITest | **Mapped; run pending.** |
| 14 | Rapid Pin stale-request handling is automated | **Mapped at unit/UI levels; run pending.** |
| 15 | Accessibility assertions pass | **Mapped through explicit assertions, public focus probes, decorative-symbol policy, and per-tab audits; pending full run.** |
| 16 | `Scripts/verify.sh` exits 0 | **Pending: full script has not run.** |
| 17 | Worktree contains no DerivedData/`.xcresult`/build artifacts | **Current fail-closed preflight passes; the full script will repeat the same check after all phases.** |
| 18 | No skips, hidden failures, or manual substitutes | **Mapped through runtime xcresult gates, exact Xcode-enumerated inventories, and repository-wide source hygiene; pending full run.** |

The remaining unmapped or partial rows are RET-11 image-file rollback, APPUI-01 Follow System,
KEY-05 keyboard Pin activation, and INFRA-06 CI execution. Execution acceptance is also pending
until the complete script—including every enumerated UI test—finishes with zero failures and zero
skips. Until then, the work must not be described as accepted or fully verified. No manual
verification step is part of the remaining path.
