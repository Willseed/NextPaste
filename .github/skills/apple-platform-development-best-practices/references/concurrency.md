# Swift Concurrency Reference

> Scope: structured concurrency, actors, `Sendable`, cancellation, continuations, bridging,
> executors, memory, and the anti-patterns that cause data races, deadlocks, and retain cycles on
> native Apple platforms (macOS, iOS, visionOS). This is a reference for the
> `apple-platform-development-best-practices` Copilot Agent Skill.

This file is a **reference**, not a tutorial. Rules are classified `MUST` (data-race safety /
correctness), `SHOULD` (recommended practice), and `PROJECT` (NextPaste repository conventions).
Precedence: task requirements > mandatory correctness/safety > repo conventions > recommended
practice. **Repo conventions must never justify unsafe code.** When a `PROJECT` rule conflicts with
a `MUST` rule, the `MUST` rule wins.

Cross-references to other skill references use relative links, e.g.
[SwiftUI](swiftui.md) and [testing-validation](testing-validation.md). Do not duplicate their
content here.

---

## Authoritative sources

Official (normative):

- The Swift Programming Language -> Concurrency:
  <https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/>
- Swift Evolution proposals directly governing this reference:
  - [SE-0306 `async`/`await`](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-async-await.md)
  - [SE-0314 `async let`](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0314-async-let.md)
  - [SE-0317 `TaskGroup`/`ThrowingTaskGroup`](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0317-async-let.md)
  - [SE-0306 `Task`/`Task.detached`](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-async-await.md)
  - [SE-0316 Actors](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0316-global-actors.md)
  - [SE-0302 `Sendable`](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0302-sendable.md)
  - [SE-0414 Region-based isolation](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md)
  - [SE-0431 `@isolated(any)` / protocol isolation](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0431-isolated-any.md)
- Apple Developer Documentation -> Concurrency:
  <https://developer.apple.com/documentation/swift/swift-concurrency>
- WWDC sessions: "Meet async/await," "Eliminate data races with Swift Concurrency," "Discover
  Swift concurrency in SwiftUI," "Demystify task groups." (Search at
  <https://developer.apple.com/videos/>.)

Community (recommendation, not normative):

- "Swift Concurrency: The Future of Async, Await, and Tasks" (Vadim Bulavin) — concrete pitfalls.
- Point-Free episodes on structured concurrency and red/blue function coloring.

Always prefer official semantics when community guidance disagrees.

---

## Repository concurrency facts (PROJECT)

Bake the following into every review/plan in this repository. They are not optional context.

- **Swift language mode is 5.0** (`SWIFT_VERSION = 5.0`). This is **not** Swift 6. Do not assume Swift
  6 strict concurrency, region-based isolation (SE-0414), or full data-race safety at compile
  time. Concurrency bugs that Swift 6 would reject may still compile here.
- **`SWIFT_STRICT_CONCURRENCY` is not explicitly set**, so it defaults to `"minimal"` in Swift 5
  mode. Concurrency-related warnings are diagnostics only. **Do NOT weaken** the setting (e.g., set
  it to `"minimal"` explicitly or turn off upcoming features) to silence warnings, and **do NOT
  claim** strict concurrency is enforced project-wide.
