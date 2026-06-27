# Tasks: Clipboard Image Auto Capture

**Input**: Design documents from `specs/006-clipboard-image-capture/`

**Prerequisites**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [quickstart.md](quickstart.md), [contracts/](contracts/)

**Tests**: Required by FR-019 and the constitution. Write failing characterization/unit/UI tests before implementation tasks in each phase.

**Organization**: Tasks are grouped by setup, shared foundation, and user stories so the MVP image capture path can be implemented first, then image history management, then regressions/privacy/quality gates.

## Phase 1: Setup & Baseline Characterization

**Purpose**: Capture current behavior, prepare deterministic image fixtures, and avoid touching user data during tests.

- [ ] T001 Run the current relevant baseline tests and record any pre-existing failures in `specs/006-clipboard-image-capture/quickstart.md` (FR-014, FR-015, FR-019, SC-005)
- [ ] T002 [P] Add deterministic PNG, JPEG, screenshot-style, corrupt, unsupported, oversized, and same-pixels-different-metadata image fixtures in `NextPasteTests/ImageTestFixtures.swift` (FR-001, FR-008, FR-009, FR-019, SC-001, SC-002, SC-003)
- [ ] T003 [P] Add temporary image file-store root helpers and image metadata fetch helpers in `NextPasteTests/SwiftDataTestSupport.swift` (FR-006, FR-016, FR-019, SC-007)
- [ ] T004 [P] Add deterministic image clipboard fixture names and expected accessibility metadata in `NextPasteUITests/UITestFixtures.swift` (FR-012, FR-013, FR-018, FR-019, SC-004, SC-006)

**Checkpoint**: Test fixtures and baseline evidence are ready.

---

## Phase 2: Foundational Image Model, Validation, Storage, and Thumbnail Infrastructure

**Purpose**: Build the image metadata and local binary infrastructure that blocks all user stories.

**Critical**: No user-story implementation should start until this phase is complete.

### Tests First

- [ ] T005 [P] Add failing SwiftData metadata and lightweight migration tests for optional image fields in `NextPasteTests/ClipItemTests.swift` (FR-005, FR-006, FR-014, FR-019, SC-005, SC-007)
- [ ] T006 [P] Add failing normalized decoded-pixel hash and dimension deduplication tests in `NextPasteTests/ImageDuplicateIdentityTests.swift` (FR-008, FR-019, SC-002)
- [ ] T007 [P] Add failing image payload validation tests for PNG, JPEG, screenshot-style, empty, corrupt, unsupported, and over-25 MB payloads in `NextPasteTests/ClipboardImagePayloadTests.swift` (FR-001, FR-002, FR-009, FR-019, SC-001, SC-003)
- [ ] T008 [P] Add failing app-private full-image and thumbnail file persistence and cleanup tests in `NextPasteTests/ImageClipFileStoreTests.swift` (FR-006, FR-007, FR-016, FR-019, FR-021, SC-007)
- [ ] T009 [P] Add failing capture-time thumbnail generation and fallback-input tests in `NextPasteTests/ImageThumbnailGeneratorTests.swift` (FR-012, FR-018, FR-019, FR-021, SC-004)

### Implementation

