# NextPaste 開發 Tasks

> GitHub Copilot 執行規則：
>
> - 每次只能執行一個 Task。
> - 完成指定 Task、執行測試並回報後，必須停止。
> - 不得自動開始下一個 Task。
> - 每個 Task 開始前，必須先讀取 repository 內的 Apple／macOS 開發 Skills。
> - 若找不到 Skills、Skills 內容互相衝突，或與本規格衝突，必須停止並回報。
> - 不得使用 `sleep`、人工延遲、陣列 index mutation、private API 或未經允許的第三方套件。
> - 不得將失敗測試直接標記為 pre-existing flaky。
> - `[ ]` 代表尚未實作；完成並通過驗收後才可改為 `[x]`。

---

## 固定技術決策

- [ ] 不新增第三方快捷鍵套件。
- [ ] 沿用或重構現有原生全域熱鍵實作。
- [ ] `Command-F` 作為 App 內搜尋快捷鍵。
- [ ] `Command-F` 不得註冊為全域快捷鍵。
- [ ] `Command-,` 打開 Settings。
- [ ] 釘選項目不計入歷史上限。
- [ ] 歷史上限只限制未釘選項目。
- [ ] 降低歷史上限時，先顯示預計刪除數量，確認後立即裁剪。
- [ ] 取消降低上限時，保留舊設定及全部資料。
- [ ] 清除歷史不可復原。
- [ ] 清除歷史前必須顯示確認對話框。
- [ ] 外觀支援 System、Light、Dark。
- [ ] 預設外觀為 System。
- [ ] 不得清除 `NSPasteboard.general`。
- [ ] 一般設定不得儲存在 SwiftData schema。
- [ ] 所有資料異動使用穩定 identity 或 SwiftData model identity。
- [ ] 不進行與目前 Task 無關的大型重構。

---

## 執行狀態總覽

- [x] T000：讀取 Skills 與建立現況報告
- [x] T001：建立修改前 baseline
- [x] T002：建立單一搜尋 Focus Action
- [x] T003：加入 Command-F 搜尋命令
- [x] T004：加入非鍵盤搜尋入口
- [x] T005：建立歷史統計 Query
- [x] T006：建立清除未釘選資料層
- [x] T007：加入清除未釘選確認 UI
- [x] T008：建立清除全部資料層
- [x] T009：加入清除全部確認 UI
- [x] T010：確認並標準化 Settings Scene
- [x] T011：加入 Command-comma
- [x] T012：抽象化現有全域熱鍵註冊器
- [x] T013：建立 Global Shortcut 型別與驗證
- [x] T014：加入全域快捷鍵 Recorder UI
- [x] T015：實作 Transactional Global Shortcut 更新
- [ ] T016：建立 History Limit typed preference
- [x] T017：加入 History Limit 設定 UI
- [x] T018：建立 History Retention Service
- [x] T019：新剪貼簿寫入後執行 Retention
- [x] T020：Unpin 後執行 Retention
- [x] T021：降低 History Limit 的確認流程
- [x] T022：建立 Appearance typed preference
- [x] T023：加入 Appearance Settings UI
- [x] T024：套用外觀至 SwiftUI 視圖
- [x] T025：套用外觀至特殊 AppKit Window
- [x] T026：新增與整理 Localization
- [x] T027：Search Accessibility UI Tests
- [x] T028：History Clear UI Tests
- [x] T029：Settings UI Tests
- [x] T030：完整 Regression 與穩定性驗證
- [x] T031：Manual Accessibility Verification 清單

---

# Phase 0：前置檢查與 Baseline

## [x] T000：讀取 Skills 與建立現況報告

### 執行限制

- [x] 只執行 inspection。
- [x] 不修改 production code。
- [x] 不修改 test code。
- [x] 完成後立即停止，不開始 T001。

### Apple Skills

- [x] 搜尋 `SKILL.md`。
- [x] 搜尋 `.github/skills/`。
- [x] 搜尋 `.github/copilot-instructions.md`。
- [x] 搜尋 `AGENTS.md`。
- [x] 搜尋 `instructions/`。
- [x] 搜尋與 Apple、macOS、Swift、SwiftUI、SwiftData、Accessibility、Testing 有關的文件。
- [x] 回報實際讀取的 Skill 路徑。
- [x] 回報本次會套用的規則。
- [x] 確認 Skills 是否與本規格衝突。
- [x] 找不到 Skills 時停止，不得繼續。

### Repository inspection