- **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`**. **This is critical:** in this project, an
  unannotated `class`/`struct`/`enum`/`actor`/global function is **MainActor-isolated by default**,
  not `nonisolated`. Reason about isolation explicitly. Do not assume a type is `nonisolated`
  merely because it lacks an annotation. When you need `nonisolated`, write the keyword.
  - Exception: `@Test`/`@Suite` test entry points and `@main` types follow their own rules; verify
    rather than assume.
  - Because of this default, **the compiler will not warn you that UI code is on the wrong actor** —
    most app code is *already* on MainActor. The real risk is the opposite: a "background" service
    accidentally running on MainActor and blocking the UI. Audit accordingly.
- **Upcoming feature**: `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`. Module-internal
  imports are not transitively visible; review `@testable import` and cross-module `Sendable`
  conformances carefully.
- **Existing pattern**: `ClipboardMonitor`, `ClipboardCaptureService` are explicitly `@MainActor`.
  `ClipboardMonitorLifecycleController.shared` is a `@MainActor` singleton. UI mutations are on
  MainActor. `ClipboardMonitor` polls a `ClipboardMonitorScheduler` abstraction at 0.5 s and stores
  a `ClipboardMonitorTask` handle with `cancel()`. `start()`/`stop()` guard `isMonitoring`.
  **Preserve this cancellation/lifecycle pattern** when extending monitor-style services.
- `ClipboardPayload` is `Sendable`. `ClipboardPasteboardReader` is a struct of closures
  (**not** `Sendable` by default; used on MainActor — do not cross actor boundaries with it
  without `@Sendable` closures or a copy strategy).
- Deployment targets: macOS 26.5, iOS 26.5, visionOS supported. Prefer shared business logic and
  `#if os(macOS)` / `#if os(iOS)` / `#if os(visionOS)` guards for platform-specific behavior.

---

## Actors, isolation, and `MainActor`

### `MainActor` and the project default (MUST + PROJECT)

- **MUST** Keep all UI state and UI mutations on `MainActor`. This includes `@State`/`@Binding`
  mutation, `ObservableObject` `@Published` updates, `NSPasteboard`/`UIPasteboard` writes,
  `NSWindow`/`UIWindow`/`UIScene` mutations, and SwiftUI view-body side effects.
