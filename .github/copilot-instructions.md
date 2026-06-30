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

- Follow the NextPaste constitution in `.specify/memory/constitution.md` and enforce the v2.6 governance pillars:
  1. Continuous Quality Improvement: Evaluate recurring Analyze findings for promotion to shared governance sources before feature-local fixes.
  2. Apple Platform Consistency: Explicitly declare supported Apple platforms, prefer shared business logic, and preserve native platform interactions.
  3. Spec Traceability Governance: Respect spec.md as the sole authoritative source of FR and SC identifiers. Report orphan identifiers and redefined identifiers as blocking Analyze errors.
  4. Root Cause First Engineering: Document the likely root cause, investigation strategy, and confirmation criteria in plans before implementation.
  5. Performance Budget Governance: Mandate measurable performance budgets only where a feature affects responsiveness, launch, clipboard capture, search, thumbnail generation, persistence latency, or memory behavior.
  6. Governance Evolution and Analysis Accuracy: Treat governance improvements as incremental evolution and classify every Analyze finding as Governance Defect, Implementation Pending, or Verification Pending.
  7. Governance Propagation Order: Apply governance updates in order `Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact`.
  8. Lifecycle Ownership Boundaries: Keep validation lifecycle ownership centralized in `specs/<feature>/contracts/validation-and-sonar-contract.md` and avoid competing lifecycle definitions in other artifacts.
  User-facing UI must follow the shared design system, user interactions must preserve native Apple platform behavior
  and documented Apple HIG alignment, refactors must preserve observable behavior with regression
  coverage while avoiding speculative abstractions, validation ownership must remain centralized in
  `specs/<feature>/contracts/validation-and-sonar-contract.md`, and repeated documentation
  structures must be promoted into `.specify/templates/` instead of being redefined per feature.
- Keep validation artifacts centralized: `quickstart.md` must contain only build commands, test
  commands, execution instructions, and references to the feature's Validation Contract. Feature
  specs, plans, tasks, and checklists should reference the Validation Contract instead of
  duplicating validation matrices, regression definitions, or SonarQube evidence rules.
- Prefer the smallest reliable test scope first: targeted unit tests for pure logic, targeted
  integration tests for cross-component behavior, targeted UI tests only for user-visible flows
  that lower layers cannot validate reliably, and full regression only at feature completion,
  release readiness, or for shared infrastructure, persistence, app launch, navigation, or
  cross-cutting interaction changes. When full regression is necessary, document why.
- Preserve the SwiftData flow already in place: add new persisted types to the schema in `NextPasteApp`, fetch them with `@Query`, and write through `modelContext`.
- Keep cross-platform UI differences behind compile-time checks. `ContentView` uses `#if os(macOS)` and `#if os(iOS)` plus a local `NavigationViewWrapper` to keep one source file building across Apple platforms.
- Unit tests and UI tests use different frameworks on purpose: `NextPasteTests` uses the newer `Testing` module, while `NextPasteUITests` still uses `XCTest`. Follow the existing framework for each target instead of mixing them.
- The project uses Xcode’s file-system-synchronized groups (`PBXFileSystemSynchronizedRootGroup`). In practice, adding source files inside `NextPaste/`, `NextPasteTests/`, or `NextPasteUITests/` is the expected way to extend each target.
- App configuration is split across generated build settings and checked-in overrides: `project.pbxproj` enables generated Info.plist entries, while `NextPaste/Info.plist` adds `UIBackgroundModes`, and `NextPaste.entitlements` carries push/iCloud capability settings. Capability changes may need updates in more than one of those places.
- The project is configured for multiple Apple platforms (`iphoneos`, `iphonesimulator`, `macosx`, `xros`, `xrsimulator`), so avoid changes that assume a single-platform app unless the target matrix is intentionally being reduced.
- For interaction changes, prefer Apple-native APIs and behaviors over custom gesture models, and
  validate applicable keyboard shortcuts, focus, scrolling, multi-selection, trackpad, Magic
  Mouse, mouse, context-menu, drag-and-drop, and VoiceOver behavior before considering the work
  done.

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at specs/012-governance-framework-v2-5/plan.md
<!-- SPECKIT END -->
