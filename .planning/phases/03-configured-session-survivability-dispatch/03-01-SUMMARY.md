---
phase: 03-configured-session-survivability-dispatch
plan: 01
subsystem: workflow-execution
tags: [config, workflow, executor-dispatch, session-survivability, one-shot-hosts]

requires: []
provides:
  - Central public registration of workflow.session_outlives_turn defaulting to true
  - Boolean schema validation and absent/default resolution in src/config.cts
  - Canonical harness Agent dispatch step with literal background and awaited foreground branches
  - Orchestrator-worktree process dispatch honoring resolved mode without re-reading config
  - Suite regressions covering config CLI directions, opposite controls, and executor-only scope
affects: [config, execute-phase, executor-isolation, session-lifecycle]

actuals:
  tokens: 12500
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - Default-preserving boolean configuration key registration in manifests and schema defaults
    - Single-resolution configuration pattern in workflow initialization step
    - Literal run_in_background true/false branching in step fragment rather than placeholder interpolation
    - Backend-scoped workflow-product assertions verifying executor exclusivity without touching verifier dispatch

key-files:
  created:
    - gsd-core/workflows/execute-phase/steps/session-survivability-dispatch.md
  modified:
    - gsd-core/bin/shared/config-defaults.manifest.json
    - gsd-core/bin/shared/config-schema.manifest.json
    - gsd-core/workflows/execute-phase.md
    - gsd-core/workflows/execute-phase/steps/executor-isolation-dispatch.md
    - src/config.cts
    - tests/config.test.cjs
    - tests/config-get-default.test.cjs
    - tests/execute-phase-active-flags.test.cjs

key-decisions:
  - "Default workflow.session_outlives_turn to true so existing asynchronous background dispatch remains untouched."
  - "Extract harness Agent dispatch into session-survivability-dispatch.md with literal branches rather than an interpolated flag."
  - "Carry already-resolved SESSION_OUTLIVES_TURN into executor-isolation-dispatch.md without re-querying configuration."
  - "Keep verifier dispatch completely separate and untouched by session-survivability configuration."

requirements-completed: [SESSION-01, SESSION-02, QUALITY-03]

duration: 25min
completed: 2026-08-29
status: complete
---

# Phase 3 Plan 1: Configured Session-Survivability Dispatch Tracer Summary

**Public default-preserving boolean `workflow.session_outlives_turn` is centrally registered, tested across absent/true/false/invalid paths, and wired into canonical workflow execution with literal foreground/background branches for both executor backends.**

## Performance

- **Tasks:** 2
- **Authored files modified/created:** 8
- **Commits:**
  - `02057c588` — `docs(03-01): align validation map with plan tasks`
  - `f25912d90` — `test(03-01): add session-survivability dispatch coverage`
  - `5f67c2142` — `feat(03-01): add foreground executor dispatch opt-out`

## Accomplishments

- Centrally registered `workflow.session_outlives_turn` in `config-schema.manifest.json` and `config-defaults.manifest.json` with a default of `true`.
- Added schema default and boolean type validation in `src/config.cts` so absent keys resolve to `true`, invalid inputs are rejected, and `config-set` persists valid booleans.
- Extracted harness Agent execution into `gsd-core/workflows/execute-phase/steps/session-survivability-dispatch.md` with explicit literal `run_in_background: true` for default/true and `run_in_background: false` followed by awaiting for false mode.
- Updated `gsd-core/workflows/execute-phase/steps/executor-isolation-dispatch.md` to consume the resolved mode for orchestrator-worktree process spawning (synchronous execution + wait when false, background spawn when true) while keeping worktree ownership and recovery intact.
- Verified all 296 tests pass across `tests/config.test.cjs`, `tests/config-get-default.test.cjs`, and `tests/execute-phase-active-flags.test.cjs`.