- **MUST** Because `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, an **unannotated** type in this
  repository is MainActor-isolated. Verify isolation explicitly — read the declaration, do not
  infer `nonisolated` from the absence of an annotation. When you genuinely need `nonisolated`,
  write `nonisolated` on the declaration and on each crossing member.
- **MUST** Do **not** put an entire service on `MainActor` solely to suppress compiler warnings.
  If a service has no UI coupling, prefer a custom `actor` (or `nonisolated` value type) and hop to
  MainActor only for the UI update. Putting long-running work on MainActor blocks the cooperative
  executor's main thread and degrades scroll/input/timer responsiveness.
- **SHOULD** When a `@MainActor` service owns a long-running task, move the heavy work off
  MainActor (`Task.detached` or a custom `actor`) and `await MainActor.run { … }` only to publish
  results. See [SwiftUI](swiftui.md) for view-side integration.
- **MUST** `MainActor.assumeIsolated` is a correctness assertion, not a migration crutch. Use it
  only when you have *proven* you are on the main thread (e.g., inside a known-main-thread delegate
  callback) and the compiler cannot see it. If the proof is wrong, it traps in production.

### Custom actors (MUST + SHOULD)

- **MUST** Define an explicit **owner** for every piece of shared mutable state. The owner is the
  `actor` (or `@MainActor` type) whose serialized access protects that state. If you cannot name
  the owner in one sentence, the state is racy.
- **SHOULD** Prefer one `actor` per cohesive responsibility rather than one global `actor`. A
  single "everything" actor reintroduces a giant lock and serializes unrelated work.
- **MUST** Do not access `actor`-isolated state from outside the actor without going through an
  `async` function or a `nonisolated` computed accessor that does not touch mutable state.
- **SHOULD** Prefer immutable value types crossing actor boundaries over `@unchecked Sendable`
  reference types. If a type is a `struct` of `let` `Sendable` fields, it is `Sendable` for free.

### Actor reentrancy (MUST)

- **MUST** Treat every `await` as a suspension point at which the actor may run other work. After
  the `await` resumes, **revalidate all assumptions**: the actor's state, the task's cancellation
  status, and any captured indices/iterators may have changed.
- **MUST** Never hold a lock (including `NSLock`, `os_unfair_lock`, `DispatchSemaphore`,
  `pthread_mutex`, `Swift Distributed Locks`) across an `await`. Reentrancy + held lock = deadlock
  or data corruption. If you need a lock, restructure so the critical section contains no
  suspension.
- **SHOULD** Make `actor` methods that perform state changes after an `await` idempotent where
  practical: re-check the precondition (e.g., `guard isMonitoring else { return }`) right before
  mutating, not only before the `await`. The existing `ClipboardMonitor.start()`/`stop()` guard on
  `isMonitoring` is the canonical pattern — re-check the guard after any `await` inside these
  methods.

---

## `Sendable`, `@Sendable`, and `@unchecked Sendable`

### `Sendable` (MUST)

- **MUST** Conform to `Sendable` only when crossing an actor/executor boundary is actually safe.
  Value types of `Sendable` fields are the easy case. Reference types require a synchronization
  strategy.
- **MUST** `final class` conforming to `Sendable` is only safe if all mutable state is protected
  by a single lock and all reads/writes go through that lock — or the class is immutable after
  construction.
- **MUST** Closures that cross actor boundaries must be `@Sendable`. A non-`@Sendable` closure
  captured into a `Task` is a compile-time error in Swift 6 and a data-race risk in Swift 5.

### `@unchecked Sendable` (MUST)

- **MUST** `@unchecked Sendable` is an *assertion*, not a convenience. Using it without a
  synchronization strategy is a data race waiting to happen. Before adding it, require all three:
  1. **Documented synchronization strategy** in a comment at the conformance site — which lock,
     which queue, which actor, or why the type is effectively immutable.
  2. **Safety proof** — a short argument for each mutable field: who writes it, under what lock,
     and why readers cannot observe a torn state.
  3. **Regression tests where practical** — at minimum a test that exercises concurrent access
     (e.g., multiple `Task`s writing/reading) and asserts no crash/race under Thread Sanitizer.
     See [testing-validation](testing-validation.md) for TSan setup.
- **MUST** Do not use `@unchecked Sendable` to silence a Sendable warning on a type you do not
  understand. Fix the type or scope its use to a single actor.
- **PROJECT** `ClipboardPayload` is `Sendable` — extend it with value semantics, do not regress
  it to a reference type. `ClipboardPasteboardReader` is intentionally **not** `Sendable`
  (closures); keep it on MainActor. Do not add `@unchecked Sendable` to it to cross actors.

### SwiftData `ModelContext` is not `Sendable` (MUST + PROJECT)

- **MUST** `ModelContext` is **not `Sendable`** and is bound to the actor/queue that owns its
  `ModelContainer`. Never capture a `ModelContext` into a `Task.detached`/background closure or
  call its mutators from a non-MainActor executor. To write from off-main work, hop to the owning
  actor (the repo uses `@MainActor`) and perform the insert/save there, or use a dedicated
  `ModelActor`-style pattern — do not share one context across actors.
- **PROJECT** `ClipboardCaptureService`/`ClipboardMonitor` are `@MainActor` and receive
  `modelContext` on MainActor. Preserve this: route SwiftData writes through the MainActor-owned
  context with `insert` + `save` + `rollback` on failure, as the repo already does. Keep blocking
  persistence work off MainActor by doing CPU/file work before the hop, not by moving the context.

### `@Sendable` closures (MUST)

- **MUST** `@Sendable` closures may not capture mutable `var` from the enclosing scope; they can
  only capture `let` and `Sendable` values. If you need to accumulate results, return them or use
  an `actor`.
- **SHOULD** Keep `@Sendable` closures small and pure; they run on an unknown executor, so avoid
  capturing `self` of a `@MainActor` type without hopping back to MainActor for UI work.

---

## Structured concurrency: `async let`, task groups, `Task`, `Task.detached`

### Prefer structured over unstructured (SHOULD)

- **SHOULD** Prefer `async let` for a fixed, statically known number of child tasks, and
  `withTaskGroup`/`withThrowingTaskGroup` for a dynamic number. Both preserve the parent-child
  relationship: cancellation propagates downward, errors propagate upward, and the parent
  `await`s all children before returning.
- **SHOULD** Use `async let` when the child's result is needed locally and its lifetime is bounded
  by the enclosing scope. Bind it to a variable and `await` it (or let it cancel on scope exit).
- **SHOULD** In task groups, accumulate results via `group.addTask { … }` then
  `for await result in group { … }`; do not block waiting for a specific child. Use
  `group.next()` only when order does not matter.

### `Task` vs `Task.detached` (MUST)

- **MUST** Do **not** use `Task { … }` merely to silence an "`await` in a sync context" compiler
  error. That detaches the work from its caller's lifecycle, drops structured error propagation,
  and hides the work from cancellation. Either make the enclosing function `async`, or use an
  `async let` / task group, or consciously use `Task` with a documented reason and a stored
  handle.
- **MUST** Avoid `Task.detached` unless **intentionally** discarding actor context, priority,
  task-local values, and cancellation inheritance. Document the reason at the call site.
  `Task.detached` is correct when you need a fresh non-MainActor executor for CPU-heavy work that
  must not inherit the caller's isolation — but in this project (MainActor default), a plain
  `Task` from a `nonisolated` context is usually what you want.
- **MUST** When you launch an unstructured `Task` whose lifetime the caller controls, **store the
  task handle** so you can `cancel()` it on teardown. The repository pattern
  (`ClipboardMonitorTask` with `cancel()`, guarded by `isMonitoring` in `start()`/`stop()`) is
  the canonical example — follow it for monitor/poller/observer services.

### Cancellation and ownership (MUST + SHOULD)

- **MUST** Preserve cancellation through call chains. Long loops, parsing, indexing, import,
  persistence, and batch operations MUST check `Task.isCancelled` or
  `try Task.checkCancellation()` at meaningful boundaries (per item or per chunk — not per byte).
  Check early and often; checking is cheap.
- **MUST** Distinguish `CancellationError` from operational failure. A cancellation is the caller
  retracting interest, not a bug. Do **not** convert `CancellationError` into a user-visible error
  unless product behavior explicitly requires it (e.g., a paste that the user aborted should be
  silent, not a "Failed" toast).
- **SHOULD** Make cancellation cooperative and prompt: cancel, then `await` the task so it can run
  its cleanup path. Fire-and-forget cancellation leaves the task to discover cancellation late.
- **SHOULD** When a service owns a task, the service's `stop()`/`deinit` path is responsible for
  cancelling it. Make ownership explicit in a comment: "Owner: `ClipboardMonitor` — cancels in
  `stop()`."

### Priority and task-locals (SHOULD)

- **SHOULD** Pass an explicit priority to `Task`/`Task.detached` only when you have a reason;
  otherwise inherit. Lowering priority for background indexing/import is fine; raising it for
  user-initiated work is fine. Do not starve the UI by launching many `.userInitiated` tasks.
- **SHOULD** Task-local values are inherited by children of `async let` and task groups but **not**
  by `Task.detached`. If you rely on task-locals (e.g., a request-id), prefer structured
  concurrency.

---

## Continuations and bridging callback APIs

### Checked vs unsafe continuations (MUST)

- **MUST** Use `withCheckedContinuation` / `withCheckedThrowingContinuation` by default. The
  checked continuation traps in debug if resumed zero or multiple times — exactly the bug class
  you want caught early.
- **MUST** Guarantee **exactly one resume** on every path, including cancellation and early
  returns. Structure the bridging closure so that every branch either resumes or delegates to a
  single resume site. A common pattern:

  ```swift
  await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
      delegate.doSomething { result in
          switch result {
          case .success:    cont.resume()
          case let .failure(e): cont.resume(throwing: e)
          }
      }
  }
  ```

  If `doSomething` can call back **zero** times (e.g., delegate deallocated) you must still resume
  — install a timeout or a cancellation handler that resumes with `CancellationError`.

- **MUST** Use `withUnsafeContinuation` / `withUnsafeThrowingContinuation` **only** when you have
  measured the checked-continuation overhead and it is a proven bottleneck, **and** you have a
  test that exercises the single-resume invariant. Document both at the call site. The checked
  variant is the default for a reason.
- **MUST** Handle **callback duplication**: if the bridged API may invoke its completion handler
  more than once, guard with a flag or `os_unfair_lock`-protected boolean so only the first call
  resumes the continuation. Subsequent calls must be no-ops.
- **MUST** Handle **callback absence**: if the API may never call back (delegate released, network
  reset), pair the continuation with `withTaskCancellationHandler` or a `Task` timeout that resumes
  with `CancellationError`. A continuation that never resumes leaks the task forever.

### Bridging delegate/callback APIs (MUST + SHOULD)

- **SHOULD** When wrapping a delegate-based API (`NSPasteboard` KVO, `URLSessionDelegate`,
  `NSFilePresenter`, `NSUserActivity`), keep the delegate object alive for the duration of the
  awaited operation (store it on the bridging type or in the continuation's closure capture), then
  resume once and release.
- **MUST** Do not bridge an API whose callback can arrive on any thread to an `actor` method that
  mutates `@MainActor` state without an explicit hop. Resume the continuation off-main, then
  `await MainActor.run { … }` for the UI mutation.
- **MUST** Bridging a synchronous callback that may be reentrant (e.g., a timer/pasteboard poll
  that can fire while a previous handler is still awaiting) requires the same reentrancy
  discipline as actor methods: revalidate after each `await`.

---

## Executors: don't block the cooperative pool

- **MUST** Do not block cooperative executor threads. The cooperative thread pool has a small
  number of workers (typically one per core). Blocking one starves the whole system. Specifically
  forbidden on a cooperative thread (including MainActor):
  - `Thread.sleep` / `usleep` synchronous sleeps — use `try await Task.sleep(for:)` / `Task.sleep(nanoseconds:)`.
  - `DispatchSemaphore.wait()` / `NSLock.lock()` across an `await` — see actor reentrancy.
  - Large synchronous file I/O (`FileManager` enumerations of huge trees, `Data(contentsOf:)` of
    large files) — use `FileHandle` async APIs, `URLSession`, or `Task.detached` + chunking.
  - Expensive CPU (indexing, hashing gigabytes) on MainActor — move to a custom `actor` or
    `Task.detached` with `.background` priority.
- **MUST** On MainActor specifically, never do anything that can take more than a few
  milliseconds synchronously: no sync network, no sync disk, no heavy parsing, no
  `DispatchQueue.sync` to a serial queue that might be busy. The UI will stall.
- **SHOULD** Use `Task.yield()` in long synchronous loops on MainActor to let the cooperative
  scheduler drain pending work — but prefer moving the loop off MainActor entirely.

---

## Memory: retain cycles, lifecycles, `AsyncSequence`

### Retain cycles (MUST)

- **MUST** Prevent retain cycles in long-lived tasks, delegates, observers, timers, AsyncSequences,
  and callback closures. A `Task` that captures `self` strongly, owned by `self`, is a cycle:
  `self -> stored Task -> closure -> self`. Use `[weak self]` (or `[weak self] weakSelf in`) in the
  closure, or hold the task on a different owner than the captured object.
- **MUST** `NotificationCenter` / `DistributedNotificationCenter` observers,
  `URLSessionTask` delegates, `NSFilePresenter`, `Timer`, ` Combine` `sink` cancellables,
  `AsyncSequence` iteration tasks: **make termination/cancellation ownership explicit**. Document
  "Owner: X cancels/releases in Y." If the owner is `deinit`'d, the observer is leaked; if it is
  not cancelled, the closure may resume on a dead object.
- **MUST** `@Sendable` closures stored long-term are a common cycle source: they capture `self`
  strongly and outlive the caller. Use `[weak self]` and bail (`guard let self else { return }`)
  when the owner is gone.
- **SHOULD** For single-shot bridging continuations, prefer to resume-and-release: the closure
  captures the continuation by value, and once resumed the closure is freed. Do not store the
  completion handler on `self` if `self` also stores the task.

### `AsyncSequence` lifecycle (MUST + SHOULD)

- **MUST** `AsyncSequence` / `AsyncStream` iteration is a long-lived task. Whoever starts the
  `for await` owns cancelling it. If the owner is a SwiftUI view, cancel in `.onDisappear` /
  `task` body — the `task` modifier handles this automatically; a manual `Task` does not.
- **MUST** `AsyncStream` must have a single consumer or be explicitly documented as
  multi-consumer. The stream's `onTerminate` must cancel its underlying source (timer, delegate,
  pipe). A stream whose source outlives the consumer is a leak.
- **MUST** When bridging a callback API into an `AsyncStream`, the `onTerminate` handler is where
  you stop the source (invalidate the timer, remove the observer, cancel the URLSessionTask). If
  you omit `onTerminate`, the source keeps firing into a buffer nobody reads.
- **SHOULD** Use `AsyncStream.makeStream(of:)` to get a `(stream, continuation)` pair and store the
  continuation so you can call `contination.finish()` from your teardown path.

### Lifecycle ownership checklist (SHOULD)

For each long-lived task in a feature, be able to answer:

1. Who creates it? (Which `start()`?)
2. Who stores its handle? (Which property?)
3. Who cancels it? (Which `stop()`/`deinit`?)
4. What cleanup runs on cancel? (Does the task `await` its own teardown?)
5. Is the captured `self` weak where it must be?

---

## Anti-patterns (with concrete examples)

### 1. `Task {}` to silence an async error

```swift
// ❌ Hides the await, drops cancellation, hides errors, may capture self strongly.
func load() {
    Task { await self.heavyImport() }
}

