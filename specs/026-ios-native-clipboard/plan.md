# Implementation Plan: iOS 原生體驗與前景剪貼簿匯入

**Branch**: `main` | **Date**: 2026-07-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/026-ios-native-clipboard/spec.md`

## Summary

NextPaste 的 iOS target 目前同時受到桌面最小寬度與桌面式工具列裁切，且非 macOS
`ClipboardPasteboardReader.live` 永遠回傳空資料，因此使用者無法在其他 App 複製後回到
NextPaste 使用內容。本功能會保留共享暖米色／金色／圓角卡片設計系統，但以 iOS 原生
`NavigationStack`、toolbar、`.searchable`、`List`、sheet 與 `Form` 重建資訊架構；同時新增
iOS 專屬、scene-aware 的前景剪貼簿協調器，在每次 active 生命週期至多處理一次最新
`UIPasteboard` 內容，並以 SwiftUI `PasteButton` 作為符合系統使用者意圖的可靠替代入口。
所有有效 payload 仍進入既有 `ClipboardCaptureService`，完整保留驗證、去重、SwiftData、
圖片檔案、保留上限與 `@Query` 畫面更新流程。macOS polling 與 visionOS 行為不變。

## Technical Context

**Language/Version**: Swift 5 language mode，Xcode 26.5 SDK

**Primary Dependencies**: SwiftUI、SwiftData、UIKit (`UIPasteboard`)、Uniform Type Identifiers、
Foundation、ImageIO；無第三方相依套件

**Storage**: 既有 SwiftData `ModelContainer`／`ClipItem`；圖片沿用本機
`ImageClipFileStore`；iOS opportunity/change-count 狀態只存在目前 App 行程記憶體

**Testing**: Swift Testing (`NextPasteTests`)、XCTest/XCUITest (`NextPasteUITests`)、
`NextPaste.xctestplan` 與 `Scripts/verify.sh`

**Target Platform**: iOS/iPadOS 26.5（本功能主要驗收）；macOS 15.0 與 visionOS 26.5
必須通過回歸且不得改變行為

**Project Type**: 多 Apple 平台 SwiftUI Xcode application（非 Swift Package）

**Performance Goals**: 前景匯入在系統授權且 payload 可用時於 1 秒內反映於歷史；
前景切換不阻塞主執行緒；一般捲動維持流暢；50 次快速 active/background 切換無重複保存

**Constraints**: 完全離線、剪貼簿內容不得離開裝置；不得繞過 iOS 貼上權限；iOS 背景
不輪詢；只處理回前景當下的最新項目；所有 iOS 觸控目標至少 44 x 44 pt；支援 Dynamic
Type、VoiceOver、安全區域與橫向；保留既有跨平台矩陣

**Scale/Scope**: 一個主畫面、一個新增sheet、一個navigation-pushed iOS設定Form；文字與
點陣圖片payload；平台adapter、UI-test harness、產品與測試約20個檔案受影響，不新增資料模型
或外部服務

## Root-Cause and Technical Strategy

| Surface | Confirmed root cause | Strategy |
| --- | --- | --- |
| Clipboard | `ClipboardPasteboardReader.live` 在非 macOS 固定 `0`/`nil`；polling monitor 啟動時又把目前 change count 當基準 | macOS monitor 保留；iOS 新增 scene-aware async coordinator，首次及每次 active 檢查目前 change count，將最新 payload 送入既有 capture service |
| Paste privacy | 程式化讀取其他 App 的內容由 iOS 決定是否顯示貼上授權；背景無可靠監測 | 尊重系統提示與選擇；永遠提供 `PasteButton` 明確使用者意圖路徑；不承諾背景捕捉或取回被覆寫內容 |
| Layout | `NextPasteApp` 的 universal `minWidth: 520`、`AppToolbar` 的桌面寬度與首頁 24pt 外距在 iPhone 形成水平畫布 | 只在 macOS 套用桌面 frame/toolbar；iOS 採原生 navigation、toolbar、search 與 edge-to-edge list |
| Row identity/action | iOS 仍使用 index identity，且整列點擊複製與列內複製鈕重複，圖示控制偏小 | iOS 以 `ClipItem.id` 建立穩定列；單一明確複製動作，加上原生 swipe/context menu，至少 44pt |
| Settings/editor | iOS 設定是 placeholder；設定與新增畫面有桌面固定尺寸 | iOS 使用 `Form` 與 `NavigationStack` sheet；共用既有 preference/service，排除 Mac shortcuts |

## Constitution Check

*GATE: Phase 0 前檢查，並於 Phase 1 設計完成後重新檢查。*

| Principle | Status | Evidence |
| --- | --- | --- |
| I. Clipboard-First | ✅ Pass | iOS payload 仍走 `Detect → Validate → Deduplicate → Persist → Refresh UI`；只新增平台取得來源。 |
| II. Local-First | ✅ Pass | SwiftData、圖片與偏好皆留在裝置；無網路相依。 |
| III. Privacy by Default | ✅ Pass | 尊重系統貼上授權；狀態與測試訊號不記錄內容；fallback 使用系統 `PasteButton`。 |
| IV. Automatic Capture | ✅ Pass | iOS 在可行的 active 邊界自動嘗試最新內容，且明確記錄平台限制；macOS 持續 polling 不變。 |
| V. Test-First Development | ✅ Pass | spec、validation contract 與 tasks 先定義單元、UI、人工權限驗證，再實作。 |
| VI. Validation Governance | ✅ Pass | 驗證矩陣與證據生命週期只由 `contracts/validation-and-sonar-contract.md` 擁有。 |
| VII. Template-First Governance | ✅ Pass | 使用既有 feature templates；未新增重複治理結構。 |
| VIII. Test Execution Efficiency | ✅ Pass | 先跑協調器／payload targeted tests，再跑 iOS UI，最後因 app launch/navigation/shared capture 變更執行完整 gate。 |
| IX. Continuous Quality Improvement | ✅ Pass | 將平台分支與 scene lifecycle seam 固化為可測結構，避免再次以 universal desktop frame 破壞 mobile。 |
| X. Apple Platform Consistency | ✅ Pass | iOS 使用原生導航、搜尋、表單、貼上與 swipe；平台差異限於 `#if os(iOS)`。 |
| XI. Spec Traceability | ✅ Pass | 只有 `spec.md` 擁有 FR/SC；design/task artifacts 僅引用。 |
| XII. Root Cause First Engineering | ✅ Pass | repository audit 已確認 reader no-op 與 universal min-width，研究與實作直接對應根因。 |
| XIII. Performance Budget Governance | ✅ Pass | SC-001/SC-008 定義 1 秒匯入與 50 次 lifecycle 壓力預算，validation contract 定義量測。 |
| XIV. Native Simplicity | ✅ Pass | 僅用 SwiftUI、UIKit、SwiftData、UTType 與既有服務，不新增替代框架。 |
| XV. Consistent Design System | ✅ Pass | 保留 `AppTheme`、DesignTokens、卡片、徽章與插圖；只替換平台容器與 interaction grammar。 |
| XVI. Refactoring Integrity | ✅ Pass | macOS monitor、資料模型、capture/dedup/retention 與現有 history 行為保持不變，另加 parity tests。 |
| XVII–XVIII. Governance Evolution/Status | ✅ Pass | 非治理功能，不修改 constitution；Implementation/Verification 狀態由 tasks/contract 管理。 |
| XIX. Specification Lifecycle | ✅ Pass | 新功能在獨立 `specs/026-ios-native-clipboard/`；完成前保持 draft/active 工作狀態。 |

