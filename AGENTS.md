# NextPaste Codex Instructions

## Authority

- The highest authority is `.specify/memory/constitution.md`, currently Constitution v2.8.0.
- Follow `.github/copilot-instructions.md` for repository build/test conventions, but defer to the
  constitution when guidance conflicts.
- Treat `.github/agents/speckit.*.agent.md` and `.agents/skills/speckit-*` as the
  operational Spec Kit command models.
- For governance-only tasks, do not modify product code.

## Product Constraints

- NextPaste is clipboard-first: preserve the core flow
  `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- The app is local-first: clipboard capture, storage, search, and retrieval must work offline, with
  local SwiftData persistence as the source of truth.
- Privacy is the default: clipboard-derived content must remain on-device unless explicit consent,
  documented scope, retention, and a local-first fallback are specified.
- Prefer the Apple-native stack and interaction model: SwiftUI, SwiftData, Observation, Vision,
  Foundation Models, Foundation, CloudKit, Apple HIG behavior, and native platform APIs.

## Spec Kit Flow

Use the SDD sequence. Copilot commands use dotted names; Codex skills use the same order with
hyphenated skill names.

`/speckit.specify -> /speckit.clarify -> /speckit.plan -> /speckit.tasks -> /speckit.analyze -> /speckit.implement`

Codex equivalent:

`$speckit-specify -> $speckit-clarify -> $speckit-plan -> $speckit-tasks -> $speckit-analyze -> $speckit-implement`

- `/speckit.specify` creates the feature specification.
- `/speckit.clarify` refines the specification before planning when material ambiguity remains.
- `/speckit.plan` records architecture, root-cause hypothesis, constraints, and validation approach.
- `/speckit.tasks` creates dependency-ordered tasks from the approved artifacts.
- `/speckit.analyze` is read-only and checks cross-artifact consistency before implementation.
- `/speckit.implement` executes `tasks.md` after analysis blockers are resolved.

## Specification Lifecycle & Archival

Constitution principle XIX governs this section. The full lifecycle is
`specify -> clarify -> plan -> tasks -> implement -> validate -> complete -> archive`. `complete`
means acceptance is finished; `archive` means the specification and its history are organized for
traceability. Implementation completion does NOT equal archival.

- Layout: in-progress specs (`draft`, `active`, `blocked`) live directly under `specs/` at the
  repository root (there is no `specs/active/` directory); `specs/archive/YYYY/` (completed and
  accepted); `specs/deprecated/` (rejected, superseded, or cancelled).
  `specs/README.md` is the authoritative index of every SPEC.
- Status vocabulary (only these): `draft`, `active`, `blocked`, `completed`, `deprecated`,
  `superseded`, `cancelled`. Do NOT use `done`, `finished`, `closed`, `complete`, or `implemented`
  as status. A SPEC replaced by another uses `superseded` with `superseded_by`, never `completed`.
- Moves MUST use Git-tracked operations (`git mv`). Never delete specs, compress to ZIP, move out of
  the repo, or rename to `old-spec`/`backup`/`legacy`. Preserve `spec.md`, `plan.md`, `tasks.md`,
  `research.md`, and `contracts/`.
- Archival requires: frozen scope, acceptance criteria completed or dispositioned, implementation
  traceable to a commit, all tasks complete or dispositioned, test results recorded, known
  limitations recorded, replacement/superseded relationships recorded, and a `completion.md`.
- Unchecked tasks MUST NOT be marked `[x]` to finish archival. Each open task records a disposition
  (`Moved to SPEC-<id>`, `Cancelled`, or `Accepted limitation`) with a concrete reason.
- AI MUST NOT assume tests passed. AI MUST NOT fabricate commit SHA, dates, PR, or release version;
  unverifiable fields are left blank, marked `unknown`, or omitted.
- Lightweight validation: run `.specify/scripts/bash/spec-archive-check.sh` to check index coverage,
  missing `completion.md`, missing `superseded_by`, disallowed status vocabulary, and open tasks
  without dispositions in archived specs.

## Spec Kit Compatibility Boundary

Official Spec Kit commands are allowed and remain the canonical workflow for SDD tasks. However, Spec Kit execution must stay bounded by the current user request and must not silently expand repo-level context.

- Do not run optional post-hooks unless the user explicitly requests them in the current turn.
- Do not run `/speckit-agent-context-update` or `/speckit.agent-context.update` unless explicitly requested.
- Do not modify `AGENTS.md` or `.github/copilot-instructions.md` during normal `/speckit.*`
  or `$speckit-*` execution.
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
- Do not run /speckit-agent-context-update or /speckit.agent-context.update.
- Do not modify AGENTS.md or .github/copilot-instructions.md.
- Do not add or update any SPECKIT START feature-plan pointer.
- If the official workflow recommends updating agent context, report it as a skipped optional step instead of executing it.
- Before completion, report files read beyond the current feature directory, files modified, optional hooks skipped, and deviations from these constraints.
```

