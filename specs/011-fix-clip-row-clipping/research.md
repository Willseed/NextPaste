# Research: Fix New Clip Row Top Clipping

**Feature**: Fix New Clip Row Top Clipping  
**Date**: 2026-06-30

## Research Scope

- Investigate the likely root cause in the current `HomeView`/`List` composition.
- Choose an Apple-native layout/inset correction strategy that preserves current design and
  interaction behavior.
- Define when programmatic scrolling is allowed and when it must be avoided.
- Define an automated and manual validation approach that proves the first visible row is fully
  below the fixed header region after insertion.

## Decision 1: Treat the bug as a viewport inset problem in `HomeView`, not a data/order problem

**Decision**: Implement the fix in the history viewport layer of `NextPaste/HomeView.swift` by
correcting how the `List` positions its first visible row beneath the composite fixed header
region. Preserve `ClipItem` ordering, `ClipboardCaptureService`, `ClipboardMonitor`, and
`NewClipView` save behavior unless a minimal coordination hook is required for visibility updates.

**Rationale**:

- The current layout composes `AppToolbar`, optional header-adjacent status text, `List`, and
  `.searchable`, but the list only has row padding rather than a measured top viewport reserve.
- Automatic capture and manual creation already insert clips correctly through SwiftData; the user
  issue is that the refreshed list can leave the first visible row partially hidden under
  persistent header UI.
- Solving the bug in `HomeView` preserves the clipboard-first pipeline and avoids unnecessary data
  or ordering changes.

**Alternatives considered**:

- **Change pinned/newest ordering rules**: rejected because the specification explicitly preserves
  pinned-first and newest-first ordering.
- **Adjust row internals only**: rejected because row-local padding does not reliably solve a
  viewport/header overlap problem.
- **Modify capture pipeline timing**: rejected because the problem is visual layout, not clip
  persistence or ordering correctness.

## Decision 2: Use measured Apple-native list inset correction as the primary fix

**Decision**: Measure the full fixed header region and apply a native top list-content inset/margin
correction so the first visible row begins below that region across full-history and filtered
views. Keep the existing `List` and native SwiftUI/AppKit interactions intact.

**Rationale**:

- The approved clarification requires a layout/inset correction, not a redesign.
- Measuring the effective header region avoids hard-coded spacing assumptions and supports small,
  medium, and tall window heights plus live resizing.
- Keeping `List` avoids regressions in native swipe actions, keyboard navigation, row accessibility,
  and scrolling feel that a custom `ScrollView` rewrite would risk.

**Alternatives considered**:

- **Hard-coded extra top padding**: rejected because it risks both under-correction and visible
  over-spacing during resize.
- **Custom `ScrollView`/`LazyVStack` rewrite**: rejected because it increases behavioral regression
  risk for native macOS list affordances.
- **Overlay-only spacer/header layering**: rejected because overlays do not reliably reserve scroll
  content space for the first row.

## Decision 3: Allow programmatic scrolling only as a corrective fallback

**Decision**: Make automatic scrolling conditional. Use it only when a newly inserted clip is
supposed to become visible and layout correction alone still would not leave the first visible row
fully below the fixed header region. Never scroll for non-visible filtered insertions.

**Rationale**:

- The specification allows automatic scrolling only as needed.
- Layout/inset correction should solve the steady-state problem, while conditional scrolling handles
  cases where insertion occurs while the user is already at or near the top and the viewport still
  needs to settle.
- Avoiding unconditional scroll preserves native browsing behavior and prevents disruptive movement
  during filtered or mid-list use.

**Alternatives considered**:

- **Always scroll to top after every insertion**: rejected because it is more invasive than allowed
  and would disrupt existing list browsing behavior.
- **Never scroll under any condition**: rejected because the approved clarifications explicitly
  allow corrective scrolling when needed to keep the first visible row fully visible.

## Decision 4: Validate geometry with targeted macOS UI tests plus a minimal deterministic seam

**Decision**: Extend the existing macOS UI test suite with frame-based assertions that prove the
first visible row sits fully below the fixed header region after insertion. Reuse stable row
identifiers and add a minimal geometry seam or fixed-header-bottom marker only if needed to make
the assertion deterministic with the native macOS search field.

**Rationale**:

- The specification explicitly requires UI tests to verify the first visible row’s full bounds are
  below the fixed header region.
- The repository already has stable row identifiers, search helpers, and frame-based assertion
  patterns that can be extended for this feature.
- A small deterministic seam is preferable to brittle UI-test heuristics because the fixed header
  spans both a native macOS toolbar search field and an in-content header.

**Alternatives considered**:

- **Manual-only validation**: rejected because FR-014 requires automated UI coverage.
- **Pure black-box frame queries only**: possible, but less reliable if the search field exposes
  differently across macOS/Xcode combinations.
- **Unit-test-only layout verification**: rejected because runtime list geometry and resize behavior
  require actual UI automation.

## Decision 5: Manual validation must focus on resize and height-band behavior

**Decision**: Manual validation will explicitly cover live resizing and small, medium, and tall
macOS window heights for both manual clip creation and automatic clipboard capture, including
filtered-search and pinned-row scenarios.

**Rationale**:

- The specification requires manual coverage for resize dynamics that are difficult to fully model
  in lower-level automation.
- This feature changes a shared macOS layout surface whose correctness depends on runtime geometry.
- Manual review is also the best place to confirm the “no visual redesign” constraint and the
  absence of new visual gaps above the first visible row.

**Alternatives considered**:

- **Single default-window manual check**: rejected because it misses the explicitly required height
  bands and live-resize behavior.
- **Automated-only resize validation**: rejected because manual confirmation is required even if
  automation covers part of the scenario.

## Decision 6: Keep SonarQube evidence centralized in the Validation Contract

**Decision**: SonarQube evidence requirements stay centralized in
`contracts/validation-and-sonar-contract.md`, and `quickstart.md` remains execution-only with
ordered commands that reference that contract.

**Rationale**:

- The constitution requires centralized validation ownership and forbids duplicating shared Sonar
  policy across feature artifacts.
- This feature does not need a bespoke Sonar process; it needs explicit evidence capture at the end
  of implementation.

**Alternatives considered**:

- **Copy Sonar evidence rules into the plan or quickstart**: rejected because it would violate the
  validation-governance requirement.

## Resolved Unknowns

- **Root cause location**: `HomeView` viewport/header/list composition
- **Allowed implementation style**: measured layout/inset correction first
- **Scroll policy**: conditional corrective scroll only when needed
- **Automated validation style**: macOS UI-test geometry assertions
- **Manual validation scope**: live resize plus small/medium/tall window heights
- **Validation ownership**: centralized in `contracts/validation-and-sonar-contract.md`

No unresolved clarifications remain.
