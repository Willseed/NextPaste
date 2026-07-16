# Validation & Sonar Contract: iOS 原生體驗與明確貼上

**Feature**: 026-ios-native-clipboard
**Spec**: [spec.md](../spec.md)
**Plan**: [plan.md](../plan.md)
**Date**: 2026-07-17

本文件是此功能唯一的驗證權威，擁有 automated/manual/regression、offline/local-first、
accessibility、platform、performance、release readiness 與 Sonar applicability 的矩陣及證據
生命週期。`quickstart.md` 只列執行指令，不得重定義驗證要求。

## 1. Scope and Ownership

必須驗證：iOS lifecycle零程式化clipboard read、system PasteButton明確貼上、文字／圖片 loader、
capture/dedup/persistence integration、native iPhone home/search/filter/rows/new clip/settings、
accessibility、localization、offline behavior，以及 macOS/visionOS parity。

明確排除：background clipboard capture、已被覆寫的中間項目、系統 paste permission prompt
文案控制、macOS UI redesign、visionOS navigation redesign、雲端／分析／外部處理。

## 2. Command Source

所有 build/test/full-gate 指令由 [`../quickstart.md`](../quickstart.md) 提供。targeted commands
必須先執行；完整 `Scripts/verify.sh` 只在功能完成閘門執行。

## 3. Targeted Validation Strategy

1. 純coordinator request ownership、payload selection與result mapping使用Swift Testing + fake decoder。
2. SwiftData capture/dedup/retention integration 使用 in-memory model container，不依賴 system prompt。
3. 可程式觀察的 iOS navigation/search/list/settings/new-clip 使用 serialized XCUITest。
4. Debug fixture 必須由完整 `-ui-testing` launch environment 隔離；Release isolation 另有 unit test。
5. system PasteButton與App-specific Paste from Other Apps設定的實際顯示以真實simulator/device
   manual matrix補足，不以fake fixture冒充；基本功能不得依賴programmatic Allow。
6. 因本功能改變 app launch、navigation、clipboard acquisition、shared capture/persistence wiring，
   完成時必須執行 repository-authoritative full gate。

## 4. Automated Validation Matrix

| Validation area | FR/SC | Execution source | Required evidence | Status | Current execution evidence | Remaining gap |
| --- | --- | --- | --- | --- | --- | --- |
| iOS build | FR-009–FR-024 | iOS simulator build | 0 errors/warnings introduced；app 可安裝啟動 | Passed | generic iOS Simulator build `succeeded`、0 errors／0 warnings／0 analyzer warnings；iPhone 17／iOS 26.5 simulator安裝、啟動及settled screenshot成功 | — |
| Lifecycle no-read | FR-001, FR-006, FR-023 / SC-003 | source/runtime contract + UI launch test | launch／active／task無general pasteboard value access、無自動新增、無programmatic prompt | Passed | privacy source contract 3/3；cold launch／foreground explicit-paste UI 2/2 | 真實system-owned prompt與裝置人工矩陣仍依§7 Pending |
| Explicit request ownership | FR-008 / SC-008 | `IOSClipboardImportCoordinatorTests` | newer request取代、cancel、stale completion與50-request serialization正確 | Executing | coordinator 6/6，涵蓋explicit capture、duplicate、replacement與stale completion | 缺inactive/background survival、獨立cancel及50-request stress |
| Payload loading | FR-003, FR-007 / SC-001, SC-002 | `IOSPasteboardClientTests` | text、supported image、image-first、invalid image、unsupported、cancel mapping 正確；無內容 log | Executing | decoder 5/5，涵蓋文字、PNG image-first、invalid image與cancellation | 缺JPEG、成功multi-provider與true unsupported provider案例 |
| Capture integration | FR-002, FR-022 / SC-001, SC-002 | coordinator + existing capture tests | valid item 保存一次；duplicate/blank/failure 不新增；retention 與 rollback 不變 | Executing | coordinator文字／圖片／duplicate／read-only結果通過 | 缺dedicated rollback、retention及query-equivalent integration suite |
| System Paste primary | FR-002, FR-004, FR-005 / SC-001–SC-003 | iOS UI tests with provider fixture | empty state恰有一個Paste primary；nonempty toolbar一次點按可用；providers走同一capture pipeline | Executing | explicit-paste UI 2/2；empty Home UI與實際system `PasteButton` import通過 | 缺deterministic app fixture、nonempty toolbar及duplicate UI flow |
| Native home/search/filter | FR-009–FR-017 / SC-004–SC-007 | `IOSNativeHomeUITests` | 無 desktop toolbar/min-width；單一 search；stable row identity；empty recovery actions；44pt contract | Executing | Home source contracts 4/4；empty/search recovery UI通過 | 缺filter/reorder、device size/orientation、XXXL與RTL矩陣 |
| New clip | FR-018 / SC-007 | existing/extended CreateTextClip UI tests | native Cancel/Save、validation、failure recovery、keyboard-safe layout | Executing | dirty-draft discard retry 1/1通過 | 缺完整blank validation、save failure、keyboard及Cancel/Save suite |
| iOS settings | FR-019–FR-021 | `IOSSettingsUITests` + preference units | preferences persist；Mac shortcuts absent；destructive confirmations cancel/confirm correct | Executing | source contracts 6/6；native navigation／Form／privacy UI通過 | 缺preference persistence、clear cancel/confirm、large type及About UI coverage |
| Accessibility/localization | FR-015–FR-017, FR-019 / SC-004–SC-006 | UI assertions + catalog checks | interactive controls named；single search；Dynamic Type layouts scroll；catalog complete | Executing | LocalizationCatalogTests 8/8；system controls與新入口有本地化accessibility labels | Dynamic Type及assistive-technology人工矩陣未執行 |
| Platform isolation | FR-020, FR-024 / SC-009 | compile-time contract tests + macOS targeted suites | macOS toolbar/settings/polling/reconciliation unchanged；visionOS compiles | Executing | generic iOS與macOS compilation、presentation/privacy contracts、macOS source/localization 17/17及完整macOS UI 52/52通過 | 本機未安裝visionOS 26.5 runtime，visionOS build無法執行 |
| Offline/local-first | FR-007, FR-022 / SC-010 | all targeted integration tests with network unused | no network dependency or off-device content path | Pending | 尚無完整可稽核執行證據 | airplane-mode與完整integration矩陣未執行 |
| Performance | SC-001, SC-008 | timing assertion + request stress | callback providers ready後row visible≤1s；50requests, 0 crash/duplicate/stale writes | Pending | 尚無符合budget的量測證據 | ≤1秒measurement seam與50-request stress未實作／執行 |

