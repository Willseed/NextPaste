---
name: nextpaste-final-verifier
description: Run NextPaste final full regression, stability checks, audits, final reporting, safe merge to main, push, and local branch cleanup. Use only after all phases are complete or all automatable work is complete. Do not use for an individual task, phase-only testing, or state reconstruction.
---

# NextPaste Final Verifier

Do not start final verification until all phases have passed, all automatable tasks are `COMPLETE`, manual verification items are honestly marked, the feature branch is synchronized with upstream, the worktree has no source-unknown edits, and no unresolved phase failure remains. If any precondition fails, stop and report it. Do not merge.

## Read order

1. Read `AGENTS.md`, `.github/copilot-instructions.md`, and [../nextpaste-shared-rules.md](../nextpaste-shared-rules.md).
2. Read `docs/implementation/PROJECT_STATE.md`.
3. Read all phase reports.
4. Read the task-status summary in `specs/022-new-feature-impl/NextPaste_TASKS.md`.
5. Read only the tests and configuration directly needed for final regression.

Do not pre-read all task summaries. Read a task summary only when a regression failure points to that task.

## Final regression

Run:

- Debug build
- Release build
- all unit tests
- all UI tests
- search regression
- pin and unpin regression
- delete regression
- clear history regression
- clipboard capture regression
- settings regression
- global hotkey regression
- history limit and retention regression
- appearance regression
- localization regression
- accessibility automation regression
- SwiftData consistency regression
- `MainActor` and concurrency regression
- the complete UI suite three consecutive times
- dependency audit
- secret audit
- private API audit
- git audit

Do not use unconditional retry or rerun until a flaky pass appears.

## Failure handling

After any production fix:

1. Run the smallest failing test first.
2. Run the responsible phase's targeted tests.
3. Create a corrective commit.
4. Push.
5. Restart the full final regression from the beginning.

## Reporting and merge

Create `docs/implementation/final-regression.md` with commands, results, three UI runs, manual verification state, and audit results. Do not store full logs.

When everything passes:

1. `git fetch origin`
2. `git switch main`
3. `git pull --ff-only origin main`
4. `git merge --no-ff <feature-branch>`
5. `git push origin main`
6. `git fetch origin`
7. Confirm `main == origin/main`
8. Delete only merged local feature branches

Never use `git branch -D` to delete an unmerged branch.

## Ending format

Use exactly this ending block:

```text
FINAL STATUS:
FILES REVIEWED:
DEBUG BUILD:
RELEASE BUILD:
UNIT TESTS:
UI TEST RUNS:
AUDITS:
FINAL REPORT:
MERGE TO MAIN:
PUSH:
BRANCH CLEANUP:
NEXT ACTION:
```
