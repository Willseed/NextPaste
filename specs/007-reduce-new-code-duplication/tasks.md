# Tasks: Reduce New Code Duplication

**Input**: Design documents from `specs/007-reduce-new-code-duplication/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [quickstart.md](quickstart.md), [contracts/](contracts/)

**Tests**: Required. This is a refactor-only feature, so every implementation task must preserve behavior parity and be validated by targeted unit/UI tests, mandatory full regression execution, and SonarQube Project Health evidence. If full regression cannot run locally, completion is blocked until successful CI or another accepted full-regression execution is recorded; local limitations are not accepted as completion evidence.

**Task format**: `- [ ] T### [P?] [US?] Description with exact file path (FR-###, SC-###)`

---

## Requirement Traceability

| Requirement | Success Criteria | Primary tasks |
| --- | --- | --- |
| FR-001 Baseline Sonar hotspots | SC-002, SC-006 | T001, T006, T009, T010, T040 |
| FR-002 Reduce duplication without suppressions/exclusions/threshold weakening | SC-001, SC-002, SC-006 | T002, T011, T040, T041 |
| FR-003 Share repeated row presentation/action structure | SC-003, SC-004, SC-005 | T012, T015, T016, T017, T018, T019, T025 |
| FR-004 Preserve row behavior and design-system presentation | SC-003, SC-005 | T003, T012, T017, T018, T019, T025, T042 |
| FR-005 Share repeated clipboard-writing logic | SC-003, SC-004, SC-005 | T013, T020, T021, T022, T023, T025 |
| FR-006 Preserve clipboard success/failure/privacy semantics | SC-003, SC-005 | T013, T014, T020, T021, T023, T024, T025 |
| FR-007 Centralize repeated UI test setup/fixtures/robots/assertions | SC-003, SC-004, SC-007 | T026, T028, T029, T030, T031, T032, T033, T035, T036 |
| FR-008 Preserve UI scenario behavior-equivalent coverage | SC-003, SC-005, SC-007 | T026, T027, T028, T032, T033, T034, T035, T036, T038 |
| FR-009 Automated regression coverage for parity | SC-003, SC-005 | T004, T005, T012, T013, T014, T026, T027, T028, T025, T036, T037, T038, T039 |
| FR-010 No product behavior, privacy, UI, capture, or AI changes | SC-005 | T002, T003, T007, T019, T024, T030, T035, T042 |
| FR-011 Helpers fail clearly for invalid input/state | SC-003, SC-005 | T012, T013, T015, T016, T022, T029, T033 |
| FR-012 Avoid speculative abstractions | SC-004, SC-005 | T008, T015, T016, T020, T021, T029, T035, T042 |
| FR-013 Record SonarQube Project Health evidence | SC-001, SC-006 | T040, T041 |
| FR-014 Preserve hotspot-to-resolution traceability | SC-002, SC-006 | T001, T006, T010, T040, T041 |

---

## Phase 1: Setup (Baseline & Guardrails)

**Purpose**: Establish traceability, no-suppression guardrails, and baseline behavior before code changes.

- [X] T001 Create `specs/007-reduce-new-code-duplication/sonar-evidence.md` with the six baseline hotspot files, baseline percentages, duplicated-line counts, and planned resolution owner for each hotspot (FR-001, FR-014, SC-002, SC-006)
- [X] T002 Audit `NextPaste.xcodeproj/project.pbxproj`, repository Sonar/CI configuration files if present, and `specs/007-reduce-new-code-duplication/sonar-evidence.md` to record that no duplicate-code suppressions, file exclusions, or quality-gate threshold changes are used (FR-002, FR-010, SC-001, SC-006)
- [X] T003 Record current public initializer/API surfaces for `NextPaste/DesignSystem/Components/ClipboardRow.swift`, `NextPaste/DesignSystem/Components/ImageClipboardRow.swift`, `NextPaste/ClipRowView.swift`, and `NextPaste/ClipboardWriter.swift` in `specs/007-reduce-new-code-duplication/sonar-evidence.md` before refactoring (FR-004, FR-010, FR-012, SC-005)
- [X] T004 Run baseline affected unit-test commands from `specs/007-reduce-new-code-duplication/quickstart.md` and record results in `specs/007-reduce-new-code-duplication/sonar-evidence.md` (FR-009, SC-003, SC-005, SC-006)
- [X] T005 Run baseline affected UI-test commands from `specs/007-reduce-new-code-duplication/quickstart.md` and record results in `specs/007-reduce-new-code-duplication/sonar-evidence.md` (FR-008, FR-009, SC-003, SC-005, SC-006)

