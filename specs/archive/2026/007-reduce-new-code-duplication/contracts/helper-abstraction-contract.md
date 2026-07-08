# Contract: Helper Abstractions

## General helper requirements

- Helpers must have one clear owner and replace duplicated hotspot code directly.
- Helpers must stay internal/private/test-only unless existing public APIs require otherwise.
- Helpers must fail clearly on invalid input or missing UI state.
- Helpers must not create new product behavior, UI redesign, persisted schema changes, or network behavior.
- Helpers must not be introduced for speculative future use outside the hotspot scope.

## Row helpers

`RowActionControlGroup` must render only existing copy, pin/unpin, and delete actions. It must preserve identifiers, labels, action order, destructive delete role, disabled states, and animation hooks.

`SharedRowPresentation` must own common row chrome and trailing copied/pinned state while accepting row-specific content slots. It must not normalize away legitimate differences between text and image rows.

## Clipboard writer helpers

`PasteboardSnapshot` must be macOS-only, internal, and usable by tests via `@testable import`. It must represent enough pasteboard state to verify unchanged behavior after failures.

`ClipboardWriteRequest` or equivalent private helper must centralize image-write preflight and failure policy without changing existing `ClipboardWriter` public call sites.

## Image fixture helpers

`DeterministicImageFixtureFactory` must produce deterministic bytes from descriptors using Apple-native ImageIO/CoreGraphics APIs already in use.

`ImageFixtureDescriptor`, `PixelStyle`, and `EncodedImageType` must express fixture intent clearly enough that unit and UI tests do not duplicate pixel loops or metadata derivation.

Existing `ImageTestFixtures`, `UITestFixtures.ImageClipboard`, and `ClipboardRobot.captureImage(...)` APIs must remain stable where possible, delegating to the shared factory.