// ✅ Make the function async, or store the handle and cancel it.
func load() async {
    await heavyImport()
}
// or
private var importTask: Task<Void, Never>?
func load() {
    importTask = Task { await heavyImport() }
}
func cancelLoad() { importTask?.cancel() }
```

### 2. Holding a lock across `await`

```swift
// ❌ Reentrancy on the same actor + held lock = deadlock or corruption.
actor Cache {
    private let lock = NSLock()
    func get(_ key: String) async -> Data {
        lock.lock()
        defer { lock.unlock() }      // unlocked only at return… after await below
        let data = await fetch(key)  // 🔥 lock held across suspension
        return data
    }
}

// ✅ No lock across await. The actor itself serializes; drop the lock, or
// fetch outside the critical section.
actor Cache {
    func get(_ key: String) async -> Data {
        await fetch(key)   // actor serializes get(); no manual lock needed
    }
}
```

### 3. Blocking the cooperative executor / MainActor

```swift
// ❌ Synchronous sleep on MainActor freezes the UI.
@MainActor func poll() {
    Thread.sleep(forTimeInterval: 0.5)
    refresh()
}

// ✅ Async sleep yields the executor.
@MainActor func poll() async {
    try? await Task.sleep(for: .milliseconds(500))
    refresh()
}
```

### 4. Forgetting to revalidate after `await` (actor reentrancy)

```swift
// ❌ isMonitoring could have flipped to false during the await.
@MainActor func stop() { isMonitoring = false }
@MainActor func tick() async {
    guard isMonitoring else { return }
    await refreshUI()
    appendHistory()   // 🔥 isMonitoring may be false now; appends after stop()
}

