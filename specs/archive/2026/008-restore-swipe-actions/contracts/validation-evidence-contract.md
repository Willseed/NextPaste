# Contract: Validation and Evidence

## Automated UI regression coverage

The implementation is complete only when automated UI tests cover:

- Text row right swipe reveals Pin.
- Text row left swipe reveals Delete.
- Image row right swipe reveals Pin when image rows are present.
- Image row left swipe reveals Delete when image rows are present.
- Pin activation toggles only the selected clip.
- Delete activation removes only the selected clip.
- Row tap copy remains unchanged.
- Pinned-first ordering remains unchanged after pinning, unpinning, and deletion.

## Targeted regression coverage

Targeted validation must include:

- `NextPasteUITests/ClipRowActionsUITests`
- `NextPasteUITests/ClipboardImageRowActionsUITests`
- `NextPasteTests/ClipboardRowPresentationTests`
- `NextPasteTests/ClipRowViewTests`
- `NextPasteTests/ClipHistoryTests`

Full `NextPaste` scheme regression is required before completion unless a CI environment records the accepted full-regression result.

## Design preservation evidence

Implementation review must confirm:

- No visual redesign occurred.
- Design tokens, colors, typography, spacing, radius, icons, and animations are unchanged.
- Row action identifiers and labels remain stable.
- No new row actions, context menus, or keyboard shortcuts were introduced.

## SonarQube Project Health evidence

After implementation, record evidence in `specs/008-restore-swipe-actions/sonar-evidence.md`.

Accepted evidence sources:

- SonarQube dashboard
- SonarCloud dashboard
- CI quality-gate artifact or log
- Local Sonar report from an already configured project analysis
- Dashboard/report screenshot

The evidence must identify:

- Source and run date/time
- Analyzed feature branch or commit
- Quality gate status
- Bugs
- Vulnerabilities
- Security Hotspots requiring review
- Code Smells
- Coverage violations
- Reliability issues
- Security issues
- Maintainability issues
- New Code duplication status
- Any false positives and justifications

The feature remains incomplete if accepted Sonar evidence is unavailable.
