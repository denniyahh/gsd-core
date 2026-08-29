# Phase 3: Configured Session-Survivability Dispatch - Research

**Researched:** 2026-08-28  
**Domain:** GSD configuration contract and runtime-loaded executor-dispatch workflow  
**Confidence:** HIGH for the current upstream seams; MEDIUM for the final emitted-runtime assertion shape because it depends on the implementation's chosen fragment interface.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Session-survivability configuration
- **D-01:** Use `workflow.session_outlives_turn` as the public boolean configuration key. An absent value and `true` preserve current background-dispatch behavior; `false` opts into the safe foreground path. — **Reversibility:** costly — a published configuration key propagates through schema, documentation, generated workflow artifacts, and user configuration.

### Executor dispatch when opted out
- **D-02:** Keep `gsd-executor` subagents and existing isolation/recovery behavior. When `workflow.session_outlives_turn` is `false`, every executor call is explicit `run_in_background: false` and the orchestrator awaits it before dispatching the next executor. Do not replace executor work with inline `execute-plan` work.

### Scope boundary
- **D-03:** Apply the opt-out to executor agents only. Verifier dispatch remains unchanged and outside #3159.

### the agent's Discretion
None — the configuration key, false-mode behavior, and executor-only boundary are locked.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within the approved #3159 boundary.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SESSION-01 | A host integrator can configure executor dispatch for a session that does not outlive its turn, so `execute-phase` waits for each executor rather than orphaning asynchronous work. | Configuration registration plus an executor-only dispatch fragment with an explicit foreground call. |
| SESSION-02 | A project with the setting absent or enabled retains the current background-dispatch behavior. | Schema default `true`, static default branch, and opposite-direction workflow tests. |
| SESSION-03 | A contributor can discover the host-session assumption and opt-out behavior in an ADR and configuration reference. | New issue-prefixed ADR, generated ADR index, and configuration rows. |
| QUALITY-03 | A maintainer can verify both configuration values through behavioral configuration and workflow/projection tests, including negative controls for the opposite dispatch direction. | Existing CLI and workflow-product test seams; tests must prove false and default/true differ. |
| COMPAT-01 | Generated runtime artifacts remain synchronized with the canonical workflow after the dispatch condition is added. | Derived-artifact regeneration/checks, install/runtime-converter coverage, and no direct edits to emitted output. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Base implementation work on current `upstream/next`; do not develop from this planning branch's stale source snapshot.
- Preserve supported runtime/capability contracts and regenerate/verify derived artifacts after canonical inputs change.
- Add a regression test for the confirmed behavior change, use focused checks before broad suites, and state what each check does not establish.
- Use Node.js 22+ and npm 10+; the checked environment has Node `v24.19.0` and npm `11.17.0`.
- Keep changes surgical, use existing test owners, avoid source-text tests unless the runtime-loaded Markdown is the product (it is here), and use explicit negative controls.
- New public changes require an issue-linked `Added` changeset and user-facing documentation. The contributor skill additionally requires a branch off `upstream/next` and `mise run check:budget && npm run build && npm run lint:ci && npm test` before push.
- Do not invoke DevFlow. No external package is needed for this phase.

## Summary

The upstream implementation seam is a runtime-loaded Markdown workflow, not a TypeScript executor scheduler. Current `upstream/next` is `83273f964` (`fix(#3798): the profile closure follows command references into workflow spawn surfaces (#4009)`). It explicitly says Claude executor Agents are backgrounded by default and its multi-plan harness-worktree example explicitly sets `run_in_background: true`. The locked feature must retain that path when `workflow.session_outlives_turn` is absent or `true`, and must make the `false` path explicit rather than relying on omission. [VERIFIED: upstream/next@83273f964 `gsd-core/workflows/execute-phase.md:20-37, 690-787`]

The current planning branch is not an implementation baseline: `HEAD` is `40d78cdbd`, while `upstream/next` is 73 commits ahead and has 88 local-only commits (`git rev-list --left-right --count HEAD...upstream/next` returned `88 73`). The named upstream files below are therefore the planning baseline; rebase or create the feature branch from current `upstream/next` before editing production sources. This inspection does not establish that a future rebase will be conflict-free.

