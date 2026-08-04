# Roadmap: GSD Core Contributions

## Overview

This milestone delivers a narrowly scoped state-integrity repair: planning a phase retains the authoritative activity metadata already recorded in `STATE.md`, with a command-level regression that proves the final serialized state remains correct.

## Phases

**Phase Numbering:**

- Integer phases are planned milestone work.
- Decimal phases are urgent insertions between planned phases.

- [x] **Phase 1: Planned-Phase State Integrity** - Preserve authoritative activity metadata during planned-phase updates and prove it against the written `STATE.md` artifact. (completed 2026-08-04)

## Phase Details

### Phase 1: Planned-Phase State Integrity

**Goal**: GSD project maintainers can plan a phase without stale same-date body prose overwriting authoritative activity metadata in the resulting `STATE.md`.
**Depends on**: Nothing (first phase)
**Requirements**: STATE-01, QUALITY-01
**Success Criteria** (what must be TRUE):

  1. A maintainer can run `state planned-phase` on a state file whose body has stale prose for the same date, and the final `STATE.md` frontmatter still contains the authoritative `last_activity` and `last_activity_desc` values.
  2. The planned-phase update retains its intentional status, body/progress, and plan-count behavior while preserving those authoritative activity fields.
  3. A contributor can run a focused command-level regression that reads the final `STATE.md` artifact and verifies both the preserved frontmatter and the intended planned-phase changes.

**Plans**: 1/1 plans complete

- [x] 01-01-PLAN.md

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Planned-Phase State Integrity | 1/1 | Complete   | 2026-08-04 |
