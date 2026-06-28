# NextPaste Copilot Instructions

## Build and test commands

This repository is an Xcode app project, not a Swift Package. Use `xcodebuild` against `NextPaste.xcodeproj` and the `NextPaste` scheme.

```bash
# Build the app for macOS
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build

# Run the full test suite
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test

# Run the Swift Testing unit target only
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test

# Run a single unit test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/NextPasteTests/example test

# Run a single UI test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/NextPasteUITests/testExample test
```

There is no repo-specific lint script or SwiftLint configuration checked in. Rely on Xcode build/test diagnostics unless a lint tool is added later.

## High-level architecture

- `NextPasteApp.swift` is the app bootstrap. It creates one shared SwiftData `ModelContainer`, currently with `Schema([Item.self])`, and injects it into the root `WindowGroup`.
- `ContentView.swift` is the main UI and the current feature entry point. It reads persisted data with `@Query`, mutates storage through `@Environment(\.modelContext)`, and depends on SwiftData to keep the list in sync rather than maintaining duplicate view state.
- `Item.swift` defines the persisted domain model. Right now the data layer is intentionally thin: a single `@Model` type with a `timestamp` field.
- The repo has three Xcode targets: the `NextPaste` app target, `NextPasteTests` for unit tests, and `NextPasteUITests` for UI automation.

## Key conventions

- Follow the NextPaste constitution in `.specify/memory/constitution.md`: features must treat the
  system clipboard as the primary source of clips, preserve local-first automatic capture, protect
  user content by default, include automated tests, prefer Apple-native frameworks, and pass the
  post-implementation SonarQube Project Health gate with recorded evidence. User-facing UI must
  follow the shared design system, and refactors must preserve observable behavior with regression
  coverage while avoiding speculative abstractions.
- Preserve the SwiftData flow already in place: add new persisted types to the schema in `NextPasteApp`, fetch them with `@Query`, and write through `modelContext`.
- Keep cross-platform UI differences behind compile-time checks. `ContentView` uses `#if os(macOS)` and `#if os(iOS)` plus a local `NavigationViewWrapper` to keep one source file building across Apple platforms.
- Unit tests and UI tests use different frameworks on purpose: `NextPasteTests` uses the newer `Testing` module, while `NextPasteUITests` still uses `XCTest`. Follow the existing framework for each target instead of mixing them.
- The project uses Xcode’s file-system-synchronized groups (`PBXFileSystemSynchronizedRootGroup`). In practice, adding source files inside `NextPaste/`, `NextPasteTests/`, or `NextPasteUITests/` is the expected way to extend each target.
- App configuration is split across generated build settings and checked-in overrides: `project.pbxproj` enables generated Info.plist entries, while `NextPaste/Info.plist` adds `UIBackgroundModes`, and `NextPaste.entitlements` carries push/iCloud capability settings. Capability changes may need updates in more than one of those places.
- The project is configured for multiple Apple platforms (`iphoneos`, `iphonesimulator`, `macosx`, `xros`, `xrsimulator`), so avoid changes that assume a single-platform app unless the target matrix is intentionally being reduced.

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at specs/007-reduce-new-code-duplication/plan.md
<!-- SPECKIT END -->