- [x] 檢查 Xcode project 與 scheme。
- [x] 檢查 minimum macOS deployment target。
- [x] 檢查 Swift language mode。
- [x] 檢查 strict concurrency 設定。
- [x] 檢查 App、Scene 與 Commands 架構。
- [x] 檢查 Settings Scene。
- [x] 檢查搜尋欄與 FocusState。
- [x] 檢查 `ClipItem` model。
- [x] 檢查 Pin、Unpin、Delete 實作。
- [x] 檢查 SwiftData repository／service。
- [x] 檢查現有全域熱鍵實作。
- [x] 檢查 UserDefaults、`@AppStorage` 或 typed settings 架構。
- [x] 檢查 localization 架構及支援語言。
- [x] 檢查 Unit test 與 UI test 架構。
- [x] 檢查 launch arguments 與測試 fixtures。
- [x] 列出每個後續 Task 預計修改的檔案。
- [x] 列出技術風險。
- [x] 確認 `git diff` 為空。

### 驗收

- [x] 現況報告完整。
- [x] Skills 使用情況已回報。
- [x] 沒有修改任何檔案。
- [x] 完成後停止。

---

## [x] T001：建立修改前 Baseline

### Build 與測試

- [x] 執行 NextPaste Debug build。
- [x] 執行 NextPaste Release build。
- [x] 執行全部 unit tests。
- [x] 執行全部 UI tests。
- [x] 記錄成功測試數。
- [x] 記錄失敗測試數。
- [x] 記錄每個失敗的完整錯誤。
- [x] 驗證失敗是否可重現。
- [x] 檢查是否存在 race condition。
- [x] 不修正功能。
- [x] 不忽略任何失敗。
- [x] 不將失敗直接歸類為 flaky。

### 驗收

- [x] Debug build 通過。
- [x] Release build 通過。
- [x] Unit tests baseline 已記錄。
- [x] UI tests baseline 已記錄。
- [x] 若有失敗，停止並回報。

---

# Phase 1：搜尋快捷鍵與 Accessibility

## [x] T002：建立單一搜尋 Focus Action

### 實作

- [x] 找出現有搜尋狀態。
- [x] 建立單一 `focusSearch()` 或符合現有命名的 action。
- [x] 不建立第二套搜尋 state。
- [x] 不建立第二個搜尋欄。
- [x] action 能顯示搜尋介面。
- [x] action 能聚焦現有搜尋欄。
- [x] action 保留既有搜尋文字。
- [ ] 若現有架構可安全支援，聚焦後選取現有搜尋文字。
- [x] 避免 SwiftUI focus loop。
- [x] 不使用 `NSEvent` monitor。
- [x] 不加入 menu command。

### 測試

- [x] action 會要求搜尋欄取得 focus。
- [x] 既有搜尋文字不會被清除。
- [x] 重複呼叫不會建立重複 state。
- [x] NextPaste target build 通過。

---

## [x] T003：加入 Command-F 搜尋命令

### 實作

- [x] 使用 SwiftUI `Commands`、`CommandGroup` 或現有 command architecture。
- [x] `Command-F` 呼叫 T002 的共用搜尋 action。
- [x] menu bar 提供標準 `Find…` 命令。
- [x] 優先放在 `Edit > Find`。
- [x] 不使用 `Command-S`。
- [x] 不將 `Command-F` 註冊為全域快捷鍵。
- [x] 不使用 raw keyboard event monitor。

### 測試

- [x] `Command-F` 執行共用搜尋 action。
- [x] 重複按 `Command-F` 不破壞搜尋狀態。
- [x] menu item 顯示正確快捷鍵。
- [x] NextPaste target build 通過。

---

## [x] T004：加入非鍵盤搜尋入口

### 實作

- [x] 提供可見的原生 Search Button。
- [x] Search Button 呼叫 T002 的同一個 action。
- [x] 不複製搜尋行為。
- [x] 唯一入口不依賴 hover。
- [x] 唯一入口不依賴 gesture。
- [x] 使用原生 `Button`。
- [x] 支援滑鼠。
- [x] 支援觸控板。
- [x] 為 Search Button 新增 accessibility identifier。
- [x] 為 Search Field 新增 accessibility identifier。
- [x] 為 Clear Search Button 新增 accessibility identifier。
- [x] 新增適當的 `accessibilityLabel`。
- [x] 新增適當的 `accessibilityHint`。
- [x] VoiceOver 可辨識 Search Button。
- [x] VoiceOver 可辨識 Search Field。
- [x] VoiceOver 可辨識 Clear Search Button。
- [x] VoiceOver 可辨識無搜尋結果狀態。
- [x] 若架構適合，VoiceOver 可讀取搜尋結果數量。

### 測試