**Checkpoint**: Baseline and guardrails are documented; implementation can begin.

---

## Phase 2: Foundational (Hotspot Traceability)

**Purpose**: Create the cross-hotspot traceability structure that every implementation story must keep current.

- [X] T006 Update `specs/007-reduce-new-code-duplication/sonar-evidence.md` with a hotspot traceability table mapping each duplicated block to its target helper/component, mechanical call-site files, targeted validation, and final Sonar evidence slot (FR-001, FR-014, SC-002, SC-006)
- [X] T007 Confirm in `specs/007-reduce-new-code-duplication/sonar-evidence.md` that SwiftData schema, app-private image storage layout, clipboard capture flow, and user-facing UI behavior are unchanged by plan before starting implementation (FR-010, SC-005)
- [X] T008 Create an implementation note in `specs/007-reduce-new-code-duplication/sonar-evidence.md` requiring any remaining similar block to document why sharing would hide behavior differences and why the Sonar gate still passes (FR-012, FR-014, SC-002, SC-004)

**Checkpoint**: All later tasks have a traceability destination and behavior-preservation guardrail.

---

## Phase 3: User Story 1 - Pass the new-code duplication gate (Priority: P1) MVP

**Goal**: Establish and maintain evidence needed for the configured SonarQube duplication gate to pass without suppressions, exclusions, or threshold changes.

**Independent Test**: Compare the baseline hotspot evidence with post-refactor SonarQube evidence and verify Duplications on New Code is at or below the configured gate.

### Evidence for User Story 1

- [X] T009 [US1] Collect evidence only, not an automated test: capture the current SonarQube/SonarCloud/CI duplication report or screenshot for the six hotspot files and record the source/run in `specs/007-reduce-new-code-duplication/sonar-evidence.md` (FR-001, FR-002, FR-013, SC-001, SC-002, SC-006)

### Implementation for User Story 1

- [X] T010 [US1] Keep `specs/007-reduce-new-code-duplication/sonar-evidence.md` updated after each hotspot refactor with baseline block, helper/component introduced, files mechanically updated, and validation command/result (FR-001, FR-014, SC-002, SC-006)
- [X] T011 [US1] Re-audit `NextPaste.xcodeproj/project.pbxproj` and any Sonar/CI configuration files after implementation to verify no duplicate-code suppressions, file exclusions, or quality-gate threshold changes were introduced (FR-002, FR-010, SC-001, SC-005, SC-006)

**Checkpoint**: The quality-gate evidence trail is ready and remains current while implementation stories proceed.

---

## Phase 4: User Story 2 - Share repeated row and clipboard behavior safely (Priority: P2)

**Goal**: Reduce duplicated row presentation and clipboard writer logic while preserving text/image row behavior and clipboard semantics.

**Independent Test**: Run row presentation, writer, privacy, and row-action UI regressions and confirm visible row states and clipboard outcomes match the baseline.

### Tests for User Story 2

- [X] T012 [P] [US2] Add or confirm row parity assertions in `NextPasteTests/ClipboardRowPresentationTests.swift` for action order, accessibility identifiers, pinned state, copied feedback, text preview, and image thumbnail/fallback invariants (FR-003, FR-004, FR-009, FR-011, SC-003, SC-005)
- [X] T013 [P] [US2] Add or confirm writer parity assertions in `NextPasteTests/ClipboardWriterTests.swift` for text copy success, image copy success, failed image write rollback, pasteboard type preservation, and unchanged clipboard state after failure (FR-005, FR-006, FR-009, FR-011, SC-003, SC-005)
- [X] T014 [P] [US2] Add or confirm local-only/privacy regression assertions in `NextPasteTests/ClipboardImagePrivacyTests.swift` for shared clipboard writer behavior without telemetry, network, sync, export, or remote processing (FR-006, FR-009, FR-010, SC-003, SC-005)

### Implementation for User Story 2