### 4.1 Current Execution Evidence

- iOS test-harness isolation：11/11 Passed，
  `/tmp/NextPasteDerived-harness/Logs/Test/Test-NextPasteCI-2026.07.17_01-13-18-+0800.xcresult`。
- iOS coordinator／decoder core：11/11 Passed，
  `/tmp/NextPasteDerived-ios-explicit-only/Logs/Test/Test-NextPasteTestsOnly-2026.07.17_01-44-16-+0800.xcresult`。
- iOS cold-launch／foreground explicit Paste：2/2 Passed，
  `/tmp/NextPasteDerived-ios-explicit-ui/Logs/Test/Test-NextPasteCI-2026.07.17_01-49-20-+0800.xcresult`。
- Home／Settings／privacy／localization contracts：21/21 Passed，
  `/tmp/NextPasteDerived-ios-presentation-contracts/Logs/Test/Test-NextPasteCI-2026.07.17_01-52-09-+0800.xcresult`。
- Native Home、Settings與editor UI首輪：4/5 Passed；dirty-draft selector失敗，
  `/tmp/NextPasteDerived-ios-native-ui/Logs/Test/Test-NextPasteCI-2026.07.17_01-53-15-+0800.xcresult`；
  修復後該selector重跑1/1 Passed，
  `/tmp/NextPasteDerived-ios-native-ui/Logs/Test/Test-NextPasteCI-2026.07.17_01-55-16-+0800.xcresult`。
- macOS source／localization：17/17 Passed，
  `/tmp/NextPasteDerived-explicit-mac-tests/Logs/Test/Test-NextPasteCI-2026.07.17_01-42-11-+0800.xcresult`。
- final generic iOS Simulator build：succeeded，0 errors／0 warnings／0 analyzer warnings，
  `/tmp/NextPaste-Final-iOS-Build.xcresult`。
- visionOS build attempt：未執行compile；Xcode回報visionOS 26.5 runtime未安裝、destination
  ineligible，`/tmp/NextPaste-Final-visionOS-Build.xcresult`。
- macOS full UI recovery execution：52/52 Passed，0 failures，session與scheduling logs分別保存於
  `/tmp/NextPaste-UI-52-Passed-session.log`、`/tmp/NextPaste-UI-52-Passed-scheduling.log`。

## 5. Final Regression Validation

Authoritative command: `Scripts/verify.sh`.

**Status**: Failed／Pending clean rerun。不得描述成full-gate pass。

此 gate 必須執行，原因是本功能觸及 `NextPasteApp` launch/scene lifecycle、Home navigation、
explicit clipboard acquisition、SwiftData persistence input、localization與跨平台conditional code。
成功必須由本次實際 log 證明 zero warnings/failures/skips；dry run 只能算 static validation。

