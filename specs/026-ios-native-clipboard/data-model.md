# Data Model: iOS 原生體驗與明確貼上

**Feature**: 026-ios-native-clipboard
**Date**: 2026-07-17

本功能不新增 SwiftData entity，也不變更 `ClipItem` schema。以下型別是 transient lifecycle／
UI state，或不含敏感內容的本機 preference。

## Existing Persisted Entity: ClipItem

`ClipItem` 繼續是唯一歷史資料來源。

| Field group | Existing meaning | Feature behavior |
| --- | --- | --- |
| `id`, timestamps, pin state | identity、排序、釘選 | 不變；iOS List 改用 `id` 作穩定 identity |
| text content/type | accepted text clip | 由既有 `ClipboardCaptureService` 驗證、去重、保存 |
| image hash/dimensions/type/file names | local image clip metadata | 由既有 image pipeline 保存；不內嵌新 clipboard representation |

### Invariants

1. 只有 `ClipboardCaptureService`／既有 model-context write paths 建立新 item。
2. 同一份文字或 image duplicate identity 不得因連續點擊Paste或重疊請求重複保存。
3. iOS acquisition 不得更改排序、retention、pinning 或 image file ownership。

## ExplicitPasteRequest (transient)

表示一次使用者實際點擊system `PasteButton`後的處理請求，不是database entity。

| Field | Type | Privacy | Rule |
| --- | --- | --- | --- |
| requestID | monotonically increasing integer | non-sensitive | 每次PasteButton callback更新；舊request不得commit |
| source | enum (`explicitPaste`) | content-free | 固定表示system control使用者意圖 |
| startedAt | monotonic clock/Date (test-injected) | content-free | 僅用於效能量測，不持久化 |
| state | enum | content-free | idle/loading/capturing/completed/cancelled |

### State transitions

```text
idle
  └─ system PasteButton callback → loading(requestID, providers)
       ├─ provider payload available → capturing
       │    ├─ service captured/ignored → completed(result)
       │    └─ service failed → completed(failed)
       ├─ no supported payload → completed(result)
       └─ cancellation or newer explicit request → cancelled
```

### Invariants

1. 同一request最多執行一次persistence commit。
2. 只有目前request owner可以從loading進入capturing；較新明確請求會取代舊owner。單純的
   inactive／background transition不撤銷已由使用者明確啟動的request。
3. cancellation後晚到provider callback只能丟棄。
4. request/result不持有可顯示的clipboard content；payload只活在loader → capture呼叫範圍。

## IOSClipboardImportResult (transient, content-free)

| Case | Meaning | UI behavior |
| --- | --- | --- |
| `captured` | 有效 payload 已保存 | 顯示短暫成功 feedback；`@Query` 自動刷新 |
| `duplicate` | 既有完全相同內容 | 不新增列；可顯示 neutral feedback |
| `empty` | 空／空白 text | 不保存；提供 Paste/New 路徑 |
| `unsupported` | 無支援 type 或 invalid image candidate | 不保存；顯示不含內容的說明 |
| `cancelled` | request取消或被較新明確貼上取代 | 不顯示錯誤，不保存 |
| `failed` | decode/persistence unexpected failure | 不保存或 rollback；顯示 generic retry feedback |

`ClipboardCaptureService.CaptureOutcome.captured(String)` 的 associated value 不可進入 result、
log、UserDefaults、accessibility probe 或 analytics。

## PasteButtonProviderSnapshot (ephemeral)

| Field | Type | Notes |
| --- | --- | --- |
| itemProviders | `[NSItemProvider]` or injected provider abstraction | 只來自system PasteButton callback，且只在explicit import operation內存在 |

### Payload selection

```text
providers
  ├─ any declared image candidate
  │    ├─ first decodable supported image → ClipboardPayload.image
  │    └─ all declared candidates invalid → unsupported/failed (no text fallback)
  └─ no image candidate
       ├─ first valid plain text → ClipboardPayload.text
       └─ otherwise → unsupported/empty
```

## ExplicitPasteRequestOwner (transient)

| Field | Type | Persistence | Rule |
| --- | --- | --- | --- |
| currentRequestID | optional integer | memory only | 只有目前owner可在decode後進入capture |
| inFlightTask | optional cancellable task | memory only | 較新明確貼上取消舊task；晚到callback不得commit |

request owner只提供非同步新鮮度，不是內容dedup authority。它不得寫入磁碟，也不保存
`UIPasteboard.changeCount`、scene狀態、source App或provider metadata；精確內容去重仍由
`ClipboardCaptureService`保證。

## IOSNavigationState (view-owned)

| Field | Type | Owner | Persistence |
| --- | --- | --- | --- |
| searchText | `String` | HomeView | transient；不記錄到 diagnostics |
| filter | existing filter enum | HomeView | 沿用現有行為 |
| presentedSheet | `newClip` / nil | HomeView | transient |
| settingsDestination | Bool / navigation path entry | HomeView | transient |
| importFeedback | optional content-free result | HomeView/coordinator | transient，明確貼上後短暫顯示 |

Navigation state 不複製 history；live history 仍只由 `@Query` 讀取。

## Existing Preferences Reused

- `AppLanguagePreference`
- `AppearancePreference`
- `HistoryLimitPreference`

iOS `Form` 直接操作這些 owner。清除未釘選／全部歷史沿用既有 service/context mutation，
不建立 iOS-only preference store 或 duplicate history state。
