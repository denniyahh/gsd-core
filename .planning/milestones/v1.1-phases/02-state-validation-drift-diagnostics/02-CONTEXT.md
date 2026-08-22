# Phase 2: State Validation Drift Diagnostics - Context

**Gathered:** 2026-08-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair the existing `state.validate` command so a normal shipped `STATE.md` resolves an active phase and performs its on-disk drift checks. Keep the work limited to ledger item 12 and focused regression coverage; do not add a new verification command, change progress calculations, or broaden state synchronization.

</domain>

<decisions>
## Implementation Decisions

### Phase-source precedence

- **D-01:** Resolve the active phase in this order: frontmatter `current_phase`, legacy body `Current Phase`, then canonical body `Phase:`.
- **D-02:** When frontmatter and canonical body `Phase:` disagree, frontmatter remains authoritative and `state.validate` reports phase-reference drift rather than resolving silently.

### Unresolvable active phase

- **D-03:** If no usable phase reference can be resolved, return `valid: false` with an actionable warning; a validator that cannot perform its promised disk check must not report clean validation.
- **D-04:** If a phase reference resolves but no matching directory exists in `.planning/phases/`, report missing-phase drift and return `valid: false`.

### Regression proof

- **D-05:** Build the main regression from the shipped `gsd-core/templates/state.md` shape, then introduce known on-disk drift in a matching phase directory.
- **D-06:** Focused coverage must separately exercise frontmatter, legacy `Current Phase`, canonical `Phase:`, and a no-source negative control; parser-only tests do not satisfy the phase.

### the agent's Discretion

- Choose the smallest compatible helper extraction and assertion wording that follows the existing state-module patterns.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract

- `.planning/ROADMAP.md` — Phase 2 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — STATE-02 and QUALITY-02 scope and explicit exclusions.
- `scratch/UPSTREAM-GSD-ISSUES.md` — ledger item 12 evidence and the original failure mode.

### State implementation and tests

- `src/state.cts` — `cmdStateValidate` is the affected command; `cmdStatePrune`, `cmdStateSnapshot`, and `buildStateFrontmatter` demonstrate existing phase-resolution patterns.
- `gsd-core/templates/state.md` — shipped state-document shape that the regression must represent.
- `tests/state.test.cjs` — owning command-level regression suite and existing `cmdStateValidate` coverage.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `extractFrontmatter`, `stripFrontmatter`, `stateExtractField`, and `parseProsePhaseField` in `src/state.cts` already parse the relevant state sources.
- `scanPhasePlans` in `src/state.cts` already supplies the disk plan/summary counts used by the validator.
- `createTempProject` and cleanup helpers in `tests/helpers.cjs` support isolated command-level fixtures.

### Established Patterns

- `cmdStatePrune` uses a frontmatter-first resolution chain with legacy/body fallbacks; preserve compatibility rather than adding an ad hoc parser.
- State diagnostics return `{ valid, warnings, drift }` and use stable, behavioral assertions in the owning `tests/state.test.cjs` suite.
- Tests must exercise behavior through the command and include a negative control, not source-text assertions.

### Integration Points

- Update `cmdStateValidate` in `src/state.cts` and its command-level tests in `tests/state.test.cjs`; rebuild generated CommonJS artifacts through the repository build workflow as required.

</code_context>

<specifics>
## Specific Ideas

The regression should prove the full validator reaches and reports a known disk-drift condition from the shipped template shape, rather than merely proving a parser extracts a phase number.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 2-state-validation-drift-diagnostics*
*Context gathered: 2026-08-04*
