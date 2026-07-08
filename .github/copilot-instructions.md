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

- `NextPasteApp.swift` is the app bootstrap. It creates one shared SwiftData `ModelContainer` with `Schema([ClipItem.self])` and injects it into the root `WindowGroup`.
- `HomeView.swift` is the main feature entry point. It reads persisted data with `@Query(sort: ClipItem.historySortDescriptors)`, mutates storage through `@Environment(\.modelContext)`, and depends on SwiftData to keep the list in sync rather than maintaining duplicate view state.
- `ContentView.swift` wraps `HomeView` in a cross-platform `NavigationViewWrapper` (using `#if os(macOS)` / `#if os(iOS)`) and injects shared theme/motion environment values.
- `ClipItem.swift` defines the persisted domain model (`@Model` type covering text/image clips, pinned state, timestamps, and history sort descriptors).
- The repo has three Xcode targets: the `NextPaste` app target, `NextPasteTests` for unit tests, and `NextPasteUITests` for UI automation.

## Key conventions

- Follow the NextPaste constitution in `.specify/memory/constitution.md` and enforce the v2.8 governance pillars:
  1. Continuous Quality Improvement: Evaluate recurring Analyze findings for promotion to shared governance sources before feature-local fixes.
  2. Apple Platform Consistency: Explicitly declare supported Apple platforms, prefer shared business logic, and preserve native platform interactions.
  3. Spec Traceability Governance: Respect spec.md as the sole authoritative source of FR and SC identifiers. Report orphan identifiers and redefined identifiers as blocking Analyze errors.
  4. Root Cause First Engineering: Document the likely root cause, investigation strategy, and confirmation criteria in plans before implementation.
  5. Performance Budget Governance: Mandate measurable performance budgets only where a feature affects responsiveness, launch, clipboard capture, search, thumbnail generation, persistence latency, or memory behavior.
  6. Governance Evolution and Analysis Accuracy: Treat governance improvements as incremental evolution and classify every Analyze finding as Governance Defect, Implementation Pending, or Verification Pending.
  7. Governance Propagation Order: Apply governance updates in order `Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact`.
  8. Lifecycle Ownership Boundaries: Keep validation lifecycle ownership centralized in `specs/<feature>/contracts/validation-and-sonar-contract.md` and avoid competing lifecycle definitions in other artifacts.
  9. Specification Lifecycle & Archival (principle XIX): Follow `specify -> clarify -> plan -> tasks -> implement -> validate -> complete -> archive`. Organize specs under `specs/` root (in-progress `draft`/`active`/`blocked` specs live directly at `specs/<id>-<name>/`; there is no `specs/active/`), `specs/archive/YYYY/`, `specs/deprecated/` with `specs/README.md` as index. Status vocabulary is limited to `draft`, `active`, `blocked`, `completed`, `deprecated`, `superseded`, `cancelled` (never `done`/`finished`/`closed`/`complete`/`implemented`). Use `git mv` for moves; never delete, ZIP, move out, or rename to fuzzy names. Archived completed specs require `completion.md`; superseded specs use `status: superseded` with `superseded_by`. Unchecked tasks must record a disposition (`Moved to SPEC-<id>`, `Cancelled`, or `Accepted limitation`) and must NOT be marked `[x]`. Do not assume tests passed; do not fabricate commit SHA, dates, PR, or release versions (use `unknown`/blank when unverifiable). Run `.specify/scripts/bash/spec-archive-check.sh` for lightweight validation.
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
- Keep cross-platform UI differences behind compile-time checks. `ContentView` uses `#if os(macOS)` and `#if os(iOS)` plus a local `NavigationViewWrapper` to keep one source file building across Apple platforms; `HomeView` is the feature entry point rendered inside that wrapper.
- Unit tests and UI tests use different frameworks on purpose: `NextPasteTests` uses the newer `Testing` module, while `NextPasteUITests` still uses `XCTest`. Follow the existing framework for each target instead of mixing them.
- The project uses Xcode’s file-system-synchronized groups (`PBXFileSystemSynchronizedRootGroup`). In practice, adding source files inside `NextPaste/`, `NextPasteTests/`, or `NextPasteUITests/` is the expected way to extend each target.
- App configuration is split across generated build settings and checked-in overrides: `project.pbxproj` enables generated Info.plist entries, while `NextPaste/Info.plist` adds `UIBackgroundModes`, and `NextPaste.entitlements` carries push/iCloud capability settings. Capability changes may need updates in more than one of those places.
- The project is configured for multiple Apple platforms (`iphoneos`, `iphonesimulator`, `macosx`, `xros`, `xrsimulator`), so avoid changes that assume a single-platform app unless the target matrix is intentionally being reduced.
- For interaction changes, prefer Apple-native APIs and behaviors over custom gesture models, and
  validate applicable keyboard shortcuts, focus, scrolling, multi-selection, trackpad, Magic
  Mouse, mouse, context-menu, drag-and-drop, and VoiceOver behavior before considering the work
  done.

