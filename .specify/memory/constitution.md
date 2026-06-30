<!--
Sync Impact Report
Version change: 2.3.0 -> 2.4.0
Modified principles:
- Added principle: VI. Test Execution Efficiency
- Renumbered principle: VI. Simplicity and Apple-Native Stack -> VII. Simplicity and Apple-Native Stack
- Renumbered principle: VII. SonarQube Project Health Gate -> VIII. SonarQube Project Health Gate
- Renumbered principle: VIII. Consistent Design System -> IX. Consistent Design System
- Renumbered principle: IX. Refactoring Integrity -> X. Refactoring Integrity
- Renumbered principle: X. Validation Governance -> XI. Validation Governance
- Renumbered principle: XI. Template-First Governance -> XII. Template-First Governance
- Renumbered principle: XII. Native Apple User Experience -> XIII. Native Apple User Experience
Added sections:
- Development workflow tiered validation rules
- Governance test-efficiency rules
Removed sections:
- None
Templates requiring updates:
- ✅ .specify/templates/plan-template.md
- ✅ .specify/templates/tasks-template.md
- ✅ .specify/templates/checklist-template.md
- ✅ .specify/templates/contracts/validation-and-sonar-contract.md
- ✅ .github/copilot-instructions.md
- ✅ .github/agents/speckit.plan.agent.md
- ✅ .github/agents/speckit.tasks.agent.md
- ✅ .github/agents/speckit.analyze.agent.md
Follow-up TODOs:
- Consider adding `.specify/templates/quickstart-template.md` if quickstart generation becomes template-driven.
-->

# NextPaste Constitution

## Core Principles

### I. Clipboard-First Product

The system clipboard is the primary source of clips. When the app is running and the system
clipboard changes, NextPaste MUST automatically save the new clipboard content as a local clip
without requiring user confirmation. Manual clip creation is secondary and optional. The default
workflow for core product behavior MUST remain `Clipboard Changed -> Detect -> Validate ->
Deduplicate -> Persist -> Refresh UI`.

Rationale: NextPaste exists first to capture clipboard history reliably and instantly, so the
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

### VI. Test Execution Efficiency

Automated validation MUST be layered and proportional to the change being made. Feature tasks MUST
prefer the smallest reliable test scope first. Unit tests MUST be preferred for pure logic.
Integration tests MUST cover cross-component behavior. UI tests MUST be reserved for user-visible
flows that cannot be reliably validated at lower levels, and they MUST avoid duplicating coverage
already provided by unit or integration tests.

Full regression MUST NOT be required after every individual task. Full regression MUST be required
only at feature completion, release readiness, or when a change affects shared infrastructure,
persistence, app launch, navigation, or cross-cutting interaction behavior. Tasks MUST specify
targeted test commands before full-suite commands. If full regression is mandatory, the reason MUST
be documented. Manual validation MUST not duplicate automated validation unless platform-native
behavior cannot be simulated reliably. Test helpers, fixtures, and launch modes SHOULD be optimized
to reduce runtime while preserving behavior parity.

Rationale: Validation confidence depends on running the right tests at the right layer. Tiered
execution keeps Test-First Development practical, reduces unnecessary runtime, and preserves
release-quality confidence for shared or high-risk changes.

### VII. Simplicity and Apple-Native Stack

Implementation MUST prefer Apple-native frameworks and the smallest design that satisfies the
specification. Approved technologies are SwiftUI, SwiftData, Observation, Vision, Foundation
Models, Foundation, and CloudKit. CloudKit is optional synchronization and MUST NOT be required
for clipboard capture. Dependencies or abstractions MUST be justified by a concrete capability gap,
must not duplicate platform functionality, and must not weaken privacy or offline guarantees.
Firebase, analytics SDKs, advertising SDKs, and unnecessary third-party dependencies are
prohibited unless this constitution is amended first.

Rationale: A focused Apple-native stack keeps the capture path fast, understandable, local-first,
and easier to maintain.

### VIII. SonarQube Project Health Gate

