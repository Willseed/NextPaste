# Research: iOS 原生體驗與明確貼上

**Feature**: 026-ios-native-clipboard
**Date**: 2026-07-17
**Research order**: 先前依使用者當時的設定呼叫 ask-bridge／ChatGPT，但沒有取得可用研究結果，
也沒有切換其他 provider。2026-07-17 使用者直接提供一份含 Apple 官方來源的研究審查，並明確
指示不用重新研究；本文件因此以該審查、本機 Xcode SDK 與 repository source audit 為準。附件
原文位於 workspace 外，不複製進 repository；下列決策保留其 Apple URL 與可執行產品結論。

## Repository Findings

### Root cause A — iOS clipboard is a deliberate no-op

- `ClipboardPasteboardReader.live.currentChangeCount` 在 `#else` 固定回傳 `0`。
- `currentPayload` 與 `currentString` 在 `#else` 固定回傳 `nil`。
- `ClipboardMonitor.start()` 會把啟動當下 change count 設成 baseline，所以即使直接把 reader
  換成 `UIPasteboard`，使用者在啟動前複製的內容仍可能被當成已觀察而略過。
- `ClipboardMonitorHostView` 只在 SwiftUI `.task` 啟動 monitor；把 iOS 接到該 lifecycle 或新增
  `scenePhase` content read 都會變成未經明確使用者意圖的程式化跨 App pasteboard access。

**Conclusion**: 不能只在現有 polling reader 補 UIKit，也不能建立 iOS active-time reader。
macOS continuous polling 保持不變；iOS 只接收真實 system paste control 交付的 providers，
然後共用既有 capture pipeline。

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

### Decision 1 — lifecycle refreshes only App-owned state

