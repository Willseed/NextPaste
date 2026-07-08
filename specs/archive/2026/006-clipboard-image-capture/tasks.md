# Tasks: Refactor-Only SonarQube Cleanup

**Input**: Design documents from `specs/006-clipboard-image-capture/`

**Prerequisites**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [quickstart.md](quickstart.md), [contracts/](contracts/), `.specify/memory/constitution.md`

**Scope**: Resolve only the current 9 SonarQube maintainability/code smell findings. Primary code/test scope remains limited to the Sonar-listed files below. No user-facing behavior changes, product feature changes, clipboard behavior changes, image capture behavior changes, visual design changes, or new product features are allowed.

**Primary file scope**:

- `NextPaste/ClipItem.swift`
- `NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift`
- `NextPasteTests/ImageClipFileStoreTests.swift`
- `NextPasteTests/ImageTestFixtures.swift`
- `NextPasteTests/SwiftDataTestSupport.swift`

**Minimal mechanical call-site compatibility scope**: Outside the primary Sonar-listed files, edits are allowed only when value-object signatures require compile-time caller compatibility, and must be limited to the exact call sites listed in tasks T007 and T010. These edits must be mechanical only and must not change product behavior.

**Tests**: Required by FR-019 and the constitution. Use existing targeted regression tests to prove behavior parity for this refactor-only cleanup.

**Required Spec Kit gate**: This task plan must follow `/speckit.specify -> /speckit.clarify -> /speckit.plan -> /speckit.tasks -> /speckit.analyze -> /speckit.implement`. The current `/speckit.analyze` run is the required pre-implementation gate; address analysis findings in `tasks.md` before `/speckit.implement` starts. Any post-implementation `/speckit.analyze` run is optional re-analysis only and does not replace the required pre-implementation gate.

**SonarQube completion gate**: Cleanup is complete only with accepted Sonar evidence from a SonarQube dashboard, SonarCloud dashboard, CI artifact, local Sonar report, or dashboard screenshot. If that evidence is unavailable, the feature remains incomplete. Evidence must show all 9 listed Sonar findings are resolved and no new Sonar issues or New Code duplication gate failures are introduced.

**Organization**: Tasks are grouped by setup, shared foundation, existing user-story behavior parity, and final validation/Sonar evidence.

## Phase 1: Setup & Baseline Guard

**Purpose**: Freeze the exact Sonar cleanup scope and capture baseline behavior before refactoring.

- [ ] T001 Record the 9 current SonarQube findings, allowed file scope, and refactor-only acceptance criteria in `specs/006-clipboard-image-capture/sonar-evidence.md` (FR-020, SC-008)
- [ ] T002 Run the targeted baseline command from `specs/006-clipboard-image-capture/quickstart.md` and record results in `specs/006-clipboard-image-capture/quickstart.md` before code changes (FR-019, FR-020, SC-005, SC-008)

**Checkpoint**: Cleanup scope and pre-refactor behavior are documented.

---

## Phase 2: Foundational Test Support Refactors

**Purpose**: Remove shared test-support Sonar findings without changing product behavior.

- [ ] T003 [P] Replace the long deterministic fixture factory parameter list with a file-local fixture options struct in `NextPasteTests/ImageTestFixtures.swift`, preserving fixture bytes, dimensions, labels, metadata variants, and oversized data (FR-001, FR-008, FR-009, FR-019, FR-020, FR-021, SC-001, SC-002, SC-003, SC-008)
- [ ] T004 [P] Add configurable temporary image store base and forbidden root parameters in `NextPasteTests/SwiftDataTestSupport.swift`, preserving the current repo-local default root and cleanup behavior (FR-006, FR-007, FR-016, FR-019, FR-020, FR-021, SC-007, SC-008)

**Checkpoint**: Shared fixtures and test storage support no longer trigger the listed parameter-count or hard-coded URI/base path findings.

---

## Phase 3: User Story 1 - Preserve Automatic Image Clip Construction (Priority: P1) MVP

**Goal**: Reduce the `ClipItem.imageClip` parameter count while preserving image clip metadata used by automatic capture.

**Independent Test**: Image capture and model tests still create `contentType = "image"` clips with identical metadata, ordering, deduplication inputs, and local file references.