- [ ] T010 Extend `ClipItem` with optional image metadata, safe text defaults, and image clip factory helpers in `NextPaste/ClipItem.swift` (FR-005, FR-006, FR-011, FR-014, FR-019, SC-005, SC-007)
- [ ] T011 [P] Implement normalized decoded pixel hash plus dimensions in `NextPaste/ImageClips/ImageDuplicateIdentity.swift` (FR-008, FR-017, FR-019, SC-002)
- [ ] T012 Implement Apple-native image payload validation, type identification, dimensions, byte-count limit, and duplicate identity creation in `NextPaste/ImageClips/ClipboardImagePayload.swift` (FR-001, FR-002, FR-008, FR-009, FR-017, FR-019, FR-021, SC-001, SC-002, SC-003)
- [ ] T013 [P] Implement app-private full image and thumbnail file storage with injectable test roots in `NextPaste/ImageClips/ImageClipFileStore.swift` (FR-006, FR-007, FR-016, FR-019, FR-021, SC-007)
- [ ] T014 [P] Implement capture-time aspect-fit thumbnail generation and fallback failure signaling in `NextPaste/ImageClips/ImageThumbnailGenerator.swift` (FR-012, FR-018, FR-019, FR-021, SC-004)
- [ ] T015 Run the foundational unit tests and fix failures in `NextPasteTests/ClipItemTests.swift`, `NextPasteTests/ImageDuplicateIdentityTests.swift`, `NextPasteTests/ClipboardImagePayloadTests.swift`, `NextPasteTests/ImageClipFileStoreTests.swift`, and `NextPasteTests/ImageThumbnailGeneratorTests.swift` (FR-001, FR-005, FR-006, FR-008, FR-009, FR-012, FR-016, FR-019, FR-021, SC-001, SC-002, SC-003, SC-004, SC-007)

**Checkpoint**: Image metadata, validation, dedupe, local storage, and thumbnail infrastructure are test-covered.

---

## Phase 3: User Story 1 - Automatically capture copied images (Priority: P1) MVP

**Goal**: Copying a supported image or screenshot while NextPaste is running creates exactly one local image clip without manual saving.

**Independent Test**: Run image capture unit tests plus UI capture tests for active, backgrounded, and minimized app states; confirm content type, persistence, deduplication, and automatic history refresh.

### Tests First

- [ ] T016 [P] [US1] Add failing capture service tests for PNG, JPEG, screenshot-style payloads, `contentType = "image"`, image-first priority over text metadata, and duplicate rejection in `NextPasteTests/ClipboardImageCaptureTests.swift` (FR-001, FR-002, FR-003, FR-004, FR-005, FR-008, FR-010, FR-019, SC-001, SC-002)
- [ ] T017 [P] [US1] Add failing monitor characterization tests for shared text/image payload polling and active/backgrounded/minimized process-alive capture in `NextPasteTests/ClipboardCaptureTests.swift` (FR-001, FR-002, FR-003, FR-014, FR-019, SC-001, SC-005)
- [ ] T018 [P] [US1] Add failing UI tests for automatic image capture and history refresh while active, backgrounded, and minimized in `NextPasteUITests/ClipboardImageAutoCaptureUITests.swift` (FR-001, FR-002, FR-003, FR-004, FR-010, FR-019, SC-001)

### Implementation

- [ ] T019 [US1] Implement `ClipboardPayload` image-first/text-fallback pasteboard snapshot support in `NextPaste/ClipboardMonitorClient.swift` (FR-001, FR-002, FR-003, FR-014, FR-017, SC-001, SC-005)
- [ ] T020 [US1] Update the monitor polling path to capture shared payload snapshots instead of text-only strings in `NextPaste/ClipboardMonitor.swift` (FR-001, FR-002, FR-003, FR-010, FR-014, SC-001, SC-005)
- [ ] T021 [US1] Implement image capture, deduplication lookup, file/thumbnail persistence orchestration, SwiftData save, and rollback cleanup in `NextPaste/ClipboardCaptureService.swift` (FR-003, FR-004, FR-005, FR-006, FR-008, FR-009, FR-010, FR-016, FR-019, FR-021, SC-001, SC-002, SC-003, SC-007)
- [ ] T022 [US1] Update UI-test clipboard helpers to write PNG/JPEG/screenshot-style image payloads and wait for image rows in `NextPasteUITests/ClipboardRobot.swift` (FR-001, FR-002, FR-010, FR-019, SC-001)
- [ ] T023 [US1] Run the User Story 1 focused tests and fix failures in `NextPasteTests/ClipboardImageCaptureTests.swift`, `NextPasteTests/ClipboardCaptureTests.swift`, and `NextPasteUITests/ClipboardImageAutoCaptureUITests.swift` (FR-001, FR-002, FR-003, FR-004, FR-005, FR-008, FR-009, FR-010, FR-014, FR-019, SC-001, SC-002, SC-003, SC-005, SC-007)