**Primary recommendation:** add the boolean to the central schema/default manifests and `src/config.cts`; resolve it once in `execute-phase`; delegate the executor-only branch to a new, small step fragment so `false` emits a literal foreground call and awaits it while the literal default branch keeps `run_in_background: true`; then document, index, regenerate, and test both directions.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Accept and persist `workflow.session_outlives_turn` | CLI/configuration module | Project config storage | The central schema controls accepted paths and `config-set`; existing file writers persist the nested value. |
| Resolve absent value as `true` | CLI/configuration module | Runtime workflow | `cmdConfigGet` is the common schema-default boundary; the workflow consumes one resolved value. |
| Choose foreground versus background executor dispatch | Orchestrator workflow | Runtime conversion/install projection | `execute-phase.md` is executed product text; runtime conversion projects that text to host formats. |
| Explain the host lifecycle contract | Documentation | ADR index generator | The public configuration reference carries operator instructions; ADR records the architecture decision and is indexed. |
| Guard regression and projection behavior | Node test suite | Derived-artifact generators | Existing configuration, workflow, converter, and ADR test owners cover the source of truth and its projections. |

## Current Upstream Baseline and Exact Seams

### Configuration contract

- The central valid-key manifest contains the existing workflow keys, including `"workflow.use_worktrees"` and `"workflow.agent_hint_routing"`. Add `"workflow.session_outlives_turn"` there; this is the key accepted by `isValidConfigKey`. [VERIFIED: upstream/next@83273f964 `gsd-core/bin/shared/config-schema.manifest.json:17-39` — `"workflow.use_worktrees"`, `"workflow.agent_hint_routing"`]
- New-project/default configuration is the nested defaults manifest. Add `"session_outlives_turn": true` beside the other `workflow` defaults so newly materialized config has the documented default. [VERIFIED: upstream/next@83273f964 `gsd-core/bin/shared/config-defaults.manifest.json:24-49` — `"workflow": { ... "agent_hint_routing": true, ... }`]
- `src/config.cts` owns absent-key resolution and direct `config-set` type validation. Add the exact default and a boolean guard there: existing precedent is `'workflow.agent_hint_routing': true` plus `if (typeof parsedValue !== 'boolean')`. This makes old/minimal configs resolve `true`, while explicit `false` remains distinguishable. [VERIFIED: upstream/next@83273f964 `src/config.cts:97-114, 124-137, 828-833` — `'workflow.agent_hint_routing': true`; `if (typeof parsedValue !== 'boolean')`]
- Do **not** add a runtime-name exception or a second configuration parser. `src/config-schema.cts` already routes central keys through the manifest and supports project-scoped capability keys separately. [VERIFIED: upstream/next@83273f964 `src/config-schema.cts:59-73` — `if (isCentralConfigKey(keyPath)) return true; return isCapabilityConfigKey(keyPath, cwd);`]
- Do **not** add a flat `CONFIG_DEFAULTS.session_outlives_turn` entry in `src/config-loader.cts` unless a real legacy consumer needs it. The current flat projection exists for legacy callers, while project initialization consumes the nested canonical defaults manifest; adding an unused projection would be speculative. [VERIFIED: upstream/next@83273f964 `src/config-loader.cts:75-138` — `const CONFIG_DEFAULTS = { ... }`]

### Dispatch contract

- In `execute-phase.md`'s initialization config gate, add one raw read that is default-preserving, for example `SESSION_OUTLIVES_TURN=$(gsd_run query config-get workflow.session_outlives_turn --raw 2>/dev/null || echo "true")`. The schema default must make that fallback defensive rather than the source of policy.
- The direct executor dispatch lives in the `Spawn executor agents` portion of the canonical workflow. The existing positive/default contract is literal: `Dispatch each Agent() call one at a time with run_in_background: true`. Retain that literal path when the resolved value is `true`. [VERIFIED: upstream/next@83273f964 `gsd-core/workflows/execute-phase.md:658-787` — `run_in_background: true`]
- Implement the decision in a new focused `gsd-core/workflows/execute-phase/steps/session-survivability-dispatch.md` fragment, referenced from the existing spawn step. The host workflow is already 91,535 LF bytes, while the contributor rule limits it to 93,400 bytes. A fragment keeps the conditional readable and preserves prompt-budget headroom. This is a planning recommendation based on the measured file size; it does not prove the final diff will fit without a post-edit measurement.
- The false path must contain an actual executor `Agent(...)` call with `run_in_background: false`, then wait for its result before dispatching another executor. Do not represent the value with an omitted argument or a text placeholder that a runtime converter may fail to project. Keep a separate literal `run_in_background: true` default branch for projection compatibility.
- Scope the fragment to executor dispatch only. Do not edit verifier dispatch, `SUMMARY.md` recovery, tool-availability fallback, `ISOLATION` negotiation, or worktree cleanup. `ISOLATION`, not runtime name, remains the fan-out selector. [VERIFIED: upstream/next@83273f964 `gsd-core/workflows/execute-phase.md:98-113`; `gsd-core/workflows/execute-phase/steps/executor-isolation-dispatch.md:90-104` — `ISOLATION` values `harness-worktree|orchestrator-worktree|none`]
- The foreground setting does not itself change executor isolation. Harness worktrees, orchestrator-managed worktrees, and sequential no-worktree mode retain their existing ownership and recovery rules. Session survivability answers whether the parent can collect a child result; isolation answers where concurrent executor work runs.