## Context Loading Policy

- 預設只讀本檔（`.github/copilot-instructions.md`）與 `AGENTS.md` 這類固定 repo-level 提示詞，以及任務直接相關的檔案。
- 不預設掃描整個 `specs/`、`docs/`、`.github/`、`.agents/`、`.specify/`。也不掃描 `DerivedData/`、`build/`、`.build/`、`*.xcresult`。
- 搜尋程式碼時優先限定在 `NextPaste/`、`NextPasteTests/`、`NextPasteUITests/`。
- 搜尋規格時，先由使用者指定或由任務中提及的 feature 編號推斷對應 `specs/<feature>/`；無法推斷時先用 `rg --files specs` 列出候選目錄，不要全文掃描所有 specs。
- 舊 feature specs 只在需要歷史決策、相容性或治理追溯時才讀取。
- 不把預設上下文綁到任何單一活躍 feature 的 spec、plan、tasks 或 contracts。

## Spec Loading Rule

- 只有當使用者明確要求規格工作（specify / clarify / plan / tasks / analyze / implement），或任務需要確認 FR/SC、validation contract、治理追溯時，才讀對應 `specs/<feature>/` 下的檔案。
- 不要主動讀取或預載任何單一活躍 feature 的 plan.md 作為預設上下文。

## Spec Kit Compatibility Boundary

Official Spec Kit commands are allowed and remain the canonical workflow for SDD tasks. However, Spec Kit execution must stay bounded by the current user request and must not silently expand repo-level context.

- Do not run optional post-hooks unless the user explicitly requests them in the current turn.
- Do not run `/speckit-agent-context-update` unless explicitly requested.
- Do not modify `AGENTS.md` or `.github/copilot-instructions.md` during normal `/speckit.*` execution.
- Do not add or update feature-specific `SPECKIT START` pointers in repo-level instruction files.
- If the official workflow recommends refreshing agent context, report it as a skipped optional step instead of executing it.
- Current feature artifacts are the product requirement source for that SDD command. Historical specs may be read only when the current artifact explicitly references them or when needed for compatibility, and then only relevant sections should be read.
- Before completing an SDD command, report:
  1. Files read beyond the current feature directory
  2. Files modified
  3. Optional hooks skipped
  4. Any deviations from this boundary

### Bounded SDD prompt template

Reusable constraints to paste at the start of a bounded SDD turn:

```text
Bounded SDD constraints:

- Follow the official Spec Kit / SDD workflow, but keep context loading bounded.
- Current feature artifact is the only product requirement source unless I explicitly name another source.
- Do not read historical specs except when the current artifact explicitly references them; if needed, read only relevant sections.
- Do not run optional post-hooks.
- Do not run /speckit-agent-context-update.
- Do not modify AGENTS.md or .github/copilot-instructions.md.
- Do not add or update any SPECKIT START feature-plan pointer.
- If the official workflow recommends updating agent context, report it as a skipped optional step instead of executing it.
- Before completion, report files read beyond the current feature directory, files modified, optional hooks skipped, and deviations from these constraints.
```

## Search / Tool Output Budget

- 使用 `rg` 或 `rg --files`，避免 `find`/`grep` 全 repo 掃描。
- 搜尋關鍵須具體，避免 `token`、`pin`、`context` 這類會打到大量不相關內容的寬鬆搜尋；必要時加 `path:` 或 `glob:` 限定範圍。
- 讀大型檔案時優先用行號區間，不要一次讀全文。
- `xcodebuild` 或測試輸出只摘要失敗重點（錯誤訊息、失敗測試名、檔案行號），不要貼完整 log。
- 若工具輸出過大，下一步必須縮小搜尋範圍或改用更精確的查詢。

## Governance Loading Scope

- 上述治理規則摘要為常駐提示；一般產品 bug fix 或小功能修改，不預設讀完整 `.specify/`、`.github/agents/` 或所有 feature specs。
- 只有治理、規格、分析、validation ownership 相關任務才讀完整治理文件（`constitution.md`、`speckit.*.agent.md`、validation contracts）。
