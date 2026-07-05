---
name: nextpaste-task-worker
description: Execute exactly one specified NextPaste task using minimal repository context, targeted validation, and persistent task-state updates. Use when given a single task ID such as T016. Do not use for phase verification, full regression, state recovery, commit, push, or another task.
---

# NextPaste Task Worker

Require one explicit task ID such as `T016`. Extract it from the user prompt if possible. If no task ID is present, stop and report the missing task ID. Do not choose a task yourself.

## Read order

1. Read `AGENTS.md`, `.github/copilot-instructions.md`, and [../nextpaste-shared-rules.md](../nextpaste-shared-rules.md).
2. Read the full section for the specified task in `specs/022-new-feature-impl/NextPaste_TASKS.md`.
3. Read `docs/implementation/PROJECT_STATE.md`.
4. Read `docs/implementation/task-summaries/TXXX.md` if it exists.
5. Read only the production files and tests directly required by that task.

Do not pre-read other tasks, all summaries, all phase reports, the full repository, or full git history.

## Execution boundary

- Implement only the specified task.
- Do not implement the next task.
- Do not prebuild follow-up UI, services, models, or tests.
- Do not refactor unrelated code or edit out-of-scope files.

## Validation

Run only:

- `git diff --check`
- the targeted tests directly related to the task
- the smallest necessary Debug compile or build only when tests cannot prove the change

Do not run full tests, Release builds, or cross-phase regression.

## State updates

After a successful implementation:

- keep the task checkbox as `[ ]`
- set status to `IMPLEMENTED_PENDING_PHASE_VERIFICATION`
- create or update `docs/implementation/task-summaries/TXXX.md`
- update `docs/implementation/PROJECT_STATE.md`
- stop after reporting

Do not commit, push, or start another task.

## Ending format

Use exactly this ending block:

```text
TASK:
STATUS:
FILES READ:
FILES CHANGED:
ROOT CAUSE:
TARGETED TESTS:
DEBUG BUILD:
TASK LIST UPDATED:
SUMMARY UPDATED:
PROJECT STATE UPDATED:
COMMIT CREATED: No
PUSH PERFORMED: No
NEXT ACTION:
```
