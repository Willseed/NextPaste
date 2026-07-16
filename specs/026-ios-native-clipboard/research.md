# Research: iOS 原生體驗與前景剪貼簿匯入

**Feature**: 026-ios-native-clipboard
**Date**: 2026-07-17
**Research order**: 依使用者要求，先呼叫 ask-bridge／ChatGPT 並設定20分鐘timeout。該網站型
研究在超過20分鐘後仍未產生回覆，已依timeout強制終止；沒有切換Gemini/Claude，也沒有把
未收到的AI回覆當成證據。後續以本機Xcode SDK、Apple官方文件與repository source完成驗證。
下列決策只以primary source、可編譯API與實際code audit為準。

## Repository Findings

### Root cause A — iOS clipboard is a deliberate no-op

- `ClipboardPasteboardReader.live.currentChangeCount` 在 `#else` 固定回傳 `0`。
- `currentPayload` 與 `currentString` 在 `#else` 固定回傳 `nil`。
- `ClipboardMonitor.start()` 會把啟動當下 change count 設成 baseline，所以即使直接把 reader
  換成 `UIPasteboard`，使用者在啟動前複製的內容仍可能被當成已觀察而略過。
- `ClipboardMonitorHostView` 只在 SwiftUI `.task` 啟動 monitor，沒有 iOS `scenePhase`
  active import 邊界。

**Conclusion**: 不能只在現有 polling reader 補 UIKit。macOS continuous polling 與 iOS
foreground opportunity 是不同平台行為，應使用不同 lifecycle owner，共用 capture pipeline。

### Root cause B — desktop layout is applied universally

- `NextPasteApp` 對所有平台套用 `.frame(minWidth: 520, minHeight: 380)`。
- `HomeView` 對所有平台顯示 desktop card toolbar；compact presentation 仍有約 440pt 的內容需求。
- iOS 設定按鈕只顯示 placeholder，而真正的 `SettingsView` 使用 macOS tab/window fixed sizing。
- `NewClipView` 使用 desktop button row 及 `.frame(minWidth: 360, minHeight: 280)`。
- iOS List 使用 index identity 的 macOS row-slot workaround，且 row tap copy 與 row 內 copy
  control 重複。

**Conclusion**: 品牌元件可共享，但 navigation/search/list/sheet/form 必須採平台原生結構；
desktop workaround 不應成為 iOS layout contract。

## Apple Platform Research

### Decision 1 — active-time import, never background monitoring