**Checkpoint**: MVP image auto-capture works independently.

---

## Phase 4: User Story 2 - Review and manage image clips in history (Priority: P2)

**Goal**: Image clips display recognizable thumbnails in the existing history list and support Copy, Delete, and Pin.

**Independent Test**: Seed or capture an image clip, then verify thumbnail rendering, accessibility, copy-back success/failure, delete, and pin behavior without needing remote services.

### Tests First

- [ ] T024 [P] [US2] Add failing image row presentation tests for thumbnail metadata, fallback icon eligibility, pinned state, and accessibility text in `NextPasteTests/ClipboardRowPresentationTests.swift` (FR-011, FR-012, FR-018, FR-019, FR-021, SC-004)
- [ ] T025 [P] [US2] Add failing image copy-back success and copy failure tests in `NextPasteTests/ClipboardWriterTests.swift` (FR-013, FR-015, FR-019, SC-006)
- [ ] T026 [P] [US2] Add failing UI tests for image thumbnail display, copy-back, copy failure feedback absence, delete, and pin/unpin in `NextPasteUITests/ClipboardImageRowActionsUITests.swift` (FR-011, FR-012, FR-013, FR-018, FR-019, SC-004, SC-006)

### Implementation

- [ ] T027 [US2] Update image row presentation metadata, thumbnail references, fallback state, and accessibility labels in `NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift` (FR-011, FR-012, FR-018, FR-019, FR-021, SC-004)
- [ ] T028 [US2] Update the image row UI to load local thumbnails, display them aspect-fit without cropping, and use the design-system fallback icon only on thumbnail failure in `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` (FR-012, FR-018, FR-019, FR-021, SC-004)
- [ ] T029 [US2] Update `ClipRowView` to choose text or image row presentation by `contentType` while preserving text row behavior in `NextPaste/ClipRowView.swift` (FR-011, FR-012, FR-014, FR-018, SC-004, SC-005)
- [ ] T030 [US2] Implement preserved full-image copy-back with existing failure semantics in `NextPaste/ClipboardWriter.swift` (FR-013, FR-015, FR-016, FR-019, SC-006, SC-007)
- [ ] T031 [US2] Update history row action routing so image copy/delete/pin use the correct content-type path and delete removes associated files in `NextPaste/HomeView.swift` (FR-011, FR-013, FR-015, FR-016, FR-019, SC-006, SC-007)
- [ ] T032 [P] [US2] Add image row action targeting helpers in `NextPasteUITests/RowRobot.swift` (FR-013, FR-019, SC-006)
- [ ] T033 [P] [US2] Add image thumbnail, image row, accessibility, and no-copy-feedback assertions in `NextPasteUITests/UITestAssertions.swift` (FR-012, FR-013, FR-018, FR-019, SC-004, SC-006)
- [ ] T034 [US2] Run the User Story 2 focused tests and fix failures in `NextPasteTests/ClipboardRowPresentationTests.swift`, `NextPasteTests/ClipboardWriterTests.swift`, and `NextPasteUITests/ClipboardImageRowActionsUITests.swift` (FR-011, FR-012, FR-013, FR-015, FR-018, FR-019, FR-021, SC-004, SC-006)

**Checkpoint**: Image clips are visible, recognizable, accessible, and manageable through existing row actions.

---

## Phase 5: User Story 3 - Preserve text capture, local-first privacy, and quality gates (Priority: P3)

**Goal**: Existing text auto-capture and row actions remain unchanged, image capture works offline, no remote transmission is introduced, and quality evidence is recorded.

**Independent Test**: Run text capture/row-action regressions, offline/local-first validation, source privacy review, and post-implementation SonarQube evidence checks.

