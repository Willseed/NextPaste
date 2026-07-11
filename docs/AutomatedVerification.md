# Automated Verification Map

This document maps the automated-acceptance brief supplied for the OCR, Settings, retention,
appearance, Pin-scroll, accessibility, and verification-infrastructure work to the current
repository. It is an evidence inventory, not a test-result report.

## Truth and result boundary

This map is intentionally run-agnostic. It records which executable evidence the gate selects;
mutable pass/fail totals, coverage, `.xcresult` paths, commit SHA, and GitHub run URL belong to the
corresponding verification output and CI run. A commit is accepted only when its complete
`Scripts/verify.sh` execution and latest GitHub workflow both succeed with zero failures and zero
skips. Any partial or missing mapping blocks acceptance before execution begins.

The status labels used below are:

| Status | Meaning |
| --- | --- |
| **Mapped — gate-enforced** | A concrete XCTest, Swift Testing test, or XCUITest covers the requirement and is selected by the blocking Test Plan/script. |
| **Partial — not accepted** | Automated evidence exists, but one or more assertions or required variants are absent. |
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
| Pin scrolling | `PinScrollRequestState`, `HistoryViewportVisibility`, native Pin action, authoritative display-order snapshot, and real `scrollTo` path | Pure-state tests, a real `NSHostingView`/SwiftData lifecycle harness, AppKit observer-ownership tests, and read-only Debug accessibility diagnostics updated by the product path | `PinScrollRequestStateTests`, `HistoryViewportVisibilityTests`, `HomeViewReconciliationLifecycleTests`, `PinScrollAppKitObservationSchedulingTests`, `PinScrollAutomationUITests` |
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
| `Unit` | `NextPasteTests`, excluding `VisionImageTextRecognizerIntegrationTests` and `AppKitAppearanceIntegrationTests` | All unit, source-policy, localization-catalog, preference, store, coordinator, and hosted lifecycle tests |
| `Integration` | `NextPasteTests/VisionImageTextRecognizerIntegrationTests` and `NextPasteTests/AppKitAppearanceIntegrationTests` | Real Apple Vision smoke tests and real `NSApplication` appearance integration |
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
# equal the executable leaf-method count produced by
# `Scripts/count-xctest-methods.sh`; suite/container identifiers are excluded.

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
  -skip-testing:NextPasteTests/AppKitAppearanceIntegrationTests \
  test-without-building

# Real Vision and native AppKit appearance integration tests
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
  -only-testing:NextPasteTests/AppKitAppearanceIntegrationTests \
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

Artifacts constitute acceptance evidence only when they correspond to the commit under review and
the strict summaries below are clean. Each full run creates the following under its printed run
directory:

| Artifact | Purpose |
| --- | --- |
| `xcodebuild-list.json`, `test-plans.txt` | Project/scheme/Test Plan discovery evidence |
| `DebugBuild.xcresult`, `DebugBuild-build-summary.json` | Debug product build evidence |
| `ReleaseBuild.xcresult`, `ReleaseBuild-build-summary.json` | Release product build and test-surface isolation evidence |
| `TestBuild.xcresult`, `TestBuild-build-summary.json` | Build-for-testing evidence |
| `<phase>-inventory.json` | Xcode-enumerated test inventory that the phase must execute exactly |
| `Unit.xcresult`, `Unit-summary.json` | Unit and localization result evidence |
| `Integration.xcresult`, `Integration-summary.json` | Real Vision and native AppKit appearance result evidence |
| `UI.xcresult`, `UI-summary.json` | XCUITest result evidence and attachments |
| `<phase>-coverage.txt`, `<phase>-coverage.json` | `xccov` target summary and machine-readable coverage |
| `<phase>-tests.json` | Detailed tests, emitted when a phase is not clean |

For every test phase, `xcresulttool` must report a `Passed` result, an executed count exactly equal
to Xcode's pre-run enumerated inventory, `passed == total`, zero failures, zero skips, and zero
expected failures. `xccov` must find `NextPaste.app` in every phase bundle. No minimum coverage
percentage is currently specified or enforced; each run still emits its numeric coverage. Each
build result must also contain a complete
build summary with `status == succeeded` and `errorCount == 0`; missing summary fields fail closed.
DerivedData and `.xcresult` are written beneath the temporary run directory. The script rejects an
artifacts directory inside the repository and performs explicit preflight and postflight scans for
`DerivedData`, `build`, `.build`, `.xcresult`, `.xcarchive`, `.dSYM`, `.app`, and profiling output;
the gate does not rely on ignore rules hiding generated files.

`.github/workflows/verify.yml` runs on pushes and pull requests with the `macos-26` runner. Before
testing it requires the hosted image's Apple `automationmodetool` status to contain
`DOES NOT REQUIRE`, writes that preflight evidence into the artifact directory, and installs the
gate's explicit `actionlint` and `ripgrep` dependencies. The blocking `Scripts/verify.sh` step has
a 350-minute timeout inside a 360-minute job, reserving time for `actions/upload-artifact@v4` under
`if: always()`. The gate itself does not use `continue-on-error` or suppress a failing exit status.
`Scripts/check-github-actions.sh` runs `actionlint -no-color` and fails closed on invalid YAML,
expressions, or context placement.

## Acceptance traceability