- Attempt 1：`run.yemKDC` 的Debug／Release／TestBuild皆0 errors/warnings，Unit 445/445、
  Integration 6/6通過；UI 35/52通過、17項全部因macOS XCTest
  `Timed out while synthesizing event`失敗。spindump證明event injector等待WindowServer，App未crash／hang；
  artifacts：
  `/private/var/folders/tp/nj4vhslx6md17fhfbdkqzzhh0000gn/T/NextPasteVerification/run.yemKDC`。
- Recovery：shutdown simulators並重啟`testmanagerd`後，代表性既有swipe selector 1/1 Passed，
  `/tmp/NextPaste-Swipe-Repro-RestartedManager.xcresult`。
- Attempt 2：`run.S3N68a` 再次得到3種build 0 errors/warnings、Unit 445/445、Integration 6/6；
  UI session log明確記錄52/52、0 failures。測試結束後Xcode持續超過15分鐘卡在coverage
  `_downloadRuntimeProfiles`且未產生final `Info.plist`，為保存已完成的test logs後以SIGTERM結束，
  因此script exit 143、不是authoritative pass。artifacts：
  `/private/var/folders/tp/nj4vhslx6md17fhfbdkqzzhh0000gn/T/NextPasteVerification/run.S3N68a`。

## 6. Regression Matrix

| Existing behavior | Expected preserved outcome |
| --- | --- |
| macOS continuous clipboard polling | copy while running continues to capture once through existing monitor |
| macOS desktop toolbar/window | three adaptive toolbar presentations and 520×380 minimum window remain |
| macOS settings | five-tab Settings scene, shortcuts and SettingsLink behavior remain |
| macOS row reconciliation | index slots/AppKit safe-boundary/pin scroll behavior and tests remain unchanged |
| SwiftData history | sorting, pinning, deletion, search, retention and relaunch persistence unchanged |
| image capture | hash/dimensions/file/thumbnail lifecycle and image-first semantics unchanged |
| visionOS support | target still compiles; no UIKit-only iOS branch leaks into visionOS |
| Release isolation | no Debug clipboard fixture/probe/control is reachable without full gated environment |

## 7. Manual Validation Matrix

| Area | Scenario | Status | Current evidence | Required evidence |
| --- | --- | --- | --- | --- |
| Real cold-launch paste | Copy text in another App → terminate/launch NextPaste → observe before tap → tap system Paste | Pending | simulator automation只證明未點擊零新增與點擊後匯入；未計時 | before tap: no prompt/row; after tap: exactly one new row within1s |
| Real foreground image | Copy supported image → background/foreground NextPaste → tap system Paste | Pending | 尚未執行真實圖片人工流程 | no auto import; after tap thumbnail visible, reopen restores image, no duplicate |
| System control | Test supported／unsupported content and visible App-specific paste settings | Pending | settled screenshot只證明可見Paste control；未覆蓋system settings／unsupported state | control visible/disabled as system decides; no custom programmatic fallback or pressure |
| Background limitation | Copy A then B while app suspended, return → tap Paste | Pending | source contract證明無lifecycle read；未執行A→B人工流程 | only current B is considered; UI/docs make no A/background-capture claim |
| Device layout | smallest/largest supported iPhone, portrait/landscape, display zoom | Pending | iPhone 17 portrait visual smoke成功 | no horizontal crop; title/search/add/filter/settings/paste/history reachable |
| Accessibility | VoiceOver, largest Dynamic Type, Bold Text, Increase Contrast, Reduce Transparency/Motion | Pending | localization/accessibility labels有自動契約；assistive technology matrix未執行 | logical focus order, named/stateful actions, readable/scrollable content, no color-only meaning |
| Offline | airplane mode for complete copy/import/search/settings/relaunch flow | Pending | 尚未執行airplane-mode完整流程 | all local tasks succeed; zero outbound clipboard content |

Manual validation只補足 system-owned prompt 與 assistive technology/device presentation；可可靠
自動驗證的 business logic 不得只靠人工聲稱。

## 8. Accessibility and Platform Validation

| Platform | Changed scope | Automated expectation | Manual expectation |
| --- | --- | --- | --- |
| iOS/iPadOS | clipboard acquisition、home、new clip、settings | unit + XCUITest + build | system prompt、VoiceOver、device orientation/zoom |
| macOS | no intended behavior change；shared wiring regression | existing unit/UI suites + full gate | visual smoke only if automated regression flags ambiguity |
| visionOS | no intended behavior change | build through configured platform/full gate where available | N/A for this feature |

iOS interaction methods include touch、VoiceOver、Switch Control、hardware keyboard/focus、scroll、
swipe actions、context menu 與 sheet dismissal。Custom icon hit regions至少 44×44pt；native controls
使用 system hit target。沒有批准的 Apple HIG deviation。

## 9. Offline / Local-First Validation

