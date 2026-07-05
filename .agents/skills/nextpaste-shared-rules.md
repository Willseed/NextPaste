# NextPaste Shared Skill Rules

Read this file after repository instructions and before task-specific work.

## Core rules

- Treat `specs/022-new-feature-impl/NextPaste_TASKS.md` as the task source of truth.
- Handle exactly one task or one explicit verification stage per session.
- Prefer minimal reads. If dependencies are unclear, add at most one file at a time.
- Read only the current task or phase spec, the directly relevant summary, the directly relevant production files, the directly relevant tests, and the repository instruction files.
- Do not output full git diffs, full build logs, or full test logs.
- Send large command output to `/tmp` and report only the result and key errors.
- Never claim build, test, manual verification, commit, or push results that did not actually happen.
- Do not use private API or dependencies not already permitted by the repo and task spec.
- Do not use `sleep`, `Task.sleep`, `asyncAfter`, fixed-second waits, or unconditional retry loops.
- Do not use SwiftUI `List` index as data identity or as the basis for delete, pin, or unpin behavior.
- Keep SwiftData writes inside the existing `ModelContext` and `MainActor` boundaries.
- Return to `MainActor` before any callback mutates UI-visible state.
- Do not overwrite unrelated or source-unknown changes already in the worktree.
- Do not use `git reset --hard`, `git push --force`, `git push --force-with-lease`, or destructive rebase flows.
- If context is running short, write state back into the repository before ending the session.
- Keep final reporting concise and do not restate the full feature specification.