Apple 的 [`UIPasteboard`](https://developer.apple.com/documentation/uikit/uipasteboard/) 提供
general pasteboard、`changeCount`、type availability 與內容存取。general pasteboard 可跨 App
與 process restart 保存目前內容，但 iOS App 在背景或未執行時沒有可靠的 clipboard-change
execution guarantee。

**Decision**:

- scene 變成 `.active` 時只 reload SwiftData 與 App 自有狀態，不讀取 `UIPasteboard.general`
  的 value、`itemProviders` 或其他跨 App 內容。
- launch、`onAppear`、`.task`、notification 與 timer 同樣禁止作為 pasteboard value read trigger。
- 背景不監測；使用者返回後，由可見的 system `PasteButton` 取得當下仍存在的內容。

**Rejected**:

- iOS repeating timer：背景會被 suspend，且會反覆接觸敏感內容，不能達成可靠 background capture。
- background mode／notification：系統沒有為一般 App 提供 clipboard change background trigger。
- 把 iOS 塞進 macOS `ClipboardMonitor` 或新增 scene-active reader：除了 lifecycle semantics 不相容，
  也會讓 App 開啟本身觸發程式化 paste permission flow。

### Decision 2 — visible system PasteButton is the only cross-App read path

Apple 說明自 iOS 14 起，沒有可辨識使用者意圖的跨 App 程式化 pasteboard content access
可能顯示通知或授權提示。Apple 的
[`UIPasteControl`](https://developer.apple.com/documentation/uikit/uipastecontrol) 與 SwiftUI
`PasteButton` 代表使用者明確貼上意圖；目前 Xcode 26.5 SwiftUI SDK 提供
`PasteButton(supportedContentTypes:payloadAction:)` 及 Transferable overload。

**Decision**:

- 「複製後打開即可使用」定義為打開 App 後立即可見且只需點一次 system `PasteButton`。
- 不先做 programmatic attempt；不把 App-specific Paste from Other Apps 設定為基本功能前提。
- 空歷史只在空狀態顯示一個 Paste primary action；已有歷史時在 trailing toolbar 顯示 Paste，
  並把 New Clip 保持為 secondary action。
- 不讀取內容來決定是否顯示控制；狀態與說明不得包含 clipboard preview。

**Rejected**:

- launch／active 時自動讀取：開啟 App 不代表使用者同意取得其他 App 的 clipboard value，
  也可能觸發 modal permission prompt。
- 自製「貼上」按鈕直接呼叫 `UIPasteboard`：不具系統控制可辨識的使用者意圖保障。
- 把 system paste control 隱藏、透明化、覆蓋或程式模擬點擊：不符合其可見使用者意圖契約。

### Decision 3 — NSItemProvider-based async loader

`PasteButton` 的 type-erased overload回傳 `[NSItemProvider]`；explicit paste 可直接在 provider
層轉換成現有 `ClipboardPayload`，不需要再讀取 `UIPasteboard.general`。

**Decision**:

- supported types 包含 Xcode SDK 可解碼的 image UTTypes 與 `.plainText`/`.text`。
- 依現有 macOS 規則先尋找圖片候選，再讀文字；有效圖片保存原始 data 與 UTType。
- 若 provider 宣告 image candidate 但資料損壞，回報 unsupported/failed，不把同一 clipboard item
  的文字 metadata 誤當主要內容。
- loader 使用 async continuation 包裝 provider callback，request ownership/cancellation 檢查發生在
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

- iOS root 使用 `NavigationStack` 與 large navigation title；只保留一個 `.searchable`。
- 空歷史以 Paste 為唯一明顯 primary action並提供secondary New Clip；已有歷史時 Paste 位於
  trailing toolbar，普通 `+` 為 secondary，filter/settings等低頻命令進入原生 menu或destination。
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

### Explicit request ownership

每次 system `PasteButton` callback 建立 content-free request ID。較新的明確貼上可以取消尚未提交
的舊 loader；callback 晚到時必須驗證 request ownership，且不得寫入 SwiftData 或覆蓋較新的 UI
回饋。不保存 `changeCount`、scene registry 或 allow/deny checkpoint，因產品不執行 lifecycle read。

### Capture outcome mapping

現有 `ClipboardCaptureService.CaptureOutcome` 是 persistence authority。iOS 顯示狀態只映射成
content-free cases：captured、duplicate、empty、unsupported、cancelled、
failed。`.captured(String)` 的 associated value 可能是實際文字，因此不可直接保存或輸出；
coordinator 只轉成 `.captured`。

### Multi-scene and stale work

App-owned process-wide coordinator只序列化 system PasteButton callbacks，不註冊scene、不在active
建立opportunity。每個import持有request ID；在payload load後與capture前再次確認owner與
cancellation。scene lifecycle本身不得啟動clipboard work，晚到callback不得寫入。

## Accessibility and Visual QA Decisions

- 最窄支援 iPhone 直向／橫向與最大 accessibility text size 都不得形成水平 scroll canvas。
- 每個 icon-only toolbar/list action以 44 x 44pt frame/contentShape 提供 hit target，並有本地化
  label/hint；pin state 使用 accessibility value/trait，不只靠顏色。
- row content 不以整列與 copy button 同時綁定相同 action；避免 VoiceOver 重複與 accidental copy。
- system paste control 與 App-specific Paste from Other Apps 設定的呈現由 iOS 擁有，只做
  simulator／device manual matrix；產品 UI automation 不嘗試偽造系統授權。
- empty history、empty search、empty filter 分開，分別提供 Paste/New、Clear Search、Reset Filter。

## Validation Research

- 純 coordinator 狀態以 fake providers/decoder + fake capture sink 驗證，不依賴 simulator permission。
- provider parsing 對 text、PNG/JPEG、invalid image candidate、unsupported、cancellation 建立 unit tests。
- Debug UI-test fixture 必須由完整 `-ui-testing` environment gate，Release 不可啟用；測試訊號不得
  包含剪貼簿內容。
- 真實 user workflow 仍需 booted simulator／device：從另一 App Copy、terminate/launch、確認未點
  Paste 前沒有 programmatic permission alert或新資料，再實際點擊可見 `PasteButton`、觀察一筆
  歷史與 screenshot。不同 iOS／語系的 system-control行為列為人工矩陣，不能把 fixture pass
  冒充 system UI evidence。
- 這次觸及 app launch、navigation、clipboard capture 與 shared persistence path，因此完成時
  必須執行 repository-authoritative `Scripts/verify.sh`。

## Resolved Clarifications

- **Auto vs explicit paste**: iOS 不做 lifecycle read；只接受可見 system `PasteButton` 的明確貼上。
- **Background behavior**: 不監測、不承諾；返回後只能由使用者明確取得當下最後一筆。
- **Supported content**: 既有純文字與可解碼點陣圖片，不擴大 ClipItem schema。
- **Design language**: 保留 theme/tokens/card/badge/illustration；navigation grammar 改原生。
- **iPad**: 同一 responsive single-column native container 保持可用，本功能不新增 sidebar architecture。
- **Other platforms**: macOS polling/settings/UI 不變；visionOS 不套 iOS 專屬 UIKit 或 navigation 分支。

沒有剩餘 `NEEDS CLARIFICATION`。