**Post-Phase-1 re-check**: 設計未引入違規。唯一主動程式化剪貼簿讀取發生在 iOS active
生命週期，仍受 Apple 系統授權控制；`PasteButton` 提供明確意圖路徑；不新增背景模式、
網路、分析或敏感診斷。macOS 與 visionOS 由 compile-time 分支及完整回歸保護。

## Project Structure

### Documentation (this feature)

```text
specs/026-ios-native-clipboard/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── ios-clipboard-import-contract.md
│   └── validation-and-sonar-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
NextPaste/
├── NextPasteApp.swift                    # scenePhase wiring；iOS 移除 desktop min width
├── HomeView.swift                        # iOS native navigation/search/list/actions/settings presentation
├── NewClipView.swift                     # iOS NavigationStack sheet；macOS presentation preserved
├── SettingsView.swift                    # macOS tabs preserved
├── IOSSettingsView.swift                 # NEW：iOS Form settings
├── ClipboardCaptureService.swift         # reused capture authority
├── ClipboardMonitor.swift                # macOS polling lifecycle preserved
├── ClipboardMonitorClient.swift          # shared payload types/macOS reader preserved
├── IOSClipboardImportCoordinator.swift   # NEW：active-generation serialization/result model
├── IOSPasteboardClient.swift             # NEW：UIKit/NSItemProvider snapshot and test seam
├── DesignSystem/                         # existing tokens/components reused
└── Localizable.xcstrings                 # new iOS labels, hints, status and privacy copy

NextPasteTests/
├── IOSClipboardImportCoordinatorTests.swift  # NEW：active/dedupe/cancel/result state
├── IOSPasteboardClientTests.swift            # NEW：text/image/type priority loader seams
├── ClipboardCaptureTests.swift               # existing dedupe/validation regression
└── SettingsPresentationContractTests.swift   # extend platform presentation contract

NextPasteUITests/
├── IOSNativeHomeUITests.swift            # NEW：no crop, one search, toolbar/list/empty actions
├── IOSClipboardImportUITests.swift       # NEW：deterministic fixture-driven active import/fallback
├── IOSSettingsUITests.swift              # NEW：Form, preferences, destructive confirmation
├── CreateTextClipUITests.swift            # extend iOS editor navigation
├── UITestAppLauncher.swift                # extend iOS fixture/scene configuration
└── ClipboardFixture.swift                 # extend iOS test clipboard path if safe
```

