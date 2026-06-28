# Research: Restore Swipe Row Actions

## Decision: Keep the product fix in the existing row interaction owner

**Decision**: Use `HomeView.swift` as the primary implementation surface for restoring the direction mapping.

**Rationale**: `HomeView` currently owns both the SwiftUI `.swipeActions` configuration and the custom `DragGesture` that sets `RevealedRowAction`. `ClipRowView` then passes the resulting action flags to either text or image row presentation. Keeping the behavior fix at this owner applies to both row types and avoids duplicate text/image changes.

**Alternatives considered**:

- Change `ClipboardRow` and `ImageClipboardRow` separately: rejected because it risks divergence and visual churn.
- Create a new row action architecture: rejected as unnecessary for a narrow behavior fix.

## Decision: Preserve the existing visual row components

**Decision**: Treat `ClipboardRow`, `ImageClipboardRow`, `SharedRowPresentation`, `RowActionControlGroup`, `DesignTokens`, and `AppTheme` as preservation surfaces.

**Rationale**: The feature only restores intended interaction direction. The current shared row components already define labels, icons, identifiers, spacing, typography, radius, colors, pinned badges, and copied feedback.

**Alternatives considered**:

- Redesign swipe affordances or move actions visually: rejected because visual redesign is explicitly out of scope.
- Rename action identifiers: rejected because existing UI tests and accessibility surfaces depend on stable identifiers.

## Decision: Cover direction with explicit XCUITest names

**Decision**: Add or update XCUITests whose names explicitly state right-swipe Pin and left-swipe Delete for text and image rows.

**Rationale**: Existing tests validate pin/delete outcomes, but direction regressions are easier to miss if helper names hide drag direction. Direction-named tests create clear failure output and satisfy FR-014 and FR-015.

**Alternatives considered**:

- Rely only on unit tests for helper constants: rejected because the regression is user interaction behavior.
- Rely only on existing outcome tests: rejected because they may pass even if helper implementation or product mapping changes together.

## Decision: Avoid all capture, storage, and dependency changes

**Decision**: Do not change `ClipboardCaptureService`, `ClipboardMonitor`, image capture/storage helpers, SwiftData models, OCR/AI paths, CloudKit settings, or dependencies.

**Rationale**: The requested fix is independent of capture and persistence. Touching those areas would increase regression risk and violate scope constraints.

**Alternatives considered**:

- Rework row actions as part of capture or model logic: rejected because action direction is a view interaction contract.

## Decision: Require accepted SonarQube evidence after implementation

**Decision**: Record accepted SonarQube/SonarCloud/CI/local Sonar evidence after implementation in `specs/008-restore-swipe-actions/sonar-evidence.md`.

**Rationale**: The constitution requires Project Health evidence after implementation. Source inspection or local tests are useful but do not replace accepted Sonar evidence.

**Alternatives considered**:

- Skip Sonar evidence because the change is small: rejected by the constitution.
- Substitute `rg` source inspection for Sonar evidence: rejected because source inspection is diagnostic only.

## Clarification Resolution

No `NEEDS CLARIFICATION` markers were present in the technical context. The user-provided constraints fully define the intended behavior and scope.