After `/speckit.implement` completes for any feature, the SonarQube Project Health dashboard MUST
show zero unresolved issues for the implemented change before the feature is considered complete.
The required post-implementation state is: Bugs 0, Vulnerabilities 0, Security Hotspots requiring
review 0, Code Smells 0, Coverage violations 0, Reliability issues 0, Security issues 0, and
Maintainability issues 0. Duplications on New Code MUST be 0, or within the configured quality
gate threshold when SonarQube reports duplication as a percentage-based gate.

Any SonarQube issue introduced by the feature MUST be fixed or explicitly documented as a false
positive with justification. SonarQube evidence MUST be recorded before commit or PR completion and
MAY be a SonarQube dashboard screenshot, SonarCloud URL, CI artifact, or local report. This gate
applies to production code and test code unless a file is explicitly excluded by project policy.
Feature specifications, plans, tasks, and checklists MUST NOT weaken, bypass, or redefine this
gate.

Rationale: Automated implementation checks are incomplete without project-health evidence from the
quality system that reviewers use to identify reliability, security, maintainability, coverage, and
duplication regressions.

### IX. Consistent Design System

All user-facing interfaces MUST follow the project's design system. New screens MUST reuse the
established design language. Colors, typography, spacing, corner radius, iconography, motion, and
component styling MUST follow shared design tokens. Components SHOULD be reused before new visual
patterns are created. New visual patterns MUST be justified in the specification and documented in
the design system. Temporary or feature-specific UI styles MUST NOT become permanent design
patterns. Features MUST preserve visual consistency across all supported Apple platforms.

Rationale: A consistent visual language reduces cognitive load, improves usability, and keeps the
product feeling cohesive as features grow.

### X. Refactoring Integrity

Refactoring exists to improve maintainability without changing user-visible behavior. Every
refactor MUST preserve existing observable behavior unless the specification explicitly defines
behavioral changes. Refactoring SHOULD reduce complexity, duplication, coupling, or maintenance
cost. Refactors MUST include regression tests demonstrating behavior parity. Refactors MUST NOT
introduce speculative abstractions or unnecessary architecture. Refactoring tasks MUST clearly
identify the behavior being preserved. Any intentional behavior change requires a new specification
rather than being hidden inside a refactor.

Rationale: Refactoring should improve code quality while maintaining predictable product behavior
and minimizing regression risk.

### XI. Validation Governance

Every feature MUST inherit a standardized validation structure from the Spec Kit templates rather
than redefining validation artifacts independently. The Validation Contract is the single source of
truth for the automated validation matrix, manual validation matrix, regression validation matrix,
SonarQube Project Health evidence, offline and local-first validation, accessibility validation,
platform-specific validation, performance validation, and release-readiness validation.

`quickstart.md` MUST contain only build commands, test commands, execution instructions, and
references to the Validation Contract. Specifications, plans, tasks, and checklists MUST reference
the Validation Contract instead of duplicating validation rules, evidence matrices, or regression
definitions. Validation ownership MUST remain centralized to prevent documentation drift, ownership
conflicts, duplicate matrices, inconsistent Sonar requirements, and divergent manual validation
procedures. Any new validation type MUST first be added to the Validation Contract template before
it may appear in a feature artifact.

Rationale: Validation is project infrastructure, not feature logic. Centralizing validation reduces
maintenance cost while improving consistency, review quality, and release readiness.

### XII. Template-First Governance

Any documentation structure that appears in three or more independent features MUST be promoted
into a shared Spec Kit template. Feature artifacts MUST inherit shared project structure from
templates instead of redefining it locally. Examples include requirement traceability tables,
validation matrices, SonarQube evidence, manual validation sections, regression checklists,
performance validation, accessibility validation, platform validation, risk tables, rollback
sections, and review checklists.

Templates are the authoritative definition of shared documentation structure. Feature artifacts MAY
extend templates only with feature-specific information and MUST NOT redefine template-owned
structures. Shared templates MUST include a standard tiered test strategy. `quickstart.md` MUST
list targeted commands first and full regression only as a final gate. The Validation Contract MUST
distinguish targeted validation from final regression validation.

