# Tasks: iOS 原生體驗與前景剪貼簿匯入

**Input**: Design documents from `/specs/026-ios-native-clipboard/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md),
[data-model.md](./data-model.md), [validation contract](./contracts/validation-and-sonar-contract.md)

**Tests**: FR-023明確要求可重複自動驗證；每個 story 的 test tasks 必須先建立並觀察到
relevant failure，再完成 implementation。系統 Paste permission prompt 由 manual matrix補足。

**Organization**: 任務依 user story 分組；macOS/visionOS parity與完整 gate集中於最後階段。

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可在不同檔案、沒有未完成依賴時平行執行
- **[Story]**: 對應 spec.md 的 US1–US4
- 只有實際完成並可驗證的 task 才可標 `[x]`

## Phase 1: Setup（可相信的 iOS 測試基礎）

**Purpose**: 修正現有 UI-test runner 與 app sandbox 不共享路徑、iOS background helper no-op等
先決問題，確保後續 iOS XCUITest不是假陽性。

- [ ] T001 在 `NextPasteTests/UITestPathConfigurationTests.swift` 先新增 failing tests，定義 iOS UI-test store/image fixture不得使用 runner temporaryDirectory絕對路徑，且 macOS既有隔離不變
- [ ] T002 在 `NextPasteUITests/UITestPathConfiguration.swift` 與 `NextPasteUITests/UITestAppLauncher.swift` 建立平台分流：iOS只傳 sandbox-relative fixture namespace／launch flags，macOS保留既有絕對隔離路徑與 real background helper
- [ ] T003 在 `NextPaste/DebugUITestLaunchEnvironment.swift` 建立完整 `-ui-testing` gate下的 app-container iOS test path resolution，並在 `NextPasteTests/DebugUITestSurfaceIsolationTests.swift` 驗證 Release／不完整環境不可啟用
- [ ] T004 執行 `Scripts/check-test-hygiene.sh` 並把新增／變更的 UI-test loop 審查結果同步至 `Scripts/ui-test-loop-inventory.txt`

**Checkpoint**: iOS app與runner不交換不可存取的sandbox絕對路徑；fixture只在完整Debug UI-test環境生效。

---

## Phase 2: Foundational（跨 story 的平台邊界）

**Purpose**: 建立不含敏感內容的共用狀態與精準 `os(iOS)` UI/platform seams。

**⚠️ CRITICAL**: 此階段完成前不得接入真實剪貼簿或大幅改 HomeView。

- [ ] T005 [P] 在 `NextPasteTests/IOSClipboardImportTypesTests.swift` 先新增 failing privacy/result/checkpoint tests，禁止 captured associated content進入result、description、defaults或debug probe，且change count不得跨process持久化
- [ ] T006 [P] 在 `NextPaste/IOSClipboardImportTypes.swift` 新增 content-free source/result/state與memory-only scene/checkpoint types，僅編譯於 `os(iOS)`
- [ ] T007 [P] 在 `NextPasteTests/PlatformPresentationContractTests.swift` 先新增 failing source/runtime contracts，要求 iOS不套用520pt desktop frame、iOS branch不包含Mac Settings/toolbar且visionOS不落入iOS分支
- [ ] T008 在 `NextPaste/NextPasteApp.swift` 建立精準 `#if os(iOS)` root presentation seam，移除iOS universal min-width並保留macOS/visionOS原本frame、navigation title與lifecycle wiring
- [ ] T009 在 `NextPaste/Localizable.xcstrings` 建立所有新iOS navigation、paste、empty state、filter、result、editor、settings、privacy與confirmation文案的en/zh-Hant條目，不改寫既有Mac語意

**Checkpoint**: 平台presentation與content-free import types可獨立編譯，其他平台行為未改。

---

## Phase 3: User Story 1 — 複製後開啟即可取得目前內容（Priority: P1）🎯 MVP

