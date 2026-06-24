<!--
Sync Impact Report
Version change: unratified template -> 1.0.0
Modified principles:
- PRINCIPLE_1_NAME -> I. AI-First Product Design
- PRINCIPLE_2_NAME -> II. Local-First Architecture
- PRINCIPLE_3_NAME -> III. Privacy by Default
- PRINCIPLE_4_NAME -> IV. Test-First Development
- PRINCIPLE_5_NAME -> V. Simplicity Over Complexity
Added sections:
- Technical Constraints
- Development Workflow & Quality Gates
Removed sections:
- None
Templates requiring updates:
- ✅ .specify/templates/plan-template.md
- ✅ .specify/templates/spec-template.md
- ✅ .specify/templates/tasks-template.md
- ✅ .specify/templates/checklist-template.md
- ✅ .github/copilot-instructions.md
- ✅ .specify/templates/commands/*.md (no command templates present)
Follow-up TODOs: None
-->

# NextPaste Constitution

## Core Principles

### I. AI-First Product Design

Every feature MUST help users turn saved text or images into actionable outcomes: summaries,
categories, decisions, reminders, follow-ups, or other next steps. AI-generated insights are a
core product capability, not a garnish; specifications MUST define how a feature improves user
productivity or reduces manual interpretation. Features that do not create, improve, validate,
or safely support actionable content workflows MUST be rejected or deferred.

Rationale: NextPaste exists to transform copied content into actions, so product scope must stay
anchored to concrete user progress instead of passive storage.

### II. Local-First Architecture

User data MUST be stored locally first using SwiftData-backed models before any cloud dependency
is introduced. Core capture, browsing, search, and previously generated insight access MUST work
offline whenever technically possible. CloudKit synchronization is secondary to local availability
and MUST be designed as replication of local state, not as the source of truth.

Rationale: Clipboard-derived content is often needed in the moment, including without network
access, and local ownership keeps the product reliable and predictable.

### III. Privacy by Default

User content is private by default. The app MUST NOT include third-party analytics SDKs, behavioral
tracking SDKs, or unnecessary third-party services. User content MUST NOT be transmitted to external
services without explicit user approval for the specific operation. AI and OCR features SHOULD prefer
Apple Vision, Foundation Models, and other on-device capabilities whenever they can satisfy the user
need. Any feature that requires remote processing MUST document the data sent, user consent flow,
retention assumptions, and local fallback behavior before implementation.

Rationale: NextPaste handles arbitrary copied text and images, which may include sensitive personal,
professional, or credential-adjacent information.

### IV. Test-First Development

New features MUST include automated tests mapped to their specification requirements before they are
considered complete. Critical user flows, including capture, retrieval, AI insight generation, consent,
and sync conflict handling, MUST include UI or integration coverage. AI outputs MUST be validated
against defined schemas or typed result contracts, with tests for valid output, malformed output, and
failure states. Regressions MUST be prevented through repeatable verification using the project test
targets and any feature-specific checks documented in the plan.

Rationale: AI-assisted workflows can fail subtly, and a local-first privacy product must prove that
data handling, consent, and generated outcomes remain correct as features evolve.

### V. Simplicity Over Complexity

Implementation MUST prefer Apple native frameworks and the smallest design that satisfies the
specification. SwiftUI, SwiftData, CloudKit, Vision OCR, and Foundation Models are the default choices
for UI, persistence, sync, OCR, and AI. Dependencies MUST be justified by a concrete capability gap,
must not duplicate platform functionality, and must not weaken privacy or offline guarantees. Firebase,
React Native, Flutter, and unnecessary third-party SDKs are prohibited unless this constitution is
amended with explicit rationale. MVP delivery speed is preferred over premature optimization, provided
privacy, offline behavior, and tests remain intact.

Rationale: A focused native stack reduces maintenance burden, improves platform fit, and keeps the
product small enough to ship quickly without compromising trust.

## Technical Constraints

NextPaste is an iOS-first product built with SwiftUI. Persistence MUST use SwiftData for local storage,
and CloudKit MAY be used for synchronization only after local behavior is defined and tested. Vision
Framework is the default OCR path for extracting text from images. Foundation Models and Apple
on-device AI capabilities are the default AI implementation path when available and suitable.

Specifications and plans MUST identify any deviation from these defaults, explain why Apple-native or
on-device options are insufficient, document privacy impact, and add tests covering the deviation.
No feature may introduce Firebase, React Native, Flutter, third-party analytics, or broad third-party
SDK adoption without a constitution amendment.

## Development Workflow & Quality Gates

Feature work MUST flow through the Spec Kit lifecycle in this order unless an explicit exception is
documented: `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`,
`/speckit.analyze`, and `/speckit.implement`.

Each specification MUST define measurable acceptance criteria, traceable functional requirements,
privacy expectations, offline behavior, and the user productivity outcome. Each plan MUST pass a
Constitution Check before Phase 0 research and again after Phase 1 design. Each task list MUST map
implementation and test tasks back to specification requirements and user stories.

Before release, reviewers MUST verify that all requirements trace to implementation tasks, all tasks
map back to a specification, acceptance criteria are measurable, automated tests cover new behavior,
AI outputs use defined validation contracts, and privacy plus offline support have been reviewed.

## Governance

This constitution supersedes conflicting project practices, templates, and implementation plans. When
conflicts are found, the constitution governs unless it is amended first.

Amendments MUST include the proposed text, rationale, impact on existing specifications or features,
and migration guidance for affected templates or code. Amendments require explicit project-owner
approval before dependent artifacts are updated. Any amendment that removes or redefines a core
principle in a backward-incompatible way requires a MAJOR version bump. Adding a new principle,
mandatory section, or materially expanding governance requires a MINOR version bump. Clarifications,
wording changes, and non-semantic corrections require a PATCH version bump.

Every `/speckit.plan` output MUST include a Constitution Check. Every `/speckit.analyze` review MUST
flag contradictions between spec, plan, tasks, and this constitution. Release readiness review MUST
confirm compliance with AI-first value, local-first behavior, privacy consent, automated testing,
and simplicity constraints.

**Version**: 1.0.0 | **Ratified**: 2026-06-24 | **Last Amended**: 2026-06-24