- [x] 點擊 Search Button 會聚焦搜尋欄。
- [x] accessibility identifiers 存在。
- [x] 不使用鍵盤也能完成搜尋。
- [x] NextPaste target build 通過。

---

# Phase 2：清除歷史

## [x] T005：建立歷史統計 Query

### 實作

- [x] 建立 `countPinnedHistory()` 或現有架構對應 API。
- [x] 建立 `countUnpinnedHistory()` 或現有架構對應 API。
- [x] 建立 `countAllHistory()` 或現有架構對應 API。
- [x] 集中在 repository 或 service。
- [x] 不將 SwiftData fetch 邏輯放在 View。
- [x] 遵守 MainActor 與 ModelContext 邊界。
- [x] 查詢結果 deterministic。

### 測試

- [x] 空資料。
- [x] 全部 pinned。
- [x] 全部 unpinned。
- [x] pinned 與 unpinned 混合。
- [x] NextPaste target build 通過。

---

## [x] T006：建立清除未釘選資料層

### 實作

- [x] 建立 `clearUnpinnedHistory()`。
- [x] 刪除所有 `isPinned == false` 的 `ClipItem`。
- [x] 保留全部 pinned items。
- [x] 保留 pinned identity。
- [x] 保留 pinned order。
- [x] 不操作 `NSPasteboard.general`。
- [x] 不使用陣列 index。
- [x] 不在 mutation 中 enumerate 同一個 mutable collection。
- [x] 安全處理 selection 指向已刪除 item。
- [x] 搜尋結果由既有資料流自然更新。
- [x] 不加入 UI。
- [x] 不加入快捷鍵。

### 測試

- [x] pinned + unpinned 混合。
- [x] 執行後只剩 pinned。
- [x] pinned identity 不變。
- [x] pinned order 不變。
- [x] 空資料不 crash。
- [x] 全部 pinned 不會被刪除。
- [x] 全部 unpinned 全部刪除。
- [x] NextPaste target build 通過。

---

## [x] T007：加入清除未釘選確認 UI

### 實作

- [x] 提供非鍵盤入口。
- [x] 入口位於 History menu、toolbar menu 或 overflow menu。
- [x] 不將唯一入口放在 row context menu。
- [x] 顯示即將刪除的未釘選數量。
- [x] 顯示將保留的 pinned 數量。
- [x] 提供 Cancel。
- [x] 提供 destructive confirm button。
- [x] 沒有 unpinned item 時 action disabled 或顯示無資料狀態。
- [x] confirmation 僅呼叫 T006 service。
- [x] 不複製 SwiftData 刪除邏輯。
- [x] 操作不可復原。
- [x] 加入 `Option-Command-Delete`。

### 測試

- [x] confirmation 顯示正確數量。
- [x] Cancel 不刪除。
- [x] Confirm 只刪除 unpinned。
- [x] pinned 保留。
- [x] 非鍵盤入口可操作。
- [x] NextPaste target build 通過。

---

## [x] T008：建立清除全部資料層

### 實作

- [x] 建立 `clearAllHistory()`。
- [x] 刪除全部 `ClipItem`，包含 pinned。
- [x] 不清除 `NSPasteboard.general`。
- [x] 不使用 index mutation。
- [x] 安全處理 selection。
- [x] 不加入 UI。
- [x] 不加入快捷鍵。

### 測試

- [x] mixed data 執行後為空。
- [x] 全部 pinned 執行後為空。
- [x] 空資料不 crash。
- [x] NextPaste target build 通過。

---

## [x] T009：加入清除全部確認 UI

### 實作

- [x] 提供非鍵盤入口。
- [x] 顯示將刪除的總數。
- [x] 明確說明包含 pinned items。
- [x] 明確說明操作不可復原。
- [x] 使用較高強度 destructive wording。
- [x] Cancel 不執行。
- [x] Confirm 僅呼叫 T008 service。
- [x] 不複製刪除邏輯。
- [x] 加入 `Shift-Option-Command-Delete`。

### 測試

- [x] confirmation 顯示總數。
- [x] confirmation 明確提到 pinned。
- [x] Cancel 保留資料。
- [x] Confirm 清除全部。
- [x] 非鍵盤入口可操作。
- [x] NextPaste target build 通過。

---

# Phase 3：Settings 與全域快捷鍵

## [x] T010：確認並標準化 Settings Scene

### 實作

- [x] 使用現有 Settings Scene。
- [x] 若已存在，只修正必要問題。
- [x] 重複開啟不產生多個 Settings window。
- [x] 建立 General 分類。
- [x] 建立 Shortcuts 分類。
- [x] 建立 Appearance 分類。
- [x] 建立 Privacy 或 History 分類。
- [x] 不提前實作 global hotkey。
- [x] 不提前實作 history limit。
- [x] 不提前實作 appearance。