**Goal**: 使用者在其他App複製文字或圖片後啟動／返回NextPaste，系統允許時自動保存最新
內容一次；不可用時有system PasteButton fallback，且不宣稱背景捕捉。

**Independent Test**: 在fake client與真實simulator各完成一次copy-before-launch flow；允許時1秒內
新增一筆，重複active不新增；拒絕／unavailable時不洩漏內容且兩次點按內可用PasteButton。

### Tests for User Story 1（先寫並確認 relevant failure）

- [ ] T010 [P] [US1] 在 `NextPasteTests/IOSPasteboardClientTests.swift` 新增text、PNG/JPEG、image-first、invalid-image-no-text-fallback、unsupported、multi-provider與cancellation failing tests
- [ ] T011 [P] [US1] 在 `NextPasteTests/IOSClipboardImportCoordinatorTests.swift` 新增首次active、changed/unchanged count、duplicate outcome、background cancel、stale callback、rapid 50 transitions、multi-scene serialization與content-free feedback failing tests
- [ ] T012 [P] [US1] 在 `NextPasteTests/IOSClipboardImportIntegrationTests.swift` 新增in-memory SwiftData文字／圖片capture、dedup、rollback、retention與`@Query`-equivalent fetch結果的failing integration tests
- [ ] T013 [P] [US1] 在 `NextPasteUITests/IOSClipboardImportUITests.swift` 新增Debug fixture cold launch、active return、duplicate active、fallback-visible與explicit provider capture failing UI tests

### Implementation for User Story 1

- [ ] T014 [US1] 在 `NextPaste/IOSPasteboardClient.swift` 實作`UIPasteboard.general.changeCount` snapshot與async `[NSItemProvider]` loader，依image-first規則產生既有`ClipboardPayload`並完整支援cancellation
- [ ] T015 [US1] 在 `NextPaste/IOSClipboardImportCoordinator.swift` 實作App-owned MainActor lifecycle owner、aggregate scene registry、generation/in-flight serialization、memory-only checkpoint、capture outcome content-free mapping與1秒量測seam
- [ ] T016 [US1] 在 `NextPaste/NextPasteApp.swift` 以`scenePhase`只於iOS active觸發coordinator、inactive/background取消舊generation，macOS `ClipboardMonitorLifecycleController`保持不變
- [ ] T017 [US1] 在 `NextPaste/IOSPasteButton.swift` 封裝SwiftUI system `PasteButton(supportedContentTypes:payloadAction:)`，將explicit providers送入同一coordinator且提供本地化accessibility語意
- [ ] T018 [US1] 在 `NextPaste/HomeView.swift` 提供無內容preview的iOS PasteButton入口與content-free import feedback；空歷史直接可貼上，有歷史且auto unavailable時顯示fallback
- [ ] T019 [US1] 在 `NextPaste/DebugUITestLaunchEnvironment.swift` 與 `NextPaste/Debug/UITestIOSClipboardFixture.swift` 新增完整Debug gate的deterministic provider/lifecycle fixture，不把實際fixture內容放入accessibility probe或Release
- [ ] T020 [US1] 更新 `NextPasteUITests/UITestAppLauncher.swift` 與 `NextPasteUITests/ClipboardFixture.swift` 讓iOS fixture能模擬cold active／reactivation，而macOS繼續使用real pasteboard與既有probe
- [ ] T021 [US1] 執行 `quickstart.md` 的US1 targeted unit/integration/UI commands並在 `contracts/validation-and-sonar-contract.md` 只依實際log更新US1 evidence狀態

**Checkpoint**: User Story 1可獨立交付；clipboard acquisition修復但不依賴完整視覺重設計。

---

## Phase 4: User Story 2 — iPhone原生且完整的主畫面（Priority: P1）

**Goal**: 所有支援iPhone尺寸上使用native navigation/search/list，不水平裁切，保留既有品牌語言。