**Structure Decision**: 維持單一 file-system-synchronized Xcode app target。新平台協調器與
pasteboard client 放在 app target，純狀態邏輯透過注入 closure/client 在 `NextPasteTests`
驗證；iOS 使用同一 SwiftData 與 design system，不建立第二套 store、theme 或 feature module。

## Implementation Phases

### Phase A — iOS clipboard acquisition

1. 建立 content-free `IOSClipboardImportResult` 與 injectable pasteboard snapshot/provider client。
2. 建立 App-owned `@MainActor` coordinator，以 scene registry、active generation、in-flight task
   與 process-local last handled change identifier 序列化請求；所有 scene background才取消舊
   generation，避免系統貼上提示造成的短暫 inactive誤取消合法結果。
3. 解析 item providers 時優先有效圖片、其次文字；若觀察到圖片候選但解碼失敗，不把
   同項目的文字 metadata 誤存為 clipboard 內容。
4. 自動 active 路徑與 `PasteButton` payload 路徑都呼叫同一 payload loader 與
   `ClipboardCaptureService`；結果只暴露 enum，不暴露內容。
5. 在 `NextPasteApp` 只對 iOS scenePhase 接線；aggregate active scene由空轉為非空才建立一次
   app-wide opportunity；macOS lifecycle controller完全保留。

### Phase B — native iOS UI

1. 將 `HomeView` 的 desktop toolbar/frame 分支限制於 macOS；iOS 採 NavigationStack、
   navigation title、toolbar、單一 `.searchable`。
2. iOS List 改用穩定 UUID；保留主題卡片但移除重複 copy gesture，提供 native swipe/menu。
3. 空歷史顯示「在其他 App 複製後返回」以及系統 Paste／New Clip；搜尋與篩選空狀態
   分別提供 clear/reset。
4. iOS 新增與設定都以 NavigationStack sheet 顯示；設定使用 Form、既有 preferences、
   privacy 文案與 destructive confirmation，不顯示 Mac shortcuts。
5. 全面檢查 44pt target、Dynamic Type、VoiceOver labels/hints/state、Reduce Motion 與 safe area。

### Phase C — verification and polish

1. 先以 fake client 驗證 lifecycle generation、重複 active、async cancellation、文字／圖片、
   denial/unavailable 與 capture outcome mapping。
2. 以 Debug-only deterministic fixture 驗證 iOS UI 與 cold launch/active import，且 Release
   不得暴露測試控制。
3. 在 booted iPhone simulator 實際安裝、複製文字、terminate/launch、處理系統 Paste prompt、
   檢查歷史與 screenshot；權限記憶行為另列人工證據。
4. 執行 targeted iOS build/tests、macOS regression，最後 `Scripts/verify.sh`。

## Complexity Tracking

沒有 constitution violation。新增兩個小型 iOS 專屬型別是為了把 scene lifecycle、UIKit
pasteboard 與現有 capture authority 分離並可測；它們不建立第二套資料或 UI 架構。
