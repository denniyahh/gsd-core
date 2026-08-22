# Roadmap: GSD Core Contributions

## Overview

Milestone v1.1 repairs the existing `state.validate` path so the shipped `STATE.md` shape resolves its active phase and reaches real on-disk drift comparison. The repair remains confined to ledger item 12 and includes focused regression coverage; item 11 and a new `state.verify-against-disk` command remain deferred.

## Milestones

- ✅ **v1.0 State Integrity** - Phase 1 shipped 2026-08-04; details are archived in [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md).
- 🚧 **v1.1 State Diagnostics** - Phase 2 restores active-phase drift diagnostics through the existing validator.
- 🚧 **v1.2 Executor Safety** - Phase 3 introduces execution guards for branch protection and one-shot agent lifetimes.

## Phases

**Phase Numbering:**

- Integer phases are planned milestone work and continue across milestones.
- Decimal phases are urgent insertions between planned phases.

### Milestone v1.1 — State Diagnostics

- [x] **Phase 2: State Validation Drift Diagnostics** - Resolve the active phase from shipped state metadata and prove that `state.validate` reports real disk drift. (completed 2026-08-22)

### Milestone v1.2 — Executor Safety

- [ ] **Phase 3: Executor Safety and Branching Guard** - Prevent accidental commits to integration branches and support one-shot executors.

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

## Milestone v1.2 — Executor Safety (Phase Details)

### Phase 3: Executor Safety and Branching Guard

**Goal**: Ensure `query commit` warns/fails when attempting to commit to protected integration branches, and allow `execute-phase` to opt out of background execution for runtimes with one-shot session lifetimes.
**Depends on**: N/A
**Requirements**: 
**Success Criteria** (what must be TRUE):

  1. A contributor running `query commit` with `branching_strategy` unset warns or fails before committing directly to `main` or `develop`.
  2. `execute-phase.md` provides an opt-out mechanism for running executors in the background, allowing safe completion on one-shot runtimes.

**Plans**: 0/0 plans executed

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 2. State Validation Drift Diagnostics | v1.1 | 1/1 | Complete | 2026-08-22 |
| 3. Executor Safety and Branching Guard | v1.2 | 0/0 | Not Started|  |