**Independent Test**: smallest/largest iPhone、portrait/landscape、standard/accessibility text size均可看見
title、單一search、add、filter、settings、paste/history；stable UUID操作不錯列。

### Tests for User Story 2（先寫並確認 relevant failure）

- [ ] T022 [P] [US2] 在 `NextPasteUITests/IOSNativeHomeUITests.swift` 新增單一search、toolbar actions、filter state/reset、empty-history/search/filter recovery與stable-row-reorder failing tests
- [ ] T023 [P] [US2] 在 `NextPasteTests/HomeViewIOSLayoutContractTests.swift` 新增iOS stable UUID、無desktop toolbar/min-width、custom target ≥44pt與Mac row-slot preservation failing contracts

### Implementation for User Story 2

- [ ] T024 [US2] 在 `NextPaste/HomeView.swift` 以精準`#if os(iOS)`分出native home container：navigation title、single `.searchable`、filter menu、settings與primary add toolbar，其他平台保留現有`AppToolbar`
- [ ] T025 [US2] 在 `NextPaste/HomeView.swift` 實作iOS stable-ID `List`、active filter status/reset與search/filter/history三種empty-state recovery，保留`AppTheme` canvas/card/badge/illustration
- [ ] T026 [US2] 在 `NextPaste/DesignSystem/Components/ClipboardRow.swift`、`ImageClipboardRow.swift` 與 `SharedRowPresentation.swift` 增加預設不改Mac的iOS presentation參數，移除iOS窄版inline duplicate controls並支援Dynamic Type
- [ ] T027 [US2] 在 `NextPaste/HomeView.swift` 實作iOS row的單一copy語意、native leading pin／trailing destructive delete swipe、context menu與VoiceOver custom actions，所有custom target至少44pt
- [ ] T028 [US2] 在 `NextPasteUITests/IOSNativeHomeUITests.swift` 補smallest/largest simulator、orientation、accessibility XXXL、RTL/long text與mixed image/pin layout assertions，並同步 `Scripts/ui-test-loop-inventory.txt`
- [ ] T029 [US2] 執行 `quickstart.md` 的US2 targeted build/UI commands並在validation contract只依實際結果記錄SC-004～SC-006 evidence

**Checkpoint**: User Stories 1與2可分別驗證；iPhone首頁已完整native且不改品牌或Mac UI。

---

## Phase 5: User Story 3 — 以iOS慣例新增與管理項目（Priority: P2）

**Goal**: 新增sheet、copy/pin/delete與鍵盤/error recovery皆符合iOS慣例並可存取。

**Independent Test**: 在iPhone新增一筆文字，依序copy、pin/unpin、delete，確認native位置／role、
feedback、資料identity與persistence正確；取消／失敗時draft不被意外丟失。

### Tests for User Story 3（先寫並確認 relevant failure）

- [ ] T030 [P] [US3] 擴充 `NextPasteUITests/CreateTextClipUITests.swift`，新增iOS navigation Cancel/Save、keyboard、blank validation、save failure retains draft與discard confirmation failing tests
- [ ] T031 [P] [US3] 擴充 `NextPasteUITests/ClipRowActionsUITests.swift`，新增iOS copy feedback、pin reorder stable identity、unpin、destructive delete confirmation/context action failing tests

### Implementation for User Story 3

- [ ] T032 [US3] 在 `NextPaste/NewClipView.swift` 保留macOS body並新增iOS `NavigationStack`/scrollable editor、cancellation/confirmation toolbar、focus、interactive-dismiss draft confirmation與accessible error recovery
- [ ] T033 [US3] 在 `NextPaste/HomeView.swift` 將iOS New Clip presentation接至native sheet並確保save走既有`ClipboardCaptureService`與`HistoryRetentionService`
- [ ] T034 [US3] 在 `NextPaste/HomeView.swift` 與row components完成copy/pin/unpin/delete non-sensitive feedback、roles、accessibility state與gesture衝突修正
- [ ] T035 [US3] 執行 `specs/026-ios-native-clipboard/quickstart.md` 的US3 targeted UI/unit regression，量測首頁→新增完成≤10秒與搜尋／重設篩選／進入設定≤5秒，並在 `specs/026-ios-native-clipboard/contracts/validation-and-sonar-contract.md` 只依實際結果更新FR-014/FR-018/SC-007 evidence

