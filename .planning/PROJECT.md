# GSD Core Contributions

## What This Is

This is a contributor planning workspace for `@opengsd/gsd-core`, the workflow and runtime system used by AI coding agents. It organizes evidence-backed upstream bug fixes and useful features into focused, reviewable pull requests for maintainers and the people who rely on GSD across supported runtimes.

## Core Value

Every contribution must make GSD more reliable without regressing its supported runtime and generated-artifact contracts.

## Requirements

### Validated

- ✓ GSD provides a Node-based CLI and deterministic project-state operations — existing
- ✓ GSD distributes commands, workflows, skills, agents, and hooks across multiple host runtimes — existing
- ✓ GSD has focused unit, integration, install, security, QA, and generated-artifact verification suites — existing
- ✓ STATE-01: Planning a phase preserves authoritative `STATE.md` frontmatter activity metadata when its body contains stale same-date prose — validated in Phase 1.
- ✓ QUALITY-01: The item-9 fix has a focused reproducing regression test and targeted verification — validated in Phase 1.

### Active

None for the completed v1.0 milestone.

### Out of Scope

- Ledger items 6 and 7 — valid safety/compatibility enhancements, deferred from the first milestone to keep the initial contribution set implementation-ready.
- Ledger item 10 — deferred intact to v2 requirements; partial implementation would create a policy mismatch across its resolver, install, reporting, and documentation surfaces.
- DevFlow orchestration — explicitly paused until the project owner re-enables it.
- Unrelated feature work — deferred until the first milestone is completed or the roadmap is revised.

## Context

The codebase is an npm package built primarily from TypeScript/CommonJS runtime modules and declarative Markdown workflows. It installs and projects artifacts for multiple coding-agent runtimes, so source, generated artifacts, and runtime-specific behavior must remain aligned.

`scratch/UPSTREAM-GSD-ISSUES.md` records evidence gathered while dogfooding. The first milestone completed confirmed item 9 (planned-phase frontmatter synchronization); item 10 (model/effort configuration consistency) remains documented research for a later milestone. The codebase map under `.planning/codebase/` records the current architecture, stack, conventions, tests, and risks.

## Current State

v1.0 shipped on 2026-08-04. It delivered the planned-phase state-integrity repair and its focused command-level regression. The completed phase and its verification evidence are archived under `.planning/milestones/v1.0-phases/`.

## Next Milestone Goals

- Define the next contribution slice and refresh its requirements before creating a new roadmap.
- Revisit the documented model/effort configuration consistency work as a coherent, separately planned milestone.

## Constraints

- **Runtime support**: Preserve behavior across supported host runtimes and capability contracts — GSD is distributed beyond the current Codex session.
- **Generated artifacts**: Regenerate and verify derived registries, skills, and runtime artifacts when their canonical inputs change — stale generated output is a release risk.
- **Verification**: Add a reproducing regression test for each confirmed defect and run focused checks before broader suites — the project has extensive specialized test coverage.
- **Tooling**: Use Node.js 22+ and npm 10+ — enforced by `package.json`.
- **Planning storage**: Track `.planning/` in this fork — project context, requirements, roadmap, and verification history must travel with contribution work.
- **DevFlow**: Do not invoke DevFlow — the project owner has deferred its use.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Broad project objective: contribute upstream bug fixes and features | The project is ongoing; any one issue ledger is only a milestone input | — Pending |
| First milestone covers ledger item 9 only | The user chose a narrow state-integrity slice with mandatory regression coverage; item 10 is deferred intact to v2 | ✓ Good |
| Codebase map before initialization | Brownfield architecture and risk context should inform requirements and roadmap | ✓ Good |
| Track planning artifacts in this fork | The project owner explicitly wants planning context versioned with contribution work | ✓ Good |
| Hold DevFlow use | The project owner considers it not mature enough for this workflow | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-08-04 after v1.0 milestone completion*
