# [Project Name] Constitution

## Core Principles

### I. Clipboard-First Product
[Define product trigger flow, e.g., Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI. Manual flows are secondary and optional.]

### II. Local-First Architecture
[Define local storage source of truth. Network-failure/sync failure MUST NOT block core capture or retrieval.]

### III. Privacy by Default
[All telemetry, behavior tracking, and third-party monitoring SDKs are prohibited. Document explicit consent requirements for any user data transmission.]

### IV. Automatic Capture
[Describe automatic, passive capture requirements and how capture pipeline interruptions are forbidden without explicit spec justifications.]

### V. Test-First Development
[Automated tests MUST be written first. Define coverage rules for core pipelines, user flows, and integrations.]

### VI. Test Execution Efficiency
[Layered, proportional validation strategy: targeted unit, targeted integration, targeted UI, and full regression only at defined gates.]

### VII. Native Simplicity & Platform Stack
[Prefer target platform native frameworks, APIs, and components over custom event/gesture models or third-party abstractions.]

### VIII. Consistent Design System
[User-facing UI MUST use shared design tokens and establish no undocumented visual patterns.]

### IX. Refactoring Integrity
[Refactoring MUST preserve observable behavior with regression coverage and introduce no speculative abstractions.]

### X. Validation Governance
[Validation Contract is the single validated source of truth. Feature specs, plans, tasks, and checklists reference validation instead of redefining it.]

### XI. Template-First Governance
[Repeated documentation structures MUST be promoted to templates. Plans, tasks, checklists inherit structure from templates.]

### XII. Apple Platform Consistency
[Declare supported Apple platforms explicitly, preserve equivalent business behavior, and enforce Apple Human Interface Guidelines.]

## Technical Constraints

[Specify permissible languages, database/persistence frameworks, UI systems, and prohibited SDKs or libraries.]

## Development Workflow & Quality Gates

[Define the Spec Kit lifecycle commands: specify, clarify, plan, tasks, analyze, implement. Set the SonarQube Project Health Gate rules.]

## Governance

Constitution amendments require Proposed Text, Rationale, Migration Guidance, and a Sync Impact Report, incrementing the version accordingly.

**Version**: 1.0.0 | **Ratified**: [Ratification Date] | **Last Amended**: [Last Amended Date]