### Tests First

- [ ] T035 [P] [US3] Add or extend text auto-capture regression tests for text-only payloads, duplicate text, whitespace text, and image-invalid no-op behavior in `NextPasteTests/ClipboardCaptureTests.swift` (FR-009, FR-014, FR-019, SC-003, SC-005)
- [ ] T036 [P] [US3] Add or extend text copy/delete/pin regression UI tests in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-015, FR-019, SC-005)
- [ ] T037 [P] [US3] Add offline/local-first and privacy regression tests for image capture using temporary storage and no network services in `NextPasteTests/ClipboardImagePrivacyTests.swift` (FR-007, FR-016, FR-017, FR-019, SC-007)

### Implementation

- [ ] T038 [US3] Preserve the existing text capture public entry points and text duplicate behavior after payload routing changes in `NextPaste/ClipboardCaptureService.swift` (FR-014, FR-019, SC-005)
- [ ] T039 [US3] Preserve existing text copy feedback, delete, and pin behavior after image row routing changes in `NextPaste/HomeView.swift` (FR-015, FR-019, SC-005)
- [ ] T040 [US3] Verify no CloudKit sync, OCR, AI analysis, analytics, remote transmission, manual image import, or third-party image library code was introduced and record findings in `specs/006-clipboard-image-capture/quickstart.md` (FR-007, FR-016, FR-017, FR-020, SC-007, SC-008)
- [ ] T041 [US3] Run the User Story 3 focused tests and fix failures in `NextPasteTests/ClipboardCaptureTests.swift`, `NextPasteUITests/ClipRowActionsUITests.swift`, and `NextPasteTests/ClipboardImagePrivacyTests.swift` (FR-007, FR-009, FR-014, FR-015, FR-016, FR-017, FR-019, SC-003, SC-005, SC-007)

**Checkpoint**: Text behavior parity, offline/local-first behavior, and privacy boundaries are verified.

---

## Phase 6: Polish, Cross-Cutting Validation, and Release Evidence

**Purpose**: Validate the complete feature, trace every requirement, run analysis, and record project-health evidence.

- [ ] T042 Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build` and record results in `specs/006-clipboard-image-capture/quickstart.md` (FR-019, FR-020, SC-008)
- [ ] T043 Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test` and record results in `specs/006-clipboard-image-capture/quickstart.md` (FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-013, FR-014, FR-016, FR-017, FR-019, FR-021, SC-001, SC-002, SC-003, SC-005, SC-006, SC-007)
- [ ] T044 Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests test` and record results in `specs/006-clipboard-image-capture/quickstart.md` (FR-010, FR-011, FR-012, FR-013, FR-015, FR-018, FR-019, SC-001, SC-004, SC-005, SC-006)
- [ ] T045 Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` and record full regression results in `specs/006-clipboard-image-capture/quickstart.md` (FR-019, FR-020, SC-005, SC-008)
- [ ] T046 Verify every FR and SC maps to implementation and tests by updating the Requirement Traceability table in `specs/006-clipboard-image-capture/tasks.md` if implementation changes task scope (FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021, SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007, SC-008)
- [ ] T047 Run `/speckit.analyze` and address or document all findings in `specs/006-clipboard-image-capture/tasks.md` (FR-019, FR-020, SC-008)
- [ ] T048 Run the available SonarQube or SonarCloud analysis and record command/report details in `specs/006-clipboard-image-capture/sonar-evidence.md` (FR-020, SC-008)
- [ ] T049 Verify no new SonarQube Bugs, Vulnerabilities, Security Hotspots requiring review, Code Smells, Coverage violations, Reliability issues, Security issues, Maintainability issues, or New Code duplication gate failures remain, and record the result in `specs/006-clipboard-image-capture/sonar-evidence.md` (FR-020, SC-008)
- [ ] T050 Confirm Constitution compliance for clipboard-first flow, local-first storage, privacy, Apple-native implementation, design-system consistency, refactoring integrity, and Sonar evidence in `specs/006-clipboard-image-capture/sonar-evidence.md` (FR-007, FR-016, FR-017, FR-018, FR-020, SC-007, SC-008)