### 測試

- [x] Settings window 可開啟。
- [x] 重複開啟仍只有一個 Settings window。
- [x] 所有分類存在。
- [x] NextPaste target build 通過。

---

## [x] T011：加入 Command-comma

### 實作

- [x] `Command-,` 打開現有 Settings Scene。
- [x] App menu 顯示 `Settings…`。
- [x] 重複按 `Command-,` 聚焦既有 Settings window。
- [x] 不建立重複 Settings window。
- [x] 不重設目前設定頁面。
- [x] 不清除未提交輸入。

### 測試

- [x] `Command-,` 打開 Settings。
- [x] 重複執行不新增 window。
- [x] menu item 顯示正確 shortcut。
- [x] NextPaste target build 通過。

---

## [x] T012：抽象化現有全域熱鍵註冊器

### 實作

- [x] 沿用現有原生實作。
- [x] 不新增第三方 package。
- [x] 不改變目前預設 global shortcut。
- [x] 建立 `GlobalHotKeyRegistering` 或符合現有命名的 protocol。
- [x] production implementation 包裝現有實作。
- [x] 提供 fake registrar。
- [x] 支援 register。
- [x] 支援 unregister。
- [x] 支援 registration failure。
- [x] 支援 current registration lifecycle。
- [x] 不加入 recorder UI。
- [x] 不改變使用者設定。

### 測試

- [x] register。
- [x] unregister。
- [x] registration failure。
- [x] 不重複註冊。
- [x] lifecycle cleanup。
- [x] NextPaste target build 通過。

---

## [x] T013：建立 Global Shortcut 型別與驗證

### 實作

- [x] 建立可儲存 key 與 modifiers 的型別。
- [x] 支援序列化至現有 settings storage。
- [x] 至少包含一個 modifier。
- [x] 禁止單一字母。
- [x] 禁止單一數字。
- [x] 禁止單一 Space。
- [x] 禁止單一 Return。
- [x] 禁止單一 Delete。
- [x] 禁止純 Option。
- [x] 禁止 `Command-F`。
- [x] 禁止 `Command-,`。
- [x] 禁止與 NextPaste menu commands 衝突。
- [x] 提供可本地化 validation error。
- [x] 不加入 recorder UI。
- [x] 不改變目前 hotkey。

### 測試

- [x] 合法 shortcut。
- [x] 無 modifier。
- [x] 純 Option。
- [x] `Command-F`。
- [x] `Command-,`。
- [x] menu conflict。
- [x] encode/decode。
- [x] NextPaste target build 通過。

---

## [x] T014：加入全域快捷鍵 Recorder UI

### 實作

- [x] 放在 `Settings > Shortcuts`。
- [x] 顯示目前 global shortcut。
- [x] 可以錄製候選 shortcut。
- [x] 使用 T013 validation。
- [x] 提供 Record。
- [x] 提供 Clear。
- [x] 提供 Reset to Default。
- [x] Reset 使用 repository 現有 default。
- [x] 不自行發明新 default。
- [x] 新增 accessibility label。
- [x] 新增 accessibility hint。
- [x] VoiceOver 可讀取目前值。
- [x] VoiceOver 可讀取 validation error。
- [x] 此 Task 不改變實際註冊 shortcut。
- [x] recorder 只產生 candidate value。

### 測試

- [x] Recorder 顯示現有值。
- [x] 合法輸入。
- [x] 非法輸入顯示錯誤。
- [x] Clear 按鈕存在。
- [x] Reset 按鈕存在。
- [x] accessibility identifiers 存在。
- [x] NextPaste target build 通過。

---

## [x] T015：實作 Transactional Global Shortcut 更新

- Status: COMPLETE
- Summary: `docs/implementation/task-summaries/T015.md`
- Reconstruction note: Phase 3 verification confirmed the retained app-level `GlobalShortcutLifecycleController`, launch-time restore wiring, termination cleanup, shared Settings ownership, and targeted macOS unit validation.

### 更新流程

- [x] 驗證 candidate。
- [x] 嘗試註冊新 shortcut。
- [x] 新 shortcut 註冊成功後才持久化。
- [x] 持久化成功後解除舊 shortcut。
- [x] 註冊失敗時保留舊 shortcut。
- [x] 註冊失敗時不覆寫儲存設定。
- [x] 註冊失敗時顯示 inline error。
- [x] 註冊失敗後舊 shortcut 繼續運作。

### Clear

- [x] 解除目前 global shortcut。
- [x] 儲存 disabled 狀態。
- [x] menu、Dock 或現有 UI 仍可打開 NextPaste。