### A. Automation, isolation, and stability

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| A-01 | Every acceptance item is automated; no manual substitute | This map, `Scripts/check-test-hygiene.sh`, and `Scripts/verify.sh` identify and enforce the available evidence | **Mapped — gate-enforced.** All acceptance rows have concrete automation; the complete gate must still execute with zero failures and zero skips. |
| A-02 | Use Apple test APIs and existing Swift Testing only | XCTest/XCUITest targets, Swift Testing unit target, Test Plan, Vision, NSPasteboard, UserDefaults, SwiftData | **Mapped — gate-enforced.** |
| A-03 | Platform boundaries are injectable/testable | `ImageTextRecognizing`, `ClipboardTextWriting`, injected `UserDefaults`, in-memory/temporary SwiftData, `PinScrollRequestState` | **Mapped — gate-enforced.** Names differ from the brief's examples but preserve the required seams. |
| A-04 | Test doubles replace only nondeterministic boundaries | `testImageOCRContextMenuCopiesRecognizedMultilineText`; `testImageOCRNoTextLeavesNamedPasteboardUnchanged`; `testImageOCRErrorIsLocalizedAndDoesNotModifyNamedPasteboard`; `testImageOCRLoadingTransitionsFromDisabledToRecognizedAction` | **Mapped — gate-enforced.** These drive the real row/context-menu/coordinator/write path. |
| A-05 | Keep a real Apple Vision integration smoke test | `VisionImageTextRecognizerIntegrationTests` | **Mapped — gate-enforced.** |
| A-06 | UI tests isolate defaults, data, pasteboard, and fixtures and clean up | `NextPasteUITests.testIsolatedLaunchExposesReadyMainWindow`; all tests inherit `UITestCase`; `UITestLaunchEnvironmentRegistry` setup/teardown | **Mapped — gate-enforced.** |
| A-07 | Test-only state is Debug/UI-test-only and uses stable accessibility identifiers | `DebugUITestLaunchEnvironment`; `DebugUITestSurfaceIsolationTests`; `RelaunchStabilityTests.uiTestSurfacesRemainDebugOnly`; Debug-only seeder/probes; Release build | **Mapped — gate-enforced.** Complete environment validation, not a bare launch argument, gates storage, monitor overrides, simulated failures, and probes; Release compiles the inert branches. |
| A-08 | Tests can run independently, repeatedly, and without fixed delays | Per-test UUID environment; `NativeSwipeTestSupportPolicyTests`; Pin source-policy tests; executable `Scripts/check-test-hygiene.sh` scans both targets and compares every UI-test `for`/`while` token against `Scripts/ui-test-loop-inventory.txt` | **Mapped — gate-enforced.** The fail-closed gate rejects XCTest skips/expected failures, Swift Testing disabled/conditional/known-issue traits, fixed sleeps/run-loop pumping, commented tests, empty XCTest/Swift Testing functions, literal always-true assertions, and any unreviewed loop change. |
| A-09 | UI tests do not depend on a fixed window unless they set it | `UITestAppLauncher.WindowSizePreset`; every Pin-scroll XCUITest requests a deterministic preset | **Mapped — gate-enforced.** |
| A-10 | No network dependency or user production state | Per-test local stores/pasteboards/defaults; `ClipboardImagePrivacyTests` local-only coverage | **Mapped — gate-enforced.** |

### B. OCR core state: all 20 requested cases

| ID | OCR acceptance case | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| OCR-01 | Successful OCR returns valid text | `ImageTextRecognitionCoordinatorTests.successfulRecognitionWritesText` | **Mapped — gate-enforced.** |
| OCR-02 | Leading/trailing whitespace is handled | `successfulRecognitionWritesText`; `ImageTextRecognizerTests.preservesRecognizedContentStructure` | **Mapped — gate-enforced.** |
| OCR-03 | Multiline text is handled | `successfulRecognitionWritesText`; `preservesRecognizedContentStructure`; `normalizesLineEndings` | **Mapped — gate-enforced.** |
| OCR-04 | Whitespace-only result becomes no text | `ImageTextRecognitionCoordinatorTests.whitespaceAndNoTextNeverWrite`; parameterized `ImageTextRecognizerTests.rejectsEmptyOrWhitespaceOnlyResults` | **Mapped — gate-enforced.** |
| OCR-05 | Newline-only result becomes no text | Parameterized `rejectsEmptyOrWhitespaceOnlyResults` includes the dedicated `"\n\n"` fixture; `whitespaceAndNoTextNeverWrite` covers the coordinator result | **Mapped — gate-enforced.** |
| OCR-06 | No recognition result (`nil`) | `whitespaceAndNoTextNeverWrite`; empty-fragment case of `rejectsEmptyOrWhitespaceOnlyResults` | **Mapped — gate-enforced.** |
| OCR-07 | Recognizer throws | `ImageTextRecognitionCoordinatorTests.recognizerFailureDoesNotWriteAndCanRetry` | **Mapped — gate-enforced.** |
| OCR-08 | OCR Task is cancelled | `cancellationIgnoresLateResult`; `removalPropagatesCancellationToRecognizer`; `cancelAllCancelsInflightAndClearsCache` | **Mapped — gate-enforced.** |
| OCR-09 | Concurrent duplicate requests coalesce | `repeatedRequestsCoalesce` | **Mapped — gate-enforced.** |
| OCR-10 | Valid cache prevents repeat recognition | `successfulResultIsCached` | **Mapped — gate-enforced.** |
| OCR-11 | Changed image content invalidates old cache/request | `reconcileCancelsDeletedAndChangedFingerprintRequests`; `staleGenerationCannotOverwriteNewerRequest` | **Mapped — gate-enforced.** |
| OCR-12 | Result arriving after item deletion is ignored | `cancellationIgnoresLateResult`; `currentItemValidationRejectsDeletedItem`; `cachedWriteRejectsExternallyDeletedItem` | **Mapped — gate-enforced.** |
| OCR-13 | Old request cannot overwrite newer result | `staleGenerationCannotOverwriteNewerRequest`; `newestCrossItemCopyIntentWins`; `newestIntentWinsAcrossSuspendingCachedWrite` | **Mapped — gate-enforced.** |
| OCR-14 | Result applies only to the same stable item ID | `currentItemValidationRejectsDeletedItem`; `newestCrossItemCopyIntentWins`; request identity assertions in `staleGenerationCannotOverwriteNewerRequest` | **Mapped — gate-enforced.** |
| OCR-15 | Recognition failure is contained, not an unhandled exception | `recognizerFailureDoesNotWriteAndCanRetry`; `writerFailureDoesNotClaimSuccess` | **Mapped — gate-enforced.** |
| OCR-16 | No-text does not create a copyable empty string | `whitespaceAndNoTextNeverWrite`; `ClipboardWriterTests.nonemptyTextWriterRejectsEmptyStringWithoutChangingInjectedPasteboard` | **Mapped — gate-enforced.** |
| OCR-17 | Outer whitespace is removed correctly | `successfulRecognitionWritesText`; `preservesRecognizedContentStructure` | **Mapped — gate-enforced.** |
| OCR-18 | Meaningful internal line breaks are retained | `successfulRecognitionWritesText`; `preservesRecognizedContentStructure`; `normalizesLineEndings` | **Mapped — gate-enforced.** |
| OCR-19 | Expensive Vision recognition is proven not to run on MainActor | `VisionImageTextRecognizerIntegrationTests.expensiveVisionPerformHasANonMainActorExecutorBoundary` verifies that the synchronous `handler.perform` call is inside the `VisionImageTextRecognizer` actor implementation and that implementation is not `@MainActor` | **Mapped — gate-enforced.** |
| OCR-20 | UI state updates complete safely on MainActor | `ImageTextRecognitionCoordinator` and its suite are `@MainActor`; `inflightRequestPublishesRecognizingBeforeCompletion` and terminal-state tests observe state transitions | **Mapped — gate-enforced.** Compile-time actor isolation plus state-transition execution is the automated evidence. |