// ✅ Re-check the guard after await.
@MainActor func tick() async {
    guard isMonitoring else { return }
    await refreshUI()
    guard isMonitoring else { return }   // revalidate
    appendHistory()
}
```

### 5. `@unchecked Sendable` without a strategy

```swift
// ❌ Asserts Sendable with no proof.
final class Counter: @unchecked Sendable {
    var count = 0   // 🔥 unsynchronized mutable state, asserted safe
}

// ✅ Either make it a value type, or protect with a lock + document + test.
final class Counter: @unchecked Sendable {
    // Strategy: all access serialized through `lock`. Single writer, single reader
    // via os_unfair_lock. No field is read without the lock. Regression test in
    // CounterConcurrencyTests exercises 8 concurrent writers under TSan.
    private var _count = 0
    private let lock = OSAllocatedUnfairLock()
    func increment() { lock.withLock { _count += 1 } }
    var count: Int { lock.withLock { _count } }
}
```

### 6. Continuation resumed twice or zero times

```swift
// ❌ If delegate fails to call back, task leaks forever.
func awaitResult() async throws -> Data {
    await withCheckedThrowingContinuation { cont in
        delegate.fetch { data, error in
            if let data { cont.resume(returning: data) }
            else      { cont.resume(throwing: error ?? URLError(.unknown)) }
        }
        // 🔥 no callback => never resumes; no timeout => leaked task
    }
}