### Reset

- [x] transactionally 還原 repository 現有 default。

### 測試

- [x] 成功更新。
- [x] 衝突時保留舊 shortcut。
- [x] persistence failure 一致性。
- [x] clear。
- [x] reset。
- [x] app restart restore。
- [x] unregister lifecycle。
- [x] NextPaste target build 通過。

---

# Phase 4：歷史上限

## [x] T016：建立 History Limit Typed Preference

- Status: COMPLETE
- Summary: `docs/implementation/task-summaries/T016.md`

### 實作

- [x] 支援 Unlimited。
- [x] 支援 50。
- [x] 支援 100。
- [x] 支援 200。
- [x] 支援 500。
- [x] 支援 1000。
- [x] 支援 Custom。
- [x] Custom 範圍為 10 至 10,000。
- [x] Custom 只接受整數。
- [x] pinned 不計入上限。
- [x] 不儲存在 SwiftData model。
- [x] 使用現有 UserDefaults、`@AppStorage` 或 typed settings。

### Migration

- [x] 若已有既存上限，保留既有 default。
- [x] 若沒有既存上限，新安裝預設 500。
- [x] 若沒有既存上限，既有安裝升級預設 Unlimited。
- [x] 使用 migration marker。
- [x] 不修改 SwiftData schema。

### 測試

- [x] encode/decode。
- [x] Unlimited。
- [x] presets。
- [x] custom valid。
- [x] custom too low。
- [x] custom too high。
- [x] non-integer。
- [x] new install。
- [x] existing install upgrade。
- [x] NextPaste target build 通過。

---

## [x] T017：加入 History Limit 設定 UI

### 實作

- [x] 放在 General 或 History。
- [x] 支援 Unlimited。
- [x] 支援 presets。
- [x] 支援 Custom。
- [x] Custom 有 inline validation。
- [x] 無效值不能儲存為 0。
- [x] 此 Task 不刪除任何 `ClipItem`。
- [x] 降低上限時只建立 pending change。
- [x] 此 Task 不直接提交降低後的 limit。
- [x] 新增 accessibility identifiers。

### 測試

- [x] options 顯示。
- [x] Custom validation。
- [x] 無效輸入不改變既有設定。
- [x] accessibility identifiers 存在。
- [x] NextPaste target build 通過。

---

## [x] T018：建立 History Retention Service

### 實作

- [x] 只計算 unpinned。
- [x] pinned 永遠排除。
- [x] 超過上限時刪除最舊 unpinned。
- [x] Unlimited 不刪除。
- [x] 使用現有 canonical sort field。
- [x] 不自行猜測 timestamp。
- [x] 支援 protected item identity。
- [x] 剛 Unpin 的 item 可被保護。
- [x] service deterministic。
- [x] 不連接 ClipboardMonitor。
- [x] 不連接 Settings UI。

### 建議 API

- [x] `calculateItemsToRemove(...)`。
- [x] `enforceLimit(...)`。
- [x] `protectedItemID` 或等價設計。

### 測試

- [x] pinned 不計入。
- [x] Unlimited。
- [x] 超過上限。
- [x] deterministic ordering。
- [x] 相同 timestamp 的 tie-break。
- [x] protected item。
- [x] limit 等於目前數量。
- [x] limit 大於目前數量。
- [x] NextPaste target build 通過。

---

## [x] T019：新剪貼簿寫入後執行 Retention

### 實作

- [x] 新 `ClipItem` 成功儲存後才執行 retention。
- [x] 不在資料寫入前裁剪。
- [x] 不裁剪 pinned。
- [x] 不改變 clipboard capture semantics。
- [x] 不使用 delay。
- [x] 不造成 capture loop。
- [x] 不影響搜尋。
- [x] 不影響列表 identity。

### 測試

- [x] 新 item 未超限。
- [x] 新 item 導致超限。
- [x] pinned 不受影響。
- [x] Unlimited。
- [x] 寫入失敗時不執行 retention。
- [x] NextPaste target build 通過。

---

## [x] T020：Unpin 後執行 Retention

### 實作

- [x] item Unpin 成功後執行 retention。
- [x] 剛 Unpin 的 item 為 protected item。
- [x] 超出上限時優先刪除其他最舊 unpinned。
- [x] 不立即刪除剛 Unpin 的 item。
- [x] 不改變目前 Pin／Unpin 排序規則。
- [x] 不使用 index。
- [x] 不使用 sleep。
- [x] 不重現 stale row。
- [x] 不重現 swipe overlay 問題。

### 測試