### C. Real Vision integration

| ID | Acceptance requirement | Automated evidence | Status |
| --- | --- | --- | --- |
| VIS-01 | Generate a deterministic high-contrast local image | `VisionImageTextRecognizerIntegrationTests.recognizesGeneratedBitmapText` / `LocalVisionImageFixture` | **Mapped — gate-enforced.** |
| VIS-02 | Real `VNRecognizeTextRequest` completes with nonempty expected major tokens | `recognizesGeneratedBitmapText` canonicalizes the result and asserts `NEXTPASTE` and `7429` | **Mapped — gate-enforced.** It intentionally avoids brittle full-string equality. |
| VIS-03 | Blank image safely yields no text | `returnsNoTextForBlankBitmap` | **Mapped — gate-enforced.** |
| VIS-04 | Invalid image data safely throws | `invalidImageDataThrowsWithoutCrashing` | **Mapped — gate-enforced.** |
| VIS-05 | Deployment/API availability is compatible | The integration suite and adapter compile in the macOS target; adapter guards `automaticallyDetectsLanguage` availability | **Mapped — gate-enforced.** |

### D. OCR context menu and pasteboard

| ID | Acceptance requirement | Automated evidence | Status |
| --- | --- | --- | --- |
| OCRUI-01 | Success: capture image, `rightClick()`, native Copy Image Text exists/enabled, exact multiline text reaches named pasteboard, nonempty | `ImageOCRContextMenuUITests.testImageOCRContextMenuCopiesRecognizedMultilineText` | **Mapped — gate-enforced.** |
| OCRUI-02 | No text: action becomes absent/disabled and sentinel remains | `testImageOCRNoTextLeavesNamedPasteboardUnchanged` | **Mapped — gate-enforced.** |
| OCRUI-03 | Error: app remains running, copy is unavailable, pasteboard unchanged, localized error shown | `testImageOCRErrorIsLocalizedAndDoesNotModifyNamedPasteboard` | **Mapped — gate-enforced.** Uses Traditional Chinese assertions. |
| OCRUI-04 | In progress: disabled loading item, controlled completion, action becomes enabled | `testImageOCRLoadingTransitionsFromDisabledToRecognizedAction` | **Mapped — gate-enforced.** |
| OCRUI-05 | Existing original-image Copy, Pin/Unpin, Delete still execute | `testImageContextMenuOriginalCopyPinUnpinAndDeleteActionsExecute`; `ClipboardImageRowActionsUITests.testImageContextMenuExposesIdleCopyTextAndPreservesExistingActions` | **Mapped — gate-enforced.** |
| PB-01 | UI/App processes share one unique named pasteboard and clean it | All `UITestCase` tests via `UITestLaunchEnvironment`; OCR UI tests use `UITestAppLauncher.pasteboard(for:)` | **Mapped — gate-enforced.** |
| PB-02 | Writer clears incompatible contents and writes `.string` readable as identical text | `ClipboardWriterTests.namedPasteboardWriterClearsPriorTypesAndWritesOnlyString`; `nonemptyTextWriterPreservesExactMultilineContentOnInjectedPasteboard` | **Mapped — gate-enforced.** |
| PB-03 | Empty text is not written | `nonemptyTextWriterRejectsEmptyStringWithoutChangingInjectedPasteboard` | **Mapped — gate-enforced.** |
| PB-04 | Whitespace-only text is not written | `nonemptyTextWriterRejectsWhitespaceWithoutChangingInjectedPasteboard` | **Mapped — gate-enforced.** |
| PB-05 | Writer failure does not alter existing content | `simulatedNonemptyTextFailureLeavesInjectedPasteboardUnchanged`; OCR coordinator writer-failure cases | **Mapped — gate-enforced.** |
| PB-06 | User general pasteboard is not a test dependency | OCR/UI tests and every `ClipboardWriterTests` text-copy case now use UUID named pasteboards with teardown clearing | **Mapped — gate-enforced.** The prior `.general` writer fixtures were replaced by injected named pasteboards. |