- [X] T015 [P] [US2] Create `NextPaste/DesignSystem/Components/RowActionControlGroup.swift` for existing copy, pin/unpin, and delete controls with unchanged labels, identifiers, roles, order, and failure behavior (FR-003, FR-004, FR-011, FR-012, SC-003, SC-004, SC-005)
- [X] T016 [US2] Create `NextPaste/DesignSystem/Components/SharedRowPresentation.swift` or equivalent row chrome modifier for common row card structure, pinned affordance, hover/deleting state, and copied-feedback placement while accepting text/image-specific content slots (FR-003, FR-004, FR-011, FR-012, SC-003, SC-004, SC-005)
- [X] T017 [US2] Refactor `NextPaste/DesignSystem/Components/ClipboardRow.swift` to use the shared row action/presentation helpers while preserving its public initializer, text preview behavior, accessibility-facing text, copy feedback, pin/delete behavior, and design tokens (FR-003, FR-004, FR-010, FR-012, SC-003, SC-004, SC-005)
- [X] T018 [US2] Refactor `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` to use the shared row action/presentation helpers while preserving its public initializer, thumbnail/fallback layout, image metadata, accessibility identifiers, copy feedback, pin/delete behavior, and design tokens (FR-003, FR-004, FR-010, FR-012, SC-003, SC-004, SC-005)
- [X] T019 [US2] Apply only compilation-required mechanical updates in `NextPaste/ClipRowView.swift` after row helper extraction and document any public API exception in `specs/007-reduce-new-code-duplication/sonar-evidence.md` (FR-004, FR-010, FR-012, FR-014, SC-003, SC-005, SC-006)
- [X] T020 [US2] Promote the duplicated macOS pasteboard snapshot into one internal helper in `NextPaste/ClipboardWriter.swift` guarded by existing platform checks and usable by tests through `@testable import` (FR-005, FR-006, FR-011, FR-012, SC-003, SC-004, SC-005)
- [X] T021 [US2] Extract private image write request/preflight logic in `NextPaste/ClipboardWriter.swift` so image copy overloads share validation, selected data/type, snapshot capture, failure rollback, and unchanged-pasteboard semantics without changing public writer APIs (FR-005, FR-006, FR-010, FR-012, SC-003, SC-004, SC-005)
- [X] T022 [US2] Create `NextPasteTests/ClipboardWriterTestSupport.swift` only for repeated process-info or failure-writer setup that appears in multiple writer/privacy tests, keeping assertions explicit and helper failures clear (FR-005, FR-006, FR-011, FR-012, SC-003, SC-004, SC-005)
- [X] T023 [US2] Refactor `NextPasteTests/ClipboardWriterTests.swift` to remove the copied pasteboard snapshot and use the production internal helper plus `ClipboardWriterTestSupport` where it removes duplicated test setup (FR-005, FR-006, FR-009, FR-014, SC-002, SC-003, SC-004)
- [X] T024 [US2] Apply only compilation-required mechanical updates in `NextPasteTests/ClipboardImagePrivacyTests.swift` for shared writer test support while preserving privacy/local-first assertions (FR-006, FR-009, FR-010, SC-003, SC-005)
- [X] T025 [US2] Run targeted row/writer/privacy unit tests and record command/results in `specs/007-reduce-new-code-duplication/sonar-evidence.md` (FR-003, FR-004, FR-005, FR-006, FR-009, SC-003, SC-005, SC-006)

**Checkpoint**: Row and writer hotspots have shared owners, public APIs remain stable or documented, and targeted unit parity evidence is recorded.

---

## Phase 5: User Story 3 - Keep UI tests readable and reusable (Priority: P3)

**Goal**: Reduce duplicated UI robot and image fixture code while keeping test bodies readable and behavior-focused.

**Independent Test**: Review changed UI tests and run affected UI suites to confirm scenarios still assert the same user-observable outcomes using shared robots/fixtures/assertions.

### Tests for User Story 3

- [X] T026 [P] [US3] Add or confirm image fixture byte/dimension/type parity coverage in `NextPasteTests/ClipboardImagePayloadTests.swift` for PNG, JPEG, screenshot-style, duplicate, and unsupported fixture paths before replacing fixture builders (FR-007, FR-008, FR-009, SC-003, SC-004, SC-005)
- [X] T027 [P] [US3] Add or confirm duplicate identity parity coverage in `NextPasteTests/ImageDuplicateIdentityTests.swift` to prove shared image fixture builders do not change decoded-pixel duplicate hashes unexpectedly (FR-007, FR-008, FR-009, SC-003, SC-005)
- [X] T028 [P] [US3] Add or confirm UI image robot behavior coverage in `NextPasteUITests/ClipboardImageAutoCaptureUITests.swift` and `NextPasteUITests/ClipboardImageRowActionsUITests.swift` for capture, thumbnail, copy-back, pin, delete, and failure-state scenarios (FR-007, FR-008, FR-009, FR-011, SC-003, SC-005, SC-007)