- [x] Unpin 未超限。
- [x] Unpin 導致超限。
- [x] 剛 Unpin item 保留。
- [x] 其他最舊 item 被刪除。
- [x] 沒有其他可刪 item 時有明確行為。
- [x] 快速連續 Pin／Unpin。
- [x] NextPaste target build 通過。

---

## [x] T021：降低 History Limit 的確認流程

### 實作

- [x] 使用 T018 計算預計刪除數量。
- [x] confirmation 顯示新 limit。
- [x] confirmation 顯示預計刪除的 unpinned 數量。
- [x] confirmation 說明 pinned 不受影響。
- [x] Confirm 儲存新設定。
- [x] Confirm 立即執行 retention。
- [x] Cancel 保留舊設定。
- [x] Cancel 不刪除資料。
- [x] 增加上限不需要 destructive confirmation。
- [x] 切換 Unlimited 不需要 destructive confirmation。
- [x] 不複製 retention 邏輯。

### 測試

- [x] 降低且需刪除。
- [x] 降低但不需刪除。
- [x] Cancel。
- [x] Confirm。
- [x] 增加 limit。
- [x] Unlimited。
- [x] pinned 保留。
- [x] NextPaste target build 通過。

---

# Phase 5：外觀

## [x] T022：建立 Appearance Typed Preference

### 實作

- [x] 建立 `system`。
- [x] 建立 `light`。
- [x] 建立 `dark`。
- [x] 預設為 `system`。
- [x] 使用現有 settings storage。
- [x] 此 Task 不套用到 UI。
- [x] 不修改 `NSApp.appearance`。

### 測試

- [x] default。
- [x] encode/decode。
- [x] system mapping。
- [x] light mapping。
- [x] dark mapping。
- [x] NextPaste target build 通過。

---

## [x] T023：加入 Appearance Settings UI

### 實作

- [x] 放在 `Settings > Appearance`。
- [x] 顯示 System。
- [x] 顯示 Light。
- [x] 顯示 Dark。
- [x] 顯示本地化名稱。
- [x] 使用原生 Picker 或 Apple Skill 建議控制項。
- [x] 新增 accessibility identifiers。
- [x] 選擇後更新 T022 preference。
- [x] 此 Task 不處理特殊 AppKit window bridge。

### 測試

- [x] 三個選項存在。
- [x] preference 更新。
- [x] 重新開啟 Settings 後保留。
- [x] NextPaste target build 通過。

---

## [x] T024：套用外觀至 SwiftUI 視圖

### 作用範圍

- [x] 主視窗。
- [x] Search UI。
- [x] Settings。
- [x] confirmation dialogs。

### 實作

- [x] 優先使用 environment 或 `preferredColorScheme`。
- [x] System 跟隨 macOS。
- [x] 不修改 macOS 系統外觀。
- [x] 不影響其他 process。
- [x] 不使用 hard-coded light-only color。
- [x] 使用 semantic colors。
- [x] 即時切換，不需重啟。
- [x] 保持 Increase Contrast 正常。
- [x] 保持 Reduce Transparency 正常。
- [x] 保持 Reduce Motion 正常。
- [x] 保持 Accent Color 正常。

### 測試

- [x] System mapping 為標準跟隨系統行為。
- [x] Light。
- [x] Dark。
- [x] 切換後即時更新。
- [x] NextPaste target build 通過。

---

## [x] T025：套用外觀至特殊 AppKit Window

### 適用條件

- [x] 確認 repository 是否存在 floating panel。
- [x] 確認是否存在 menu bar popover。
- [x] 確認是否存在自訂 `NSWindow`。
- [x] 確認是否存在 AppKit bridge window。

### 若存在特殊視窗

- [ ] 建立單一 appearance coordinator。 <!-- N/A: no special windows -->
- [ ] 不在多處直接設定 appearance。 <!-- N/A -->
- [ ] System 能恢復跟隨系統。 <!-- N/A -->
- [ ] 不影響其他 app。 <!-- N/A -->
- [ ] 不破壞 window lifecycle。 <!-- N/A -->
- [ ] 新增必要測試。 <!-- N/A -->

### 若不存在特殊視窗

- [x] 回報 Not Applicable。
- [x] 不建立無用 coordinator。
- [x] 不修改程式碼。

---

# Phase 6：Localization

## [x] T026：新增與整理 Localization

### 字串

