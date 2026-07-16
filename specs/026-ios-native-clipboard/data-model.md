# Data Model: iOS 原生體驗與前景剪貼簿匯入

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
2. 同一份文字或 image duplicate identity 不得因多次 active、PasteButton 或 multi-scene 重複保存。
3. iOS acquisition 不得更改排序、retention、pinning 或 image file ownership。

## ForegroundClipboardOpportunity (transient)

表示一次 iOS scene active 邊界，不是 database entity。

| Field | Type | Privacy | Rule |
| --- | --- | --- | --- |
| generation | monotonically increasing integer | non-sensitive | 每次 active/background transition 更新；舊 generation 不得 commit |
| observedChangeCount | `Int` | content-free | 從 `UIPasteboard.changeCount` 取得；process-local opaque equality token |
| source | enum (`automaticForeground`, `explicitPaste`) | content-free | 明確區分權限語意與 UI feedback |
| startedAt | monotonic clock/Date (test-injected) | content-free | 僅用於效能量測，不持久化 |
| state | enum | content-free | idle/loading/capturing/completed/cancelled |

### State transitions

```text
idle
  └─ scene active + new opportunity → loading(generation, changeCount)
       ├─ provider payload available → capturing
       │    ├─ service captured/ignored → completed(result)
       │    └─ service failed → completed(failed)
       ├─ no supported payload/permission unavailable → completed(result)
       └─ all scenes background/removed or newer generation → cancelled

explicit PasteButton providers
  └─ loading(generation, no required changeCount)
       └─ same payload → capture/result transitions
```

### Invariants

1. 同一 generation 最多執行一次 persistence commit。
2. 只有目前foreground generation可以從loading進入capturing；system prompt造成的短暫inactive
   仍屬foreground，不單獨取消。
3. cancellation 後晚到 provider callback 只能丟棄。
4. opportunity/result 不持有可顯示的 clipboard content；payload 只活在 loader → capture 呼叫範圍。

## IOSClipboardImportResult (transient, content-free)

| Case | Meaning | UI behavior |
| --- | --- | --- |
| `captured` | 有效 payload 已保存 | 顯示短暫成功 feedback；`@Query` 自動刷新 |
| `duplicate` | 既有完全相同內容 | 不新增列；可顯示 neutral feedback |
| `empty` | 空／空白 text | 不保存；提供 Paste/New 路徑 |
| `unsupported` | 無支援 type 或 invalid image candidate | 不保存；顯示不含內容的說明 |
| `unavailable` | provider/permission/representation 無法取得 | 不保存；保持 PasteButton 可用 |
| `cancelled` | scene/generation 已過期 | 不顯示錯誤，不保存 |
| `failed` | decode/persistence unexpected failure | 不保存或 rollback；顯示 generic retry feedback |

`ClipboardCaptureService.CaptureOutcome.captured(String)` 的 associated value 不可進入 result、
log、UserDefaults、accessibility probe 或 analytics。

## IOSPasteboardSnapshot (ephemeral)

| Field | Type | Notes |
| --- | --- | --- |
| changeCount | `Int` | 可先讀取，不代表內容可用 |
| itemProviders | `[NSItemProvider]` or injected provider abstraction | 只在 active import operation 內存在 |

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

## SceneActivityRegistry and IOSClipboardCheckpoint (transient)

| Field | Type | Persistence | Rule |
| --- | --- | --- | --- |
| scenes | `[UUID: SceneActivity]` | memory only | 彙總每個scene的active/inactive/background狀態 |
| activeSceneIDs | `Set<UUID>` | memory only | 空→非空時建立一次app-wide opportunity |
| foregroundSceneIDs | `Set<UUID>` | memory only | active + inactive；清空時generation失效 |
| lastHandledChangeCount | optional `Int` | memory only | 只在目前process抑制已完成token的重複讀取 |
| inFlightChangeCount | optional `Int` | memory only | 相同token不得建立第二個automatic request |

Checkpoint只減少同一process的重複prompt/work，不是dedup authority。它不得寫入磁碟，因change
count不保證跨process／裝置重置穩定；cold launch由`ClipboardCaptureService`精確內容去重保證正確。

## IOSNavigationState (view-owned)

| Field | Type | Owner | Persistence |
| --- | --- | --- | --- |
| searchText | `String` | HomeView | transient；不記錄到 diagnostics |
| filter | existing filter enum | HomeView | 沿用現有行為 |
| presentedSheet | `newClip` / `settings` / nil | HomeView | transient |
| importFeedback | optional content-free result | HomeView/coordinator | transient，短暫顯示 |

Navigation state 不複製 history；live history 仍只由 `@Query` 讀取。

## Existing Preferences Reused

- `AppLanguagePreference`
- `AppearancePreference`
- `HistoryLimitPreference`

iOS `Form` 直接操作這些 owner。清除未釘選／全部歷史沿用既有 service/context mutation，
不建立 iOS-only preference store 或 duplicate history state。