### Implementation for User Story 1

- [ ] T005 [US1] Introduce an image clip initialization value object and update `imageClip` to accept the value object in `NextPaste/ClipItem.swift` while preserving `contentType = "image"`, empty text fallback, timestamps, pin state, and image metadata assignment (FR-003, FR-005, FR-006, FR-008, FR-011, FR-014, FR-019, FR-020, SC-001, SC-002, SC-005, SC-007, SC-008)
- [ ] T006 [US1] Remove the previous long `imageClip` factory signature from `NextPaste/ClipItem.swift` so no function in that file exceeds the SonarQube parameter threshold (FR-020, SC-008)
- [ ] T007 [US1] Mechanically update only compile-required `ClipItem.imageClip` call sites in `NextPaste/ClipboardCaptureService.swift`, `NextPasteTests/ClipItemTests.swift`, `NextPasteTests/ClipHistoryTests.swift`, `NextPasteTests/ClipboardRowPresentationTests.swift`, and `NextPasteTests/ClipRowViewTests.swift` to pass the new value object without changing assertions or behavior (FR-003, FR-005, FR-006, FR-008, FR-011, FR-014, FR-019, FR-020, SC-001, SC-002, SC-005, SC-007, SC-008)

**Checkpoint**: Automatic image clip construction is behavior-equivalent and the `ClipItem.swift` Sonar finding is resolved.

---

## Phase 4: User Story 2 - Preserve Image Row Presentation (Priority: P2)

**Goal**: Reduce image row presentation initializer complexity while preserving thumbnail, metadata, accessibility, pin, and copy feedback behavior.

**Independent Test**: Row presentation tests and row view tests still observe the same identifiers, labels, values, fallback icon behavior, pin state, copy feedback, and design-token-derived presentation.

### Implementation for User Story 2

- [ ] T008 [US2] Introduce an image row presentation content value object and update `ImageClipboardRowPresentation` initialization in `NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift` while preserving computed accessibility labels, values, metadata formatting, fallback icon state, and `init(clip:copyFeedback:interactionState:)` behavior (FR-011, FR-012, FR-018, FR-019, FR-020, FR-021, SC-004, SC-006, SC-008)
- [ ] T009 [US2] Remove the previous 8-parameter `ImageClipboardRowPresentation` initializer from `NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift` so no initializer in that file exceeds the SonarQube parameter threshold (FR-020, SC-008)
- [ ] T010 [US2] Mechanically update only compile-required `ImageClipboardRowPresentation` call sites in `NextPaste/ClipRowView.swift` and `NextPasteTests/ClipboardRowPresentationTests.swift` to pass the new content value object without changing visual design, accessibility expectations, or behavior (FR-011, FR-012, FR-018, FR-019, FR-020, FR-021, SC-004, SC-006, SC-008)

**Checkpoint**: Image row presentation is behavior-equivalent and the `ClipboardRowPresentation.swift` Sonar finding is resolved.

---

## Phase 5: User Story 3 - Preserve Test Safety, Text Regressions, and Quality Gates (Priority: P3)

**Goal**: Resolve test URI/base path and empty-block findings while preserving local-first storage safety, text regressions, and project health evidence.

**Independent Test**: Unsafe image file paths are rejected for the intended error, test store roots remain configurable and isolated, text regressions still pass, and Sonar evidence proves the cleanup restored maintainability health.

### Implementation for User Story 3

- [ ] T011 [US3] Replace hard-coded escaped URI/path fixture values with a local path-safety configuration value in `NextPasteTests/ImageClipFileStoreTests.swift`, deriving escaped URLs and unsafe source extensions from configurable parameters (FR-006, FR-007, FR-016, FR-019, FR-020, FR-021, SC-007, SC-008)
- [ ] T012 [US3] Replace the suspicious empty `catch` block in `NextPasteTests/ImageClipFileStoreTests.swift` with an explicit assertion that unsafe extensions throw `ImageClipFileStoreError.unsafeSourceExtension(sourceExtension)` and record unexpected errors (FR-006, FR-009, FR-019, FR-020, SC-003, SC-007, SC-008)
- [ ] T013 [US3] Verify `NextPasteTests/ImageClipFileStoreTests.swift` uses the configurable test-support base path from `NextPasteTests/SwiftDataTestSupport.swift` without weakening root containment, sibling asset, or cleanup assertions (FR-006, FR-007, FR-016, FR-019, FR-020, FR-021, SC-007, SC-008)

