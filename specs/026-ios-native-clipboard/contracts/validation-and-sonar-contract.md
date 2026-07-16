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

| Validation area | FR/SC | Execution source | Required evidence |
| --- | --- | --- | --- |
| iOS build | FR-009–FR-024 | iOS simulator build | 0 errors/warnings introduced；app 可安裝啟動 |
| Lifecycle no-read | FR-001, FR-006, FR-023 / SC-003 | source/runtime contract + UI launch test | launch／active／task無general pasteboard value access、無自動新增、無programmatic prompt |
| Explicit request ownership | FR-008 / SC-008 | `IOSClipboardImportCoordinatorTests` | newer request取代、cancel、stale completion與50-request serialization正確 |
| Payload loading | FR-003, FR-007 / SC-001, SC-002 | `IOSPasteboardClientTests` | text、supported image、image-first、invalid image、unsupported、cancel mapping 正確；無內容 log |
| Capture integration | FR-002, FR-022 / SC-001, SC-002 | coordinator + existing capture tests | valid item 保存一次；duplicate/blank/failure 不新增；retention 與 rollback 不變 |
| System Paste primary | FR-002, FR-004, FR-005 / SC-001–SC-003 | iOS UI tests with provider fixture | empty state恰有一個Paste primary；nonempty toolbar一次點按可用；providers走同一capture pipeline |
| Native home/search/filter | FR-009–FR-017 / SC-004–SC-007 | `IOSNativeHomeUITests` | 無 desktop toolbar/min-width；單一 search；stable row identity；empty recovery actions；44pt contract |
| New clip | FR-018 / SC-007 | existing/extended CreateTextClip UI tests | native Cancel/Save、validation、failure recovery、keyboard-safe layout |
| iOS settings | FR-019–FR-021 | `IOSSettingsUITests` + preference units | preferences persist；Mac shortcuts absent；destructive confirmations cancel/confirm correct |
| Accessibility/localization | FR-015–FR-017, FR-019 / SC-004–SC-006 | UI assertions + catalog checks | interactive controls named；single search；Dynamic Type layouts scroll；catalog complete |
| Platform isolation | FR-020, FR-024 / SC-009 | compile-time contract tests + macOS targeted suites | macOS toolbar/settings/polling/reconciliation unchanged；visionOS compiles |
| Offline/local-first | FR-007, FR-022 / SC-010 | all targeted integration tests with network unused | no network dependency or off-device content path |
| Performance | SC-001, SC-008 | timing assertion + request stress | callback providers ready後row visible≤1s；50requests, 0 crash/duplicate/stale writes |

## 5. Final Regression Validation

Authoritative command: `Scripts/verify.sh`.

此 gate 必須執行，原因是本功能觸及 `NextPasteApp` launch/scene lifecycle、Home navigation、
explicit clipboard acquisition、SwiftData persistence input、localization與跨平台conditional code。
成功必須由本次實際 log 證明 zero warnings/failures/skips；dry run 只能算 static validation。

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

| Area | Scenario | Required evidence |
| --- | --- | --- |
| Real cold-launch paste | Copy text in another App → terminate/launch NextPaste → observe before tap → tap system Paste | before tap: no prompt/row; after tap: exactly one new row within1s |
| Real foreground image | Copy supported image → background/foreground NextPaste → tap system Paste | no auto import; after tap thumbnail visible, reopen restores image, no duplicate |
| System control | Test supported／unsupported content and visible App-specific paste settings | control visible/disabled as system decides; no custom programmatic fallback or pressure |
| Background limitation | Copy A then B while app suspended, return → tap Paste | only current B is considered; UI/docs make no A/background-capture claim |
| Device layout | smallest/largest supported iPhone, portrait/landscape, display zoom | no horizontal crop; title/search/add/filter/settings/paste/history reachable |
| Accessibility | VoiceOver, largest Dynamic Type, Bold Text, Increase Contrast, Reduce Transparency/Motion | logical focus order, named/stateful actions, readable/scrollable content, no color-only meaning |
| Offline | airplane mode for complete copy/import/search/settings/relaunch flow | all local tasks succeed; zero outbound clipboard content |

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

| Budget | Operation | Measurement |
| --- | --- | --- |
| ≤1 second | PasteButton callback providers ready至歷史row可見 | monotonic timestamp around explicit import + UI readiness assertion；使用者操作時間excluded |
| 50 requests | rapid explicit paste with duplicate/new/cancelled/stale callbacks and lifecycle changes | deterministic coordinator stress；0 crash、0 duplicate、0 stale commit |

如果目前實作超過 budget，測試必須失敗；不得在 plan/tasks 階段放寬 SC。

## 11. Representative Validation

- Backward compatibility representative: existing macOS `ClipboardAutoCaptureUITests`、
  `AdaptiveToolbarUITests`、`SearchAccessibilityUITests`、`SettingsUITests`、row-action/pin suites。
- Forward correctness representative: new iOS no-read launch、explicit text/image paste、native
  home search/filter、new clip、settings preference flow。
- Status保持 `Pending`，直到實際命令與結果被記錄；artifact consistency analysis不等於 pass。

## 12. Release Readiness

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
| `tasks.md` | Synchronized | 49 dependency-ordered tasks generated after plan completion |
