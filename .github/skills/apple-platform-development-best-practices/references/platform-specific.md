# Platform-Specific Behavior (macOS / iOS / visionOS)

Reference for native Apple platform behavior. Use this when writing or reviewing
code that touches platform lifecycle, windows/scenes, menus, keyboard, focus,
pasteboard, background execution, entitlements, or privacy-gated APIs.

Cross-references: [privacy-security](privacy-security.md),
[concurrency](concurrency.md), [testing-validation](testing-validation.md).

## Rule classification

- **MUST** — platform correctness, safety, or privacy. Violations break the app,
  reject it from the App Store, or leak user data.
- **SHOULD** — recommended practice that improves quality but is not mandatory.
- **PROJECT** — convention specific to the NextPaste repository.

Precedence: task requirements > mandatory platform correctness/safety/privacy >
repo conventions > recommended practice. **PROJECT rules must never justify
platform-invalid or privacy-violating code.** When a PROJECT convention
conflicts with a MUST rule, the MUST rule wins and the convention is recorded as
an exception.

## Authoritative sources

Official (consult first):

- Apple Developer Documentation — `NSPasteboard`, `UIPasteboard`, App Sandbox,
  Entitlements, Background Execution, `SMAppService`/ServiceManagement,
  Accessibility, Security-Scoped Bookmarks, State Restoration, Human Interface
  Guidelines (HIG), App Review Guidelines.
- WWDC sessions for the deployment-target year (clipboard privacy, background
  execution, paste controls, App Sandbox evolution).
- App Store Connect / App Review Guidelines for current policy on background
  use, clipboard access, accessibility, and login items.

Community (recommendation only, verify against official docs before relying on):

- Swift Forums, Apple Developer Forums, well-maintained open-source clipboard
  and status-bar projects for implementation patterns — never as a substitute
  for entitlement/sandbox/policy verification.

## Repository facts (PROJECT)

Recorded so guidance stays grounded; update when build settings change.

- Project: `NextPaste.xcodeproj`. `SUPPORTED_PLATFORMS = "iphoneos
  iphonesimulator macosx xros xrsimulator"` (visionOS included).
- `TARGETED_DEVICE_FAMILY = "1,2,7"` → iPhone, iPad, Vision Pro.
- Deployment targets: `MACOSX_DEPLOYMENT_TARGET = 26.5`,
  `IPHONEOS_DEPLOYMENT_TARGET = 26.5`, `XROS_DEPLOYMENT_TARGET = 26.5`
  (visionOS is a confirmed 26.5 target). Verify API/UI/build compatibility
  against the visionOS SDK before relying on a specific minimum.
- `SWIFT_VERSION = 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
- Cross-platform UI: `#if os(macOS)` / `#else` with a local
  `NavigationViewWrapper` around `NavigationStack`. Preserve platform-native
  interaction patterns.
- Entitlements (`NextPaste.entitlements`): `aps-environment` (development) and
  `com.apple.developer.aps-environment` (development);
  `com.apple.developer.icloud-container-identifiers = []`;
  `com.apple.developer.icloud-services = [CloudKit]`.
  **App Sandbox is enabled** (`ENABLE_APP_SANDBOX = YES`, resolved via
  `xcodebuild -showBuildSettings` though not declared explicitly in the
  entitlements file). Treat the app as sandboxed; verify entitlement-granted
  file-access hardening (security-scoped bookmarks, user-selected paths) per
  feature.
- `Info.plist`: `UIBackgroundModes = [remote-notification]`.
- macOS clipboard monitor: `NSPasteboard.general.changeCount` polled at 0.5 s
  via `ClipboardMonitorScheduler`; a `changeCount` delta triggers capture;
  `lastObservedChangeCount` prevents re-capture of the same count.
- `ClipboardPasteboardReader` is a struct abstraction with a `.live` factory;
  supports `.text` and `.image` payloads (`ClipboardPayload`).
- Image capture: `ClipboardImagePayload`, `ImageClipFileStore` persists image
  assets to disk, `ImageThumbnailGenerator` produces thumbnails.
- Dedup: text by equality; image by hash + width + height.
- `ClipboardCaptureService` is `@MainActor`; uses `modelContext.insert` +
  `save` with rollback on failure.
- **No `PrivacyInfo.xcprivacy` is present — required-reason APIs may apply;
  verify before shipping.**
- Do not modify signing, teams, or provisioning.

## macOS

### AppKit interop

