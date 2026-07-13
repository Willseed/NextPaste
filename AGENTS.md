# NextPaste Project Instructions

This file is the shared repository guide for coding assistants and contributors. Keep it
tool-neutral. The project constitution at `.specify/memory/constitution.md` has higher authority;
read it only for governance, specification, validation-ownership, or traceability work.

## Quick Start

NextPaste is an Xcode application, not a Swift Package. It has no dependency-bootstrap step.
A full Xcode installation is required. The complete verification gate also requires `rg` and
`actionlint` (`brew install ripgrep actionlint`).

```bash
# Open the project for development and launch it with Xcode.
open NextPaste.xcodeproj

# Build the macOS app from the command line.
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste \
  -destination 'platform=macOS' build

# Run the unit-test target while iterating.
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration Unit -destination 'platform=macOS' \
  -only-testing:NextPasteTests test

# Run one Swift Testing suite.
xcodebuild -project NextPaste.xcodeproj -scheme NextPasteCI -testPlan NextPaste \
  -only-test-configuration Unit -destination 'platform=macOS' \
  -only-testing:NextPasteTests/ClipValidationTests test

# Run the authoritative full verification gate before completion/release.
Scripts/verify.sh
```

`Scripts/verify.sh --dry-run` validates configuration without compiling or testing. The gate builds
Debug and Release, runs unit/integration/UI phases, checks hygiene, workflows, and localization,
and requires zero warnings, failures, or skips. It writes evidence outside the repository and
rejects in-repository `DerivedData`, `build`, `.build`, `.xcresult`, and generated products.

There is no configured formatter, SwiftLint configuration, or repository lint command. Use the
existing four-space Swift style and treat Xcode/verification diagnostics as authoritative; do not
invent a formatting or lint command.

## Project Structure

- `NextPaste/`: application target; SwiftUI views, SwiftData model, clipboard services, settings,
  design system, image/OCR support, and Debug-only UI-test surfaces.
- `NextPasteTests/`: unit and integration tests using Swift Testing (`Testing`).
- `NextPasteUITests/`: XCUITests using `XCTest` and the shared `UITestCase` isolation harness.
- `NextPaste.xcodeproj/`: Xcode project with `NextPaste` and `NextPasteCI` schemes.
- `NextPaste.xctestplan`: Unit, Integration, and serialized UI configurations with coverage.
- `Scripts/`: local/CI verification, hygiene checks, and UI-test shard manifests.
- `specs/`: active and historical SDD artifacts; `specs/README.md` is the index.
- `.specify/`: constitution, templates, Spec Kit scripts, and governance support.
- `docs/AutomatedVerification.md`: complete test architecture, gate phases, and evidence contract.

The app target currently supports `iphoneos`, `iphonesimulator`, `macosx`, `xros`, and
`xrsimulator`; deployment targets are macOS 26.0 and iOS/visionOS 26.5. Do not narrow the platform
matrix accidentally.

## Development Rules

- Preserve the primary flow:
  `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- Keep capture, storage, search, and retrieval offline-capable. SwiftData is the source of truth;
  network or optional sync must not block core behavior.
- Treat clipboard-derived content as sensitive and on-device by default. Off-device processing
  requires explicit consent, documented scope and retention, validation, and a local fallback.
- Prefer SwiftUI, SwiftData, Observation, Vision, Foundation Models, Foundation, CloudKit, and
  native Apple APIs. Add a dependency only for a documented capability gap and privacy impact.
- Add persisted models to the `Schema` in `NextPasteApp.makeModelContainer`. Read live history with
  `@Query` and write through `modelContext`; do not introduce duplicate view-owned history state.
- Keep platform differences behind compile-time checks such as `#if os(macOS)` and share business
  logic. Preserve native keyboard, focus, pointer, scrolling, context-menu, drag/drop, and
  accessibility behavior for affected platforms.
- Reuse tokens and components under `NextPaste/DesignSystem/` for user-facing UI. Add a new visual
  primitive there when it is genuinely shared instead of hard-coding a parallel style.
- Keep refactors behavior-preserving unless the governing spec requires visible change. Add parity
  regression coverage and avoid speculative abstractions or unrelated cleanup.
