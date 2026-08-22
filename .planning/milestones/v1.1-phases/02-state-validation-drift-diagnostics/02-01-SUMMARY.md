---
phase: 02-state-validation-drift-diagnostics
plan: 01
subsystem: state-validation
tags: [node-cli, state-md, frontmatter, drift-diagnostics, filesystem-safety]

requires: []
provides:
  - Frontmatter-first active-phase resolution for state.validate
  - Warning-backed phase-reference and phase-directory drift diagnostics
  - Command-level positive drift, clean-control, precedence, failure, normalization, and path-confusion regressions
affects: [state-validation, phase-diagnostics, recovery-workflows]

actuals:
  tokens: 5082
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - Independent source parsing before precedence selection and conflict comparison
    - Canonical phase-key matching against enumerated directory entries
    - Fail-closed diagnostics when required validation subjects cannot be scanned

key-files:
  created: []
  modified:
    - src/state.cts
    - tests/state.test.cjs

key-decisions:
  - "Resolve usable phase sources in locked order: frontmatter current_phase, legacy Current Phase, then Current Position Phase."
  - "Construct scan paths only from enumerated phase-directory names whose canonical phase key matches the selected source."
  - "Treat unresolved sources and unavailable phase targets as warning-backed invalid results rather than clean validation."

patterns-established:
  - "State validation retains every parsed phase source long enough to report canonical disagreement without changing the authoritative winner."
  - "Command regressions pair disk-backed positive findings with exact opposite-result controls."

requirements-completed: [STATE-02, QUALITY-02]

coverage:
  - id: D1
    description: "Shipped-template STATE.md frontmatter selects the canonical phase directory and exposes passed-verification drift through the emitted CLI."
    requirement: STATE-02
    verification:
      - kind: integration
        ref: "tests/state.test.cjs#template frontmatter phase reaches passed-verification drift on disk"
        status: pass
      - kind: integration
        ref: "node --test --test-name-pattern='state validate command' tests/state.test.cjs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Source precedence, conflict visibility, fail-closed boundaries, canonical equality, and outside-root path confusion are covered through command regressions."
    requirement: QUALITY-02
    verification:
      - kind: integration
        ref: "tests/state.test.cjs#state validate command"
        status: pass
      - kind: integration
        ref: "node scripts/run-tests.cjs --files state.test.cjs"
        status: pass
    human_judgment: false

duration: 27min
completed: 2026-08-05
status: complete
---

# Phase 2 Plan 1: State Validation Drift Diagnostics Summary

**Frontmatter-first phase resolution now reaches canonical, enumerated disk scans while missing subjects fail closed and crafted references cannot escape the phases root.**

## Performance

- **Duration:** 27 min
- **Started:** 2026-08-04T23:44:25Z
- **Completed:** 2026-08-05T00:11:47Z
- **Tasks:** 2
- **Authored files modified:** 2
- **Actual estimate tokens:** 5,082 characters/4 over the realized two-file diff; both `wc -m` and an independent `awk length()` count measured 20,328 characters.

## Accomplishments

- `state validate` now resolves frontmatter, legacy, and canonical Current Position phase sources independently, preserves the locked precedence, and reports canonical conflicts while scanning the winner.
- Phase-directory lookup now compares canonical phase keys and joins only an enumerated child name; absent roots, unmatched phases, and unreadable targets return structured invalid results.
- The owning command suite now derives its tracer from the shipped template and covers a real passed-verification finding, exact clean equality, every source branch, unresolved inputs, missing targets, and outside-root evidence.

## Task Commits

1. **Task 1 RED: reproduce the shipped-template failure and clean control** — `c2aa78b6` (test)
2. **Task 1 GREEN: repair active-phase resolution and safe disk scanning** — `55f12e7b` (fix)
3. **Task 2: expand precedence and boundary regression coverage** — `c2e76b70` (test)

## Files Created/Modified

- `src/state.cts` — Resolves phase sources, records structured reference/directory drift, and safely selects the scan directory.
- `tests/state.test.cjs` — Adds the shipped-template fixture helper and fourteen focused command cases with positive and opposite-result controls.

## Decisions Made

- Reused `parseProsePhaseField`, `phaseKeyFromToken`, `phaseKeyFromDir`, and `scanPhasePlans`; no new parser, scanner, command, package, or generated source was introduced.
- Kept conflict reporting additive: the authoritative source remains selected and disk evidence from that phase is still returned.
- Retained per-verification-file best-effort reads while failing closed when the required phase root or directory cannot be scanned.

## TDD Gate Compliance

- **RED:** Before the repair, the template-derived executing fixture with an on-disk passed verification returned `valid: true`; the matched clean control also returned `valid: true`. This proved the shipped frontmatter path was stuck off rather than the positive assertion being permanently on.
- **GREEN:** After the repair, the same positive fixture reports `verification_status` drift and the clean control remains exactly `{ valid: true, warnings: [], drift: {} }`.
- Task 2's expansion tests passed on their first run because Task 1 implemented the complete locked D-01 through D-04 behavior; no second production adjustment was needed.

## Verification

- `npm run build:lib && node --test --test-name-pattern='state validate command' tests/state.test.cjs` — PASS, 14/14 focused command cases.
- `node scripts/run-tests.cjs --files state.test.cjs` — PASS for the complete owning test file.
- `npm run lint` — PASS.
- `npm run lint:ci` — PASS, including generated and compiled artifact synchronization.
- `npm test` — NOT GREEN. Chunk 1 passed 1,719/1,719 tests. Chunk 2 exposed two independently reproduced, out-of-scope baseline failures; the run was stopped after entering chunk 3, so later chunks were not completed.

These results establish the exercised local state-validation behaviors and repository lint contracts. They do not establish cross-platform reliability, and the incomplete/non-green full suite cannot support a claim of repository-wide regression freedom.

## Deviations from Plan

### Verification Deviation

**1. Full repository test gate remained non-green for unrelated baseline failures**
- **Found during:** Plan-wide verification
- **Issue:** `tests/emitted-attribution.test.cjs` fails against `origin/next@f4185554ea08`, and `tests/issue-2765-brace-expansion-lockfile.test.cjs` rejects pre-existing `brace-expansion@5.0.6`.
- **Scope check:** The realized plan diff contains only `src/state.cts` and `tests/state.test.cjs`; the failing tests and `package-lock.json` are unchanged from the plan base.
- **Action:** Did not modify emitted-attribution acknowledgments or dependencies. Recorded both failures and the incomplete full gate in `deferred-items.md` and `.planning/WINDOWS.md`.

**Total deviations:** 1 verification deviation; no implementation deviation or scope expansion.

## Issues Encountered

- The sandbox initially blocked command-level test subprocesses with `spawnSync ... EPERM`; the same focused tests ran normally with approved subprocess execution. This was an execution-environment limitation, not a product failure.
- The two broad-suite failures reproduced together in isolation: 169/171 tests passed and exactly the same two cases failed. This isolates them from the interruption-induced cancellations seen when the original full run was stopped.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- STATE-02 and QUALITY-02 have focused and owning-suite evidence and are ready for phase verification.
- Repository-wide regression freedom remains unestablished until the open emitted-attribution baseline and vulnerable lockfile entries are handled in separately scoped work and the full suite is rerun to completion.

## Self-Check: PASSED

- Both authored files, the summary, deferred-items record, and broken-windows ledger exist.
- Task commits `c2aa78b6`, `55f12e7b`, and `c2e76b70` exist in repository history.
- Negative controls correctly rejected a deliberately absent file and a bogus commit hash.

---
*Phase: 02-state-validation-drift-diagnostics*
*Completed: 2026-08-05*