// ✅ Pair with cancellation/timeout so it always resumes.
func awaitResult() async throws -> Data {
    let timeout = Task<Data, Error> {
        try await Task.sleep(for: .seconds(30))
        throw URLError(.timedOut)
    }
    let fetch = Task<Data, Error> {
        try await withCheckedThrowingContinuation { cont in
            delegate.fetch { data, error in
                if let data { cont.resume(returning: data) }
                else      { cont.resume(throwing: error ?? URLError(.unknown)) }
            }
        }
    }
    return try await Task { try await fetch.value }
        .race(against: timeout).value   // whichever resumes first cancels the other
}
```

(Use a small `race` helper or `withTaskGroup` with two children returning on first result and
cancelling the other. The point: every path resumes.)

### 7. Strong `self` cycle in a stored `Task`

```swift
// ❌ self -> monitorTask -> closure -> self.
@MainActor final class Monitor {
    var monitorTask: Task<Void, Never>?
    func start() {
        monitorTask = Task { while !Task.isCancelled { self.tick(); try? await Task.sleep(…) } }
    }
}

// ✅ Weak self, bail when gone.
@MainActor final class Monitor {
    var monitorTask: Task<Void, Never>?
    func start() {
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.tick()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }
    func stop() { monitorTask?.cancel(); monitorTask = nil }
}
```

### 8. Weakening `SWIFT_STRICT_CONCURRENCY` to get a green build

```swift
// ❌ // in build settings: SWIFT_STRICT_CONCURRENCY = minimal   // to silence warnings
// ❌ // annotating a service @MainActor just to suppress a Sendable warning
```

Fix the type or move the work. Never trade correctness for a green build.

---

## Quick checklist for review

- [ ] Every shared mutable state has a named owner (actor / `@MainActor` type).
- [ ] No lock held across any `await`.
- [ ] No `Thread.sleep`/`semaphore.wait`/sync disk on a cooperative thread; MainActor stays light.
- [ ] Every `Task` whose lifetime is controlled has a stored handle and a `cancel()` path.
- [ ] Cancellation checked in every long loop; `CancellationError` not surfaced as user error.
- [ ] Every continuation resumes exactly once on every path (incl. cancel/timeout/duplicate).
- [ ] `@unchecked Sendable` has strategy comment + safety proof + test where practical.
- [ ] No `Task {}` used only to silence an async error.
- [ ] `Task.detached` has a documented reason for dropping actor context/cancellation.
- [ ] `[weak self]` in long-lived closures; teardown cancels observers/streams/timers.
- [ ] Isolation reviewed assuming the **MainActor default** (not `nonisolated`).
- [ ] `SWIFT_STRICT_CONCURRENCY` not weakened; no false claim that strict concurrency is enforced.