- **MUST** Keep SwiftUI/AppKit interop explicit. When bridging `NSView*` into
  SwiftUI via `NSViewRepresentable`/`NSViewControllerRepresentable`, own the
  lifecycle and clean up observers/KVO in `dismantleCoordinator`/`deinit`.
- **SHOULD** Prefer SwiftUI primitives; drop to AppKit only for behavior SwiftUI
  cannot express (validated menus, responder-chain commands, global shortcuts,
  pasteboard monitoring).
- **PROJECT** Cross-platform UI differences stay behind `#if os(macOS)` and the
  local `NavigationViewWrapper`; do not fork the source file per platform.

### Window/scene management

- **MUST** Support multiple windows when `WindowGroup` is used; design state so
  each `Window`/`Scene` can stand alone. Never store per-window state in a
  shared singleton without a clear ownership story.
- **SHOULD** Use `Scene`-based restoration (`WindowGroup` + `handlesExternalEvents`)
  and `NSApplicationDelegate` for app-level hooks rather than `AppDelegate`
  window management.
- **SHOULD** Persist window frame/state via `NSWindow`-level or `SceneStorage`
  so restoration is deterministic.

### Multiple windows

- **MUST** Ensure model mutations from any window go through the shared
  `ModelContext`/container and that writes are serialized. See
  [concurrency](concurrency.md).
- **SHOULD** Make list/detail views tolerate appearing in separate windows.

### Menus and commands

- **MUST** Validate commands so disabled actions do not fire. Use
  `CommandGroup`/`CommandMenu` with `.disabled` predicates; for AppKit-responder
  commands use `NSUserInterfaceValidations` (`validateUserInterfaceItem`) — the
  canonical "NSUserValidatedCommand" pattern — so menu items reflect responder
  availability.
- **SHOULD** Define semantic `Command` shortcuts in one place; reuse across
  menus and keyboard shortcuts to avoid drift.

### Responder chain, focus, and keyboard navigation

- **MUST** Do not steal key focus from text fields on launch except when the
  user's clear intent is to type. Honor first-responder ownership.
- **SHOULD** Support full keyboard navigation: tab order, `Esc`, `Return`,
  arrow keys, `Cmd`-directional traversal. Verify focus rings are visible when
  Keyboard > Shortcuts > "Use keyboard navigation to move focus between
  controls" is enabled.
- **SHOULD** Verify `VO` navigation for menus, lists, and detail panes.

### Keyboard shortcuts

- **MUST** Scope shortcuts: app-global via `Command` shortcuts; window-local via
  `KeyEquivalent` only where it does not collide with system shortcuts.
- **SHOULD** Avoid overriding system-reserved shortcuts (`Cmd-W`, `Cmd-Q`,
  `Cmd-Space`, `Cmd-Tab`, screenshot combos) unless the app intentionally owns
  that context.

### Global keyboard shortcuts

- **MUST** Treat global hotkeys as a capability requiring verification, not a
  default. Carbon `RegisterEventHotKey` and `CGEvent`-based interception
  **do not work from a sandboxed app without the appropriate entitlement and,
  for event-tap interception, Accessibility permission (`AXIsProcessTrusted`)**
  which itself requires user grant and is subject to App Review scrutiny.
- **MUST** Before implementing a global shortcut, verify: deployment target,
  sandbox state, entitlement set, the current App Store policy on
  accessibility/event taps, and the lifecycle (must unregister on terminate).
- **SHOULD** Prefer SwiftUI `KeyboardShortcut` (app-level) over system-wide
  hotkeys unless the product explicitly requires capture while unfocused.

### Activation policy and status/menu bar apps

- **MUST** Choose an activation policy deliberately:
  `NSApp.setActivationPolicy(.regular)` (visible Dock/app), `.accessory`
  (menu-bar/agent, no Dock icon), or `.prohibited` (background only).
- **SHOULD** For a menu-bar–oriented clipboard tool, prefer `.accessory` and a
  `NSStatusItem`; do not show a Dock icon unless a window is genuinely primary.
- **SHOULD** Activate windows with `NSApp.activate(ignoringOtherApps:)` only on
  explicit user action; avoid stealing focus from the user's current app.

### Launch at login

- **MUST** Use `SMAppService` (ServiceManagement framework) on current targets;
  the legacy `LSSharedFileList`/login-items approach is deprecated.
- **MUST** Treat login-item registration as a verified capability: it requires
  the app to be code-signed, and App Sandbox/helper-tool rules apply. Do not
  assume a helper or background service is valid without checking entitlements,
  sandbox, and current App Store rules.
