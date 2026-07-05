# NextPaste Shared Skill Rules

Read this file after repository instructions and before task-specific work.

## Task source resolution

- Treat the task file explicitly provided by the user or invocation as the primary task source of truth.
- When a task ID or phase is provided without a task-file path, locate the matching task definition under `specs/`.
- Prefer task files matching patterns such as:
  - `specs/*/*_TASKS.md`
  - `specs/*/tasks.md`
  - `specs/*/TASKS.md`
- Confirm that the selected task file actually contains the requested task ID or phase before using it.
- Do not assume `specs/022-new-feature-impl/NextPaste_TASKS.md` is always the active task source.
- Do not combine requirements from multiple task files unless the current task explicitly depends on them.
- If multiple task files contain the same task ID and the intended source cannot be determined from the invocation, repository state, or project state file, stop and report the ambiguity instead of guessing.
- Once resolved, treat that task file as the source of truth for the current session only.

## Core rules

- Handle exactly one task or one explicit verification stage per session.
- Prefer minimal reads. If dependencies are unclear, add at most one file at a time.
- Read only:
  - the current task or phase specification
  - the directly relevant project state
  - the directly relevant task or phase summary
  - the directly relevant production files
  - the directly relevant tests
  - the applicable repository instruction and Skill files
- Do not scan all files under `specs/`, `docs/`, source directories, test directories, or Git history unless the current task cannot be resolved through narrower reads.
- Do not output full Git diffs, full build logs, or full test logs.
- Send large command output to `/tmp` and report only the result and key errors.
- Never claim build, test, manual verification, commit, or push results that did not actually happen.
- Do not use private API or dependencies not already permitted by the repository instructions and active task specification.
- Do not use `sleep`, `Task.sleep`, `asyncAfter`, fixed-second waits, or unconditional retry loops.
- Do not use SwiftUI `List` index as data identity or as the basis for delete, pin, or unpin behavior.
- Keep SwiftData writes inside the existing `ModelContext` and `MainActor` boundaries.
- Return to `MainActor` before any callback mutates UI-visible state.
- Do not overwrite unrelated or source-unknown changes already in the worktree.
- Do not use `git reset --hard`, `git push --force`, `git push --force-with-lease`, or destructive rebase flows.
- If context is running short, write state back into the repository before ending the session.
- Keep final reporting concise and do not restate the full feature specification.

## Project-state resolution

- Prefer the project-state file explicitly named by the active workflow.
- Otherwise, look for a narrowly relevant state file such as:
  - `docs/implementation/PROJECT_STATE.md`
  - a feature-specific state file referenced by the active task specification
- Do not assume a state file from another feature applies to the current task.
- Do not read every task summary or phase report.
- Read only the summary directly associated with the current task, phase, or identified dependency.

## Scope isolation

- A repository may contain multiple specifications and feature branches at the same time.
- Resolve the active specification from:
  1. the explicit invocation
  2. the requested task or phase ID
  3. the current project-state file
  4. the current Git branch
  5. the matching task file under `specs/`
- Do not modify another specification’s task status, summaries, reports, or implementation unless the active task explicitly requires it.
- Do not carry assumptions, state, or completion evidence from one specification into another.