**Checkpoint**: User Story 3可獨立驗證；所有日常item管理不需要desktop control grammar。

---

## Phase 6: User Story 4 — 真正可用的iOS設定（Priority: P2）

**Goal**: iOS原生Form可調語言、外觀、歷史上限、閱讀device/clipboard privacy、確認後清除，
且不顯示Mac shortcuts。

**Independent Test**: 從iPhone首頁進入Settings，修改三個preferences並relaunch確認保存；取消與確認
兩種clear流程資料結果正確，畫面在大字級可捲動且沒有Shortcuts。

### Tests for User Story 4（先寫並確認 relevant failure）

- [ ] T036 [P] [US4] 在 `NextPasteTests/IOSSettingsPresentationTests.swift` 新增iOS sections、device-not-Mac privacy copy、shortcut absence、history-limit normalization與clear-count message failing contracts
- [ ] T037 [P] [US4] 在 `NextPasteUITests/IOSSettingsUITests.swift` 新增navigation、language/appearance/limit persistence、large type、clear unpinned/all cancel/confirm與about version failing UI tests

### Implementation for User Story 4

- [ ] T038 [US4] 在 `NextPaste/IOSSettingsView.swift` 建立native `Form` sections，直接使用`AppLanguagePreference`、`AppearancePreference`、`HistoryLimitPreference`與既有retention/history services
- [ ] T039 [US4] 在 `NextPaste/IOSSettingsView.swift` 實作device-local/foreground-only privacy說明、dynamic clear counts、destructive confirmations與About version/build，排除Mac shortcuts
- [ ] T040 [US4] 在 `NextPaste/HomeView.swift` 將settings toolbar action接至native navigation destination，保留macOS `SettingsLink`與placeholder移除只限iOS
- [ ] T041 [US4] 執行 `specs/026-ios-native-clipboard/quickstart.md` 的US4 targeted unit/UI tests並在 `specs/026-ios-native-clipboard/contracts/validation-and-sonar-contract.md` 只依實際結果更新FR-019～FR-021 evidence

**Checkpoint**: 四個user stories全部具獨立驗收路徑。

---

## Phase 7: Polish & Cross-Cutting Verification

**Purpose**: 整合privacy/accessibility/performance/localization與跨平台release gate。