### E. Language and localization

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| LANG-01 | `en_us` encodes/decodes | Parameterized `AppLanguagePreferenceTests.supportedLanguagesRoundTripThroughCodable` | **Mapped — gate-enforced.** |
| LANG-02 | `zh_TW` encodes/decodes | `supportedLanguagesRoundTripThroughCodable` | **Mapped — gate-enforced.** |
| LANG-03 | Unknown raw value falls back safely | `unknownLegacyValueFallsBackAndRepairsStorage` | **Mapped — gate-enforced.** |
| LANG-04 | Missing defaults value selects default language | `missingValueDefaultsToEnglishAndRepairsStorage` | **Mapped — gate-enforced.** |
| LANG-05 | Corrupt/non-string defaults value does not crash | `nonStringPersistedValueFallsBackWithoutCrashingAndRepairsStorage` | **Mapped — gate-enforced.** |
| LANG-06 | Recreated preference reads the stored language | `bothSupportedLanguagesPersistAcrossInstances` | **Mapped — gate-enforced.** |
| LANG-07 | Product raw values map to Apple locale/localization identifiers | `productRawValuesAndAppleMappingsAreStable` | **Mapped — gate-enforced.** |
| LANG-08 | Feature localization keys have nonempty English and Traditional Chinese values | `LocalizationCatalogTests.featureKeysHaveConcreteEnglishAndTraditionalChineseValues` | **Mapped — gate-enforced.** |
| LANGUI-01 | UI uses isolated defaults and finds the picker by stable identifier | `SettingsUITests.testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch`; `languagePopup` requires `app-language-picker` | **Mapped — gate-enforced.** |
| LANGUI-02 | Select English and verify English UI | `testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` asserts the English picker/description, all Settings tabs, the main-window `Clips` toolbar title, and the `New Clip` button | **Mapped — gate-enforced.** |
| LANGUI-03 | Select Traditional Chinese and verify the same UI updates immediately | `testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` selects the stable Traditional Chinese menu option and asserts the picker/description, Settings tabs and shortcuts, the main-window `剪貼簿項目` toolbar title, and the `新增剪貼簿項目` button | **Mapped — gate-enforced.** Menu-option selection is intentional here; keyboard-only picker operation is independently covered by `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation`. |
| LANGUI-04 | Relaunch with the same suite and retain Traditional Chinese | `testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` relaunches the isolated suite and reasserts the Chinese picker/description, Settings tabs, main toolbar title, and New Clip button | **Mapped — gate-enforced.** |
| LANGUI-05 | Switch back to English, relaunch again, and retain English | `testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` selects the stable localized English menu option, terminates, relaunches, and reasserts the English Settings and main-window surfaces | **Mapped — gate-enforced.** |
| LOC-01 | Catalog contains all required branch keys | `LocalizationCatalogTests.stringCatalogContainsBranchFeatureLocalizationKeys` | **Mapped — gate-enforced.** |
| LOC-02 | No missing/empty feature translation in either supported locale | `stringCatalogHasTranslatedValuesForProjectSupportedLocales`; `featureKeysHaveConcreteEnglishAndTraditionalChineseValues` | **Mapped — gate-enforced.** Traditional Chinese completeness is intentionally scoped to the branch-owned `featureBilingualKeys`. |
| LOC-03 | Resource is included in the correct target and readable from the built bundle | `LocalizationCatalogTests.compiledAppBundleContainsEveryFeatureStringForBothLocales` locates the compiled `en.lproj` and `zh-Hant.lproj` in `Bundle(for: ClipItem.self)` and compares every feature key with the catalog | **Mapped — gate-enforced.** |
| LOC-04 | Localization fallback never returns an empty string | `LocalizationCatalogTests.unknownLocaleFallsBackToANonemptyLocalizedValue` performs an unknown-locale bundle lookup | **Mapped — gate-enforced.** |
| LOC-05 | Critical UI text is displayed in both locales | `SettingsUITests.testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` asserts the language controls, Settings tabs, main toolbar title, and New Clip action in both locales; `ImageOCRContextMenuUITests.testImageOCRErrorIsLocalizedAndDoesNotModifyNamedPasteboard` asserts Chinese OCR, retry, original-copy, Pin, and Delete labels while the English OCR tests assert the English surface | **Mapped — gate-enforced.** |

### F. Storage-limit parsing, UI, persistence, and retention

#### Input policy and preference

| ID | Acceptance requirement | Automated evidence | Status |
| --- | --- | --- | --- |
| LIMIT-01 | Accept `1`, `2`, a middle value, `999`, and `1000` | Parameterized `HistoryLimitPreferenceTests.validValuesRemainUnchanged`; `commitAcceptsIntegersAndClampsOutOfRange` | **Mapped — gate-enforced.** |
| LIMIT-02 | Accept surrounding whitespace on a valid integer | `commitAcceptsIntegersAndClampsOutOfRange` (`"  25  "`) | **Mapped — gate-enforced.** |
| LIMIT-03 | Reject empty and whitespace-only drafts | `commitRestoresCurrentValueForEmptyOrUnparseableInput` | **Mapped — gate-enforced.** |
| LIMIT-04 | Clamp `0`, `-1`, other negatives, `1001`, and larger integers | `constructionClampsOutsideRange`; `commitAcceptsIntegersAndClampsOutOfRange` | **Mapped — gate-enforced.** |
| LIMIT-05 | Reject decimals (`1.0`, `1.5`) | `commitRestoresCurrentValueForEmptyOrUnparseableInput` | **Mapped — gate-enforced.** |
| LIMIT-06 | Reject letters, alphanumeric, symbols, non-ASCII digits, and non-Int text | `commitRestoresCurrentValueForEmptyOrUnparseableInput` (`abc`, `12abc`, `#42`, `１２`, `NaN`, `∞`, signs) | **Mapped — gate-enforced.** |
| LIMIT-07 | Safely clamp huge positive/negative integers | `commitAcceptsIntegersAndClampsOutOfRange` | **Mapped — gate-enforced.** |
| LIMIT-08 | Invalid draft does not persist and restores the prior valid value | `commitRestoresCurrentValueForEmptyOrUnparseableInput` asserts `shouldPersist == false` and prior normalized text | **Mapped — gate-enforced.** |
| LIMIT-09 | Slider/formal value remains an integer in `[1, 1000]` | Bounds/clamp tests; Settings slider uses `step: 1` and rounds into `HistoryLimit` | **Mapped — gate-enforced.** |
| LIMIT-10 | UserDefaults never leaves an invalid formal value; corrupt legacy data repairs | `legacyNSNumberIntegersAreNormalized`; `fractionalOrNonfiniteLegacyNumbersRepairToDefault`; `persistedIntegerDataIsNormalizedAndRepaired`; migration/corrupt-data tests | **Mapped — gate-enforced.** |
| LIMIT-11 | Recreated preference retains a legal value | `persistedLimitSurvivesNewInstance` | **Mapped — gate-enforced.** |

#### Storage-limit UI

Current storage-limit UI evidence is distributed across the boundary/synchronization,
invalid-input/focus-loss, and real-retention tests named below.

