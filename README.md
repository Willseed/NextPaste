# NextPaste

> 一個以剪貼簿為核心、本地優先的 Apple 平台剪貼簿管理員。自動捕捉你複製的內容，讓你之後能快速回顧、搜尋與重用。

NextPaste 會自動保存文字與圖片剪貼簿內容，並提供搜尋、釘選與快速複製，讓常用內容隨時可取用。所有剪貼簿歷史預設保留在裝置上；除非明確取得同意，否則不會外送至遠端服務。

應用以 SwiftUI、SwiftData、Observation 與 Apple 原生互動模型建構，並遵循 `.specify/memory/constitution.md`（目前為 v2.8.0）的治理框架與 SDD（Spec-Driven Development）流程開發。

## 安裝

### Mac App Store

[前往 NextPaste 的 Mac App Store 正式頁面](https://apps.apple.com/us/app/nextpaste/id6791212237)。公開供應狀態與地區可用性以 App Store 顯示為準。

### Homebrew

使用 [`willseed/tap`](https://github.com/Willseed/homebrew-tap) 中的 `nextpaste` cask 安裝：

```bash
brew install --cask willseed/tap/nextpaste
```

## 核心流程

NextPaste 的核心價值來自以下不可破壞的剪貼簿優先流程：

```
剪貼簿變更 -> 偵測 -> 驗證 -> 去重 -> 持久化 -> 刷新 UI
```

- **自動捕捉**：應用程式執行期間，無論前景、背景或最小化，都會自動監聽剪貼簿變更並將新內容存為剪輯（Feature `003` 文字、Feature `006` 圖片）。
- **去重與驗證**：忽略空白或全空白內容，並對重複的剪貼簿內容去重，避免歷史清單充斥雜訊。
- **本地優先**：使用 SwiftData 作為本地持久化的事實來源；不需要網路連線即可建立、儲存與回顧剪輯。
- **手動建立**：保留手動貼上純文字並儲存為文字剪輯的流程（Feature `001`），作為自動捕捉的後備方案。

## 主要功能

| 功能 | Spec | 說明 |
| --- | --- | --- |
| 建立文字剪輯 | `001-create-text-clip` | 開啟 NewClipView 貼上純文字、儲存為 `ClipItem`，並在 HomeView 歷史中看到新剪輯。 |
| 剪輯列操作 | `002-clip-row-actions` | 列列上的 copy、pin、delete 等操作。 |
| 剪貼簿自動捕捉 | `003-clipboard-auto-capture` | 應用執行時自動捕捉文字剪貼簿變更，去重並刷新歷史。 |
| 視覺識別系統 | `004-visual-identity-system` | 暖色奶油畫布、深色油墨字體、Inter 字體、圓角形式與沉靜動畫的設計系統。 |
| 圖片剪貼簿捕捉 | `006-clipboard-image-capture` | 自動捕捉 Apple 可解碼的點陣圖（PNG、JPEG、截圖），於本機保留完整圖檔並產生縮圖。 |
| 剪貼簿歷史搜尋 | `010-clipboard-history-search` | 工具列原生搜尋欄，即時子字串過濾，保留 pinned-first 與最新優先排序。 |
| 原生 macOS 滑動操作 | `009-native-macos-swipe-actions` | 在 macOS 上保留原生滑動操作體驗。 |
| Pin/Unpin 安全重構 | `021-refactor-pin-unpin-safety` | 透過 `@MainActor` 序列化變動管線、以穩定身份驅動 Pin/Unpin，並在儲存失敗時回滾。 |

更多功能與對應的 spec/plan/tasks/contracts 請見 [`specs/`](specs/) 目錄。

## 架構

- `NextPasteApp.swift`：應用啟動入口，建立共用的 SwiftData `ModelContainer` 並注入根 `WindowGroup`。
- `ContentView.swift`：主要 UI 與目前功能入口。以 `@Query` 讀取持久化資料，透過 `@Environment(\.modelContext)` 寫入，並依賴 SwiftData 維持清單同步。
- `HomeView.swift`：剪貼簿歷史的主要介面。
- `NewClipView.swift`：手動建立文字剪輯的介面。
- `ClipItem.swift`：持久化領域模型，記錄 `id`、`contentType`、`textContent`、`createdAt`、`updatedAt` 等欄位。
- `ClipboardMonitor.swift` / `ClipboardCaptureService.swift`：剪貼簿監聽與捕捉服務。
- `ClipboardWriter.swift`：將剪輯內容寫回系統剪貼簿。
- `PinStateMutationStore.swift` 系列：序列化的 Pin/Unpin 變動管線與診斷。
- `DesignSystem/`：共用的視覺識別與設計系統元件。

專案包含三個 Xcode target：`NextPaste`（App）、`NextPasteTests`（單元測試，使用 Swift Testing 模組）、`NextPasteUITests`（UI 自動化測試，使用 XCTest）。

## 平台與技術棧

- **平台**：以 macOS 為主要目標，專案亦設定 `iphoneos`、`iphonesimulator`、`macosx`、`xros`、`xrsimulator` 等多平台。請勿假設為單一平台應用。
- **技術棧**：SwiftUI、SwiftData、Observation、Vision、Foundation Models、Foundation、CloudKit、AppKit（macOS 原生列操作觀察）。
- **持久化**：本地 SwiftData 為事實來源；遠端同步與 CloudKit 為次要選項，必須服從本地優先的捕捉與檢索。
- **隱私**：剪貼簿衍生內容預設留在裝置上，除非明確同意且具備本地優先後備方案。

## 建置與測試

此專案為 Xcode app project，非 Swift Package，請使用 `xcodebuild` 搭配 `NextPaste.xcodeproj` 與 `NextPaste` scheme。

```bash
# 建置 macOS 應用
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build

# 執行完整測試套件
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test

# 僅執行 Swift Testing 單元測試目標
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test

# 執行單一單元測試
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteTests/NextPasteTests/example test

# 執行單一 UI 測試
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/NextPasteUITests/testExample test
```

本專案未簽入 SwiftLint 或 repo 專屬 lint 腳本，請以 Xcode 建置/測試診斷為準，除非日後新增工具。

## 開發流程（SDD）

本專案採用 Spec-Driven Development（SDD）序列，並由 `.specify/memory/constitution.md` 治理：

```
/speckit.specify -> /speckit.clarify -> /speckit.plan -> /speckit.tasks -> /speckit.analyze -> /speckit.implement
```

- `spec.md` 是功能性需求 ID（`FR-###`）與成功準則 ID（`SC-###`）的唯一權威來源。
- 驗證執行與生命週期規則集中於 `specs/<feature>/contracts/validation-and-sonar-contract.md`；`quickstart.md` 僅為執行說明，不重複定義驗證矩陣。
- 治理傳播順序：`Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact`。
- 重構預設為行為保留，並以回歸覆蓋驗證一致性；偏好根因修復而非症狀修補。
- 驗證採比例原則：先針對純邏輯跑單元測試、跨元件跑整合測試、使用者可見流程跑 UI 測試，完整回歸僅於完成/發布/共用基礎設施閘門執行。

## 專案結構

```
NextPaste/
├── NextPaste.xcodeproj        # Xcode 專案
├── NextPaste/                 # App target 原始碼
│   ├── NextPasteApp.swift     # 應用啟動與 ModelContainer
│   ├── ContentView.swift      # 主要 UI 入口
│   ├── HomeView.swift         # 剪貼簿歷史介面
│   ├── NewClipView.swift      # 手動建立文字剪輯
│   ├── ClipItem.swift         # 持久化領域模型
│   ├── ClipboardMonitor.swift # 剪貼簿監聽
│   ├── DesignSystem/          # 共用設計系統
│   └── ImageClips/            # 圖片剪輯相關元件
├── NextPasteTests/            # 單元測試（Swift Testing）
├── NextPasteUITests/          # UI 測試（XCTest）
├── specs/                     # 各功能的 spec/plan/tasks/contracts
└── .specify/                  # SDD 治理、模板、腳本與記憶
    └── memory/constitution.md # 治理憲法（v2.8.0）
```

## 授權

請參考專案內的授權檔案（若存在）或聯絡維護者取得授權資訊。