- 任何 clipboard payload 都只傳入本機 loader、capture service、SwiftData/image store。
- 不新增 network import、analytics、remote logging、sync requirement 或 third-party dependency。
- unit/UI tests在網路未使用的 test environment 完成；人工 airplane-mode flow 作最終確認。
- logs、UserDefaults、debug probes、test attachments 不得包含 clipboard text/image/preview。

## 10. Performance Validation

| Budget | Operation | Status | Current evidence | Measurement |
| --- | --- | --- | --- | --- |
| ≤1 second | PasteButton callback providers ready至歷史row可見 | Pending | 未建立合格的callback→row timing seam | monotonic timestamp around explicit import + UI readiness assertion；使用者操作時間excluded |
| 50 requests | rapid explicit paste with duplicate/new/cancelled/stale callbacks and lifecycle changes | Pending | 6個ownership案例通過，但未執行50-request stress | deterministic coordinator stress；0 crash、0 duplicate、0 stale commit |

如果目前實作超過 budget，測試必須失敗；不得在 plan/tasks 階段放寬 SC。

## 11. Representative Validation

- Backward compatibility representative: existing macOS `ClipboardAutoCaptureUITests`、
  `AdaptiveToolbarUITests`、`SearchAccessibilityUITests`、`SettingsUITests`、row-action/pin suites。
- Forward correctness representative: new iOS no-read launch、explicit text/image paste、native
  home search/filter、new clip、settings preference flow。
- Status保持 `Pending`，直到實際命令與結果被記錄；artifact consistency analysis不等於 pass。

### 11.1 Accepted Validation Boundaries

- `PasteButton`可見／enabled狀態、paste permission prompt與App-specific paste settings由Apple系統
  擁有；自動測試不得programmatically Allow。§7未執行的system-owned觀察一律維持Pending。
- iOS targeted unit／UI evidence因shared test targets仍含既有macOS-only sources，執行時使用
  command-line source filtering隔離所選suite。這不修改product target，也不得被描述成整個test
  target已在iOS通過；generic iOS product build、install與launch維持unfiltered。
- iOS設計刻意不承諾background capture；只有使用者點擊可見system `PasteButton`後由Apple提供的
  當下providers可進入capture pipeline。這是產品privacy boundary，不是待修復的自動監控缺口。
- 本機macOS XCTest曾讓所有velocity swipe event卡在WindowServer；重啟`testmanagerd`後同一未改碼
  selector與完整52-test UI execution皆通過。這可作host recovery evidence，但coverage finalizer未完成時
  仍不得把`Scripts/verify.sh`標Passed。
- visionOS 26.5 runtime未安裝；Xcode destination明確回報ineligible。visionOS compile保持Pending，
  不以iOS/macOS compile推定通過。

## 12. Release Readiness

**Overall status**: Pending。Automated evidence依§4逐列記錄；§7 manual matrix、§10 performance、
visionOS build、authoritative full-gate clean rerun與其餘未勾tasks完成前不得宣稱本feature達成完整
release readiness。

- 所有 required automated rows具本次 execution evidence，0 failures/skips/warnings。
- system permission/manual rows具裝置/OS、步驟與觀察結果；未執行不得標 Passed。
- `Scripts/verify.sh` 完成且 evidence 在 script-managed repository 外位置。
- `git diff --check`、test hygiene、localization completeness、supported platform matrix通過。
- 無 clipboard-derived content出現在 logs、attachments、defaults 或對外傳輸。
- spec/plan/tasks/analyze traceability已同步，optional hooks仍依 repository instruction skipped。

## 13. SonarQube Evidence

Repository目前沒有受版本控制的 SonarQube scanner/project/quality-gate integration，因此此功能
Sonar evidence為 **Not Applicable**。如果完成前新增正式 Sonar integration，本 contract必須先
更新為 required，並記錄 Project Health gate、feature-introduced issues、coverage與duplication證據。
Xcode／repository verification不能被描述成 Sonar pass。

## 14. Evidence Lifecycle

狀態：`Pending → Executing → Passed | Failed`。

- `Passed` 只可由本次實際 command/report支持。
- static search、dry run、compile plan或先前 run不能當成 test pass。
- failure必須保存第一份有效 log／result位置，修復後再執行適當 scope。
- commit SHA、PR、release、日期或設備結果若不可驗證，一律標 `unknown`，不得推測。

## 15. Propagation Progress

| Artifact | Status | Notes |
| --- | --- | --- |
| `research.md` | Synchronized | root causes、Apple API/HIG decisions、alternatives recorded |
| `data-model.md` | Synchronized | explicit request ownership/result and existing ClipItem invariants recorded |
| `quickstart.md` | Synchronized | commands only; references this contract |
| `ios-clipboard-import-contract.md` | Synchronized | explicit trigger、provider、serialization與privacy boundaries recorded |
| `tasks.md` | Synchronized | 21/49 tasks具目前implementation/execution evidence；其餘保留Pending |