### Implementation for User Story 3

- [X] T029 [US3] Create `NextPasteTests/DeterministicImageFixtureFactory.swift` with `DeterministicImageFixtureFactory`, `ImageFixtureDescriptor`, `PixelStyle`, and `EncodedImageType` to centralize deterministic image byte and metadata generation for both test targets (FR-007, FR-008, FR-011, FR-012, SC-003, SC-004, SC-007)
- [X] T030 [US3] Update `NextPaste.xcodeproj/project.pbxproj` only if required to include `NextPasteTests/DeterministicImageFixtureFactory.swift` in both `NextPasteTests` and `NextPasteUITests` without duplicating source code (FR-007, FR-010, FR-012, SC-004, SC-005, SC-007)
- [X] T031 [P] [US3] Refactor `NextPasteTests/ImageTestFixtures.swift` to keep existing fixture constants/APIs while delegating encoded bytes, dimensions, expected UTTypes, screenshot metadata, and oversized fixture behavior to `DeterministicImageFixtureFactory` (FR-007, FR-008, FR-009, FR-012, SC-003, SC-004, SC-005)
- [X] T032 [P] [US3] Refactor `NextPasteUITests/UITestFixtures.swift` to back image fixture metadata with shared `ImageFixtureDescriptor` values while preserving existing fixture names and UI test intent (FR-007, FR-008, FR-010, FR-012, SC-003, SC-004, SC-007)
- [X] T033 [P] [US3] Refactor `NextPasteUITests/ClipboardRobot.swift` to remove private duplicated image-generation logic and use `DeterministicImageFixtureFactory` while keeping `captureImage(...)` and pasteboard semantics stable (FR-007, FR-008, FR-010, FR-011, FR-012, SC-003, SC-004, SC-005, SC-007)
- [X] T034 [US3] Apply minimal repeated-payload helper call-site updates in `NextPasteTests/ClipboardImageCaptureTests.swift`, `NextPasteTests/ImageThumbnailGeneratorTests.swift`, and `NextPasteTests/ClipboardWriterTests.swift` only where shared `ImageTestFixtures` builders remove duplicated setup without hiding test intent (FR-007, FR-008, FR-009, FR-012, SC-003, SC-004, SC-005)
- [X] T035 [US3] Review `NextPasteUITests/ClipboardRobot.swift`, `NextPasteUITests/UITestFixtures.swift`, `NextPasteUITests/HistoryRobot.swift`, `NextPasteUITests/RowRobot.swift`, and `NextPasteUITests/UITestAssertions.swift`, then record evidence in `specs/007-reduce-new-code-duplication/sonar-evidence.md` that repeated image fixture, clipboard, row-action, and assertion logic is centralized and one representative future scenario can be added using the shared Robot, Fixture, Builder, and Assertion infrastructure without copying helper logic or adding speculative helper APIs (FR-007, FR-008, FR-010, FR-011, FR-012, SC-004, SC-005, SC-007)
- [X] T036 [US3] Run targeted image fixture, image payload, duplicate identity, image UI, and automatic capture tests and record command/results in `specs/007-reduce-new-code-duplication/sonar-evidence.md` (FR-007, FR-008, FR-009, SC-003, SC-005, SC-006, SC-007)

**Checkpoint**: UI/unit image fixture and robot hotspots use shared deterministic builders, UI robot APIs remain stable, and behavior parity evidence is recorded.

---

## Phase 6: Polish & Cross-Cutting Validation

**Purpose**: Complete broad regression, SonarQube validation, and final refactor integrity review.

