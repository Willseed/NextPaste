---
name: nextpaste-state-recovery
description: Reconstruct NextPaste task and phase state from repository evidence after an interrupted or lost agent session. Use when PROJECT_STATE.md or task summaries are missing, stale, or inconsistent. Do not implement features, run normal task work, perform phase verification, commit, or push.
---

# NextPaste State Recovery

Use this skill only to reconstruct implementation state from repository evidence. Do not implement product work while recovering state.

## Read order

1. Read `AGENTS.md`, `.github/copilot-instructions.md`, and [../nextpaste-shared-rules.md](../nextpaste-shared-rules.md).
2. Read `specs/022-new-feature-impl/NextPaste_TASKS.md`.
3. Read `git status --short`, the current branch, the latest commit, and `git diff --stat`.
4. Read `docs/implementation/PROJECT_STATE.md` if it exists.
5. If evidence is ambiguous, read only the single task's relevant source or test files.
6. Read only the most recent necessary task summary or phase report.

Do not begin by reading all source files, all tests, all summaries, or full git history.

## Reconstruction rules

Task status may only be one of:

- `PENDING`
- `IMPLEMENTED_PENDING_PHASE_VERIFICATION`
- `COMPLETE`
- `BLOCKED_EXTERNAL`

Apply these rules:

- `[x]` plus sufficient verification evidence means `COMPLETE`
- implementation evidence without phase verification means `IMPLEMENTED_PENDING_PHASE_VERIFICATION`
- insufficient implementation evidence means `PENDING`
- a real external blocker means `BLOCKED_EXTERNAL`

Do not mark a task complete just because files exist.

## Outputs

Create or repair:

- `docs/implementation/PROJECT_STATE.md`
- `docs/implementation/task-summaries/TXXX.md` only when sufficient evidence exists

Do not implement features, run full builds, run full tests, commit, or push.

## Ending format

Use exactly this ending block:

```text
RECOVERY STATUS:
FILES READ:
TASKS RECONSTRUCTED:
PROJECT STATE UPDATED:
SUMMARIES UPDATED:
BUILD EXECUTED: No
TESTS EXECUTED: No
COMMIT CREATED: No
PUSH PERFORMED: No
NEXT ACTION:
```
