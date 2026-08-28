# Roadmap: GSD Core Contributions

## Overview

Milestone v1.2 delivers the maintainer-approved #3159 escape hatch for hosts whose orchestrator session ends with the turn. The work remains confined to an opt-out configuration key, the execute-phase dispatch condition, an ADR, user-facing configuration documentation, generated artifacts, and focused verification. It does not alter default behavior or bundle unrelated executor safety work.

## Milestones

- ✅ **v1.0 State Integrity** - Phase 1 shipped 2026-08-04; details are archived in [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md).
- ✅ **v1.1 State Diagnostics** - Phase 2 restored active-phase drift diagnostics through the existing validator.
- 🚧 **v1.2 Executor Session Survivability** - Phase 3 adds the #3159 opt-out for one-shot executor sessions.

## Phases

**Phase Numbering:**

- Integer phases are planned milestone work and continue across milestones.
- Decimal phases are urgent insertions between planned phases.

### Milestone v1.1 — State Diagnostics

- [x] **Phase 2: State Validation Drift Diagnostics** - Resolve the active phase from shipped state metadata and prove that `state.validate` reports real disk drift. (completed 2026-08-22)

### Milestone v1.2 — Executor Session Survivability

- [ ] **Phase 3: Configured Session-Survivability Dispatch** - Let a host opt out of asynchronous executor dispatch when its parent session cannot collect results.

## Phase Details

## Milestone v1.1 — State Diagnostics (Phase Details)

### Phase 2: State Validation Drift Diagnostics

**Goal**: Contributors can rely on `state.validate` to resolve the active phase from a normal shipped `STATE.md` document and report drift against the corresponding phase artifacts on disk.
**Depends on**: Phase 1
**Requirements**: STATE-02, QUALITY-02
**Success Criteria** (what must be TRUE):

  1. A contributor running `state.validate` with `current_phase` present in `STATE.md` frontmatter receives drift findings for that active phase's on-disk artifacts.
  2. When `current_phase` is absent, the same validation resolves the canonical body `Phase:` field and still performs the on-disk drift checks; when both forms exist, frontmatter remains authoritative.
  3. A maintainer can run a focused regression that uses the shipped state-document shape and proves the validator reaches and reports a known disk-drift condition.

**Plans**: 1/1 plans executed

- [x] 02-01-PLAN.md

## Milestone v1.2 — Executor Session Survivability (Phase Details)

### Phase 3: Configured Session-Survivability Dispatch

**Goal**: Give host integrators an explicit, default-preserving opt-out from background executor dispatch when their parent session does not survive the turn.
**Depends on**: N/A
**Requirements**: SESSION-01, SESSION-02, SESSION-03, QUALITY-03, COMPAT-01
**Success Criteria** (what must be TRUE):

  1. A host can explicitly configure its executor session as not outliving the turn, and `execute-phase` directs every executor dispatch through the foreground, awaited path.
  2. With the configuration absent or enabled, the current background-dispatch path remains unchanged.
  3. An ADR and configuration reference distinguish tool availability from session survivability and document the opt-out's default-preserving contract.
  4. Focused behavioral and emitted-artifact checks exercise both values; each check includes an opposite-direction control.

**Plans**: 0/0 plans executed

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 2. State Validation Drift Diagnostics | v1.1 | 1/1 | Complete | 2026-08-22 |
| 3. Configured Session-Survivability Dispatch | v1.2 | 0/0 | Not Started |  |
