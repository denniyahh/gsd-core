# Phase 3: Configured Session-Survivability Dispatch - Context

**Gathered:** 2026-08-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the maintainer-approved #3159 opt-out for hosts whose orchestrator session does not outlive a turn: a configuration key, executor-dispatch branch, ADR, configuration documentation, derived artifacts, and focused verification. Default behavior remains unchanged. #3552, shape-2 worktree-dispatch redesign, orchestrator-owned `SUMMARY.md` recovery, and verifier-dispatch changes are out of scope.

</domain>

<decisions>
## Implementation Decisions

### Session-survivability configuration
- **D-01:** Use `workflow.session_outlives_turn` as the public boolean configuration key. An absent value and `true` preserve current background-dispatch behavior; `false` opts into the safe foreground path. — **Reversibility:** costly — a published configuration key propagates through schema, documentation, generated workflow artifacts, and user configuration.

### Executor dispatch when opted out
- **D-02:** Keep `gsd-executor` subagents and existing isolation/recovery behavior. When `workflow.session_outlives_turn` is `false`, every executor call is explicit `run_in_background: false` and the orchestrator awaits it before dispatching the next executor. Do not replace executor work with inline `execute-plan` work.

### Scope boundary
- **D-03:** Apply the opt-out to executor agents only. Verifier dispatch remains unchanged and outside #3159.

### the agent's Discretion
None — the configuration key, false-mode behavior, and executor-only boundary are locked.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract
- `.planning/ROADMAP.md` — Phase 3 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — SESSION-01 through COMPAT-01 acceptance contract and exclusions.
- `.planning/notes/2026-08-28-feature-3159-development-brief.md` — maintainer-approved scope, deferred alternatives, and negative-control expectations.

### Configuration and dispatch seams
- `gsd-core/workflows/execute-phase.md` — canonical executor dispatch instructions and runtime compatibility contract.
- `gsd-core/bin/shared/config-schema.manifest.json` — canonical central configuration-key whitelist.
- `src/config.cts` — `config-get` schema-default resolution and config-set validation boundary.
- `docs/CONFIGURATION.md` — public configuration-reference format and `workflow.use_worktrees` escape-hatch precedent.

### Contribution architecture
- `docs/adr/README.md` — required ADR naming, status, index generation, and validation rules.
- `CONTRIBUTING.md` — approved-feature, changeset, documentation, and regression-test requirements.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `gsd-core/bin/shared/config-schema.manifest.json` and `src/config.cts` provide the existing configuration registration, default-resolution, and command-validation seams.
- `tests/config.test.cjs` and `tests/config-get-default.test.cjs` contain CLI-level configuration behavior patterns.
- `tests/runtime-converters.test.cjs` and `tests/execute-phase-wave.test.cjs` cover runtime-loaded workflow projection and executor-wave contracts.

### Established Patterns
- Markdown workflows are shipped runtime behavior; their content may be tested as the deployed contract, while configuration registration must be tested through the CLI.
- Canonical sources generate distributed runtime artifacts. Update authored sources, regenerate, and verify generated-sync rather than editing emitted copies.
- Host behavior must be capability/configuration-based; do not introduce a runtime-name special case for a wrapper-host lifecycle property.

### Integration Points
- `execute-phase.md` resolves executor wave dispatch and currently makes the background-dispatch choice.
- The configuration manifests plus `src/config.cts` determine whether the key is accepted and what absent-key reads return.
- ADR indexing, configuration documentation, changesets, and generated runtime projections are release-facing companion surfaces.

</code_context>

<specifics>
## Specific Ideas

The opt-out must be explicit: omitting `run_in_background` is unsafe because Claude backgrounds agents by default. The default path is protected by an opposite-direction test so the new safe path cannot silently become the universal path.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the approved #3159 boundary.

</deferred>

---

*Phase: 3-Configured Session-Survivability Dispatch*
*Context gathered: 2026-08-28*
