# Implementation Plan: iOS 原生體驗與明確貼上

**Branch**: `main` | **Date**: 2026-07-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/026-ios-native-clipboard/spec.md`

## Summary

NextPaste 的 iOS target 目前同時受到桌面最小寬度與桌面式工具列裁切，且非 macOS
`ClipboardPasteboardReader.live` 永遠回傳空資料，因此使用者無法在其他 App 複製後回到
NextPaste 使用內容。本功能會保留共享暖米色／金色／圓角卡片設計系統，但以 iOS 原生
`NavigationStack`、toolbar、`.searchable`、`List`、sheet 與 `Form` 重建資訊架構；同時新增
iOS 專屬的明確貼上協調器，只處理使用者實際點擊 SwiftUI `PasteButton` 後由系統交付的
providers。啟動、畫面出現與 `scenePhase` 只處理 App 自有狀態，不讀取跨 App pasteboard value。
所有有效 payload 仍進入既有 `ClipboardCaptureService`，完整保留驗證、去重、SwiftData、
圖片檔案、保留上限與 `@Query` 畫面更新流程。macOS polling 與 visionOS 行為不變。

## Technical Context

**Language/Version**: Swift 5 language mode，Xcode 26.5 SDK

**Primary Dependencies**: SwiftUI、SwiftData、Uniform Type Identifiers、
Foundation、ImageIO；無第三方相依套件

**Storage**: 既有 SwiftData `ModelContainer`／`ClipItem`；圖片沿用本機
`ImageClipFileStore`；iOS 明確貼上 request ownership只存在目前 App 行程記憶體

**Testing**: Swift Testing (`NextPasteTests`)、XCTest/XCUITest (`NextPasteUITests`)、
`NextPaste.xctestplan` 與 `Scripts/verify.sh`

**Target Platform**: iOS/iPadOS 26.5（本功能主要驗收）；macOS 15.0 與 visionOS 26.5
必須通過回歸且不得改變行為

**Project Type**: 多 Apple 平台 SwiftUI Xcode application（非 Swift Package）

**Performance Goals**: PasteButton callback收到provider後於1秒內反映於歷史；App啟動與前景
切換的clipboard value access次數為0；50次快速明確貼上無重複保存或過期寫入

**Constraints**: 完全離線、剪貼簿內容不得離開裝置；不得繞過 iOS 使用者貼上意圖；iOS
launch／active／background不程式化讀取，只處理使用者點擊system Paste後的最新項目；所有 iOS 觸控目標至少 44 x 44 pt；支援 Dynamic
Type、VoiceOver、安全區域與橫向；保留既有跨平台矩陣

**Scale/Scope**: 一個主畫面、一個新增sheet、一個navigation-pushed iOS設定Form；文字與
點陣圖片payload；平台adapter、UI-test harness、產品與測試約20個檔案受影響，不新增資料模型
或外部服務

## Root-Cause and Technical Strategy

| Surface | Confirmed root cause | Strategy |
| --- | --- | --- |
| Clipboard | `ClipboardPasteboardReader.live` 在非 macOS 固定 `0`/`nil`；現有 polling語意也不適合 iOS隱私模型 | macOS monitor保留；iOS只解碼system `PasteButton` callback providers並送入既有capture service，不新增lifecycle reader |
| Paste privacy | launch／active程式化讀取其他App內容可能觸發modal permission；scene active不等於貼上意圖 | system `PasteButton` 是唯一cross-App acquisition boundary；控制必須可見且由使用者點擊，基本功能不依賴programmatic Allow |
| Layout | `NextPasteApp` 的 universal `minWidth: 520`、`AppToolbar` 的桌面寬度與首頁 24pt 外距在 iPhone 形成水平畫布 | 只在 macOS 套用桌面 frame/toolbar；iOS 採原生 navigation、toolbar、search 與 edge-to-edge list |
| Row identity/action | iOS 仍使用 index identity，且整列點擊複製與列內複製鈕重複，圖示控制偏小 | iOS 以 `ClipItem.id` 建立穩定列；單一明確複製動作，加上原生 swipe/context menu，至少 44pt |
| Settings/editor | iOS 設定是 placeholder；設定與新增畫面有桌面固定尺寸 | iOS 使用 `Form` 與 `NavigationStack` sheet；共用既有 preference/service，排除 Mac shortcuts |

## Constitution Check

*GATE: Phase 0 前檢查，並於 Phase 1 設計完成後重新檢查。*

| Principle | Status | Evidence |
| --- | --- | --- |
| I. Clipboard-First | ⚠️ Documented iOS exception | iOS payload仍走`Detect → Validate → Deduplicate → Persist → Refresh UI`，但Apple使用者意圖／隱私模型要求先點system Paste；macOS passive capture不變，FR-001～FR-006與SC-003提供例外回歸。 |
| II. Local-First | ✅ Pass | SwiftData、圖片與偏好皆留在裝置；無網路相依。 |
| III. Privacy by Default | ✅ Pass | iOS只接收可見system Paste control交付的providers；狀態與測試訊號不記錄內容。 |
| IV. Automatic Capture | ⚠️ Documented iOS exception | iOS刻意採一次明確system Paste，不以launch／active觸發content read；Apple隱私語意是理由，SC-003驗證零自動讀取，SC-009保護macOS持續polling。 |
| V. Test-First Development | ✅ Pass | spec、validation contract 與 tasks 先定義單元、UI、人工權限驗證，再實作。 |
| VI. Validation Governance | ✅ Pass | 驗證矩陣與證據生命週期只由 `contracts/validation-and-sonar-contract.md` 擁有。 |
| VII. Template-First Governance | ✅ Pass | 使用既有 feature templates；未新增重複治理結構。 |
| VIII. Test Execution Efficiency | ✅ Pass | 先跑協調器／payload targeted tests，再跑 iOS UI，最後因 app launch/navigation/shared capture 變更執行完整 gate。 |
| IX. Continuous Quality Improvement | ✅ Pass | 將平台分支與 scene lifecycle seam 固化為可測結構，避免再次以 universal desktop frame 破壞 mobile。 |
| X. Apple Platform Consistency | ✅ Pass | iOS 使用原生導航、搜尋、表單、貼上與 swipe；平台差異限於 `#if os(iOS)`。 |
| XI. Spec Traceability | ✅ Pass | 只有 `spec.md` 擁有 FR/SC；design/task artifacts 僅引用。 |
| XII. Root Cause First Engineering | ✅ Pass | repository audit 已確認 reader no-op 與 universal min-width，研究與實作直接對應根因。 |
| XIII. Performance Budget Governance | ✅ Pass | SC-001/SC-008定義callback後1秒匯入與50次request ownership壓力預算，validation contract定義量測。 |
| XIV. Native Simplicity | ✅ Pass | 僅用 SwiftUI、UIKit、SwiftData、UTType 與既有服務，不新增替代框架。 |
| XV. Consistent Design System | ✅ Pass | 保留 `AppTheme`、DesignTokens、卡片、徽章與插圖；只替換平台容器與 interaction grammar。 |
| XVI. Refactoring Integrity | ✅ Pass | macOS monitor、資料模型、capture/dedup/retention 與現有 history 行為保持不變，另加 parity tests。 |
| XVII–XVIII. Governance Evolution/Status | ✅ Pass | 非治理功能，不修改 constitution；Implementation/Verification 狀態由 tasks/contract 管理。 |
| XIX. Specification Lifecycle | ✅ Pass | 新功能在獨立 `specs/026-ios-native-clipboard/`；完成前保持 draft/active 工作狀態。 |