## Governance Workflow

- Governance propagation order is:
  `Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact`.
- Downstream artifacts may reference upstream governance, but must not introduce, redefine,
  weaken, or reorder governance before the upstream owner does.
- Governance changes are incomplete until Sync Impact is updated and required downstream artifacts
  are synchronized or an explicit exception is documented.
- No product code changes are allowed for governance-only synchronization unless the governing spec
  explicitly requires them.

## Governance Status Modeling

Model governance status as three distinct checkpoint categories:

- `Governance Lifecycle Status`: owned by the Constitution; determines overall governance
  readiness.
- `Propagation Progress`: owned by the Validation Contract; tracks downstream synchronization such
  as templates, agents, Copilot instructions, and generated feature artifacts.
- `Verification Status`: records executed evidence such as representative validation, Analyze
  checkpoints, and Sync Impact closure.

Analyze must compare equivalent checkpoints only:

- Compare Governance Lifecycle Status only with Governance Lifecycle Status.
- Compare Propagation Progress only with Propagation Progress.
- Compare Verification Status only with Verification Status.
- Do not report cross-category status differences as Governance Defects unless ownership,
  lifecycle, or propagation-order rules are violated.

Every Analyze finding must be classified as exactly one of:

- `Governance Defect`: constitutional conflict, governance inversion, competing lifecycle owner,
  equivalent-checkpoint contradiction, or mandatory propagation/readiness violation.
- `Implementation Pending`: required implementation work is not yet complete.
- `Verification Pending`: required validation, representative evidence, or checkpoint execution has
  not yet occurred.

Only Governance Defects and Governance Inconsistencies block governance readiness. Implementation
Pending and Verification Pending remain visible follow-up work but are not governance failures.

## Validation Ownership

- `specs/<feature>/contracts/validation-and-sonar-contract.md` owns validation execution,
  validation lifecycle rules, evidence requirements, Sonar evidence, release-readiness validation,
  and Propagation Progress.
- `quickstart.md` is execution-only. It may list build commands, test commands, execution steps, and
  references to the Validation Contract, but must not redefine validation ownership, matrices,
  evidence rules, lifecycle states, or Propagation Progress.
- Feature specs, plans, tasks, and checklists must reference the Validation Contract instead of
  duplicating validation matrices or lifecycle definitions.
- Prefer targeted validation first, then broader regression only at defined gates or when
  cross-cutting scope justifies it. Document the reason for any full regression requirement.

## Implementation Guardrails

- Preserve `spec.md` as the sole authority for functional requirement IDs (`FR-###`) and success
  criterion IDs (`SC-###`). Downstream artifacts may reference these IDs but must not redefine,
  renumber, extend, or invent them.
- Treat orphan FR/SC identifiers, redefined identifiers, and contradictory downstream identifiers as
  blocking governance errors.
- Keep refactors behavior-preserving unless the specification explicitly defines user-visible
  change, and include regression coverage for parity.
