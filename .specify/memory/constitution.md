<!--
Sync Impact Report
Version change: 1.0.0 -> 2.0.0
Modified principles:
- I. AI-First Product Design -> I. Clipboard-First Product
- II. Local-First Architecture -> II. Local-First Architecture
- III. Privacy by Default -> III. Privacy by Default
- IV. Test-First Development -> IV. Automatic Capture
- V. Simplicity Over Complexity -> V. Test-First Development
- Added principle: VI. Simplicity and Apple-Native Stack
Added sections:
- None
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

### I. Clipboard-First Product

The system clipboard is the primary source of clips. When the app is running and the system
clipboard changes, NextPaste MUST automatically save the new clipboard content as a local clip
without requiring user confirmation. Manual clip creation is secondary and optional. The default
workflow for core product behavior MUST remain `Clipboard Changed -> Detect -> Validate ->
Deduplicate -> Persist -> Refresh UI`.

Rationale: NextPaste now exists first to capture clipboard history reliably and instantly, so the
product must optimize for passive capture instead of manual save flows.

### II. Local-First Architecture

Clipboard capture MUST work without internet, CloudKit, AI services, or external APIs. All
captured clipboard content MUST be saved locally first using SwiftData-backed models before any
optional sync or network feature runs. Network failure MUST NOT block clipboard monitoring,
capture, persistence, sorting, retrieval, or history display. CloudKit synchronization is
secondary and MUST be designed as replication of local state, not as the source of truth.

Rationale: Clipboard history is only trustworthy when capture and recall continue to work
regardless of connectivity or remote service state.

### III. Privacy by Default

Clipboard content belongs to the user. Clipboard monitoring and capture MUST happen on-device. The
app MUST NOT transmit clipboard data outside the device unless the user explicitly enables sync,
export, or another clearly scoped transmission flow. The app MUST NOT include Firebase, analytics
SDKs, advertising SDKs, behavioral telemetry, or other third-party telemetry. Any remote
processing feature requires explicit user consent, documented data scope, retention assumptions,
and a local-first fallback before implementation.

Rationale: Clipboard history can contain highly sensitive personal and professional information, so
trust depends on keeping monitoring and storage private by default.

### IV. Automatic Capture

When clipboard content changes while the app is running, the app MUST detect the new content,
identify the content type, ignore duplicate content, persist a new clip, and refresh the history
list. Users MUST NOT need to press Save for normal clipboard capture. Any feature that interrupts,
delays, or bypasses the automatic capture pipeline requires explicit justification in the
specification and plan.

Rationale: Automatic capture is the core product behavior and the main promise of a
clipboard-first app.

### V. Test-First Development

Every new feature MUST include automated tests before it is considered complete. Clipboard behavior
MUST be tested, including monitoring, content-type identification, deduplication, local
persistence, row actions, sorting, and offline behavior. Critical user flows, including capture,
retrieval, consent, and optional sync/export behaviors, MUST include UI or integration coverage.
Features that add AI output MUST also validate typed result contracts and failure behavior.

Rationale: Clipboard-first behavior is easy to regress in subtle ways, and automated coverage is
required to keep capture, privacy, and history behavior reliable as the app evolves.

### VI. Simplicity and Apple-Native Stack

Implementation MUST prefer Apple-native frameworks and the smallest design that satisfies the
specification. Approved technologies are SwiftUI, SwiftData, Observation, Vision, Foundation
Models, Foundation, and CloudKit. CloudKit is optional synchronization and MUST NOT be required
for clipboard capture. Dependencies or abstractions MUST be justified by a concrete capability gap,
must not duplicate platform functionality, and must not weaken privacy or offline guarantees.
Firebase, analytics SDKs, advertising SDKs, and unnecessary third-party dependencies are
prohibited unless this constitution is amended first.

Rationale: A focused Apple-native stack keeps the capture path fast, understandable, local-first,
and easier to maintain.

## Technical Constraints

NextPaste is a clipboard-first Apple app built with SwiftUI. Persistence MUST use SwiftData for
local storage, and clipboard monitoring MUST rely on Apple-native platform APIs. CloudKit MAY be
used only as optional synchronization after local clipboard behavior is defined, implemented, and
tested. Vision is the default OCR path for image clips, and Foundation Models are an optional
on-device analysis path that MUST remain outside the required clipboard capture pipeline.

Specifications and plans MUST identify any deviation from these defaults, explain why Apple-native
or on-device options are insufficient, document privacy impact, and add tests covering the
deviation. No feature may introduce Firebase, analytics SDKs, advertising SDKs, React Native,
Flutter, or broad third-party SDK adoption without a constitution amendment.

## Development Workflow & Quality Gates

Feature work MUST flow through the Spec Kit lifecycle in this order unless an explicit exception is
documented: `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`,
`/speckit.analyze`, and `/speckit.implement`.

Each specification MUST define the clipboard-triggered user flow, content-type handling,
deduplication rules, measurable acceptance criteria, privacy expectations, offline behavior, and
any optional manual creation or sync/export scope. Each plan MUST pass a Constitution Check before
Phase 0 research and again after Phase 1 design. Each task list MUST map implementation and test
tasks back to specification requirements and user stories, including clipboard monitoring and local
persistence coverage where applicable.

Before release, reviewers MUST verify that all requirements trace to implementation tasks, all
tasks map back to a specification, acceptance criteria are measurable, automated tests cover new
behavior, clipboard capture stays local-first, and privacy plus offline support have been
reviewed.

## Governance

This constitution supersedes conflicting project practices, templates, and implementation plans.
When conflicts are found, the constitution governs unless it is amended first.

Every constitution amendment MUST include the proposed text, rationale, impact on existing
specifications or features, migration guidance for affected templates or code, and a Sync Impact
Report. Amendments require explicit project-owner approval before dependent artifacts are updated.
Every amendment MUST increment the constitution version. Any amendment that removes or redefines a
core principle in a backward-incompatible way requires a MAJOR version bump. Adding a new
principle, mandatory section, or materially expanding governance requires a MINOR version bump.
Clarifications, wording changes, and non-semantic corrections require a PATCH version bump. A
product-direction change that redefines the primary source or capture behavior of clips is a MAJOR
change.

Every `/speckit.plan` output MUST include a Constitution Check. Every `/speckit.analyze` review
MUST flag contradictions between spec, plan, tasks, and this constitution. Release readiness
review MUST confirm compliance with clipboard-first behavior, local-first storage, privacy
protections, automated testing, and Apple-native simplicity constraints.

**Version**: 2.0.0 | **Ratified**: 2026-06-24 | **Last Amended**: 2026-06-25