### Documentation and release surfaces

- Add `docs/adr/3159-executor-session-survivability-dispatch.md` using the issue-prefix convention. It should be `Proposed` until shipped, distinguish tool availability from parent-session survivability, record default `true`/explicit `false`, and state executor-only scope. ADR filenames are `docs/adr/<issue#>-<kebab-slug>.md`; `Accepted` is reserved for a decision "in force." [VERIFIED: upstream/next@83273f964 `docs/adr/README.md:16-24, 52-64` — `docs/adr/<issue#>-<kebab-slug>.md`; `Accepted | Decided and in force`; `Proposed | Decided in principle, not ratified`]
- Run `node scripts/gen-adr-index.cjs --write` rather than editing `docs/adr/README.md` by hand, then check it. The index is generated and CI validates it. [VERIFIED: upstream/next@83273f964 `docs/adr/README.md:154-165` — `node scripts/gen-adr-index.cjs --write`; `node scripts/gen-adr-index.cjs --check`]
- Add a row to `docs/CONFIGURATION.md` adjacent to `workflow.use_worktrees`. State that `workflow.session_outlives_turn` is boolean, defaults to `true`, and changes only executor-Agent foreground/background handling; it neither declares tool availability nor changes isolation or verifier behavior. `workflow.use_worktrees` is the closest public escape-hatch precedent. [VERIFIED: upstream/next@83273f964 `docs/CONFIGURATION.md:400-411` — `| workflow.use_worktrees | boolean | true |`]
- Add the same setting to `gsd-core/references/planning-config.md`'s complete configuration reference. It is a shipped reference and contains the closest workflow setting precedent; this is necessary for a complete discoverability story even though the existing automated parity extraction may not require a new flat legacy projection. [VERIFIED: upstream/next@83273f964 `gsd-core/references/planning-config.md:39, 272` — `workflow.use_worktrees`]
- Add an `Added` `.changeset/` fragment for #3159. This is a public feature change, and the contributor contract requires changesets for touched runtime-loaded sources. [VERIFIED: `CONTRIBUTING.md:201-214`]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Node.js built-ins and existing GSD TypeScript/CommonJS modules | Node 22+; checked Node `v24.19.0` | Config parsing, workflow build, tests, and generators | This is a repository-native configuration/workflow change; no dependency is justified. |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| TypeScript compiler (`npm run build:lib`) | Compiles touched `.cts` sources for focused and full tests | Before testing config behavior. |
| Node test runner through repository scripts | Runs existing CLI, product-workflow, converter, and ADR test owners | Focused checks during implementation, then full suite before push. |
| Repository generators | Regenerate ADR index and validate all derived artifacts | After canonical documentation/workflow changes. |

**Installation:** none. No external package should be added.

## Package Legitimacy Audit

Not applicable — this phase installs no external packages.

## Architecture Patterns

### System Architecture Diagram

```text
project .planning/config.json
          |
          v
config-schema.manifest + config-defaults.manifest
          |
          v
src/config.cts: config-set validation / config-get default=true
          |
          v
execute-phase config gate resolves SESSION_OUTLIVES_TURN
          |
          +-- absent or true --> literal background executor dispatch
          |                       run_in_background: true
          |
          +-- false -----------> literal foreground executor dispatch
                                  run_in_background: false; await result

Both paths preserve existing isolation/recovery; verifier dispatch is unchanged.
          |
          v
runtime conversion/install projection + focused tests
```