| ID | Required XCUITest variant | Current assertion | Status / remaining gap |
| --- | --- | --- | --- |
| LIMITUI-01 | Type `1`, Return, Slider becomes minimum | `SettingsUITests.testHistoryLimitSliderAndFieldSynchronizeAtBoundariesAndIntermediateInteger` commits `1` through the TextField and asserts both controls | **Mapped — gate-enforced.** |
| LIMITUI-02 | Type `1000`, Return, Slider becomes maximum | Exact field and slider value assertions | **Mapped — gate-enforced.** |
| LIMITUI-03 | Type `0`, commit, legal recovery/clamp | `SettingsUITests.testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` asserts clamp to `1` in both controls | **Mapped — gate-enforced.** |
| LIMITUI-04 | Type `1001`, commit, clamp to `1000` | Exact recovery assertion | **Mapped — gate-enforced.** |
| LIMITUI-05 | Type a negative value; never make it formal | `testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` commits `-17` and asserts the legal value `1` | **Mapped — gate-enforced.** |
| LIMITUI-06 | Type a decimal; never make it formal | `testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` keeps the Slider at `437` while editing `1.5`, then restores `437` on Return | **Mapped — gate-enforced.** |
| LIMITUI-07 | Type letters; restore prior valid value | `letters` returns to `1000` | **Mapped — gate-enforced.** |
| LIMITUI-08 | Clear the field; app remains running | `testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` clears the field, commits by Return and Tab, and asserts `.runningForeground` | **Mapped — gate-enforced.** |
| LIMITUI-09 | Commit empty field; restore prior valid value | `testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` asserts restoration to the previous value after both Return and focus-loss commits | **Mapped — gate-enforced.** |
| LIMITUI-10 | Slider change immediately updates field | Minimum and maximum normalized-position adjustments update the field | **Mapped — gate-enforced.** |
| LIMITUI-11 | Slider never emits a fractional formal value | `testHistoryLimitSliderAndFieldSynchronizeAtBoundariesAndIntermediateInteger` adjusts to normalized position `0.5`, parses the accessibility value as `Int`, rejects a decimal point, and asserts matching field text | **Mapped — gate-enforced.** |
| LIMITUI-12 | Relaunch retains the value | The same isolated suite relaunches and asserts `1` | **Mapped — gate-enforced.** |

#### Retention/store behavior

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| RET-01 | Create more unpinned items than capacity and lower capacity | `HistoryRetentionServiceTests.overLimitRemovesOldestUnpinned`; UI storage-limit test | **Mapped — gate-enforced.** |
| RET-02 | Remove the oldest unpinned items | `overLimitRemovesOldestUnpinned`; `enforceLimitActuallyDeletesItems` | **Mapped — gate-enforced.** |
| RET-03 | Keep newest items | `retentionPreservesCanonicalNewestFirstOrder`; UI storage-limit test | **Mapped — gate-enforced.** |
| RET-04 | Never remove pinned items | `pinnedItemsNeverCountTowardLimit`; `enforceLimitWithPinnedKeepsAllPinned`; `retentionDoesNotTrimPinnedAfterCapture` | **Mapped — gate-enforced.** |
| RET-05 | Preserve canonical ordering | `deterministicOrderingRemovesConsistently`; `retentionPreservesCanonicalNewestFirstOrder` | **Mapped — gate-enforced.** |
| RET-06 | Define behavior at limit `1` | `HistoryRetentionServiceTests.limitOneKeepsOnlyTheNewestUnpinnedItem`; pinned and UI limit-one cases | **Mapped — gate-enforced.** |
| RET-07 | Define behavior at limit `1000` | `maximumLimitRemovesNothingWhenUnderLimit`; `maximumLimitTrimsOnlyTheSingleOldestItemFromOneThousandAndOne` | **Mapped — gate-enforced.** |
| RET-08 | Pinned count equals limit | `enforceLimitWithPinnedKeepsAllPinned` uses two pinned items and limit two while separately limiting unpinned items | **Mapped — gate-enforced.** Product policy explicitly excludes pinned items from capacity. |
| RET-09 | Pinned count exceeds limit | `pinnedCountAboveTheLimitStillPreservesEveryPinnedItem`; `pinnedItemsNeverCountTowardLimit` | **Mapped — gate-enforced.** |
| RET-10 | Rapid consecutive capacity changes converge without a race | `rapidLimitChangesEndAtLatestValidCapacity` executes the serialized `@MainActor` service through multiple rapid limits and asserts the final latest valid capacity and ordering | **Mapped — gate-enforced.** |
| RET-11 | Delete/save failure leaves rows and image/thumbnail files consistent | `HistoryRetentionServiceTests.saveFailureRollsBackRowsAndPreservesImageFiles` injects save failure, then asserts every SwiftData row and image/thumbnail filename is restored and both files retain their exact bytes | **Mapped — gate-enforced.** |
| RET-12 | Capacity handling is not repeatedly run in View rendering | `HistoryRetentionServiceTests.SettingsViewDoesNotEnforceRetentionDuringBodyEvaluation` source-checks the `HistorySettingsTab` body/event-handler region and confirms enforcement exists only in `apply`; `HistoryRetentionHookTests` covers event boundaries | **Mapped — gate-enforced.** |
| RET-13 | Trimming image items removes local files only after store save | `trimmingAnImageRemovesItsFilesAfterTheStoreSave` | **Mapped — gate-enforced.** Additional local-file consistency evidence. |

### G. Appearance

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| APP-01 | Light encodes/decodes and persists | `AppearancePreferenceTests.lightRoundTripsThroughCodable`; parameterized `everyAppearanceModePersistsAcrossInstances` | **Mapped — gate-enforced.** |
| APP-02 | Dark encodes/decodes and persists | `darkRoundTripsThroughCodable`; `persistedModeSurvivesNewInstance`; `everyAppearanceModePersistsAcrossInstances` | **Mapped — gate-enforced.** |
| APP-03 | Follow System encodes/decodes and persists | `systemRoundTripsThroughCodable`; `everyAppearanceModePersistsAcrossInstances` | **Mapped — gate-enforced.** |
| APP-04 | Unknown legacy value falls back | `invalidPersistedModeFallsBackToSystem` | **Mapped — gate-enforced.** |
| APP-05 | Values map to SwiftUI `ColorScheme` and native AppKit appearance | `systemMapsToNilColorScheme`; `lightMapsToLightColorScheme`; `darkMapsToDarkColorScheme`; `appearanceModesMapToNativeAppKitAppearances` | **Mapped — gate-enforced.** |
| APPUI-01 | Picker exposes System/Light/Dark and each choice updates the app | `SettingsUITests.testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight` proves option exposure plus Light/Dark switching; `testFollowSystemClearsNativeOverrideAndPersistsAcrossRelaunch` selects Follow System, proves the native override is cleared, matches both windows to the native effective appearance, and repeats those assertions after relaunch | **Mapped — gate-enforced.** |
| APPUI-02 | Root effective appearance is light/dark, based on real environment/AppKit state | `testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight` queries the `effective-appearance-main` environment probe for Light and Dark, including relaunches | **Mapped — gate-enforced.** |
| APPUI-03 | Main list and Settings window receive the same appearance | `testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight` asserts `effective-appearance-main` and `effective-appearance-settings` together after each change/relaunch | **Mapped — gate-enforced.** |
| APPUI-04 | Dark survives relaunch | `testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight` | **Mapped — gate-enforced.** |
| APPUI-05 | Light survives a subsequent relaunch | `testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight` switches the dark-relaunched app to Light, relaunches again, and asserts both probes and picker | **Mapped — gate-enforced.** |
| APPUI-06 | Appearance switching leaves the active window usable | The same test asserts the Settings window remains enabled and continues operating after changes | **Mapped — gate-enforced.** |