Rationale: Repeated documentation eventually diverges. Template-first governance keeps every
feature consistent while reducing maintenance effort and documentation drift.

### XIII. Native Apple User Experience

All user-facing interactions MUST follow native interaction patterns of the target Apple platform
and MUST feel native rather than application-specific. Implementations MUST prefer Apple-native
interaction APIs and behaviors over custom interaction models whenever equivalent platform
functionality exists. Features MUST NOT replace, redefine, or conflict with Apple platform
interaction conventions without explicit product justification documented in the specification.
Applicable interaction methods include macOS trackpad gestures, Magic Mouse gestures, mouse
interactions, keyboard shortcuts, context menus, drag and drop, focus behavior, scrolling
behavior, multi-selection behavior, accessibility actions, VoiceOver support, and standard Apple
navigation patterns. Any intentional deviation from Apple Human Interface Guidelines (HIG) MUST be
documented and justified in the specification before implementation begins.

Rationale: NextPaste succeeds when it behaves like a natural part of Apple platforms, so the
product must protect the interaction conventions and accessibility behaviors users already know.

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

Apple-native interaction APIs MUST be preferred over custom gesture or event-handling
implementations whenever technically feasible. Gesture recognizers, event handling, focus,
scrolling, selection, context-menu, drag-and-drop, keyboard, mouse, trackpad, and accessibility
interaction models SHOULD follow Apple platform conventions unless the specification documents an
explicit product justification. Third-party interaction frameworks SHOULD NOT be introduced; if one
is proposed, this constitution MUST be amended first.

## Development Workflow & Quality Gates

Feature work MUST flow through the Spec Kit lifecycle in this order unless an explicit exception is
documented: `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`,
`/speckit.analyze`, and `/speckit.implement`. After `/speckit.implement`, the SonarQube Project
Health Gate MUST pass before the feature is complete.

Each specification MUST define the clipboard-triggered user flow, content-type handling,
deduplication rules, measurable acceptance criteria, privacy expectations, offline behavior, and
any optional manual creation or sync/export scope. Each plan MUST pass a Constitution Check before
Phase 0 research and again after Phase 1 design. Each task list MUST map implementation work back
to specification requirements and user stories, including clipboard monitoring and local
persistence coverage where applicable.

Each feature MUST create or inherit `contracts/validation-and-sonar-contract.md` as the canonical
validation source. That contract owns the automated validation matrix, manual validation matrix,
regression validation matrix, offline and local-first validation, accessibility validation,
platform-specific validation, performance validation, release-readiness validation, and SonarQube
evidence requirements. Specifications, plans, tasks, and checklists MUST reference that contract
instead of duplicating its template-owned structures. `quickstart.md` MUST remain an execution
guide only and MUST contain only build commands, test commands, execution instructions, and
references to the Validation Contract.

Each `tasks.md` MUST include a tiered validation strategy in this order: 1. targeted unit tests,
2. targeted integration tests, 3. targeted UI tests, 4. full regression only at defined gates,
and 5. SonarQube evidence after implementation. Targeted validation commands MUST appear before
full-suite commands. Full regression is required only at feature completion, release readiness, or
when the change affects shared infrastructure, persistence, app launch, navigation, or cross-
cutting interaction behavior. If full regression is required, the reason MUST be documented.

Manual validation MUST supplement automated validation rather than duplicate it, unless
platform-native behavior cannot be simulated reliably. UI test coverage MUST not restate coverage
already provided by reliable unit or integration tests. Test helpers, fixtures, and launch modes
SHOULD be optimized to reduce runtime while preserving behavior parity.

Shared documentation structures MUST originate from `.specify/templates/`. Plans MUST reference
templates instead of reproducing shared governance rules. Tasks MUST reference template-owned
validation instead of redefining validation ownership. Risk tables, rollback sections, review
checklists, validation matrices, and similar repeated structures MUST be maintained in templates
and populated with feature-specific content only.