### Pattern 1: Central key + explicit schema default

**What:** Register the path in the central schema manifest, materialize it in canonical defaults, and make `config-get` resolve the absent legacy/minimal-config case from `SCHEMA_DEFAULTS`.

**When to use:** A new public boolean needs identical CLI acceptance and runtime behavior whether the project config predates the feature or was newly created.

**Example:**

```typescript
// Follow the existing default-on config contract; values shown are locked decisions.
const SCHEMA_DEFAULTS: Record<string, unknown> = {
  'workflow.session_outlives_turn': true,
};

if (kp === 'workflow.session_outlives_turn' && typeof parsedValue !== 'boolean') {
  error(`Invalid workflow.session_outlives_turn '${val}'. Must be a boolean (true or false).`);
}
```

The literal values are grounded by the locked D-01 decision and the verified boolean-validator precedent above; the final code must use the surrounding module's existing error conventions.

### Pattern 2: Literal dispatch branches, not inferred behavior

**What:** Keep a visible static `run_in_background: true` default branch and a visible static `run_in_background: false` safe branch.

**When to use:** A host's default Agent behavior is asynchronous and a foreground result is required for parent-session survival.

**Why:** Existing regression coverage establishes that Claude Code backgrounds executor Agents by default and that `run_in_background: false` is the opt-out. [VERIFIED: upstream/next@83273f964 `tests/execute-phase-active-flags.test.cjs:460-489, 636-655` — `run_in_background: false`; `backgrounded by default`]

### Anti-patterns to avoid

- **Omitting `run_in_background`:** omission re-enables the host default and does not establish foreground waiting.
- **A single placeholder argument (`{EXECUTOR_BACKGROUND}`):** it weakens runtime projection inspection; maintain literal true and false branches so conversion tests can observe both directions.
- **Using `RUNTIME` to select behavior:** session survival is an integrator-provided lifecycle property, not a hardcoded host identity.
- **Changing `workflow.use_worktrees`:** it selects isolation, not whether the parent agent can survive to collect a result.
- **Changing verifier dispatch:** violates D-03 and obscures a narrow upstream feature PR.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Config-key acceptance | A new workflow-local JSON reader | `config-schema.manifest.json` + existing `config-set`/`config-get` seams | Preserves validation, workstream inheritance, defaults, and raw output behavior. |
| Default resolution | A shell-only `echo true` policy | `SCHEMA_DEFAULTS` plus defensive shell fallback | Old configs and CLI callers must see the same effective default. |
| Host/isolation selection | Runtime-name branches | Existing `dispatch-isolation` capability/fragment | Preserves declared host contracts and fail-closed behavior. |
| ADR table update | Hand-edited index row | `scripts/gen-adr-index.cjs --write` | Prevents generated-index drift. |
| Generated artifact updates | Manual edits to `gsd-core/bin/lib/*.cjs` or plugin skills | `npm run build`, `npm run regen:derived`, and generator checks | Generated outputs must come from canonical inputs. |

## Common Pitfalls

### Pitfall 1: Treating absent as false

**What goes wrong:** An unset key either errors or accidentally selects the foreground behavior, changing all established runtime behavior.

**How to avoid:** Register default `true` in both new-project defaults and `SCHEMA_DEFAULTS`; test absent config and explicit `true` against explicit `false` as opposite outcomes.

**Warning signs:** `config-get workflow.session_outlives_turn --raw` returns an error for a minimal config, or false-mode and default-mode workflow assertions both see the same background value.

### Pitfall 2: A foreground prose claim without a foreground call

**What goes wrong:** The workflow says "await" but omits the parameter, so Claude's default backgrounding still orphans work.

**How to avoid:** Assert every executor Agent dispatch selected by the false branch contains a literal `run_in_background: false`; include a negative control that the false path contains no `run_in_background: true` executor dispatch.

**Warning signs:** A test only looks for the word "foreground" or only counts a single dispatch block.

### Pitfall 3: Regressing the default path while adding the escape hatch

**What goes wrong:** Safe-mode implementation serializes or foregrounds all executors, silently sacrificing intended parallel background behavior for regular integrations.

**How to avoid:** Preserve the existing default `run_in_background: true` branch verbatim and test it separately for absent and explicit `true`.