### H. Pin-scroll coordinator and end-to-end behavior

#### Unit/state acceptance

| ID | Acceptance case | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| PIN-01 | Applied unpinned-to-pinned mutation creates a request | `PinScrollRequestStateTests.appliedPinCreatesStableIDRequest` | **Mapped — gate-enforced.** |
| PIN-02 | Unpin creates no Pin-scroll request | `unpinAndNoOpDoNotRequestScrolling` | **Mapped — gate-enforced.** |
| PIN-03 | Still-visible/no-op Pin avoids unnecessary scrolling | `unpinAndNoOpDoNotRequestScrolling`; `fullyVisibleTargetDoesNotScroll` | **Mapped — gate-enforced.** |
| PIN-04 | Offscreen target requests scrolling | `offscreenLazyRowRequestsScroll` | **Mapped — gate-enforced.** |
| PIN-05 | Request uses stable item ID | `appliedPinCreatesStableIDRequest`; `offscreenLazyRowRequestsScroll` | **Mapped — gate-enforced.** |
| PIN-06 | Mutation/scroll identity never uses array index | `PinStateMutationSourcePolicyTests.testPinStateMutationStoreAcceptsItemIDAndDesiredStateNotRowIndex`; `testHomeViewPinUnpinProductionCallDoesNotUseRowIndexAsIdentity` | **Mapped — gate-enforced.** |
| PIN-07 | Rapid Pin A/B/C retains only C | `rapidPinsABCOnlyRetainC`; `rapidPinsRetainLatestRequest` | **Mapped — gate-enforced.** |
| PIN-08 | Stale A completion cannot consume C | `rapidPinsABCOnlyRetainC`; `rapidPinsRetainLatestRequest` | **Mapped — gate-enforced.** |
| PIN-09 | Deleted target cancels request | `unavailableTargetCancelsRequest`; failed-outcome cancellation in `failedMutationOutcomesCancelOlderRequest` | **Mapped — gate-enforced.** |
| PIN-10 | Search-hidden target does not scroll | `filteredTargetIsCancelled`; `clearingSearchDoesNotReviveCancelledRequest` | **Mapped — gate-enforced.** |
| PIN-11 | Filter-hidden target does not scroll | `filterHiddenAppliedPinDoesNotRequestScrolling`; `filteredTargetIsCancelled`; `projectionReconciliationDistinguishesReorderFromFiltering`; filter XCUITest | **Mapped — gate-enforced.** |
| PIN-12 | Clearing search follows the defined cancellation rule | `clearingSearchDoesNotReviveCancelledRequest` | **Mapped — gate-enforced.** Defined behavior is “do not revive a cancelled request.” |
| PIN-13 | Wait until reordered projection is published | `projectionReconciliationDistinguishesReorderFromFiltering`; `pureReorderRequiresNewAggregateSnapshot`; hosted `HomeViewReconciliationLifecycleTests.nativePinMutationWaitsForLifecycleBoundary` | **Mapped — gate-enforced.** The hosted case asserts the installed List keeps the exact pre-action projection and model state until the deterministic lifecycle boundary, then publishes the exact pinned-first projection and releases its owner-scoped snapshot. |
| PIN-14 | Missing row/layout does not scroll to a wrong row | `missingCurrentAggregateLayoutWaits`; `aggregateLayoutAvoidsOffscreenTargetCallbackDeadlock`; `HistoryViewportVisibilityTests.waitsForFirstLayoutPassBeforeMakingCorrectiveScrollDecision` | **Mapped — gate-enforced.** Current-order aggregate geometry prevents both wrong-row scrolling and an unrealized-target deadlock. |
| PIN-15 | View disappearance invalidates stale request | `viewDisappearanceInvalidatesPendingRequest` | **Mapped — gate-enforced.** |
| PIN-16 | Reduce Motion removes/reduces Pin-scroll animation | `ThemeContractTests.reduceMotionDisablesDesignSystemAnimations` proves the reduced policy returns no animation; `pinScrollUsesAppMotionAnimationPolicy` proves the production Pin-scroll call routes through that policy | **Mapped — gate-enforced.** |
| PIN-17 | Window-size changes reevaluate visibility correctly | `windowResizeReevaluatesStableTargetVisibility` | **Mapped — gate-enforced.** |
| PIN-18 | Repeated Pin of the same already-pinned item does not loop | `unpinAndNoOpDoNotRequestScrolling` | **Mapped — gate-enforced.** |

`HistoryViewportVisibilityTests` method names referenced above are executable Swift Testing
functions; their descriptive `@Test` names are what Xcode normally presents in reports.

The Pin unit phase also hosts a real `HomeView` in `NSHostingView` with an in-memory SwiftData
container, so lifecycle assertions observe the state that drives the installed List rather than a
detached View value. `PinScrollAppKitObservationSchedulingTests` separately proves that detached
stale resolvers cannot reclaim observation ownership, replacement owners reject stale teardown,
notification bursts publish only the latest projection, and reset generations cannot cancel a
replacement publication.

#### Pin-scroll XCUITest acceptance

The deterministic fixture contains 64 rows and every test launches a fresh store. Tests invoke
the real native Pin action; no test calls `scrollTo`.