---

## Requirement Traceability

| Requirement | Covered by tasks |
|---|---|
| FR-001 Detect Apple-decodable raster image clipboard content | T002, T007, T012, T016, T018, T019, T022, T023, T043 |
| FR-002 Shared screenshot/copied-image pipeline and process-alive states | T007, T012, T016, T017, T018, T019, T020, T022, T023, T043 |
| FR-003 Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI | T016, T017, T018, T019, T020, T021, T023, T043 |
| FR-004 Automatically save new image clipboard content | T016, T018, T021, T023, T043 |
| FR-005 Image clips use `contentType = "image"` | T005, T010, T016, T021, T023, T043 |
| FR-006 App-private full image storage with SwiftData metadata only | T003, T005, T008, T010, T013, T021, T043 |
| FR-007 No clipboard image data transmitted outside device | T008, T013, T037, T040, T041, T050 |
| FR-008 Deduplicate by decoded pixels plus dimensions | T002, T006, T011, T012, T016, T021, T023, T043 |
| FR-009 Ignore unsupported, empty, invalid, inaccessible, oversized image data | T002, T007, T012, T021, T035, T041, T043 |
| FR-010 History refresh after image capture | T016, T018, T020, T021, T022, T023, T044 |
| FR-011 Image clips appear in existing history ordering/pinning rules | T024, T027, T029, T031, T034, T044 |
| FR-012 Display local aspect-fit thumbnails with fallback icon rules | T004, T009, T014, T024, T026, T027, T028, T033, T034, T044 |
| FR-013 Image Copy/Delete/Pin row actions and copy failure behavior | T025, T026, T030, T031, T032, T033, T034, T043, T044 |
| FR-014 Existing text auto-capture continues | T005, T017, T019, T020, T029, T035, T038, T041, T043 |
| FR-015 Existing text Copy/Delete/Pin continues | T025, T030, T031, T036, T039, T041, T044 |
| FR-016 Offline image capture/storage/history/actions | T003, T008, T013, T021, T030, T031, T037, T040, T041, T043, T050 |
| FR-017 No OCR, AI, CloudKit sync, remote transmission, third-party image libraries, or manual import | T012, T019, T037, T040, T050 |
| FR-018 Shared design-system thumbnail presentation | T004, T009, T014, T024, T027, T028, T033, T034, T044, T050 |
| FR-019 Automated tests for image capture, dedupe, rejection, persistence, UI, regressions, offline behavior | T001-T009, T015-T018, T023-T026, T034-T037, T041-T047 |
| FR-020 SonarQube Project Health evidence | T040, T042, T045, T046, T047, T048, T049, T050 |
| FR-021 No full image recompression; thumbnail derived display data only | T008, T009, T012, T013, T014, T021, T024, T027, T028, T034, T043 |
| SC-001 Image appears in history while active/backgrounded/minimized | T002, T007, T012, T016, T017, T018, T019, T020, T022, T023, T044 |
| SC-002 Repeated same decoded pixels and dimensions do not duplicate | T002, T006, T011, T012, T016, T021, T023, T043 |
| SC-003 Unsupported/empty/invalid/inaccessible/oversized image data does not create a clip | T002, T007, T012, T021, T035, T041, T043 |
| SC-004 Image thumbnail visible, non-blank, uncropped, fallback only for valid thumbnail failures | T004, T009, T014, T024, T026, T027, T028, T033, T034, T044 |
| SC-005 Existing text capture and row-action regressions pass | T001, T005, T017, T019, T020, T023, T029, T035, T036, T038, T039, T041, T043, T044, T045 |
| SC-006 Image copy/delete/pin work and copy failure shows no success | T004, T025, T026, T030, T031, T032, T033, T034, T043, T044 |
| SC-007 Offline/local-first image capture and row actions work | T003, T005, T008, T013, T021, T030, T031, T037, T040, T041, T043, T050 |
| SC-008 SonarQube evidence recorded with no unresolved introduced issues | T042, T045, T046, T047, T048, T049, T050 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies.
- **Phase 2 Foundation**: Depends on Phase 1 fixtures and baseline.
- **Phase 3 US1 MVP**: Depends on Phase 2 image validation/storage/thumbnail infrastructure.
- **Phase 4 US2**: Depends on Phase 2 and can use seeded image clips, but full copy/delete/pin UI validation depends on US1 capture integration.
- **Phase 5 US3**: Depends on US1/US2 code paths so regressions validate final routing.
- **Phase 6 Validation**: Depends on all implementation phases.

