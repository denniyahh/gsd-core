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

### Active

- [ ] STATE-01: Planning a phase preserves authoritative `STATE.md` frontmatter activity metadata when its body contains stale same-date prose. (Ledger item 9.)
- [ ] EFFORT-01: A contributor can determine and configure the effective model and reasoning effort for each agent without partial overrides or inheritance changing unrelated defaults. (Ledger item 10.)
- [ ] QUALITY-01: Each first-milestone fix has a focused reproducing regression test and targeted verification before an upstream pull request is opened.

### Out of Scope

- Ledger items 6 and 7 — valid safety/compatibility enhancements, deferred from the first milestone to keep the initial contribution set implementation-ready.
- DevFlow orchestration — explicitly paused until the project owner re-enables it.
- Unrelated feature work — deferred until the first milestone is completed or the roadmap is revised.

## Context

The codebase is an npm package built primarily from TypeScript/CommonJS runtime modules and declarative Markdown workflows. It installs and projects artifacts for multiple coding-agent runtimes, so source, generated artifacts, and runtime-specific behavior must remain aligned.

`scratch/UPSTREAM-GSD-ISSUES.md` records evidence gathered while dogfooding. The first milestone focuses on confirmed items 9 (planned-phase frontmatter synchronization) and 10 (model/effort configuration consistency). The codebase map under `.planning/codebase/` records the current architecture, stack, conventions, tests, and risks.

## Constraints

- **Runtime support**: Preserve behavior across supported host runtimes and capability contracts — GSD is distributed beyond the current Codex session.
- **Generated artifacts**: Regenerate and verify derived registries, skills, and runtime artifacts when their canonical inputs change — stale generated output is a release risk.
- **Verification**: Add a reproducing regression test for each confirmed defect and run focused checks before broader suites — the project has extensive specialized test coverage.
- **Tooling**: Use Node.js 22+ and npm 10+ — enforced by `package.json`.
- **Planning storage**: Keep `.planning/` local — this repository’s `.gitignore` intentionally excludes it.
- **DevFlow**: Do not invoke DevFlow — the project owner has deferred its use.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Broad project objective: contribute upstream bug fixes and features | The project is ongoing; any one issue ledger is only a milestone input | — Pending |
| First milestone covers ledger items 9 and 10 | Both are confirmed and implementation-ready; items 6 and 7 are deferred enhancements | — Pending |
| Codebase map before initialization | Brownfield architecture and risk context should inform requirements and roadmap | ✓ Good |
| Keep planning artifacts local | The repository deliberately ignores `.planning/` | ✓ Good |
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
*Last updated: 2026-08-02 after initialization*
