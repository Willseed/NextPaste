# Validation & Sonar Contract: iOS 原生體驗與前景剪貼簿匯入

**Feature**: 026-ios-native-clipboard
**Spec**: [spec.md](../spec.md)
**Plan**: [plan.md](../plan.md)
**Date**: 2026-07-17

本文件是此功能唯一的驗證權威，擁有 automated/manual/regression、offline/local-first、
accessibility、platform、performance、release readiness 與 Sonar applicability 的矩陣及證據
生命週期。`quickstart.md` 只列執行指令，不得重定義驗證要求。

## 1. Scope and Ownership

必須驗證：iOS foreground clipboard opportunity、system PasteButton fallback、文字／圖片 loader、
capture/dedup/persistence integration、native iPhone home/search/filter/rows/new clip/settings、
accessibility、localization、offline behavior，以及 macOS/visionOS parity。

明確排除：background clipboard capture、已被覆寫的中間項目、系統 paste permission prompt
文案控制、macOS UI redesign、visionOS navigation redesign、雲端／分析／外部處理。

## 2. Command Source

所有 build/test/full-gate 指令由 [`../quickstart.md`](../quickstart.md) 提供。targeted commands
必須先執行；完整 `Scripts/verify.sh` 只在功能完成閘門執行。

## 3. Targeted Validation Strategy

1. 純 coordinator、checkpoint、payload selection 與 result mapping 使用 Swift Testing + fake clients。
2. SwiftData capture/dedup/retention integration 使用 in-memory model container，不依賴 system prompt。
3. 可程式觀察的 iOS navigation/search/list/settings/new-clip 使用 serialized XCUITest。
4. Debug fixture 必須由完整 `-ui-testing` launch environment 隔離；Release isolation 另有 unit test。
5. 系統 paste permission 的 Allow/Don't Allow/Ask Every Time 與 Settings 撤銷以真實 simulator/manual
   matrix 補足，不以 fake fixture 冒充。
6. 因本功能改變 app launch、navigation、clipboard acquisition、shared capture/persistence wiring，
   完成時必須執行 repository-authoritative full gate。

## 4. Automated Validation Matrix

| Validation area | FR/SC | Execution source | Required evidence |
| --- | --- | --- | --- |
| iOS build | FR-009–FR-024 | iOS simulator build | 0 errors/warnings introduced；app 可安裝啟動 |
| Foreground lifecycle | FR-001, FR-006, FR-008 / SC-008 | `IOSClipboardImportCoordinatorTests` | cold active、重複 active、change、background cancel、stale completion、multi-scene serialization 全部正確 |
| Payload loading | FR-003, FR-007 / SC-001, SC-002 | `IOSPasteboardClientTests` | text、supported image、image-first、invalid image、unsupported、cancel mapping 正確；無內容 log |
| Capture integration | FR-002, FR-022 / SC-001, SC-002 | coordinator + existing capture tests | valid item 保存一次；duplicate/blank/failure 不新增；retention 與 rollback 不變 |
| Paste fallback | FR-004, FR-005 / SC-003 | iOS UI tests with provider fixture | PasteButton 可在兩次點按內到達；explicit providers 走同一 capture pipeline |
| Native home/search/filter | FR-009–FR-017 / SC-004–SC-007 | `IOSNativeHomeUITests` | 無 desktop toolbar/min-width；單一 search；stable row identity；empty recovery actions；44pt contract |
| New clip | FR-018 / SC-007 | existing/extended CreateTextClip UI tests | native Cancel/Save、validation、failure recovery、keyboard-safe layout |
| iOS settings | FR-019–FR-021 | `IOSSettingsUITests` + preference units | preferences persist；Mac shortcuts absent；destructive confirmations cancel/confirm correct |
| Accessibility/localization | FR-015–FR-017, FR-019 / SC-004–SC-006 | UI assertions + catalog checks | interactive controls named；single search；Dynamic Type layouts scroll；catalog complete |
| Platform isolation | FR-020, FR-024 / SC-009 | compile-time contract tests + macOS targeted suites | macOS toolbar/settings/polling/reconciliation unchanged；visionOS compiles |
| Offline/local-first | FR-007, FR-022 / SC-010 | all targeted integration tests with network unused | no network dependency or off-device content path |
| Performance | SC-001, SC-008 | timing assertion + lifecycle stress | authorized payload visible ≤1s；50 transitions, 0 crash/duplicate/stale writes |

## 5. Final Regression Validation

Authoritative command: `Scripts/verify.sh`.

此 gate 必須執行，原因是本功能觸及 `NextPasteApp` launch/scene lifecycle、Home navigation、
clipboard capture acquisition、SwiftData persistence input、localization 與跨平台 conditional code。
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
| Real cold-launch paste | Copy text in another App → terminate/launch NextPaste → Allow system paste | screenshot/video showing exactly one new row within 1s after permission |
| Real foreground image | Copy supported image → background/foreground NextPaste | row thumbnail visible, reopen restores image, no duplicate |
| Permission denial | Reset permission → deny programmatic paste → use system PasteButton | no content preview/leak/crash; fallback visible and succeeds via explicit intent |
| Permission revocation | Change NextPaste Paste from Other Apps setting, relaunch | app honors new state without repeated pressure; fallback remains available |
| Background limitation | Copy A then B while app suspended, return | only current B is considered; UI/docs make no A/background-capture claim |
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
| ≤1 second | system 已允許且 provider ready 時，scene active 至歷史 row 可見 | monotonic timestamp around import + UI readiness assertion；system prompt think time excluded |
| 50 transitions | alternating active/background with duplicate/new/stale callbacks | deterministic coordinator stress；0 crash、0 duplicate、0 stale commit |
| responsive UI | provider decode/persistence while navigation remains usable | no synchronous large-data load on main-thread UI callback；Xcode diagnostics/manual interaction |

如果目前實作超過 budget，測試必須失敗；不得在 plan/tasks 階段放寬 SC。

## 11. Representative Validation

- Backward compatibility representative: existing macOS `ClipboardAutoCaptureUITests`、
  `AdaptiveToolbarUITests`、`SearchAccessibilityUITests`、`SettingsUITests`、row-action/pin suites。
- Forward correctness representative: new iOS cold-active text flow、image flow、fallback paste、native
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
| `data-model.md` | Synchronized | transient state/checkpoint/result and existing ClipItem invariants recorded |
| `quickstart.md` | Synchronized | commands only; references this contract |
| `ios-clipboard-import-contract.md` | Synchronized | trigger、provider、serialization與privacy boundaries recorded |
| `tasks.md` | Synchronized | 49 dependency-ordered tasks generated after plan completion |
