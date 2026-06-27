# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]

**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]

**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]

**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]

**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]

**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]

**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]

**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]

**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Clipboard-first product**: The primary trigger is clipboard change detection, and the default
  workflow is `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
  Manual clip creation is secondary and optional.
- **Local-first architecture**: SwiftData local storage is the source of truth. Clipboard capture,
  browsing, retrieval, sorting, and row actions work without network access. CloudKit is optional
  replication, not a prerequisite for core use.
- **Privacy by default**: Clipboard monitoring stays on-device. No Firebase, analytics SDKs,
  advertising SDKs, or third-party telemetry. Any clipboard-data transmission requires explicit
  user opt-in, documented data scope, retention assumptions, and local fallback behavior.
- **Automatic capture**: The plan defines content-type identification, duplicate handling,
  persistence, and history refresh behavior for clipboard changes while the app is running.
- **Test-first coverage**: Automated tests are planned for each new requirement. Clipboard behavior
  includes monitoring, deduplication, local persistence, row actions, sorting, and offline
  coverage. Features with AI outputs add typed contract validation and failure tests.
- **Native simplicity**: SwiftUI, SwiftData, Observation, Vision, Foundation Models, Foundation,
  and CloudKit are the default choices. Any dependency or platform deviation is justified with a
  concrete capability gap and privacy impact.
- **SonarQube project health gate**: After `/speckit.implement`, the feature is not complete until
  SonarQube Project Health shows zero unresolved feature-introduced issues, or documented false
  positives with justification, and evidence is recorded before commit or PR completion.
- **Consistent design system**: User-facing UI follows shared design tokens for colors,
  typography, spacing, radius, iconography, motion, and component styling. New visual patterns are
  justified in the specification and documented in the design system.
- **Refactoring integrity**: Refactors preserve existing observable behavior unless the
  specification explicitly defines behavior changes, include regression coverage for behavior
  parity, and avoid speculative abstractions.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