- Product code is MainActor-isolated by the Xcode project setting. Keep UI/storage mutation on the
  owning actor and use existing injectable boundaries for platform or nondeterministic behavior.
- New files placed under `NextPaste/`, `NextPasteTests/`, or `NextPasteUITests/` are discovered by
  Xcode file-system-synchronized groups; do not hand-edit `project.pbxproj` merely to add them.
- Capability changes may span generated Info.plist settings, `NextPaste/Info.plist`, and the Debug
  and Release entitlements. Inspect all owners before editing one.

## Do / Don't

- Do use the existing SwiftData container, query, and service paths; do not create a second store or
  make remote state authoritative.
- Do isolate UI tests through `UITestCase`/`UITestAppLauncher`; do not use production user defaults,
  pasteboards, stores, image directories, fixed sleeps, skipped tests, or expected failures.
- Do update `Scripts/ui-test-loop-inventory.txt` after reviewing any added/changed UI-test loop; do
  not bypass `Scripts/check-test-hygiene.sh`.
- Do use `#if DEBUG` plus the complete `-ui-testing` environment for test-only app surfaces; do not
  expose test controls or test-selected storage in Release behavior.
- Do modify localization source in `NextPaste/Localizable.xcstrings`; do not replace localized UI
  with untracked string literals. Unit validation checks catalog completeness.
- Do put verification output in the script-managed temporary directory; do not commit or generate
  build products and result bundles inside the repository.

## Validation

Run the smallest reliable scope first, then batch related edits before broader validation:

- Pure logic/model change: relevant `NextPasteTests` suite, then the Unit configuration.
- Cross-component, persistence, Vision, or AppKit boundary: relevant unit tests plus the Integration
  configuration when applicable.
- User-visible flow not provable below UI: the relevant `NextPasteUITests/<Class>/<method>` selector;
  keep UI execution serialized.
- Shared infrastructure, persistence, launch, navigation, clipboard capture, cross-cutting UI,
  feature completion, or release: `Scripts/verify.sh`.
- Workflow-only change: `Scripts/check-github-actions.sh` (requires `actionlint`).
- Test-source change: `Scripts/check-test-hygiene.sh` before the selected tests.
- Specification archival change: `.specify/scripts/bash/spec-archive-check.sh`.

Never claim a test passed unless it was executed for the current change. Save and inspect the first
large log/result bundle instead of rerunning an expensive command merely to recover output.

## Specifications and Governance

Use the SDD order `specify -> clarify -> plan -> tasks -> analyze -> implement`. Load only the
current feature directory unless it explicitly references historical material. Do not run optional
post-hooks, agent-context updates, or add feature pointers to repository instructions unless the
current request explicitly asks for them. At completion, report out-of-feature reads, modified
files, skipped optional hooks, and boundary deviations.

`spec.md` alone owns `FR-###` and `SC-###`; downstream artifacts reference but never invent or
redefine them. The feature's `contracts/validation-and-sonar-contract.md` owns validation rules and
evidence; `quickstart.md` only explains execution. See the constitution for lifecycle/status,
archival, propagation, and Analyze-classification rules. Governance-only work must not modify
product code, and unverifiable dates, test results, commit SHAs, PRs, or releases remain unknown.

## Pull Requests and Commits

- Keep changes scoped and include the targeted validation performed; explain why a full gate was
  required when the change is cross-cutting.
- Follow the repository's existing Conventional Commit-style subjects, for example
  `fix(settings): preserve native slider behavior` or `test(ui): verify relaunch state`.
- Do not mix generated artifacts, unrelated refactors, or speculative cleanup into a change.

## Context and Further Documentation

Search with `rg`/`rg --files` inside `NextPaste/`, `NextPasteTests/`, or `NextPasteUITests/` before
reading large files. Do not preload all of `specs/`, `docs/`, `.github/`, `.agents/`, or `.specify/`;
read relevant ranges and avoid rereading unchanged content. Exclude generated artifact directories.

- Product overview and feature map: `README.md`
- Governance authority: `.specify/memory/constitution.md`
- Specification index and archival layout: `specs/README.md`
- Verification commands and evidence: `docs/AutomatedVerification.md`
- Spec Kit command models: `.github/agents/speckit.*.agent.md` and `.agents/skills/speckit-*`