- **SHOULD** Prompt for consent before enabling launch-at-login; never register
  silently on first launch.

### App Sandbox, entitlements, and file access

- **MUST** Treat the app as sandboxed before relying on any filesystem or
  process-spanning behavior. **`ENABLE_APP_SANDBOX = YES`** is resolved via
  `xcodebuild -showBuildSettings`; the entitlements file does not declare it
  explicitly, but the resolved setting is authoritative. Verify
  entitlement-granted file-access hardening per feature.
- **MUST** File access outside the user-selected directory requires
  security-scoped bookmarks (`NSURL` start/stop access) and the relevant
  entitlement; never hold a security-scoped resource open across user gestures.
- **SHOULD** Prefer app-container paths for generated assets (thumbnails) and
  document user-selected paths for imported files.
- **MUST** Do not modify signing/teams/provisioning from code or scripts.

### Accessibility permission

- **MUST** `AXIsProcessTrusted()`/`AXIsProcessTrustedWithOptions` requires
  user consent; never assume it. Gate accessibility-dependent features behind
  the prompt and degrade gracefully when denied.
- **MUST** Do not use the Accessibility API to read clipboard contents; use
  pasteboard APIs. Accessibility is for element automation, not data harvesting.

### Pasteboard monitoring (macOS)

- **MUST** Choose a monitoring strategy consciously:
  - `NSPasteboard.general.changeCount` polling (the repo's approach) is
    universally available, sandbox-safe, and does not require entitlements;
    tradeoff: a polling interval and the inability to distinguish producer.
  - `NSPasteboard.notifications` (e.g. `NSPasteboard.changedNotification`) exist
    but availability/reliability varies and some are private; verify before
    depending on them.
- **MUST** Prevent feedback loops: if the app writes to the pasteboard, that
  write increments `changeCount`; the monitor must not re-capture its own write.
  The repo's `lastObservedChangeCount` prevents re-capture of the *same* count,
  **but app-generated writes still increment `changeCount`** — explicitly verify
  the feedback-loop path (e.g. mark app-origin writes, or skip the next delta
  whose producer is self). See the dedicated Clipboard subsection.
- **SHOULD** Poll at the lowest frequency that meets responsiveness; the repo
  uses 0.5 s. Document the budget. See [concurrency](concurrency.md) for the
  timer/`@MainActor` scheduling story.

### Termination, restoration, observers

- **MUST** In `NSApplicationDelegate.applicationWillTerminate(_:)` (or
  `Scene`-phase change), flush pending writes, stop timers, remove observers,
  and release security-scoped resources.
- **MUST** Use `NotificationCenter` removal / `invalidate()` for timers in
  `deinit` or dismantle hooks; retained observers leak across launches.
- **SHOULD** Opt into state restoration (`NSWindowRestoration`,
  `SceneStorage`) so relaunch returns the user to the same selection.
- **SHOULD** For long-running background agents, prefer `DispatchSource`
  timers or a helper over a raw `Timer` that survives unexpected lifecycle
  transitions; verify behavior under `applicationDidResignActive`.

## iOS / iPadOS

### App/scene lifecycle

- **MUST** Design around `UIScene`/`Scene` lifecycle: foreground → inactive →
  background → suspended. Never assume the app runs continuously.
- **MUST** Do work in `scenePhase` transitions that the system allows; the
  suspended state freezes execution. Persist state *before* suspending.

### Foreground/inactive/background/suspended

- **MUST** Treat background time as limited and opportunistic. The system
  suspends and may kill the app at any time; persist on
  `scenePhase == .background`, not "later".
- **SHOULD** Avoid relying on exact timing of lifecycle callbacks across
  versions; verify against the deployment target (26.5 here).

### Background execution

- **MUST** Background execution requires a declared `UIBackgroundModes` reason.
  NextPaste declares `remote-notification` only — this grants a brief window on
  a remote push, **not** arbitrary background polling. Do not add clipboard
  monitoring in the background under this mode.
- **MUST** Do not design iOS clipboard functionality as if the app can
  continuously monitor the system clipboard while inactive/suspended. It
  cannot. See Clipboard subsection.
- **SHOULD** If background work is needed, verify the specific mode (e.g.
  `fetch`, `processing`, `location`) against current App Review policy and the
  deployment target; each mode has separate review scrutiny.

### Privacy prompts

- **MUST** Trigger privacy prompts only on user intent, and handle denial
  gracefully. For pasteboard, `UIPasteboard.detectPresence(for:)` may surface
  a paste-access prompt; verify current behavior for iOS 26.5.
- **MUST** Provide usage strings where required and keep them accurate.
- **SHOULD** Add a `PrivacyInfo.xcprivacy` describing required-reason API use;
  the repo lacks one — verify whether required-reason APIs (e.g. file timestamp,
  user defaults) apply.

### Pasteboard access (iOS)

- **MUST** `UIPasteboard.general` access is foreground-gated and
  privacy-restricted on current iOS; the system may prompt the user or present
  a paste button. **Verify current pasteboard privacy + lifecycle for iOS 26.5
  before implementing any iOS clipboard feature.**
- **MUST** `UIPasteboard.detectPresence(for:)` returns presence without
  granting contents and may avoid a prompt; prefer it to decide whether to
  offer a paste action.
- **SHOULD** Prefer the system paste button (`PasteButton`/`UIKit` paste
  control) for user-initiated paste to avoid prompts and respect the user's
  privacy choice.

### UIKit interop

- **MUST** In SwiftUI/UIKit bridges, drive `UIView` updates from the SwiftUI
  update cycle and remove gesture/observer state in `dismantleCoordinator`.
- **SHOULD** Avoid mixing UIKit focus and SwiftUI focus stories for the same
  element.

### Navigation, presentation, and state restoration

- **MUST** Keep navigation/presentation state restorable: encode the path with
  `NavigationStack` path binding or `SceneStorage`.
- **SHOULD** Deep-link handlers must validate input and never decode arbitrary
  objects.

### Memory pressure

- **MUST** Respond to `didReceiveMemoryWarning`/`UIApplication.didReceiveMemoryWarningNotification`
  by releasing caches (e.g. generated thumbnails) — reconstructable data only.
- **SHOULD** For image-heavy clipboard history, prefer disk-backed assets
  (the repo's `ImageClipFileStore`) over in-memory caches.

### Protected data and data protection

- **MUST** If the app reads protected files, require
  `Data Protection` capability and choose `NSFileProtectionType` deliberately
  (`.complete` is safest; `.completeUntilFirstUserAuthentication` is common for
  clipboard history).
- **SHOULD** Verify `applicationProtectedDataDidBecomeAvailable` behavior and
  avoid accessing protected files when unavailable.

### Touch targets, accessibility, and adaptivity

- **MUST** Maintain ≥44pt touch targets for interactive controls (HIG).
- **MUST** Support Dynamic Type, VoiceOver labels/hints/traits, and
  `accessibilityElements` grouping.
- **MUST** Honor size classes, rotation, and iPad multitasking (Split View,
  Slide Over); never assume a fixed width.
- **SHOULD** Verify external keyboard shortcuts and `UIKeyCommand` on iPad.

## visionOS

- **SHOULD** Reuse SwiftUI patterns shared with iOS/iPadOS; availability and
  some lifecycle semantics differ.
- **MUST** Verify every API against the visionOS SDK and the confirmed
  `XROS_DEPLOYMENT_TARGET = 26.5` minimum before relying on availability.
- **SHOULD** Do not assume pasteboard, background, or accessibility semantics
  match iOS; confirm per API on visionOS.

## Clipboard (dedicated subsection)

Conceptual pipeline (recommend implementing the stages as separable, testable
units):

```
Clipboard changed
  → detect change WITHOUT unnecessary content access
  → inspect available representations
  → choose supported representation per product policy
  → validate
  → normalize ONLY when product semantics require
  → apply privacy rules
  → apply payload-size rules
  → deduplicate atomically
  → persist locally
  → publish state update
  → refresh UI
```

### Change detection

- **MUST (macOS)** Poll `NSPasteboard.general.changeCount` and act only on a
  delta. The repo uses a 0.5 s `ClipboardMonitorScheduler` and
  `lastObservedChangeCount` to avoid re-capturing the same count. **Verify
  feedback-loop prevention:** app-origin writes increment `changeCount` too, so
  after the app writes, the monitor must not re-capture its own content.
- **MUST (iOS)** Do not poll the pasteboard in the background. Foreground access
  is privacy-gated; verify iOS 26.5 behavior before implementing.

### Pasteboard privacy

- **MUST (macOS)** Verify current macOS pasteboard privacy APIs rather than
  assuming unrestricted reads; recent macOS versions add paste-access prompts
  and concealed-content handling. Test on the deployment target.
- **MUST (iOS)** Use `UIPasteboard.detectPresence(for:)` for presence checks
  and the system paste button for user-initiated paste; do not read contents
  opportunistically.
- **MUST** Honor concealed content: on macOS, `NSPasteboard.PasteboardType`
  conveys `conveysConcealedObjectsType`; do not capture, log, or persist
  concealed content. On iOS, there is no public `concealedObjectTypes` symbol —
  use the documented privacy surfaces: `UIPasteboard.OptionsKey.localOnly`,
  `expirationDate`, `detectPresence(for:)`/`detectPatterns`, and the system
  paste control (`UIPasteControl`/`PasteButton`). Verify these against iOS 26.5
  before relying on them.

### Representations

- **MUST** Support the product's declared representations and explicitly skip
  others: plain text, attributed text/RTF, HTML, URLs, file URLs, images.
- **MUST** Handle malformed data and unsupported representations by skipping,
  not crashing; never assume a representation is present because another is.
- **MUST** Handle multiple items: enumerate, do not collapse to "the" item.
- **SHOULD** Apply payload-size rules (max bytes, max dimensions for images)
  before persistence; document the chosen limits.

### Persistence, ordering, deduplication

- **MUST** Local-first: persist to SwiftData on-device; never upload without
  explicit requirements, informed consent, and a local-first fallback. See
  [privacy-security](privacy-security.md).
- **MUST** Preserve deterministic ordering (capture order / timestamp); the UI
  must reflect a stable history.
- **MUST** Make deduplication semantics explicit and atomic: the repo uses text
  equality and image hash + width + height. Do not dedup on text equality alone
  when content type/representation matters (e.g. same text but different image).
- **MUST** Handle concurrent capture atomically; `ClipboardCaptureService` is
  `@MainActor` and rolls back on save failure — preserve that contract.

### Capture control

- **MUST** Support pause/resume capture so the user can keep sensitive copies
  private; verify the monitor honors pause across lifecycle transitions.
- **SHOULD** Provide clear-one and clear-all with confirmation for destructive
  clear-all; never delete assets orphaned from the model without a cleanup pass.

### Source attribution

- **SHOULD** Treat source-app attribution as best-effort. On macOS,
  `NSWorkspace.frontmostApplication` (and the pasteboard's producer when
  officially available) is best-effort; do not persist a claimed source as fact
  unless an official API guarantees it. On iOS, source attribution is largely
  unavailable — do not invent it.

### Race conditions and feedback loops

- **MUST** Prevent app-generated writes from being captured repeatedly:
  app writes → `changeCount` increments → monitor sees a delta → risk of
  re-capturing the app's own content. The repo's `lastObservedChangeCount`
  mitigates same-count re-capture but does NOT by itself distinguish producer;
  explicitly verify the path that suppresses self-origin deltas.
- **MUST** Treat repeated change events idempotently for the same content; do
  not insert duplicates on rapid successive deltas.
- **MUST** Never log clipboard contents (debug or otherwise) — log only
  metadata (type, size, timestamp, source label).

### Testability

- **MUST** Interact with the pasteboard only through a protocol/adapter so unit
  tests do not depend on the real system clipboard. The repo's
  `ClipboardPasteboardReader` struct with a `.live` factory is the seam — inject
  a test double in tests. See [testing-validation](testing-validation.md).

### Anti-normalization rules

- **MUST** Never auto-discard or aggressively trim content because it contains
  multiple lines, emoji, composed characters, combining marks, Traditional
  Chinese, CJK, RTL, or unusual Unicode. Preserve bytes as-is unless product
  semantics require normalization, and then document the exact transform.
- **MUST** Avoid destructive trimming/normalization that changes user content
  meaning; store the original representation alongside any derived one.

## Mandatory clipboard rules (summary)

- **MUST** Prevent app-generated writes being captured repeatedly.
- **MUST** Do not depend solely on text equality when content
  type/representation matters; make dedup semantics explicit.
- **MUST** Preserve deterministic ordering.
- **MUST** Handle concurrent capture atomically.
- **MUST** Never log clipboard contents.
- **MUST** Never upload without explicit requirements + informed consent +
  local-first fallback.
- **MUST** Never auto-discard content because it contains multiple lines/emoji/
  composed chars/combining marks/Traditional Chinese/CJK/RTL/unusual Unicode.
- **MUST** Use a protocol/adapter so tests do not depend on the real clipboard.
- **MUST** Treat source-app attribution as best-effort unless an official API
  guarantees it.
- **MUST** Verify current macOS pasteboard privacy APIs rather than assuming
  unrestricted reads.