**Checkpoint**: Test path configurability and explicit error assertions resolve the listed test-code Sonar findings without weakening local-first safety coverage.

---

## Phase 6: Validation, Traceability, and Sonar Evidence

**Purpose**: Prove behavior parity and record the project-health evidence required before continuing feature work.

- [ ] T014 Run the targeted unit validation command from `specs/006-clipboard-image-capture/quickstart.md` and record results in `specs/006-clipboard-image-capture/quickstart.md` (FR-001, FR-003, FR-005, FR-006, FR-007, FR-008, FR-009, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-018, FR-019, FR-020, FR-021, SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007, SC-008)
- [ ] T015 Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` if feasible and record full-suite results in `specs/006-clipboard-image-capture/quickstart.md` (FR-019, FR-020, SC-005, SC-008)
- [ ] T016 Run available SonarQube, SonarCloud, or local Sonar analysis and record accepted Sonar evidence from a SonarQube dashboard, SonarCloud dashboard, CI artifact, local Sonar report, or dashboard screenshot in `specs/006-clipboard-image-capture/sonar-evidence.md`; if that evidence is unavailable, leave the feature incomplete (FR-020, SC-008)
- [ ] T017 Verify accepted Sonar evidence shows all 9 listed parameter-count, configurable URI/base path, and empty-block SonarQube findings are resolved with no new Bugs, Vulnerabilities, Security Hotspots requiring review, Code Smells, Coverage violations, Reliability issues, Security issues, Maintainability issues, or New Code duplication gate failures, and record results in `specs/006-clipboard-image-capture/sonar-evidence.md` (FR-020, SC-008)
- [ ] T018 [Optional] Re-run `/speckit.analyze` after implementation as a post-implementation consistency check, and address or document any new findings in `specs/006-clipboard-image-capture/tasks.md` without expanding cleanup scope; this optional re-analysis does not replace the required pre-implementation `/speckit.analyze` gate (FR-019, FR-020, SC-008)
- [ ] T019 Review the final diff against the refactor-only scope and record behavior-parity confirmation in `specs/006-clipboard-image-capture/sonar-evidence.md`, including no user-facing behavior, clipboard behavior, image capture behavior, visual design, or product feature changes (FR-007, FR-014, FR-015, FR-017, FR-018, FR-020, SC-005, SC-007, SC-008)

---

## Requirement Traceability

| Requirement / criterion | Cleanup coverage |
| --- | --- |
| FR-001 Detect supported raster image clipboard content | T003, T014 |
| FR-002 Clipboard image detection uses the same active/background/minimized capture path | T014, T015, T019 (behavior not modified; regression-covered) |
| FR-003 Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI | T005, T007, T014 |
| FR-004 Automatically save new supported image clipboard content as local image clips | T014, T015, T019 (behavior not modified; regression-covered) |
| FR-005 Image clips use `contentType = "image"` | T005, T007, T014 |
| FR-006 App-private image storage with SwiftData metadata only | T004, T005, T007, T011, T012, T013, T014 |
| FR-007 No clipboard image data transmitted outside device | T004, T011, T013, T019 |
| FR-008 Deduplicate by decoded pixels plus dimensions | T003, T005, T007, T014 |
| FR-009 Ignore unsupported/empty/invalid/oversized image data | T003, T012, T014 |
| FR-010 History list refreshes automatically after image capture | T014, T015, T019 (behavior not modified; regression-covered) |
| FR-011 Existing history ordering and pinning for image clips | T005, T007, T008, T010, T014 |
| FR-012 Local thumbnail display and fallback icon rules | T008, T010, T014 |
| FR-013 Image row actions and copy failure behavior | T014 |
| FR-014 Existing text auto-capture continues | T005, T007, T019 |
| FR-015 Existing text Copy/Delete/Pin continues | T014, T019 |
| FR-016 Offline image capture/storage/history/actions | T004, T011, T013, T014 |
| FR-017 No OCR, AI, sync, remote transmission, analytics, import, or new product surfaces | T019 |
| FR-018 Shared design-system presentation remains unchanged | T008, T010, T019 |
| FR-019 Automated tests and behavior-parity validation | T002, T003, T004, T007, T010, T011, T012, T013, T014, T015, T019 |
| FR-020 SonarQube Project Health evidence | T001, T002, T003, T004, T005, T006, T008, T009, T011, T012, T014, T015, T016, T017, T019 |
| FR-021 No full-image recompression; thumbnails remain derived display data | T003, T004, T008, T010, T011, T013, T014 |
| SC-001 Supported image/screenshot capture remains covered | T003, T005, T007, T014 |
| SC-002 Duplicate visual image behavior remains covered | T003, T005, T007, T014 |
| SC-003 Invalid/unsupported image no-op behavior remains covered | T003, T012, T014 |
| SC-004 Thumbnail and fallback behavior remains covered | T008, T010, T014 |
| SC-005 Existing text capture and row-action regressions pass | T002, T005, T007, T014, T015, T019 |
| SC-006 Image copy/delete/pin and copy failure behavior remains covered | T008, T010, T014 |
| SC-007 Offline/local-first behavior remains covered | T004, T011, T013, T014, T019 |
| SC-008 Sonar evidence records zero unresolved introduced issues | T001, T002, T006, T009, T014, T015, T016, T017, T019 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies.
- **Phase 2 Foundation**: Depends on Phase 1 scope guard.
- **Phase 3 US1**: Depends on Phase 2 where fixture/test support changes are available.
- **Phase 4 US2**: Can run after Phase 1; may run in parallel with US1 after file ownership is coordinated.
- **Phase 5 US3**: Depends on Phase 2 configurable test support.
- **Phase 6 Validation**: Depends on all implementation phases.

### User Story Dependencies

- **US1 (P1)**: Independent refactor for image clip construction after foundational setup.
- **US2 (P2)**: Independent refactor for image row presentation after foundational setup.
- **US3 (P3)**: Depends on configurable test support from T004 for URI/base path cleanup.

### Parallel Opportunities

- T003 and T004 can run in parallel because they touch different test support files.
- T005/T006/T007 and T008/T009/T010 can run in parallel if developers coordinate shared test call-site edits in `NextPasteTests/ClipboardRowPresentationTests.swift`.
- T011 and T012 can be implemented together in `NextPasteTests/ImageClipFileStoreTests.swift` after T004.
- T014 and T015 must wait until all code tasks are complete.
- T016 and T017 must wait until targeted/full tests are complete enough to support Sonar evidence.

---

## Parallel Execution Examples

### Foundation

```bash
Task: "T003 Refactor fixture options in NextPasteTests/ImageTestFixtures.swift"
Task: "T004 Refactor configurable test store paths in NextPasteTests/SwiftDataTestSupport.swift"
```

### US1 and US2 after foundation

```bash
Task: "T005-T007 Refactor ClipItem.imageClip value object in NextPaste/ClipItem.swift and mechanical call sites"
Task: "T008-T010 Refactor ImageClipboardRowPresentation content value object in NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift and mechanical call sites"
```

---

## Implementation Strategy

### MVP First

1. Complete T001-T004 to lock scope and remove shared test-support blockers.
2. Complete T005-T013 to resolve all listed Sonar issues.
3. Stop and run T014 targeted validation before any broader cleanup.

### Cleanup Completion

1. Run T014 targeted tests.
2. Run T015 full tests if feasible.
3. Run T016 Sonar analysis and record accepted Sonar evidence from an approved dashboard, artifact, report, or screenshot source; if evidence is unavailable, stop because cleanup is incomplete.
4. Complete T017 and T019 before continuing feature work; T018 may be run only as optional post-implementation re-analysis.

### Scope Guard

- Do not add product features, UI changes, clipboard behavior changes, image capture behavior changes, or visual design changes.
- Do not modify files outside the listed Sonar files except for minimal mechanical call-site compatibility edits named in T007 and T010 when value-object signatures require them.
- Do not add new dependencies, lint tools, or test frameworks.

---

## Validation Checklist

| Validation item | Required task(s) |
| --- | --- |
| Targeted tests for affected production/test helper files run | T014 |
| Full test suite run if feasible | T015 |
| Accepted Sonar evidence from approved dashboard/artifact/report/screenshot source recorded | T016 |
| All 9 listed SonarQube findings resolved | T017 |
| Feature remains incomplete if accepted Sonar evidence is unavailable | T016 |
| No new Sonar issues or New Code duplication gate failures introduced | T017 |
| New Code duplication within configured quality gate | T017 |
| Refactor-only behavior parity confirmed | T019 |
| Scope did not expand into product feature changes | T019 |

## Archive Dispositions
> Appended at archival (2026-07-08). Open checkbox items below retain their original state; no item was marked complete. Each records its final disposition per the archival workflow.

- [ ] T001 Record the 9 current SonarQube findings, allowed file scope, and refactor-only acceptance criteria in `specs/006-clipboard-image-capture/sonar-evidence.md` (FR-020, SC-008)
  - Disposition: Accepted limitation
  - Reason: SonarQube/SonarCloud not configured in this repository; required Sonar evidence is unobtainable.
- [ ] T002 Run the targeted baseline command from `specs/006-clipboard-image-capture/quickstart.md` and record results in `specs/006-clipboard-image-capture/quickstart.md` before code changes (FR-019, FR-020, SC-005, SC-008)
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T003 [P] Replace the long deterministic fixture factory parameter list with a file-local fixture options struct in `NextPasteTests/ImageTestFixtures.swift`, preserving fixture bytes, dimensions, labels, metadata variants, and oversized data (FR-001, FR-008, FR-009, FR-019, FR-020, FR-021, SC-001, SC-002, SC-003, SC-008)
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T004 [P] Add configurable temporary image store base and forbidden root parameters in `NextPasteTests/SwiftDataTestSupport.swift`, preserving the current repo-local default root and cleanup behavior (FR-006, FR-007, FR-016, FR-019, FR-020, FR-021, SC-007, SC-008)
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T005 [US1] Introduce an image clip initialization value object and update `imageClip` to accept the value object in `NextPaste/ClipItem.swift` while preserving `contentType = "image"`, empty text fallback, timestamps, pin state, and image metadata assignment (FR-003, FR-005, FR-006, FR-008, FR-011, FR-014, FR-019, FR-020, SC-001, SC-002, SC-005, SC-007, SC-008)
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T006 [US1] Remove the previous long `imageClip` factory signature from `NextPaste/ClipItem.swift` so no function in that file exceeds the SonarQube parameter threshold (FR-020, SC-008)
  - Disposition: Accepted limitation
  - Reason: SonarQube/SonarCloud not configured in this repository; required Sonar evidence is unobtainable.
- [ ] T007 [US1] Mechanically update only compile-required `ClipItem.imageClip` call sites in `NextPaste/ClipboardCaptureService.swift`, `NextPasteTests/ClipItemTests.swift`, `NextPasteTests/ClipHistoryTests.swift`, `NextPasteTests/ClipboardRowPresentationTests.swift`, and `NextPasteTests/ClipRowViewTests.swift` to pass the new value object without changing assertions or behavior (FR-003, FR-005, FR-006, FR-008, FR-011, FR-014, FR-019, FR-020, SC-001, SC-002, SC-005, SC-007, SC-008)
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T008 [US2] Introduce an image row presentation content value object and update `ImageClipboardRowPresentation` initialization in `NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift` while preserving computed accessibility labels, values, metadata formatting, fallback icon state, and `init(clip:copyFeedback:interactionState:)` behavior (FR-011, FR-012, FR-018, FR-019, FR-020, FR-021, SC-004, SC-006, SC-008)
  - Disposition: Accepted limitation
  - Reason: Manual/hardware/platform regression validation not executed at archival closure.
- [ ] T009 [US2] Remove the previous 8-parameter `ImageClipboardRowPresentation` initializer from `NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift` so no initializer in that file exceeds the SonarQube parameter threshold (FR-020, SC-008)
  - Disposition: Accepted limitation
  - Reason: SonarQube/SonarCloud not configured in this repository; required Sonar evidence is unobtainable.
- [ ] T010 [US2] Mechanically update only compile-required `ImageClipboardRowPresentation` call sites in `NextPaste/ClipRowView.swift` and `NextPasteTests/ClipboardRowPresentationTests.swift` to pass the new content value object without changing visual design, accessibility expectations, or behavior (FR-011, FR-012, FR-018, FR-019, FR-020, FR-021, SC-004, SC-006, SC-008)
  - Disposition: Accepted limitation
  - Reason: Manual/hardware/platform regression validation not executed at archival closure.
- [ ] T011 [US3] Replace hard-coded escaped URI/path fixture values with a local path-safety configuration value in `NextPasteTests/ImageClipFileStoreTests.swift`, deriving escaped URLs and unsafe source extensions from configurable parameters (FR-006, FR-007, FR-016, FR-019, FR-020, FR-021, SC-007, SC-008)
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T012 [US3] Replace the suspicious empty `catch` block in `NextPasteTests/ImageClipFileStoreTests.swift` with an explicit assertion that unsafe extensions throw `ImageClipFileStoreError.unsafeSourceExtension(sourceExtension)` and record unexpected errors (FR-006, FR-009, FR-019, FR-020, SC-003, SC-007, SC-008)
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T013 [US3] Verify `NextPasteTests/ImageClipFileStoreTests.swift` uses the configurable test-support base path from `NextPasteTests/SwiftDataTestSupport.swift` without weakening root containment, sibling asset, or cleanup assertions (FR-006, FR-007, FR-016, FR-019, FR-020, FR-021, SC-007, SC-008)
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T014 Run the targeted unit validation command from `specs/006-clipboard-image-capture/quickstart.md` and record results in `specs/006-clipboard-image-capture/quickstart.md` (FR-001, FR-003, FR-005, FR-006, FR-007, FR-008, FR-009, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-018, FR-019, FR-020, FR-021, SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007, SC-008)
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T015 Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` if feasible and record full-suite results in `specs/006-clipboard-image-capture/quickstart.md` (FR-019, FR-020, SC-005, SC-008)
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T016 Run available SonarQube, SonarCloud, or local Sonar analysis and record accepted Sonar evidence from a SonarQube dashboard, SonarCloud dashboard, CI artifact, local Sonar report, or dashboard screenshot in `specs/006-clipboard-image-capture/sonar-evidence.md`; if that evidence is unavailable, leave the feature incomplete (FR-020, SC-008)
  - Disposition: Accepted limitation
  - Reason: SonarQube/SonarCloud not configured in this repository; required Sonar evidence is unobtainable.