| ID | End-to-end requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| PINUI-01 | Long list, deterministic window, native Pin, reordered stable-ID target automatically returns to viewport | `PinScrollAutomationUITests.testOffscreenPinAutoScrollsTheExactSameStableItemID` | **Mapped — gate-enforced.** Asserts execution count, `scroll` decision, exact UUID, pinned state, and hittability. |
| PINUI-02 | Initially visible target emits no programmatic scroll | `testInitiallyVisiblePinDoesNotExecuteProgrammaticScroll` | **Mapped — gate-enforced.** |
| PINUI-03 | Rapid A/B/C leaves C as latest target | `testRapidPinsAThenBThenCLeaveCLatest` performs all three native actions without terminal-decision waits, proves A/B/C all became pinned, and asserts C is the final stable-ID diagnostic target | **Mapped — gate-enforced.** Stale-request consumption is additionally covered at unit level. |
| PINUI-04 | Pin then Delete removes the same stable target without a stale follow-up | `testPinThenDeleteRemovesTheSameTargetWithoutStaleScroll` waits for the real Pin scroll to settle, invokes native Delete, and asserts exact-ID removal, one completed scroll, no pending request, and app survival; unit test `unavailableTargetCancelsRequest` covers deletion before execution | **Mapped — gate-enforced.** |
| PINUI-05 | Search-visible Pin target remains valid and auto-scrolls | `testSearchVisiblePinnedTargetRemainsInProjectionAndAutoScrolls` asserts the filtered projection, exact stable ID, one real scroll, and pinned state | **Mapped — gate-enforced.** |
| PINUI-06 | Search-hidden target does not issue a stale extra scroll | `testSearchHidesPinnedTargetWithoutIssuingAStaleScroll` changes the native searchable projection immediately after Pin, then asserts target removal, exactly one completed Pin scroll, and no pending request | **Mapped — gate-enforced.** |
| PINUI-07 | Distinct non-search filter state Pin behavior | `testUnpinnedFilterHidesPinnedTargetWithoutIssuingAStaleScroll` activates the real Unpinned filter, Pins through the native action, proves exact-target removal, zero scroll execution, and app survival | **Mapped — gate-enforced.** |
| PINUI-08 | Unpin never triggers auto-scroll | `testUnpinNeverRequestsOrExecutesAutomaticScroll` | **Mapped — gate-enforced.** |
| PINUI-09 | Native Pin action is accessibility-discoverable and uses the stable-ID mutation path | `testNativePinActionButtonIsAccessibleAndTriggersStableIDMutation` asserts identifier, accessible label, enabled/hittable state, native activation, exact UUID diagnostics, and pinned state | **Mapped — gate-enforced.** |
| PINUI-10 | Keyboard activation reaches the same Pin/scroll path | `testKeyboardFocusedContextMenuPinActivatesWithReturnAndAutoScrollsExactStableID` opens the native text-row context menu, keyboard-selects its stable Pin item, activates only with Return, and asserts the exact UUID becomes pinned, visible, and hittable after one real scroll | **Mapped — gate-enforced.** |

### I. Accessibility and keyboard

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| AX-01 | Language picker is findable, enabled, and operable | `SettingsUITests.testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch` uses stable menu-option selection for immediate localization/relaunch assertions; `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` independently requires `app-language-picker`, asserts enabled/hittable/focused state, and operates it in both directions with Space/arrows/Return | **Mapped — gate-enforced.** |
| AX-02 | Storage-limit Slider has a nonempty label | `SettingsUITests.testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` finds `history-limit-slider` and uses `assertAccessibleControl` to require a nonempty label, enabled state, and hittability | **Mapped — gate-enforced.** |
| AX-03 | Slider exposes the correct accessibility value | `testStorageLimitSynchronizesSliderAndFieldAndTrimsOnlyOldestUnpinnedRows` asserts values `1000` and `1` | **Mapped — gate-enforced.** |
| AX-04 | Storage-limit TextField has a nonempty label | `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` requires `history-limit-field` and explicitly asserts its nonempty label, enabled state, and hittability | **Mapped — gate-enforced.** |
| AX-05 | Appearance picker is present in the accessibility tree | `testCommandCommaOpensSingleSettingsWindowAndExposesRequiredTabs`; `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` requires `appearance-picker` and operates it by keyboard | **Mapped — gate-enforced.** |
| AX-06 | OCR context-menu option has localized names | English assertions in the OCR success/regression tests; `testImageOCRErrorIsLocalizedAndDoesNotModifyNamedPasteboard` asserts Traditional Chinese Copy Image Text, failure, retry, Copy Original Image, Pin, and Delete labels | **Mapped — gate-enforced.** |
| AX-07 | Disabled OCR states expose disabled items | OCR no-text, error, and loading UI tests | **Mapped — gate-enforced.** |
| AX-08 | Pin action is discoverable with stable identifier/label | `ClipRowActionsUITests.testRowActionsExposeKeyboardReachableControlsAndVoiceOverLabels`; `ClipboardImageRowActionsUITests.testT064ImageRowActionUXBaselinePreservedLabelsIconsAccessibilitySwipe` | **Mapped — gate-enforced.** |
| AX-09 | Image item has an appropriate description | `ClipboardImageRowActionsUITests.testCapturedImageDisplaysThumbnailSurface` | **Mapped — gate-enforced.** |
| AX-10 | Decorative icons do not create duplicate VoiceOver elements | `ThemeContractTests.decorativeControlSymbolsAreAccessibilityHidden`; OCR context-menu descendant assertion; per-tab accessibility audits | **Mapped — gate-enforced.** |
| AX-11 | New Settings controls work through keyboard focus order | `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` reads the public macOS `XCUIElement.AttributeName.hasFocus` snapshot, proves language/appearance focus survives updates, Tab moves Record→Clear, and Space/Return operates applicable controls | **Mapped — gate-enforced.** |
| AX-12 | Apple accessibility audit runs when supported, otherwise explicit assertions cover the same surface | `SettingsUITests.testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` runs `performAccessibilityAudit(for: .sufficientElementDescription)` after explicit control assertions; only the macOS-owned Touch Bar element is dispositioned by the issue handler, while every product issue remains blocking | **Mapped — gate-enforced.** |
| KEY-01 | Tab moves focus away from the active Settings field and commits on focus loss | `testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss` proves the commit; `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` independently verifies native focused elements through `XCUIElement` snapshots | **Mapped — gate-enforced.** |
| KEY-02 | Return commits storage-limit input | Storage-limit UI test uses Return for `1000`, invalid letters, and `1001` | **Mapped — gate-enforced.** |
| KEY-03 | Space/Return activates the focused applicable Settings control | `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` uses Space to open identified pop-up controls and Return to choose values | **Mapped — gate-enforced.** |
| KEY-04 | Escape dismisses the context menu | OCR and image-context-menu UI tests press Escape; `testImageContextMenuExposesIdleCopyTextAndPreservesExistingActions` asserts disappearance | **Mapped — gate-enforced.** |
| KEY-05 | Keyboard Pin reaches the Pin/scroll logic | `PinScrollAutomationUITests.testKeyboardFocusedContextMenuPinActivatesWithReturnAndAutoScrollsExactStableID` opens the native text-row context menu, moves keyboard selection to `toggle-pin-text-menu-item`, activates it with Return without tapping the item, and asserts exact stable-ID Pin, scroll, visibility, and hittability results | **Mapped — gate-enforced.** |
| KEY-06 | Language change does not lose focus into an unusable state | `testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation` changes language by keyboard in both directions through the same identified picker and continues operating it after each locale update | **Mapped — gate-enforced.** |
| KEY-07 | Appearance change leaves current window operable | Appearance test performs successive picker operations after each change | **Mapped — gate-enforced.** |