Every specification that changes user interaction MUST describe affected interaction methods,
including applicable keyboard shortcuts, context menus, drag and drop, focus, scrolling,
multi-selection, trackpad, Magic Mouse, mouse, accessibility actions, VoiceOver behavior, and
navigation patterns. Each plan MUST identify impacted interaction models, the Apple-native APIs or
behaviors being reused, any manual validation required for native interactions that automated UI
tests cannot faithfully simulate, and any intentional HIG deviation with explicit product
justification. Each task list MUST include automated interaction tests where reliable and
implementation tasks that preserve native interaction behavior unless the specification explicitly
changes it. Validation execution details for those interaction methods MUST live in the Validation
Contract rather than being restated in other artifacts.

Before release, reviewers MUST verify that all requirements trace to implementation tasks, all
tasks map back to a specification, acceptance criteria are measurable, automated tests cover new
behavior, clipboard capture stays local-first, privacy plus offline support have been reviewed, and
the Validation Contract has been executed without duplicated ownership elsewhere. Reviewers MUST
also verify that SonarQube evidence is recorded and that no unresolved feature-introduced
SonarQube issues remain, except documented false positives with justification. User-facing changes
MUST be reviewed for design-system consistency. Refactors MUST be reviewed for behavior parity,
reduced maintenance cost, and absence of speculative architecture.

## Governance

This constitution supersedes conflicting project practices, templates, implementation plans, and
feature artifacts. When conflicts are found, the constitution governs unless it is amended first.

**Validation**: The Validation Contract is the canonical validation source. `quickstart.md` is an
execution guide only. Specifications, plans, tasks, and checklists reference validation instead of
redefining it. SonarQube evidence requirements are inherited from the Validation Contract. No
feature may duplicate validation matrices. Targeted validation commands MUST be listed before full
regression commands, and final regression gates MUST be clearly distinguished from targeted
validation.

**Templates**: Spec Kit templates are the authoritative project documentation model. Shared
documentation structures MUST originate from templates. Feature artifacts may extend templates only
with feature-specific content. Repeated documentation MUST be promoted into templates before it is
repeated locally again. Shared templates MUST include the standard tiered test strategy and define
when full regression becomes mandatory.

**Constitution**: `/speckit.analyze` MUST report duplicated validation ownership, duplicated
template-owned structures, inconsistent template inheritance, and feature-local redefinition of
template-owned structures as Constitution Alignment violations. Duplicated template-owned structure
MUST also be reported as Documentation Drift. `/speckit.plan` MUST reference templates instead of
reproducing shared governance and MUST generate quickstart execution guides with targeted commands
before any final regression gate. `/speckit.tasks` MUST reference template-owned validation instead
of redefining validation ownership. `/speckit.analyze` MUST also flag unnecessary full-regression
requirements, duplicated UI test coverage, or overly broad validation commands. `/speckit.tasks`
MUST generate targeted validation tasks before full regression tasks.

Every constitution amendment MUST include the proposed text, rationale, impact on existing
specifications or features, migration guidance for affected templates or code, and a Sync Impact
Report. Amendments require explicit project-owner approval before dependent artifacts are updated.
Every amendment MUST increment the constitution version. Any amendment that removes or redefines a
core principle in a backward-incompatible way requires a MAJOR version bump. Adding a new
principle, mandatory section, or materially expanding governance requires a MINOR version bump.
Clarifications, wording changes, and non-semantic corrections require a PATCH version bump. A
product-direction change that redefines the primary source or capture behavior of clips is a MAJOR
change.

The SonarQube Project Health Gate, Test-First Development, Test Execution Efficiency, Validation
Governance, Template-First Governance, design-system requirements, native Apple user experience
requirements, privacy and local-first requirements, and refactoring-integrity requirements may be
changed, weakened, or waived only through a constitution amendment.

**Version**: 2.4.0 | **Ratified**: 2026-06-24 | **Last Amended**: 2026-06-30