- [X] T037 Run the full `NextPasteTests` unit target and record command/results in `specs/007-reduce-new-code-duplication/sonar-evidence.md` after US2 and US3 implementation tasks pass (FR-009, FR-010, SC-003, SC-005, SC-006)
- [X] T038 Run affected UI test classes `NextPasteUITests/ClipRowActionsUITests.swift`, `NextPasteUITests/ClipboardImageRowActionsUITests.swift`, `NextPasteUITests/ClipboardAutoCaptureUITests.swift`, and `NextPasteUITests/ClipboardImageAutoCaptureUITests.swift`, then record command/results in `specs/007-reduce-new-code-duplication/sonar-evidence.md` (FR-007, FR-008, FR-009, SC-003, SC-005, SC-006, SC-007)
- [X] T039 Run the full regression command `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` and record successful command/results in `specs/007-reduce-new-code-duplication/sonar-evidence.md`; if full regression cannot run locally, leave the feature incomplete until successful CI or another accepted full-regression execution is recorded because local limitations are not completion evidence (FR-009, FR-010, SC-003, SC-005, SC-006)
- [ ] T040 Run or collect accepted SonarQube/SonarCloud/CI/local-report evidence for the changed production and test files, then update `specs/007-reduce-new-code-duplication/sonar-evidence.md` with source/run identifier, date, Duplications on New Code result, and quality-gate status (FR-001, FR-002, FR-013, FR-014, SC-001, SC-002, SC-006)
- [ ] T041 Verify `specs/007-reduce-new-code-duplication/sonar-evidence.md` shows no new unresolved feature-introduced Bugs, Vulnerabilities, Security Hotspots requiring review, Code Smells, Coverage violations, Reliability issues, Security issues, Maintainability issues, or duplication failures; document any accepted false positives with justification (FR-002, FR-013, FR-014, SC-001, SC-006)
- [X] T042 Review final diffs for `NextPaste/DesignSystem/Components/ClipboardRow.swift`, `NextPaste/DesignSystem/Components/ImageClipboardRow.swift`, `NextPaste/ClipboardWriter.swift`, `NextPasteTests/ImageTestFixtures.swift`, `NextPasteTests/ClipboardWriterTests.swift`, and `NextPasteUITests/ClipboardRobot.swift` to confirm refactor-only behavior, public API preservation, local-first/privacy preservation, design-system consistency, and absence of speculative abstractions; record result in `specs/007-reduce-new-code-duplication/sonar-evidence.md` (FR-004, FR-006, FR-010, FR-012, SC-003, SC-004, SC-005, SC-006)

---

## Dependencies & Execution Order

### Phase Dependencies

| Phase | Depends on | Notes |
| --- | --- | --- |
| Phase 1 Setup | None | Baseline and guardrails must be recorded before implementation. |
| Phase 2 Foundational | Phase 1 | Traceability table blocks code changes because every hotspot must map to a resolution. |
| Phase 3 US1 | Phase 2 | Evidence trail starts before implementation stories and is updated throughout. |
| Phase 4 US2 | Phase 2 and US1 evidence setup | Row/writer refactor can proceed independently from UI fixture work after guardrails exist. |
| Phase 5 US3 | Phase 2 and US1 evidence setup | Fixture/robot refactor can proceed independently from row/writer work after guardrails exist; T029-T030 block T031-T033. |
| Phase 6 Polish | Phases 3, 4, and 5 | Must run after all duplicated code removals and targeted validations. |

### User Story Dependencies

| User story | Dependency | Can be tested independently by |
| --- | --- | --- |
| US1 Pass new-code duplication gate | Needs Phase 2 traceability; final gate also depends on US2 and US3 implementation | Current and final Sonar evidence plus hotspot traceability table |
| US2 Share repeated row and clipboard behavior safely | Needs Phase 2 traceability and US1 evidence file | Row presentation, writer, privacy, and row-action tests |
| US3 Keep UI tests readable and reusable | Needs Phase 2 traceability and US1 evidence file; T029-T030 block T031-T033 | Image fixture, duplicate identity, image UI, automatic capture, and UI helper readability checks |

### Parallelization Notes

| Parallel set | Tasks | Why safe |
| --- | --- | --- |
| Baseline test authoring/checks | T012, T013, T014 | Different test files; all read the same contracts and do not modify shared implementation files. |
| Row helper creation and writer helper work | T015-T018 and T020-T023 | Separate production/test files once contracts from Phase 2 are fixed; coordinate only before final test run. |
| Image fixture tests | T026, T027, T028 | Different unit/UI test files and independent fixture behavior checks. |
| Image fixture wiring after T029-T030 | T031, T032, T033 | Different files; all depend on the shared factory contract created in T029 and target availability from T030. |
| Final validation collection | T037, T038 | Unit and UI validations can be assigned separately, but evidence updates to `sonar-evidence.md` must be serialized. |