**Post-Phase-1 re-check**: 設計採constitution I／IV允許的明確平台例外：iOS cross-App
clipboard acquisition只在使用者點擊system `PasteButton` 後發生；launch／active不讀取，macOS
自動polling保持不變。例外由FR-001～FR-006、SC-003與SC-009驗證；不新增背景模式、網路、
分析或敏感診斷。visionOS由compile-time分支及完整回歸保護。

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
├── NextPasteApp.swift                    # explicit-paste coordinator injection；iOS移除desktop min width
├── HomeView.swift                        # iOS native navigation/search/list/actions/settings presentation
├── NewClipView.swift                     # iOS NavigationStack sheet；macOS presentation preserved
├── SettingsView.swift                    # macOS tabs preserved
├── IOSSettingsView.swift                 # NEW：iOS Form settings
├── ClipboardCaptureService.swift         # reused capture authority
├── ClipboardMonitor.swift                # macOS polling lifecycle preserved
├── ClipboardMonitorClient.swift          # shared payload types/macOS reader preserved
├── IOSClipboardImportTypes.swift         # NEW：content-free explicit request/result types
├── IOSClipboardImportCoordinator.swift   # NEW：explicit request ownership/result model
├── IOSPasteboardClient.swift             # NEW：PasteButton provider decoder/test seam；no general read
├── IOSPasteButton.swift                   # NEW：visible system PasteButton presentations
├── DesignSystem/                         # existing tokens/components reused
└── Localizable.xcstrings                 # new iOS labels, hints, status and privacy copy