Apple 的 [`UIPasteboard`](https://developer.apple.com/documentation/uikit/uipasteboard/) 提供
general pasteboard、`changeCount`、type availability 與內容存取。general pasteboard 可跨 App
與 process restart 保存目前內容，但 iOS App 在背景或未執行時沒有可靠的 clipboard-change
execution guarantee。

**Decision**:

- 在 scene 變成 `.active` 時建立一個 foreground opportunity。
- 先讀不含內容的 `changeCount`，只有首次 opportunity 或 change count 改變才載入內容。
- 每個 active generation 至多提交一次；短暫 inactive 不取消（系統貼上提示可能造成此轉換），
  只有所有 scene 真正進入 background／移除時才使舊 generation 失效。
- 只承諾處理回前景當下仍存在的最新 clipboard item；不宣稱捕捉背景期間的中間項目。

**Rejected**:

- iOS repeating timer：背景會被 suspend，且會反覆接觸敏感內容，不能達成可靠 background capture。
- background mode／notification：系統沒有為一般 App 提供 clipboard change background trigger。
- 把 iOS 塞進 macOS `ClipboardMonitor`：啟動 baseline 與 lifecycle semantics 不相容，會再次漏掉 cold-launch copy。

### Decision 2 — programmatic attempt plus system PasteButton fallback

Apple 說明自 iOS 14 起，沒有可辨識使用者意圖的跨 App 程式化 pasteboard content access
可能顯示通知或授權提示。Apple 的
[`UIPasteControl`](https://developer.apple.com/documentation/uikit/uipastecontrol) 與 SwiftUI
`PasteButton` 代表使用者明確貼上意圖；目前 Xcode 26.5 SwiftUI SDK 提供
`PasteButton(supportedContentTypes:payloadAction:)` 及 Transferable overload。

**Decision**:

- 為達成「複製後打開即可使用」，進入 active 時對最新內容做一次 programmatic attempt，
  完整尊重 iOS 顯示的 Paste permission 與使用者選擇。
- 主畫面提供常駐、易找到的 system `PasteButton` fallback；不以自製 button 模擬或繞過意圖。
- 不讀取內容來決定是否顯示 fallback；狀態與說明不得包含 clipboard preview。
- permission 被拒絕或 provider unavailable 時保持 App 可用，不重複施壓；下一個明確 active/change
  opportunity 才重新評估，使用者亦可直接按 Paste。

**Rejected**:

- 僅自動讀取、沒有 fallback：拒絕權限後核心功能無恢復路徑。
- 僅 PasteButton：隱私最佳但不符合使用者明確要求的「複製後打開即可使用」。
- 自製「貼上」按鈕直接呼叫 `UIPasteboard`：不具系統控制可辨識的使用者意圖保障。

### Decision 3 — NSItemProvider-based async loader

`PasteButton` 的 type-erased overload回傳 `[NSItemProvider]`；因此 programmatic snapshot 與
explicit paste 都可在 provider 層匯流，再轉換成現有 `ClipboardPayload`。

**Decision**:

- supported types 包含 Xcode SDK 可解碼的 image UTTypes 與 `.plainText`/`.text`。
- 依現有 macOS 規則先尋找圖片候選，再讀文字；有效圖片保存原始 data 與 UTType。
- 若 provider 宣告 image candidate 但資料損壞，回報 unsupported/failed，不把同一 clipboard item
  的文字 metadata 誤當主要內容。
- loader 使用 async continuation 包裝 provider callback，generation/cancellation 檢查發生在
  persistence 前；不把 content 放入 log、defaults 或 debug accessibility value。

**Rejected**:

- 直接以 `UIPasteboard.string` 作唯一來源：不支援圖片，且會失去既有 image-first semantics。
- 新增另一個 iOS capture service：會複製 validation/dedup/persistence rules，違反 SwiftData
  source-of-truth 與 refactor parity。

### Decision 4 — native navigation/search/toolbar/list/form

Apple 的 [`Search fields`](https://developer.apple.com/design/human-interface-guidelines/search-fields)
與 [`Searching`](https://developer.apple.com/design/human-interface-guidelines/searching) 指引強調
清楚且一致的單一搜尋位置；[`Toolbars`](https://developer.apple.com/design/human-interface-guidelines/toolbars)
要求依平台與內容層級安排主要/次要 actions；
[`Accessibility`](https://developer.apple.com/design/human-interface-guidelines/accessibility)
對 iOS/iPadOS 建議至少 44 x 44pt 的 hit target。

**Decision**:

- iOS root 使用 `NavigationStack` 與 inline/automatic navigation title；只保留一個 `.searchable`。
- 新增為主要 toolbar item；filter/settings 放在原生 toolbar/menu；Paste 在空狀態與可達 menu 中。
- 使用 `List` 保留原生 scrolling、safe area、swipe、keyboard/focus 與 accessibility 行為；
  card 仍以 `AppTheme`/tokens 呈現。
- iOS settings 使用 `Form`/sections，editor 使用 NavigationStack sheet 的 leading Cancel、trailing Save。
- 最小 44pt、Dynamic Type wrapping、VoiceOver label/hint/value、Reduce Motion/Transparency 由
  native controls 與共享 theme semantic colors 支援。

**Rejected**:

- 將既有 `AppToolbar` 壓縮：其資訊結構與 desktop minimum widths 仍不適合 iPhone。
- 全新平面 system-gray 外觀：雖原生，但不符合保留既有設計語言的要求。
- custom search field 加 `.searchable`：製造重複入口與 VoiceOver 混淆。

## State and Persistence Decisions

### Last handled change identifier

使用 content-free `Int` 在目前 App 行程記憶體內記錄最近已完成／正在處理的 pasteboard
`changeCount`，避免相同 active/inactive或多scene事件重複觸發內容讀取與權限提示。change count
是只能做相等比較的 opaque token，不假設單調或跨啟動穩定，因此不得寫入UserDefaults。
每次cold launch可重新處理當下clipboard；既有content dedupe是最終正確性防線。

### Capture outcome mapping

現有 `ClipboardCaptureService.CaptureOutcome` 是 persistence authority。iOS 顯示狀態只映射成
content-free cases：captured、duplicate、empty、unsupported、permission/unavailable、cancelled、
failed。`.captured(String)` 的 associated value 可能是實際文字，因此不可直接保存或輸出；
coordinator 只轉成 `.captured`。

### Multi-scene and stale work

App-owned process-wide coordinator序列化所有scene events。每個scene以穩定ID註冊active、
inactive、background；aggregate active set由空轉非空才建立opportunity。每個import持有request ID、
generation與automatic change-count token；在payload load後與capture前再次確認owner、foreground
與freshness。所有scene background才取消task，晚到callback不得寫入。

## Accessibility and Visual QA Decisions

- 最窄支援 iPhone 直向／橫向與最大 accessibility text size 都不得形成水平 scroll canvas。
- 每個 icon-only toolbar/list action以 44 x 44pt frame/contentShape 提供 hit target，並有本地化
  label/hint；pin state 使用 accessibility value/trait，不只靠顏色。
- row content 不以整列與 copy button 同時綁定相同 action；避免 VoiceOver 重複與 accidental copy。
- 系統 paste permission prompt 的文字與位置由 iOS 擁有，只做 simulator/manual matrix；產品
  UI automation 不嘗試偽造系統授權。
- empty history、empty search、empty filter 分開，分別提供 Paste/New、Clear Search、Reset Filter。

## Validation Research

- 純 coordinator 狀態以 fake snapshot/client + fake capture sink 驗證，不依賴 simulator permission。
- provider parsing 對 text、PNG/JPEG、invalid image candidate、unsupported、cancellation 建立 unit tests。
- Debug UI-test fixture 必須由完整 `-ui-testing` environment gate，Release 不可啟用；測試訊號不得
  包含剪貼簿內容。
- 真實 user workflow 仍需 booted simulator：從另一 process 設定 pasteboard、terminate/launch、
  對系統 prompt 選 Allow、觀察一筆歷史與 screenshot。不同 iOS permission memory state 必須列
  為人工矩陣，不能把 deterministic fixture pass 冒充 system prompt evidence。
- 這次觸及 app launch、navigation、clipboard capture 與 shared persistence path，因此完成時
  必須執行 repository-authoritative `Scripts/verify.sh`。

## Resolved Clarifications

- **Auto vs explicit paste**: active 時自動嘗試，系統可提示；永遠提供 PasteButton fallback。
- **Background behavior**: 不監測、不承諾；只取得回前景時最後一筆。
- **Supported content**: 既有純文字與可解碼點陣圖片，不擴大 ClipItem schema。
- **Design language**: 保留 theme/tokens/card/badge/illustration；navigation grammar 改原生。
- **iPad**: 同一 responsive single-column native container 保持可用，本功能不新增 sidebar architecture。
- **Other platforms**: macOS polling/settings/UI 不變；visionOS 不套 iOS 專屬 UIKit 或 navigation 分支。

沒有剩餘 `NEEDS CLARIFICATION`。