### Parallel Example: User Story 2

```text
Task: T012 Add/confirm row parity assertions in NextPasteTests/ClipboardRowPresentationTests.swift
Task: T013 Add/confirm writer parity assertions in NextPasteTests/ClipboardWriterTests.swift
Task: T014 Add/confirm privacy regression assertions in NextPasteTests/ClipboardImagePrivacyTests.swift
```

### Parallel Example: User Story 3

```text
After T029-T030:
Task: T031 Refactor NextPasteTests/ImageTestFixtures.swift
Task: T032 Refactor NextPasteUITests/UITestFixtures.swift
Task: T033 Refactor NextPasteUITests/ClipboardRobot.swift
```

---

## Validation Checklist

| Check | Evidence task | Required outcome |
| --- | --- | --- |
| Behavior parity for row presentation | T012, T025, T038, T039 | Text/image row labels, previews, thumbnails, action order, copied feedback, pin/delete behavior, and accessibility remain unchanged. |
| Clipboard writer parity | T013, T014, T025, T039 | Text/image copy success, failure rollback, unchanged pasteboard state, type preservation, and privacy remain unchanged. |
| UI robot and fixture parity | T026, T027, T028, T035, T036, T038 | Deterministic image bytes, metadata, duplicate identity, pasteboard writes, row targeting, and UI scenario outcomes remain unchanged; one representative future scenario is proven addable through shared Robot, Fixture, Builder, and Assertion infrastructure without helper-logic copying. |
| Clipboard-first behavior | T036, T038, T039 | Existing automatic capture, deduplication, persistence, and history refresh tests pass. |
| Local-first behavior | T014, T025, T039 | No network/sync dependency and no persisted schema/storage behavior change. |
| Privacy-by-default | T002, T014, T041, T042 | No telemetry, analytics, network transmission, remote processing, or policy weakening. |
| Design-system consistency | T012, T017, T018, T025, T042 | Existing tokens, spacing, radius, iconography, motion, and component styling are preserved. |
| Refactoring integrity | T003, T008, T035, T042 | Public APIs are preserved unless mechanically documented; abstractions map to hotspot duplication only. |
| Full regression gate | T039 | Full `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` regression succeeds locally, in CI, or through another accepted full-regression execution; local limitations alone cannot complete the feature. |
| SonarQube quality gate | T040, T041 | Duplications on New Code is at or below the configured gate with no new unresolved feature-introduced issues. |

---

## SonarQube Validation Tasks

| Task | Required evidence |
| --- | --- |
| T009 | Current SonarQube/SonarCloud/CI duplication report or screenshot for the six baseline hotspot files. |
| T010 | Updated hotspot traceability after each helper extraction or documented rationale. |
| T011 | No suppression/exclusion/threshold weakening after implementation. |
| T040 | Accepted SonarQube/SonarCloud/CI/local-report evidence with source/run, date, Duplications on New Code, and quality-gate status. |
| T041 | Project Health status showing no unresolved feature-introduced issues, or documented accepted false positives. |

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2 to establish baseline, no-suppression guardrails, and hotspot traceability.
2. Complete Phase 3 to keep the Sonar evidence trail current while implementation stories execute.
3. Complete Phase 4 to address row and writer duplication with targeted parity tests.
4. Stop and validate T025 before proceeding to UI fixture and robot refactors.

### Incremental Delivery

1. Baseline and traceability: T001-T011.
2. Row/writer tests and refactors: T012-T025.
3. Image fixture/UI robot tests and refactors: T026-T036.
4. Full validation, Sonar evidence, and final review: T037-T042.

### Refactor Boundaries

- Do not introduce product behavior, UI redesign, clipboard behavior changes, image capture behavior changes, telemetry, sync, export, or AI behavior.
- Do not suppress Sonar rules, exclude hotspot files, or weaken thresholds.
- Do not add generic abstractions unless they directly remove duplicated hotspot code and preserve behavior clarity.
- Prefer no changes to `NextPaste/HomeView.swift`; if compilation requires any call-site update, document it in `specs/007-reduce-new-code-duplication/sonar-evidence.md` before completion.
