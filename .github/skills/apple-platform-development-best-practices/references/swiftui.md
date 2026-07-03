# SwiftUI — Apple Platform Development Reference

This reference covers SwiftUI patterns for native Apple platform (macOS / iOS / visionOS) development in the NextPaste repository. It is a companion to the skill's other references: see [platform-specific](platform-specific.md), [concurrency](concurrency.md), and [testing-validation](testing-validation.md). Rules are classified as **MUST** (correctness/safety), **SHOULD** (recommended practice), or **PROJECT** (repository conventions). Precedence: task requirements > mandatory correctness/safety > repo conventions > recommended practice. Repo conventions must NOT justify unsafe or invalid code.

---

## Authoritative sources

Prefer official sources first; treat community sources as recommendations to be evaluated against the official guidance.

- Official (authoritative):
  - [SwiftUI tutorials — Apple Developer](https://developer.apple.com/tutorials/swiftui)
  - [SwiftUI — Apple Developer Docs](https://developer.apple.com/documentation/swiftui)
  - [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines)
  - [WWDC sessions](https://developer.apple.com/videos/)
  - [Sample code — Apple Developer](https://developer.apple.com/sample-code/)
- Community (recommended, non-authoritative):
  - [Swift Forums — Using Swift](https://forums.swift.org/c/using-swift)
  - [Point-Free](https://www.pointfree.co/) and other community blogs for pattern discussion only.

When a community recipe conflicts with the official guidance or HIG, the official guidance wins.

---

## State ownership matrix

Choose the smallest, most local state owner that fits. State that can be derived should be derived, not stored. State that crosses view boundaries should be passed through bindings or environment, not duplicated.

| State kind | Primary owner / mechanism | Project usage |
| --- | --- | --- |
| Local transient (view-local UI only) | `@State` in the view that owns it | Transient selection, present sheet flags, in-progress text not yet committed |
| View-owned observable | `@StateObject` for `ObservableObject` types created by the view; project default is to keep views thin and rely on `@Query`/`@Environment` instead | Not heavily used; do not introduce `@StateObject` to migrate `@Query`/`@Environment` patterns |
| Parent-owned via bindings | `@Binding` from the parent; parent owns `@State`/source of truth | Narrow bindings into child row/editor views |
| Shared app-scoped dependency | `@Environment` with a custom `EnvironmentKey` | `@Environment(\.appTheme)`, `@Environment(\.appMotion)` (see `DesignSystem/Theme/ThemeEnvironment.swift`) |
| Persisted domain model | SwiftData `@Model` + `@Query` for reads, `@Environment(\.modelContext)` for writes | `@Model ClipItem`; `@Query(sort: ClipItem.historySortDescriptors)` in `HomeView` |
| Navigation / presentation state | `@State` in the route-owning view, or `NavigationStack` path binding | macOS uses direct content presentation; iOS uses `NavigationStack` |
| Platform service | Owned by a lifecycle controller / service, started/stopped from the scene via `.task` | `ClipboardMonitorLifecycleController.shared` started from `ClipboardMonitorHostView.task` |

### `@State` and `@Binding`

- **MUST** Use `@State` only for value-typed, view-local UI state. Do not use `@State` to hold reference types or to mirror data that has another owner — that creates a sync hazard.
- **MUST** Keep bindings narrow. Bind the single property that needs mutation, not the entire model. `TextField("Title", text: $clip.title)` is correct; passing `$clip` and mutating arbitrary fields from a leaf is not.
- **SHOULD** Prefer derived state over stored state: compute `isEmpty`, `canSubmit`, etc. from the source of truth in `body` rather than caching them and keeping them in sync.
- **PROJECT** The repo keeps cross-platform navigation in `NavigationViewWrapper` with `#if os(macOS)` / `#else NavigationStack`. Do not push platform-specific navigation into leaf views.

### `@StateObject` / `ObservableObject`

- **MUST** When a view creates an `ObservableObject` reference type itself, store it in `@StateObject` so SwiftUI keeps the same instance across re-renders. Never recreate it in `body` (it would reset on every evaluation).
- **MUST** Only use `@StateObject` for objects the view *owns and creates*. For objects injected from outside, pass them through the environment or as parameters and observe with `@ObservedObject` / `@EnvironmentObject`.
- **PROJECT** NextPaste does NOT heavily use `ObservableObject`/`@StateObject`. It relies on `@Query`, `@Environment`, custom `EnvironmentKey`s, and a shared lifecycle controller. Do not introduce `@StateObject` purely to migrate those patterns.

### `Observation` and `@Observable`

- **MUST** Do not mix observation systems on the same type: pick one mechanism per type and keep it consistent.
- **MUST** Do not mandate migration from `ObservableObject` to `@Observable` (or the reverse) for style. Migrate only when a task requires it (e.g. a new type that benefits from per-property tracking, or a documented performance problem).
- **SHOULD** When adopting `@Observable`, prefer it for new reference types that are observed across many views and benefit from fine-grained dependency tracking. Keep `ObservableObject` where `@Published` semantics are already sufficient and the type is stable.
- **PROJECT** The repo runs in Swift 5 mode with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. New observable types that touch UI must remain `@MainActor`-isolated. Do not change the global actor isolation setting as a side effect of a SwiftUI change.

### Environment dependencies

- **MUST** Inject cross-cutting dependencies through `@Environment` with explicit `EnvironmentKey`s and documented default values. Avoid `@EnvironmentObject` when a typed `EnvironmentKey` with a default is clearer and safer (missing `@EnvironmentObject` crashes at runtime; a defaulted key degrades gracefully).
- **SHOULD** Keep environment values `Equatable` where practical so SwiftUI can skip re-renders when the value is unchanged (`AppMotion` is `Equatable`).
- **PROJECT** Follow the existing pattern in `DesignSystem/Theme/ThemeEnvironment.swift`: define a private `*Key` conforming to `EnvironmentKey`, then an `EnvironmentValues` computed property. `appTheme` and `appMotion` are injected from `ContentView` via `.environment(\.appTheme, …)` and `.environment(\.appMotion, …)`.
- **PROJECT** `@Environment(\.modelContext)` is the single write path into SwiftData. Reads use `@Query`. Do not bypass this by constructing a `ModelContainer` inside a view body.

---

## View and list identity

- **MUST** Give every `ForEach` / `List` item stable, unique identity. Use `id:` with a stable identifier (e.g. the `PersistentIdentifier`/domain `id`), not the array index. SwiftUI relies on identity to diff, animate, and preserve selection/state.
- **MUST** Never use a mutable collection index (`ForEach(array.indices, id: \.self)`) as identity when the collection can reorder, insert, or delete. That breaks diffing and can attach state to the wrong element.
- **SHOULD** Conform model types to `Identifiable` once they have a stable `id`, and omit the explicit `id:` argument. For SwiftData `@Model` types, the persistent identifier is the stable identity.
- **PROJECT** `ClipItem` is the persisted domain model; rows render from a `@Query` result that is already sorted (`historySortDescriptors`, pinned-first newest-first). Use the clip's stable identity for row identity, not the position in the sorted array.

### Body purity

- **MUST** Treat `body` as a *description* of the current UI, not a place to perform work. Do not mutate external state, write to persistence, kick off network I/O, or log analytics directly from `body` evaluation.
- **MUST** Do not construct expensive or persistent dependencies during `body` evaluation (e.g. do not create a `ModelContainer`, open a file, or build a heavy service in `body`). Construct once and inject.
- **SHOULD** Keep `body` cheap: derive computed values, compose subviews, apply modifiers. Move any non-trivial computation into a cached helper, a model, or a service invoked from `task`.
- **PROJECT** `ContentView` derives `appTheme` and `appearance` from `@Environment(\.colorScheme)` in computed properties and injects them into the environment. This is the expected pattern — derive, don't store-and-sync.

---

## Async work: `task` and `task(id:)`

- **MUST** Use `task` (or `task(id:)`) to start async work tied to a view's lifetime. SwiftUI cancels the task when the view disappears, so prefer `task` over manual `Task {}` launched from `onAppear`.
- **MUST** Understand that `task(id:)` cancels the previous task and starts a new one whenever `id` changes. Use `id:` when the work depends on a value that can change (e.g. a selected clip id or a search query) so stale work is cancelled and replaced.
- **SHOULD** Make async work cooperative and cancellable. Check `Task.isCancelled` / use structured concurrency so cancellation propagates. Long, uncancellable loops defeat the `task` lifecycle.
- **PROJECT** `ClipboardMonitorHostView` starts `ClipboardMonitorLifecycleController.shared.startIfNeeded(using: modelContext)` from `.task` and stops it on macOS termination via `.onReceive(NSApplication.willTerminateNotification)`. Lifecycle start/stop belongs at the scene host, not in leaf views.
- **PROJECT** UI tests run with `-ui-testing` so `NextPasteApp.makeModelContainer` returns an in-memory `ModelContainer`. Do not introduce real-disk persistence assumptions in test-only paths.

---

## Navigation and presentation state

- **MUST** Make navigation and presentation state explicit and, where the experience requires restoration, restorable. Use `NavigationStack(path:)` with a value-typed path (or `Hashable` route enums) on iOS so back/forward and deep links are deterministic.
- **MUST** Keep navigation decisions in the route-owning view (or a small navigation model). Do not let a leaf row decide navigation routes for the whole flow.
- **SHOULD** Model routes as a `Hashable` enum and bind `NavigationStack` to `[Route]`. This makes the path inspectable, testable, and easy to deep-link.
- **PROJECT** `ContentView` keeps platform navigation behind `#if os(macOS)` / `#else NavigationStack` inside `NavigationViewWrapper`. Preserve this single-source pattern; do not split navigation per platform into multiple files unless a task explicitly requires it.
- **PROJECT** Presentation state for sheets/alerts should live in `@State` on the presenting view. Keep sheet content as a self-contained child view that takes bindings/parameters; do not reach up into the presenter from the presented content.

### Presentation state

- **MUST** Drive sheets, alerts, popovers, and inspectors from explicit `@State`/bindings (`isPresented` or `item:`). Do not trigger presentation as a side effect of data mutation.
- **SHOULD** Prefer `item:`-based presentation when the sheet's content depends on a selected model item; it keeps the binding tied to identity and clears itself when the item becomes `nil`.
- **PROJECT** Row action presentation (pin/delete/copy) should reuse `RowActionControlGroup` and `SharedRowPresentation` from `DesignSystem/Components` rather than building ad-hoc presentation per row.

---

## Lifecycle

- **MUST** Use `task`/`onAppear`/`onDisappear` for view-scoped lifecycle. Use scene-level APIs (`WindowGroup`, `.commands`, `scenePhase`) for app-scoped lifecycle.
- **MUST** Observe `scenePhase` (`.active`, `.inactive`, `.background`) when behavior must respond to foreground/background transitions. Do not assume `onAppear`/`onDisappear` map 1:1 to scene state.
- **PROJECT** `ClipboardMonitorHostView` is the lifecycle host: `.task` starts the monitor and (macOS) `.onReceive(NSApplication.willTerminateNotification)` stops it. New scene-scoped services should hook into this host or a peer, not into individual content views.
- **PROJECT** `NextPasteApp` constructs `sharedModelContainer` once in `init` and injects it via `.modelContainer(sharedModelContainer)` on the scene. Do not recreate the container per view.

---

## Keyboard, focus, and menus

- **MUST** On macOS, ensure keyboard navigation works: focusable controls, tab order, `keyboardShortcut`, `focused(_:)`/`@FocusState`, and `.commands` for menu bar items. A macOS app that is mouse-only is incomplete.
- **MUST** Manage focus with `@FocusState` rather than relying on side effects. Bind focus to a stable enum/value so focus is restorable and testable.
- **SHOULD** Provide discoverable shortcuts via `.keyboardShortcut` and `.commands`. Keep shortcuts consistent with system conventions (⌘N new, ⌘W close, ⌘F find, etc.).
- **PROJECT** macOS is a first-class target (`platform=macOS`, `.defaultSize(640, 480)`, `WindowGroup("NextPaste")`). Support multiple windows and menu commands where the feature calls for it.
- **PROJECT** iOS targets must support Dynamic Type, VoiceOver, rotation, size classes, safe areas, and touch. Do not hard-code sizes that break Dynamic Type or safe-area layout.

---

## Accessibility

- **MUST** Provide meaningful accessibility labels and hints for interactive elements and informative controls. Use `.accessibilityLabel`, `.accessibilityHint`, and `accessibilityValue` so VoiceOver describes state, not just type.
- **MUST** Group related controls with `accessibilityElement(children: .combine/.contain)` so VoiceOver reads them as one logical element where appropriate.
- **MUST** Respect accessibility preferences. The repo already honors `accessibilityReduceMotion` via `AppMotion` — new animations must consult `@Environment(\.appMotion)` (or `accessibilityReduceMotion` directly) and disable/reduce motion accordingly.
- **SHOULD** Test with VoiceOver on macOS and iOS; verify focus order, rotor behavior, and that actions are reachable from the keyboard.
- **PROJECT** `ContentView` reads `@Environment(\.accessibilityReduceMotion)` and constructs `AppMotion(reduceMotion:)`. Use `appMotion.animation(_:)`/`appMotion.duration(_:)` for any timing so reduced-motion is honored automatically.

---

## Dynamic Type

- **MUST** Use semantic font APIs (`Font.body`, `.headline`, `.title`, `.system(size:weight:)` with `relativeTo:`) so text scales with Dynamic Type. Do not hard-code fixed pixel sizes that ignore the user's text-size setting.
- **MUST** Lay out with `VStack`/`HStack`/`Grid`/`Layout` and let text wrap. Do not clip or truncate solely to preserve a fixed frame.
- **SHOULD** Verify layouts at the largest accessibility text sizes on iOS; use `.dynamicTypeSize(...)` ranges to test boundaries.
- **PROJECT** Design tokens live in `DesignSystem/Theme/DesignTokens.swift`. Keep type styles routed through the token system so Dynamic Type scaling is consistent across components.

---

## UIKit / AppKit representables and coordinators

- **MUST** Keep `UIViewRepresentable` / `NSViewRepresentable` / `UIViewControllerRepresentable` adapters narrow: wrap one platform view, expose only the configuration the SwiftUI layer needs, and avoid leaking `UIKit`/`AppKit` types into shared domain modules.
- **MUST** Put delegate/data-source logic in a dedicated `Coordinator` so it is testable independently of the representable. The coordinator should forward callbacks into SwiftUI via closures or a small observable, not by mutating the view struct.
- **MUST** Ensure mutations to model/UI state from a representable occur on the correct actor. On macOS/iOS, UI work belongs on `@MainActor`; cross that boundary deliberately, not accidentally.
- **SHOULD** Prefer native SwiftUI equivalents over representables when they exist. Introduce a representable only when a platform capability is not available in SwiftUI.
- **SHOULD** Make `updateUIView`/`updateNSView` cheap and idempotent. It runs on many state changes; do not recreate subviews or reload heavy data there.
- **PROJECT** The repo's shared logic (clipboard capture, validation, persistence) is platform-agnostic Swift, not UIKit/AppKit. Keep representables isolated to the view layer; do not let them leak into `ClipItem`, `ClipboardCaptureService`, or `ClipboardWriter`.

---

## Performance

- **MUST** Avoid expensive work in `body`: no per-frame sorting, filtering of large collections, image decoding, or persistence fetches during rendering.
- **MUST** Avoid repeated persistence fetches during rendering. `@Query` is the read path; let SwiftUI re-render when the store changes rather than polling from `body`.
- **MUST** Avoid loading entire histories when pagination or incremental loading fits. Use `FetchDescriptor` limits / fetch limits and load more on demand.
- **SHOULD** Prefer stable identity for diffing so SwiftUI can skip unchanged rows. Unstable identity forces full re-renders and loses row-local `@State`.
- **SHOULD** Avoid unnecessary `AnyView` / type erasure. Erasure defeats SwiftUI's diffing optimizations; use opaque return types (`some View`) and concrete types instead. Reach for `AnyView` only when a heterogeneous return is unavoidable.
- **SHOULD** Extract views by responsibility, reuse, state boundary, or performance — not by an arbitrary line count. Splitting a 300-line view into six 50-line views that share no boundary adds overhead without benefit.
- **PROJECT** History is sorted pinned-first newest-first via `historySortDescriptors`. If pagination is added, preserve the pinned-first ordering invariant and keep it defined in `ClipItem.historySortDescriptors`, not duplicated at call sites.

---

## Cross-links

- Platform-specific APIs, menus, focus, windows, and HIG behavior: [platform-specific](platform-specific.md)
- Structured concurrency, actors, `@MainActor`, task cancellation: [concurrency](concurrency.md)
- Swift Testing, UI testing with `-ui-testing`, targeted vs. full regression: [testing-validation](testing-validation.md)

---

## Quick checklist

- **MUST** Views describe UI; business workflows live in models/services/domain use cases.
- **MUST** No persistent dependency construction in `body`.
- **MUST** No uncontrolled side effects during `body` evaluation.
- **MUST** Stable identity in lists; no mutable-index identity.
- **MUST** Narrow bindings; don't expose an entire model as a binding.
- **MUST** Handle loading/empty/success/error/retry states explicitly.
- **MUST** Preserve user edits during async refresh; prevent duplicate work from repeated appearance.
- **MUST** Use `task`/`task(id:)` intentionally; understand cancellation behavior.
- **MUST** Avoid unnecessary `AnyView` / type erasure.
- **MUST** Extract views by responsibility/reuse/state boundary/performance — not line count.
- **MUST** Make navigation/presentation state explicit and restorable where required.
- **MUST** macOS: keyboard, menus, commands, focus, multiple windows.
- **MUST** iOS: Dynamic Type, VoiceOver, rotation, size classes, safe areas, touch.
- **PROJECT** Keep cross-platform UI differences behind `#if os(...)` in one source file.
- **PROJECT** Keep observation as `@Query`/`@Environment`/custom `EnvironmentKey`; do not migrate `ObservableObject` ↔ `@Observable` for style.
- **PROJECT** Route writes through `@Environment(\.modelContext)`; reads through `@Query`.