- [x] `Find…`
- [x] `Search Clipboard History`
- [x] `Clear Search`
- [x] `Clear Unpinned History`
- [x] `Clear All History`
- [x] `Items to Be Deleted`
- [x] `Pinned Items Will Be Preserved`
- [x] `This Includes Pinned Items`
- [x] `This Action Cannot Be Undone`
- [x] `Global Shortcut`
- [x] `Record Shortcut`
- [x] `Clear Shortcut`
- [x] `Reset to Default`
- [x] `Shortcut Is Already in Use`
- [x] `History Limit`
- [x] `Unlimited`
- [x] `Custom`
- [x] `Follow System`
- [x] `Light`
- [x] `Dark`
- [x] `General`
- [x] `Shortcuts`
- [x] `Appearance`
- [x] `Privacy`
- [x] `History`
- [x] 所有 validation messages。
- [x] 所有 confirmation messages。

### 實作要求

- [x] 補齊 repository 目前支援的全部語言。
- [x] 不 hard-code 中文。
- [x] 不 hard-code 英文。
- [x] 不重複建立不同 key 表示相同文字。
- [x] 遵循現有 String Catalog 或 `Localizable.strings` 架構。

### 測試

- [x] localization key 完整性。
- [x] 缺少翻譯檢查。
- [x] Build 無 localization warning。
- [x] NextPaste target build 通過。

---

# Phase 7：UI Tests

## [x] T027：Search Accessibility UI Tests

### 測試

- [x] `Command-F` 聚焦搜尋欄。
- [x] `Command-F` 後輸入文字進入搜尋欄。
- [x] 點擊 Search Button 聚焦搜尋欄。
- [x] Search Button identifier。
- [x] Search Field identifier。
- [x] Clear Search identifier。
- [x] 不使用鍵盤也能完成搜尋。

### 限制

- [ ] 不修改 production behavior。
- [x] 若測試發現 production bug，停止並回報。
- [ ] 不在此 Task 順便修正 bug。

註：T027 初次驗證已先依限制停止並回報；後續 product fix 是在使用者明確要求繼續完成 active thread goal 後補做。

---

## [x] T028：History Clear UI Tests

### 測試

- [x] 建立 pinned + unpinned fixture。
- [x] 開啟 Clear Unpinned confirmation。
- [x] 確認刪除數量正確。
- [x] 測試 Cancel。
- [x] 測試 Confirm。
- [x] 確認 pinned 保留。
- [x] 開啟 Clear All confirmation。
- [x] 確認包含 pinned 警告。
- [x] Clear All 後列表為空。
- [x] 非鍵盤入口存在。

### 限制

- [x] 不修改 production behavior。
- [x] 若測試發現 production bug，停止並回報。

註：T028 失敗原因為 macOS `confirmationDialog` 在 UI automation 中將 title/message 暴露為通用 `StaticText`，不是 production bug；最終僅調整 UI test selector，未修改 product code。

---

## [x] T029：Settings UI Tests

### 測試

- [x] `Command-,`。
- [x] 單一 Settings window。
- [x] General section。
- [x] Shortcuts section。
- [x] Appearance section。
- [x] History 或 Privacy section。
- [x] Global Shortcut Recorder。
- [x] Clear。
- [x] Reset。
- [x] History Limit。
- [x] Custom validation。
- [x] System。
- [x] Light。
- [x] Dark。
- [x] 設定持久化。

### 限制

- [ ] 不修改 production behavior。
- [ ] 若測試發現 production bug，停止並回報。

---

# Phase 8：Regression 與人工驗證

## [x] T030：完整 Regression 與穩定性驗證

- Status: COMPLETE

### Build 與測試

- [x] Debug build。
- [x] Release build。
- [x] 全部 unit tests。
- [x] 全部 UI tests。
- [x] 重複執行 UI tests。
- [x] 確認沒有 flakiness。
- [x] 檢查 Swift concurrency warnings。
- [x] 檢查 MainActor。
- [x] 檢查 memory leak。
- [x] 檢查重複 observer。
- [x] 檢查 global hotkey registration lifecycle。
- [x] 檢查 SwiftData mutation safety。

### Regression 範圍

- [x] Clipboard capture。
- [x] Search。
- [x] Pin。
- [x] Unpin。
- [x] 單筆 delete。
- [x] Clear unpinned。
- [x] Clear all。
- [x] History limit。
- [x] Global hotkey。
- [x] `Command-F`。
- [x] `Command-,`。
- [x] Settings。
- [x] Light。
- [x] Dark。
- [x] Localization。

### 失敗處理

- [x] 重現失敗。
- [x] 找出 root cause。
- [x] 回報應回到哪一個 Task 修正。
- [x] 不在 T030 修改 production code。
- [x] 有失敗時不得宣告 COMPLETE。

---

## [x] T031：Manual Accessibility Verification 清單

- Status: COMPLETE

### Automated coverage