NextPasteTests/
├── IOSClipboardImportCoordinatorTests.swift  # NEW：explicit/dedupe/cancel/result state
├── IOSPasteboardClientTests.swift            # NEW：text/image/type priority loader seams
├── IOSClipboardImportIntegrationTests.swift  # NEW：SwiftData/dedup/retention integration
├── IOSClipboardPrivacyContractTests.swift    # NEW：zero lifecycle/general-pasteboard reads
├── PlatformPresentationContractTests.swift   # extend precise iOS/macOS/visionOS branches
├── HomeViewIOSLayoutContractTests.swift      # NEW：native container/stable ID/hit targets
├── IOSSettingsPresentationTests.swift        # NEW：iOS Form/privacy/shortcut absence
├── ClipboardCaptureTests.swift               # existing dedupe/validation regression
└── SettingsPresentationContractTests.swift   # existing macOS presentation regression

NextPasteUITests/
├── IOSNativeHomeUITests.swift            # NEW：no crop, one search, toolbar/list/empty actions
├── IOSClipboardImportUITests.swift       # NEW：deterministic fixture-driven explicit paste
├── IOSSettingsUITests.swift              # NEW：Form, preferences, destructive confirmation
├── CreateTextClipUITests.swift            # extend iOS editor navigation
├── UITestAppLauncher.swift                # extend iOS fixture/scene configuration
└── ClipboardFixture.swift                 # extend iOS test clipboard path if safe
```

**Structure Decision**: 維持單一 file-system-synchronized Xcode app target。新平台協調器與
provider decoder放在app target，純狀態邏輯透過注入closure/client在`NextPasteTests`
驗證；iOS 使用同一 SwiftData 與 design system，不建立第二套 store、theme 或 feature module。

## Implementation Phases

### Phase A — iOS explicit clipboard acquisition

1. 建立content-free `IOSClipboardImportResult`與injectable provider decoder；release acquisition
   surface不得存取`UIPasteboard.general`。
2. 建立App-owned `@MainActor` coordinator，以request ID與in-flight task序列化使用者明確貼上；
   較新請求取消舊請求，晚到callback不得commit。
3. 解析 item providers 時優先有效圖片、其次文字；若觀察到圖片候選但解碼失敗，不把
   同項目的文字 metadata 誤存為 clipboard 內容。
4. system `PasteButton` providers是唯一content source，直接呼叫payload decoder與
   `ClipboardCaptureService`；結果只暴露enum，不暴露內容或再讀general pasteboard。
5. `NextPasteApp`只注入iOS coordinator，不以scenePhase、task、notification或timer啟動clipboard
   work；macOS lifecycle controller完全保留。

### Phase B — native iOS UI

1. 將 `HomeView` 的 desktop toolbar/frame 分支限制於 macOS；iOS 採 NavigationStack、
   navigation title、toolbar、單一 `.searchable`。
2. iOS List 改用穩定 UUID；保留主題卡片但移除重複 copy gesture，提供 native swipe/menu。
3. 空歷史以`ContentUnavailableView`顯示「返回並點Paste」，system Paste為唯一明顯primary、
   New Clip為secondary；已有歷史時toolbar顯示Paste＋`+`；搜尋與篩選空狀態分別提供clear/reset。
4. iOS新增使用NavigationStack sheet；設定使用navigation destination中的Form、既有preferences、
   privacy文案與destructive confirmation，不顯示Mac shortcuts。
5. 全面檢查 44pt target、Dynamic Type、VoiceOver labels/hints/state、Reduce Motion 與 safe area。

### Phase C — verification and polish

1. 先以fake decoder驗證explicit request ownership、async cancellation、文字／圖片、
   empty/unsupported與capture outcome mapping；source contract驗證lifecycle零general pasteboard read。
2. 以Debug-only deterministic fixture驗證iOS UI與user-triggered paste，且Release
   不得暴露測試控制。
3. 在booted iPhone simulator／device實際安裝、從另一App複製、terminate/launch，先確認未點
   Paste前無prompt／無新增，再點system Paste並檢查歷史與screenshot；system設定行為另列人工證據。
4. 執行 targeted iOS build/tests、macOS regression，最後 `Scripts/verify.sh`。

## Complexity Tracking

Principle I／IV具有已記錄的iOS平台例外，理由是Apple的paste使用者意圖與隱私模型；macOS
automatic capture不變且有回歸保護。少數聚焦的iOS專屬型別只把system Paste control、provider
decoding、request ownership與現有capture authority分離並可測，不建立第二套資料或UI架構。
