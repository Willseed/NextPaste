---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md,
contracts/, and `contracts/validation-and-sonar-contract.md`

**Validation Contract**: `specs/[###-feature-name]/contracts/validation-and-sonar-contract.md`
owns the automated validation matrix, manual validation matrix, regression validation matrix,
offline/local-first validation, accessibility validation, platform-specific validation,
performance validation, release-readiness validation, and SonarQube evidence requirements.
`quickstart.md` owns build/test/run commands and Validation Contract references only.

**Tests**: Generate automated test tasks when the specification or constitution requires them, and
generate validation execution tasks that reference the Validation Contract instead of restating its
matrices or ownership rules inside `tasks.md`.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing
of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

<!--
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.

  The /speckit.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Endpoints from contracts/

  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Tested independently
  - Delivered as an MVP increment

  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

Examples of foundational tasks (adjust based on your project):

- [ ] T004 Create local persistence models and clipboard history schema
- [ ] T005 [P] Implement clipboard monitoring pipeline
- [ ] T006 [P] Define content-type identification and deduplication rules
- [ ] T007 Create base models/entities that all stories depend on
- [ ] T008 Configure explicit error reporting for local capture failures
- [ ] T009 Setup feature flags or settings for optional sync/export flows

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T010 [P] [US1] Unit test for clipboard monitoring or deduplication behavior in
  NextPasteTests/[Name]Tests.swift
- [ ] T011 [P] [US1] UI test for [critical clipboard/history journey] in
  NextPasteUITests/[Name]UITests.swift
- [ ] T012 [P] [US1] Persistence or sorting regression test for captured clips in
  NextPasteTests/[Name]PersistenceTests.swift
- [ ] T013 [US1] Reference and, if needed, extend feature-specific validation execution in
  specs/[###-feature-name]/contracts/validation-and-sonar-contract.md without duplicating its
  template-owned matrices

### Implementation for User Story 1

- [ ] T014 [P] [US1] Create SwiftData model [Entity1] in NextPaste/[Entity1].swift
- [ ] T015 [P] [US1] Create clipboard observation or capture service in
  NextPaste/[ClipboardService].swift
- [ ] T016 [US1] Implement validation, deduplication, and persistence in NextPaste/[Service].swift
- [ ] T017 [US1] Implement SwiftUI history refresh flow for [feature] in NextPaste/[View].swift
- [ ] T018 [US1] Add explicit consent handling for any optional user-content transmission
- [ ] T019 [US1] Add type-identification handling for supported clipboard content

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 2 ⚠️

- [ ] T020 [P] [US2] Unit test for [requirement/schema] in NextPasteTests/[Name]Tests.swift
- [ ] T021 [P] [US2] UI test for [critical user journey] in NextPasteUITests/[Name]UITests.swift
- [ ] T022 [P] [US2] Offline/privacy behavior test for [scenario] in
  NextPasteTests/[Name]PrivacyTests.swift
- [ ] T023 [US2] Reference the Validation Contract in
  specs/[###-feature-name]/contracts/validation-and-sonar-contract.md for any story-specific
  execution additions instead of redefining local validation ownership

### Implementation for User Story 2

- [ ] T024 [P] [US2] Create [Entity] model in NextPaste/[Entity].swift
- [ ] T025 [US2] Implement [Service] in NextPaste/[Service].swift
- [ ] T026 [US2] Implement [feature] in NextPaste/[Location].swift
- [ ] T027 [US2] Integrate with User Story 1 components (if needed)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 3 ⚠️

- [ ] T028 [P] [US3] Unit test for [requirement/schema] in NextPasteTests/[Name]Tests.swift
- [ ] T029 [P] [US3] UI test for [critical user journey] in NextPasteUITests/[Name]UITests.swift
- [ ] T030 [US3] Reference manual/platform/performance/release-readiness execution from
  specs/[###-feature-name]/contracts/validation-and-sonar-contract.md instead of recreating that
  checklist in tasks.md

### Implementation for User Story 3

- [ ] T031 [P] [US3] Create [Entity] model in NextPaste/[Entity].swift
- [ ] T032 [US3] Implement [Service] in NextPaste/[Service].swift
- [ ] T033 [US3] Implement [feature] in NextPaste/[Location].swift

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Documentation updates in docs/
- [ ] TXXX Code cleanup and refactoring
- [ ] TXXX Performance optimization across all stories
- [ ] TXXX [P] Additional regression tests in NextPasteTests/
- [ ] TXXX Privacy review for on-device monitoring, local storage, and explicit data transmission
- [ ] TXXX Offline support review for local-first clipboard behavior
- [ ] TXXX Design-system consistency review for colors, typography, spacing, radius, iconography,
  motion, and component styling in user-facing UI
- [ ] TXXX Execute build/test/run commands from specs/[###-feature-name]/quickstart.md and evaluate
  them against specs/[###-feature-name]/contracts/validation-and-sonar-contract.md
- [ ] TXXX Execute manual, accessibility, platform-specific, performance, and release-readiness
  validation from specs/[###-feature-name]/contracts/validation-and-sonar-contract.md
- [ ] TXXX Run SonarQube Project Health validation and record evidence exactly as required by
  specs/[###-feature-name]/contracts/validation-and-sonar-contract.md

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 -> P2 -> P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models before services
- Clipboard monitoring and persistence before optional sync/export integrations
- Core implementation before integration
- Shared validation execution belongs in the Validation Contract, not in task-local matrices
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together (if tests requested):
Task: "Contract test for [endpoint] in tests/contract/test_[name].py"
Task: "Integration test for [user journey] in tests/integration/test_[name].py"

# Launch all models for User Story 1 together:
Task: "Create [Entity1] model in src/models/[entity1].py"
Task: "Create [Entity2] model in src/models/[entity2].py"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational -> Foundation ready
2. Add User Story 1 -> Test independently -> Deploy/Demo (MVP!)
3. Add User Story 2 -> Test independently -> Deploy/Demo
4. Add User Story 3 -> Test independently -> Deploy/Demo
5. Execute the Validation Contract and record Sonar evidence before completion
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Do not duplicate contract-owned validation matrices, regression definitions, risk tables,
  rollback sections, or Sonar evidence rules inside `tasks.md`
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