- [x] Search result accessibility marker (`search-result-count`) reports matching and empty states — verified by `SearchAccessibilityUITests/testSearchResultAccessibilityMarkerReflectsMatchingAndEmptyStates` (passed 2026-07-06).
- [x] Search Button, Search Field, and Clear Search identifiers are asserted by existing `SearchAccessibilityUITests` cases.

### Manual verification required

The following items require human interaction with VoiceOver, Voice Control, Switch Control, mouse/trackpad-only operation, or system Accessibility settings. They cannot be automated in this environment without triggering system authorization prompts.

- MANUAL VERIFICATION REQUIRED — TOUCH ID / Accessibility authorization: VoiceOver, Voice Control, Switch Control, Increase Contrast, Reduce Transparency, Reduce Motion, Light/Dark/System Mode live toggling, and mouse-only operation must be verified by a human on a configured device.

### VoiceOver

- [ ] VoiceOver 找得到 Search Button。
- [ ] VoiceOver 找得到 Search Field。
- [ ] VoiceOver 可讀取搜尋結果狀態。
- [ ] VoiceOver 可讀取清除確認數量。
- [ ] VoiceOver 可操作 global shortcut recorder。
- [ ] VoiceOver 可操作 Clear。
- [ ] VoiceOver 可操作 Reset。

### 無鍵盤操作

- [ ] 只使用滑鼠可搜尋。
- [ ] 只使用滑鼠可清除未釘選歷史。
- [ ] 只使用滑鼠可清除全部歷史。
- [ ] 只使用滑鼠可打開 Settings。
- [ ] 只使用滑鼠可修改 History Limit。
- [ ] 只使用滑鼠可切換 Appearance。
- [ ] 全域熱鍵不是打開 NextPaste 的唯一方式。

### 系統 Accessibility 設定

- [ ] Increase Contrast。
- [ ] Reduce Transparency。
- [ ] Reduce Motion。
- [ ] Light Mode。
- [ ] Dark Mode。
- [ ] System Mode。
- [ ] Voice Control。
- [ ] Switch Control 有可操作入口。

### 回報

- [x] 無法自動驗證的項目標記 `MANUAL VERIFICATION REQUIRED`。
- [ ] 不得假裝完成人工驗證。

---

# Definition of Done

- [ ] `Command-F` 能聚焦現有搜尋欄。
- [ ] 搜尋有滑鼠、觸控板及 accessibility 替代入口。
- [ ] `Option-Command-Delete` 清除未釘選歷史。
- [ ] `Shift-Option-Command-Delete` 清除全部歷史。
- [ ] 一般清除不會刪除 pinned items。
- [ ] History limit 不會刪除 pinned items。
- [ ] 全域熱鍵可錄製。
- [ ] 全域熱鍵可清除。
- [ ] 全域熱鍵可重設。
- [ ] 全域熱鍵可持久化。
- [ ] `Command-F` 不可設為 global hotkey。
- [ ] `Command-,` 不可設為 global hotkey。
- [ ] History limit 支援 Unlimited。
- [ ] History limit 支援 presets。
- [ ] History limit 支援 Custom。
- [ ] 降低上限會先確認再裁剪。
- [ ] System／Light／Dark 即時生效。
- [ ] 外觀設定持久化。
- [ ] `Command-,` 穩定開啟單一 Settings window。
- [ ] 所有新增字串完成 localization。
- [ ] 全部 unit tests 通過。
- [ ] 全部 UI tests 通過。
- [ ] Debug build 通過。
- [ ] Release build 通過。
- [ ] 未新增第三方 dependency。
- [ ] 未使用 sleep 或 timing workaround。
- [ ] 未使用 index mutation。
- [ ] 未清除 `NSPasteboard.general`。
- [ ] 未破壞既有搜尋。
- [ ] 未破壞 Pin。
- [ ] 未破壞 Unpin。
- [ ] 未破壞單筆刪除。
- [ ] 未破壞 clipboard capture。

---

# Copilot 每次執行的固定回報格式

```text
TASK:
STATUS: COMPLETE / BLOCKED / FAILED

SKILLS USED:
- Skill 路徑與套用規則

FILES CHANGED:
- 檔案與修改目的

IMPLEMENTATION:
- 實際完成內容

TESTS ADDED OR UPDATED:
- 測試名稱

COMMANDS EXECUTED:
- 完整 command

RESULTS:
- Build 結果
- Unit test 結果
- UI test 結果

MANUAL VERIFICATION:
- 尚需人工驗證的內容

KNOWN LIMITATIONS:
- 沒有則寫 None

NEXT TASK:
- 只列出建議的下一個 Task ID
- 不得執行它
```

---