- Prefer root-cause fixes. Plans should record the likely root cause, investigation strategy, and
  confirmation criteria before implementation begins.
- Keep validation proportional: targeted unit tests for pure logic, targeted integration tests for
  cross-component behavior, targeted UI tests only where lower layers cannot prove user-visible
  behavior, and full regression for completion/release/shared-infrastructure gates.

## Repository Notes

- This is an Xcode app project, not a Swift Package. Use `xcodebuild` with
  `NextPaste.xcodeproj` and the `NextPaste` scheme.
- There is no checked-in SwiftLint or repository-specific lint script; rely on Xcode diagnostics
  unless tooling is added later.
- The project is configured for multiple Apple platforms. Do not assume a single-platform app unless
  the governing specification intentionally narrows the platform matrix.

## Synchronized Sources

- `.specify/memory/constitution.md`: v2.8.0 authority, governance status modeling,
  specification lifecycle & archival (principle XIX), equivalent-checkpoint comparison, validation
  ownership, propagation order, product constraints, and completion gates.
- `.github/agents/speckit.*.agent.md`: SDD command sequence, agent-layer inheritance, read-only
  Analyze behavior, classification categories, targeted validation ordering, and implementation
  checkpoints.
- `.agents/skills/speckit-*`: Codex SDD skill sequence, bounded hook execution, hyphenated command
  naming, read-only Analyze behavior, targeted validation ordering, and implementation checkpoints.
- `.github/copilot-instructions.md`: Xcode build/test commands, current architecture notes, Apple
  platform conventions, SwiftData usage, and existing validation guidance.

## Context Loading Policy

- 默認只讀本檔（`AGENTS.md`）與 `.github/copilot-instructions.md` 這類固定 repo-level 提示詞，以及任務直接相關的檔案。
- 不預設掃描整個 `specs/`、`docs/`、`.github/`、`.agents/`、`.specify/`。也不掃描 `DerivedData/`、`build/`、`.build/`、`*.xcresult`。
- 搜尋程式碼時優先限定在 `NextPaste/`、`NextPasteTests/`、`NextPasteUITests/`。
- 搜尋規格時，先由使用者指定或由任務中提及的 feature 編號推斷對應 `specs/<feature>/`；無法推斷時先用 `rg --files specs` 列出候選目錄，不要全文掃描所有 specs。
- 舊 feature specs 只在需要歷史決策、相容性或治理追溯時才讀取。
- 不把預設上下文綁到任何單一活躍 feature 的 spec、plan、tasks 或 contracts。

## Spec Loading Rule

- 只有當使用者明確要求規格工作（specify / clarify / plan / tasks / analyze / implement），或任務需要確認 FR/SC、validation contract、治理追溯時，才讀對應 `specs/<feature>/` 下的檔案。
- 不要主動讀取或預載任何單一活躍 feature 的 plan.md 作為預設上下文。

## Search / Tool Output Budget

- 使用 `rg` 或 `rg --files`，避免 `find`/`grep` 全 repo 掃描。
- 搜尋關鍵須具體，避免 `token`、`pin`、`context` 這類會打到大量不相關內容的寬鬆搜尋；必要時加 `path:` 或 `glob:` 限定範圍。
- 讀大型檔案時優先用行號區間，不要一次讀全文。
- `xcodebuild` 或測試輸出只摘要失敗重點（錯誤訊息、失敗測試名、檔案行號），不要貼完整 log。
- 若工具輸出過大，下一步必須縮小搜尋範圍或改用更精確的查詢。

## Governance Loading Scope

- 上述治理規則摘要為常駐提示；一般產品 bug fix 或小功能修改，不預設讀完整 `.specify/`、`.github/agents/` 或所有 feature specs。
- 只有治理、規格、分析、validation ownership 相關任務才讀完整治理文件（`constitution.md`、`speckit.*.agent.md`、validation contracts）。