**Warning signs:** The test suite passes with only false-mode assertions, or the runtime converter output lacks the existing true branch.

### Pitfall 4: Conflating session survivability with isolation

**What goes wrong:** The change disables worktrees, changes `ISOLATION`, or adds a Codex/Claude branch instead of solving the parent-turn lifecycle.

**How to avoid:** Keep the new branch executor-dispatch-local and reuse the existing isolation fragment unchanged.

### Pitfall 5: Generated and release drift

**What goes wrong:** The ADR index, runtime outputs, or documentation-derived checks fail only in CI.

**How to avoid:** Generate the ADR index, run derived-sync checks, and include the required changeset before broad verification.

## Validation Architecture

`workflow.nyquist_validation` is explicitly `true` in `.planning/config.json`; validation is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node built-in test runner, orchestrated by `scripts/run-tests.cjs` |
| Quick run command | `npm run build:lib && node --test tests/config.test.cjs tests/config-get-default.test.cjs tests/execute-phase-active-flags.test.cjs tests/runtime-converters.test.cjs tests/adr-index-gate.test.cjs` |
| Full suite command | `mise run check:budget && npm run build && npm run lint:ci && npm test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SESSION-01 | `config-set` accepts boolean values; false selects explicit foreground executor dispatch and awaits it | CLI integration + workflow-product | focused command above | Extend `tests/config.test.cjs`; extend `tests/execute-phase-active-flags.test.cjs` |
| SESSION-02 | missing and explicit true preserve background executor dispatch | CLI default + workflow-product | focused command above | Extend `tests/config-get-default.test.cjs`; extend `tests/execute-phase-active-flags.test.cjs` |
| SESSION-03 | ADR and config reference describe only the host-session opt-out | ADR/doc generator | `node scripts/gen-adr-index.cjs --check` and `npm run lint:generated-sync` | Extend/add ADR generator coverage only if new format requires it; existing gate exists |
| QUALITY-03 | two values have opposite observable dispatch results; malformed non-boolean input is rejected | integration + negative workflow control | focused command above | Existing owners listed above |
| COMPAT-01 | canonical workflow survives runtime conversion/install projection and derived-sync checks | conversion/install + generated sync | `npm run test:install && npm run lint:generated-sync` | Extend `tests/runtime-converters.test.cjs`; existing install coverage |

### Required negative controls

1. **Config direction:** in a project with no key, `config-get --raw` must yield `true`; after `config-set ... false`, it must yield `false`. Assert the outputs differ. An explicit `true` must again yield `true`.
2. **Validation direction:** `config-set workflow.session_outlives_turn not-a-boolean` must fail and leave no value that reads as `false` or `true` accidentally.
3. **Dispatch direction:** the false-mode executor branch must have literal `run_in_background: false` and no literal executor-background instruction; the default/true branch must retain literal `run_in_background: true` and must not use the safe false branch.
4. **Scope control:** verifier dispatch text is unchanged/does not reference `workflow.session_outlives_turn`; a false-mode test that only finds an executor keyword is insufficient.
5. **Projection control:** convert the canonical workflow through at least the supported runtime conversion seam and assert the default and safe path survive in the emitted result as the target runtime permits. A source-only assertion does not prove an installed projection remains coherent.

These checks establish the exercised configuration and workflow instructions, not reliable behavior on every external host version or actual parent-turn termination. The feature documents and exposes a safe control path; host lifecycle behavior still needs integration-level evidence from the host that sets `false`.

### Sampling Rate

- **Per task commit:** relevant focused Node tests plus `git diff --check`.
- **After generated changes:** `node scripts/gen-adr-index.cjs --check` and `npm run lint:generated-sync`.
- **Before push/phase gate:** `mise run check:budget && npm run build && npm run lint:ci && npm test`; add `npm run test:install` when checking installed-runtime projections.

### Wave 0 Gaps

None — existing test infrastructure and owners cover configuration, runtime-loaded workflow text, conversion, install projection, and ADR index behavior. New cases belong in existing owners rather than a top-level issue-number test file.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No identity or credential surface changes. |
| V3 Session Management | Yes, conceptually | The feature controls orchestrator session lifetime assumptions but does not create or authenticate user sessions. |
| V4 Access Control | No | No authorization boundary changes. |
| V5 Input Validation | Yes | Existing `config-set` boolean validation rejects non-boolean parsed values. |
| V6 Cryptography | No | No cryptographic material or protocol changes. |

### Known threat patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed config coerces into a plausible lifecycle value | Tampering | Central schema whitelist plus explicit boolean validation and hostile-value regression case. |
| A runtime-specific shortcut bypasses declared capabilities | Tampering / Reliability | Preserve `dispatch-isolation` negotiation; do not branch on runtime identity. |
| A misleading default silently changes execution availability | Denial of service / Reliability | Schema default `true` and opposite-direction tests for missing, true, and false values. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | build, generators, tests | Yes | `v24.19.0` | None; project requires Node 22+ |
| npm | build, generators, tests | Yes | `11.17.0` | None; project requires npm 10+ |
| Git | upstream baseline/rebase and verification | Yes | Available in this checkout | None |

No external service, package, database, or browser dependency is required.

## Implementation Surface Plan

| Surface | Change | Why |
|---------|--------|-----|
| `gsd-core/bin/shared/config-schema.manifest.json` | Add the exact public key | Allows `config-set`/schema recognition. |
| `gsd-core/bin/shared/config-defaults.manifest.json` | Add nested default `true` | Materializes default in new project configs. |
| `src/config.cts` | Add schema default and boolean validation | Gives old/minimal config the same effective default and rejects malformed values. |
| `gsd-core/workflows/execute-phase.md` | Resolve key once and lazily call the new dispatch fragment | Canonical executor orchestration contract. |
| `gsd-core/workflows/execute-phase/steps/session-survivability-dispatch.md` | Add literal default/background and false/foreground dispatch instructions | Keeps the host workflow under budget and makes both directions observable. |
| `docs/CONFIGURATION.md` | Add operator-facing setting row | Documents default, use case, and scope fence. |
| `gsd-core/references/planning-config.md` | Add complete field-reference row | Keeps shipped configuration reference discoverable. |
| `docs/adr/3159-*.md` + generated `docs/adr/README.md` | Record decision and regenerate index | Required architecture rationale and generated index parity. |
| `.changeset/<generated-name>.md` | Add `Added` release fragment for #3159 | Required release-facing user change. |
| `tests/config.test.cjs` | Cover set true/false and malformed input | CLI behavior and parse-boundary negative control. |
| `tests/config-get-default.test.cjs` | Cover absent default true, explicit false, and workstream inheritance as applicable | Verifies absence is not conflated with false. |
| `tests/execute-phase-active-flags.test.cjs` | Cover all executor dispatch directions and unchanged verifier scope | Runtime-loaded workflow is the product; use the established allowed source-text test owner. |
| `tests/runtime-converters.test.cjs` | Cover canonical workflow projection of the new literal branches | Guards emitted-runtime compatibility. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A new `session-survivability-dispatch.md` fragment will be the smallest implementation that stays below the local 93,400-byte workflow threshold. | Dispatch contract | The final implementation may choose a different equally-small extracted surface; measure after editing. |
| A2 | `gsd-core/references/planning-config.md` should be updated alongside the public configuration reference even though current automatic field parity does not force this particular nested key. | Documentation | Discoverability could be incomplete if omitted; confirm with maintainer preference only if upstream asks to minimize documentation surfaces. |

## Open Questions

None that require operator input. The configuration name, semantics, dispatch behavior, and executor-only boundary are locked. The planner should choose the smallest fragment API that keeps literal true/false branches visible to runtime conversion and the workflow-size guard.

## Sources

### Primary (HIGH confidence)

- Current `upstream/next` commit `83273f964` — canonical workflow, configuration, test, and documentation seams inspected directly.
- `docs/adr/README.md` — ADR lifecycle and generated-index rules.
- `CONTRIBUTING.md` — approved-feature, changeset, documentation, test, and branch requirements.

### Secondary (MEDIUM confidence)

- Current project contributor skill `gsd-pr-contributor` — adds local pre-push verification and workflow-size guidance.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new dependency and current Node/npm availability were directly checked.
- Architecture: HIGH — current `upstream/next` workflow/config seams were opened and compared with the stale planning branch.
- Pitfalls: HIGH — grounded in the current #3177 regression suite and locked #3159 decisions.

**Research date:** 2026-08-28  
**Valid until:** Re-check `upstream/next` immediately before implementation; this branch is currently behind it.