### J. Regression, policy, and infrastructure gates

| ID | Acceptance requirement | Automated evidence | Status / remaining gap |
| --- | --- | --- | --- |
| REG-01 | Run every existing unit test | Unit phase selects all `NextPasteTests` except the two suites moved to Integration | **Mapped — gate-enforced.** |
| REG-02 | Run every real-framework integration test | Integration phase selects the complete `VisionImageTextRecognizerIntegrationTests` and `AppKitAppearanceIntegrationTests` suites | **Mapped — gate-enforced.** |
| REG-03 | Run every existing/new UI test | UI phase selects all `NextPasteUITests` | **Mapped — gate-enforced.** |
| REG-04 | No runtime skips or expected failures | `summarize_xcresult` fails the script if either count is nonzero | **Mapped — gate-enforced.** |
| REG-05 | No `XCTSkip` or `XCTExpectFailure` left in source | `Scripts/check-test-hygiene.sh`, invoked by `Scripts/verify.sh` | **Static-validated.** Current executable scan passed. |
| REG-06 | No fixed sleeps used for UI synchronization | Repository-wide test-source scan in `Scripts/check-test-hygiene.sh`; selected source-policy tests | **Static-validated.** The scan rejects `Task.sleep`, `Thread.sleep`, `sleep`, `usleep`, `DispatchQueue.main.asyncAfter`, and run-loop pumping. |
| REG-07 | No commented-out failure, empty test, always-true assertion, or unjustified retry | `Scripts/check-test-hygiene.sh` scans both test roots, detects empty XCTest and Swift Testing functions, and requires an exact reviewed UI-test loop-token inventory | **Static-validated.** Current executable scan passed. |
| INFRA-01 | Shared Test Plan has Unit, Integration, UI, timeouts, and coverage | `NextPaste.xctestplan`; fail-closed script checks exact configuration/target counts, identities, coverage target, timeouts, and serialized UI execution | **Static-validated.** Plan parses and is discoverable before every run. |
| INFRA-02 | Test Plan has no personal absolute path | Project-relative `container:NextPaste.xcodeproj` references only | **Static-validated.** |
| INFRA-03 | One script runs formatter status, lint status, GitHub Actions validation, artifact preflight/postflight, Debug/Release builds, executable-method inventory, all test phases, localization, `.xcresult`, strict build/test summaries, and coverage | `Scripts/verify.sh`; `Scripts/count-xctest-methods.sh`; `Scripts/check-github-actions.sh` runs `actionlint -no-color` as a blocking preflight | **Static-validated.** Shell syntax, inventory self-test, workflow lint, and dry run are blocking preflights. |
| INFRA-04 | Formatter/lint handling is truthful | Script emits “Project not configured” for both | **Static-validated.** No formatter/lint config was found. |
| INFRA-05 | Results are not committed | Fresh external temp run directory plus mandatory repository artifact preflight/postflight | **Mapped — gate-enforced.** |
| INFRA-06 | Repository CI executes the complete verification gate | `.github/workflows/verify.yml` runs on push/pull request with `macos-26`, read-only contents permission, noninteractive Automation Mode preflight, explicit `actionlint`/`ripgrep` setup, blocking `Scripts/verify.sh`, bounded timeout headroom, and `actions/upload-artifact@v4` under `if: always()` | **Mapped — gate-enforced.** |

## Completion-gate ledger

This ledger mirrors the brief's 18 completion gates. It records enforcement, while the matching
run's strict summaries and GitHub check provide the mutable result.

| Gate | Required completion condition | Current state |
| --- | --- | --- |
| 1 | App build succeeds | **Required by full gate.** |
| 2 | All existing unit tests pass | **Required by full gate.** |
| 3 | All new unit tests pass | **Required by full gate.** |
| 4 | Vision and native AppKit appearance integration tests pass | **Required by full gate.** |
| 5 | All XCUITests pass | **Required by full gate.** |
| 6 | Localization automated checks pass | **Mapped, including compiled-bundle and fallback checks; gate-enforced.** |
| 7 | OCR context menu is exercised with `rightClick()` | **Mapped; gate-enforced.** |
| 8 | OCR copy is checked through an isolated test pasteboard | **Mapped; gate-enforced.** |
| 9 | Language switching and relaunch persistence are automated | **Mapped in both directions; gate-enforced.** |
| 10 | Every storage-limit boundary and invalid UI input is automated | **Mapped; gate-enforced.** |
| 11 | Slider/TextField bidirectional synchronization is automated | **Mapped at both boundaries and an intermediate integer; gate-enforced.** |
| 12 | Appearance switching and relaunch persistence are automated | **Mapped for Light, Dark, and Follow System, including native override/effective-appearance assertions across relaunch; gate-enforced.** |
| 13 | Actual Pin-triggered list auto-scroll is proven by XCUITest | **Mapped; gate-enforced.** |
| 14 | Rapid Pin stale-request handling is automated | **Mapped at unit/UI levels; gate-enforced.** |
| 15 | Accessibility assertions pass | **Mapped through explicit assertions, native focus snapshots, decorative-symbol policy, and per-tab audits; gate-enforced.** |
| 16 | `Scripts/verify.sh` exits 0 | **Required: the script must exit 0.** |
| 17 | Worktree contains no DerivedData/`.xcresult`/build artifacts | **Current fail-closed preflight passes; the full script will repeat the same check after all phases.** |
| 18 | No skips, hidden failures, or manual substitutes | **Mapped through runtime xcresult gates, exact Xcode-enumerated inventories, and repository-wide source hygiene; gate-enforced.** |

No acceptance row remains unmapped or partial. Acceptance always requires the complete script—
including every executable unit method, Vision/AppKit integration test, and UI test—to finish with
zero failures and zero skips for the exact commit, followed by a successful corresponding GitHub
workflow. No manual verification step is part of that path.