### Parallelization Notes

- `[P]` tasks in the same phase modify different files and may run in parallel after that phase's prerequisites are complete.
- Do not run tasks from later phases in parallel with earlier phases unless the earlier phase checkpoint is complete.
- Do not parallelize tasks that modify `NextPaste/ClipboardCaptureService.swift`, `NextPaste/HomeView.swift`, or `NextPasteUITests/ClipboardImageAutoCaptureUITests.swift`; those changes are intentionally serialized.
- UI helper tasks T032 and T033 are parallel because they modify different helper files and depend only on the US2 test contract.
- Phase 6 validation tasks are intentionally sequential because each result informs the next quality gate.

---

## Parallel Examples

### Phase 2 foundation

```bash
Task: "T006 Add decoded-pixel hash tests in NextPasteTests/ImageDuplicateIdentityTests.swift"
Task: "T008 Add file store tests in NextPasteTests/ImageClipFileStoreTests.swift"
Task: "T009 Add thumbnail generator tests in NextPasteTests/ImageThumbnailGeneratorTests.swift"
```

### User Story 1 tests

```bash
Task: "T016 Add image capture service tests in NextPasteTests/ClipboardImageCaptureTests.swift"
Task: "T017 Add monitor payload tests in NextPasteTests/ClipboardCaptureTests.swift"
Task: "T018 Add image auto-capture UI tests in NextPasteUITests/ClipboardImageAutoCaptureUITests.swift"
```

### User Story 2 helpers

```bash
Task: "T032 Add image row targeting in NextPasteUITests/RowRobot.swift"
Task: "T033 Add image thumbnail assertions in NextPasteUITests/UITestAssertions.swift"
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 only.
3. Validate image auto-capture for supported images, screenshots, deduplication, and active/backgrounded/minimized app states.
4. Stop and demo an image clip appearing in history without manual saving.

### Incremental Delivery

1. Add foundation: model metadata, image validation, file storage, thumbnail generation.
2. Add US1: shared clipboard payload pipeline and automatic image capture.
3. Add US2: thumbnail row display and image copy/delete/pin.
4. Add US3: text regressions, privacy/local-first verification, and out-of-scope safeguards.
5. Run full validation, `/speckit.analyze`, SonarQube, and evidence recording.

---

## Validation Checklist

| Validation item | Required task(s) |
|---|---|
| Required automated tests executed | T015, T023, T034, T041, T043, T044, T045 |
| Every FR and SC verified against tasks and implementation | T046 |
| `/speckit.analyze` run and findings addressed | T047 |
| SonarQube analysis run or unavailable-state evidence recorded | T048 |
| No new SonarQube issues introduced | T049 |
| New Code duplication within configured quality gate | T049 |
| Clipboard-first and automatic capture flow preserved | T046, T050 |
| Local-first and privacy-by-default preserved | T040, T050 |
| Apple-native-only constraint preserved | T040, T050 |
| Shared design system preserved | T034, T044, T050 |
| Refactoring integrity and text regressions preserved | T035, T036, T038, T039, T041, T050 |
