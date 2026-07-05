---
name: nextpaste-phase-verifier
description: Independently verify one specified NextPaste phase with minimal context, targeted tests, task completion updates, a phase report, one commit, and push. Use after every task in that phase is implemented. Do not use to implement a normal task, run full final regression, or reconstruct missing state.
---

# NextPaste Phase Verifier

Require one explicit phase ID such as `Phase 4`. If the phase ID is missing, stop and report that it is required. Do not guess the phase.

## Read order

1. Read `AGENTS.md`, `.github/copilot-instructions.md`, and [../nextpaste-shared-rules.md](../nextpaste-shared-rules.md).
2. Read the phase task section in `specs/022-new-feature-impl/NextPaste_TASKS.md`.
3. Read `docs/implementation/PROJECT_STATE.md`.
4. Read only the summaries for tasks in that phase that are not yet verified.
5. Read only the production files and tests directly modified by that phase.

If a task is already `COMPLETE`, do not pre-read its full summary unless verification requires it.

## Verification responsibility

Build a direct mapping of:

- `Task -> modified behavior -> affected component -> selected test`

Run only:

- `git diff --check`
- warning review
- scope review
- skills compliance review
- phase-targeted unit tests
- phase-targeted UI tests
- the smallest necessary Debug build

Do not run full unit tests, full UI tests, Release builds, cross-phase regression, or repeated UI stability suites.

## Failure handling

If verification fails:

- do not mark tasks as `[x]`
- do not commit or push
- do not start the next phase
- identify the responsible task, root cause, and smallest repair scope
- if needed, apply only the minimal in-phase repair
- rerun the failed testcase first, then rerun the phase-targeted tests

## Pass handling

If verification passes:

1. Mark that phase's tasks as `[x]`.
2. Set their status to `COMPLETE`.
3. Update the necessary task summaries.
4. Update `docs/implementation/PROJECT_STATE.md`.
5. Create `docs/implementation/phase-reports/phase-N.md`.
6. Create exactly one commit for that phase.
7. Push.
8. Verify local `HEAD` matches upstream.

## Ending format

Use exactly this ending block:

```text
PHASE:
STATUS:
FILES REVIEWED:
BUILD:
TARGETED UNIT TESTS:
TARGETED UI TESTS:
TASKS UPDATED:
PHASE REPORT:
COMMIT:
PUSH:
REMOTE SYNC:
NEXT ACTION:
```