- [ ] T017 Verify accepted Sonar evidence shows all 9 listed parameter-count, configurable URI/base path, and empty-block SonarQube findings are resolved with no new Bugs, Vulnerabilities, Security Hotspots requiring review, Code Smells, Coverage violations, Reliability issues, Security issues, Maintainability issues, or New Code duplication gate failures, and record results in `specs/006-clipboard-image-capture/sonar-evidence.md` (FR-020, SC-008)
  - Disposition: Accepted limitation
  - Reason: SonarQube/SonarCloud not configured in this repository; required Sonar evidence is unobtainable.
- [ ] T018 [Optional] Re-run `/speckit.analyze` after implementation as a post-implementation consistency check, and address or document any new findings in `specs/006-clipboard-image-capture/tasks.md` without expanding cleanup scope; this optional re-analysis does not replace the required pre-implementation `/speckit.analyze` gate (FR-019, FR-020, SC-008)
  - Disposition: Accepted limitation
  - Reason: Optional task not executed at archival closure.
- [ ] T019 Review the final diff against the refactor-only scope and record behavior-parity confirmation in `specs/006-clipboard-image-capture/sonar-evidence.md`, including no user-facing behavior, clipboard behavior, image capture behavior, visual design, or product feature changes (FR-007, FR-014, FR-015, FR-017, FR-018, FR-020, SC-005, SC-007, SC-008)
  - Disposition: Accepted limitation
  - Reason: SonarQube/SonarCloud not configured in this repository; required Sonar evidence is unobtainable.