- [ ] T042 [P] 執行 `NextPasteTests/LocalizationCatalogTests` 與catalog completeness檢查，修正 `NextPaste/Localizable.xcstrings` 所有缺漏或stale iOS/macOS translations
- [ ] T043 [P] 在 `NextPasteTests/IOSClipboardImportCoordinatorTests.swift` 完成文字20次、圖片10次、≤1秒ready-path量測與50次lifecycle壓力證據；禁止把system prompt等待納入app budget
- [ ] T044 執行 `Scripts/check-test-hygiene.sh`、`git diff --check`、`Scripts/verify.sh --dry-run`，並以generic iOS Simulator及visionOS simulator各build一次，修正所有static/hygiene/platform問題且不得在repository產生build artifacts
- [ ] T045 執行macOS targeted regression：`AdaptiveToolbarUITests`、`SearchAccessibilityUITests`、`SettingsUITests`、`ClipboardAutoCaptureUITests`、row-action/pin suites，確認desktop UI/polling/reconciliation parity
- [ ] T046 在booted iPhone及iPad simulator依 `quickstart.md` 完成真實text/image copy→cold launch/foreground、system Allow/deny/revoke、PasteButton fallback、VoiceOver focus order、最大Dynamic Type與portrait/landscape matrix，保存不含敏感內容的screenshot/observations於repository外evidence位置
- [ ] T047 執行 `Scripts/verify.sh` 完整gate，保存第一份log/result bundle位置並只依實際0 warnings/failures/skips更新 `contracts/validation-and-sonar-contract.md`
- [ ] T048 以 `speckit-analyze` 非破壞檢查 `spec.md`、`plan.md`、`tasks.md` traceability；修正所有CRITICAL/HIGH與真實consistency defects
- [ ] T049 更新 `specs/026-ios-native-clipboard/quickstart.md` 與 `contracts/validation-and-sonar-contract.md` 的最終已執行證據／accepted platform-owned limitations，保留未執行項為Pending

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 無依賴；T001 tests先於T002/T003，T004在修改test source後執行。
- **Foundational (Phase 2)**: 依賴Setup；T005/T007可平行先寫，T006/T008對應實作，T009可平行。
- **US1 (Phase 3)**: 依賴Foundational；T010–T013可平行先寫；T014→T015→T016/T017→T018–T020→T021。
- **US2 (Phase 4)**: 依賴Foundational；可與US1 service work平行，但T018的Paste入口整合與T024–T025需協調同一HomeView修改。
- **US3 (Phase 5)**: 依賴US2 row/navigation shell；tests T030/T031可先平行。
- **US4 (Phase 6)**: 依賴US2 navigation shell；可與US3在不同檔案平行，T040最後整合HomeView。
- **Polish (Phase 7)**: 依賴所有預定stories；先targeted/static，再manual，最後full gate與analyze/evidence同步。

### User Story Dependencies

```text
Setup → Foundation ─┬→ US1 Clipboard MVP ───────────┐
                    └→ US2 Native Home ─┬→ US3 Items├→ Polish / Full Gate
                                        └→ US4 Settings┘
```

- **US1**: business/service flow可在minimal existing home中獨立交付。
- **US2**: native home可用Debug seeded history獨立驗證，不依賴system paste permission。
- **US3**: 依賴US2的native row/sheet shell，但data mutation沿用existing services。
- **US4**: 依賴US2的navigation shell，與US3沒有資料依賴。

## Parallel Execution Examples

### User Story 1

```text
Parallel tests: T010 IOSPasteboardClientTests + T011 CoordinatorTests +
                T012 integration tests + T013 UI tests
After tests fail: T014 loader → T015 coordinator；T017 PasteButton與T019 Debug fixture可平行
```

### User Story 2

```text
Parallel tests: T022 XCUITest + T023 source/runtime contract
Implementation: T026 row component API可與T024 native container先在不同檔案進行；T025/T027整合
```

### User Stories 3 and 4

```text
US3 NewClipView (T030/T032) 與 US4 IOSSettingsView (T036–T039) 可平行；
兩者完成後再依序整合共享 HomeView 的 T033/T040。
```

## Implementation Strategy

### MVP First

1. 完成Setup與Foundation，讓iOS測試可信且其他平台frame不受影響。
2. 完成US1，先證明copy-before-launch與system Paste fallback能真正保存內容一次。
3. 停下執行US1 targeted/manual驗證；失敗先修root cause，不以UI redesign掩蓋。
4. 再交付US2 native home、US3 item flow、US4 settings。

### Completion Rules

- tests先寫並觀察relevant failure；不得為滿足task而加入無意義斷言。
- 同一個SwiftData history source、capture/dedup/retention pipeline與design tokens必須共享。
- `#if os(iOS)`不可寫成廣泛`#if !os(macOS)`；visionOS必須保持原路徑。
- UI-test fixture只在完整Debug gate下；真實system prompt證據必須另外執行。
- optional agent-context hooks依repository指示跳過；不得修改repository agent pointers。
- 只有實際執行成功的test/task可以標`[x]`或把contract status改Passed。
