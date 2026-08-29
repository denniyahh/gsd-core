# Phase 3: Configured Session-Survivability Dispatch - Pattern Map

**Mapped:** 2026-08-28
**Baseline:** `upstream/next` at `1051c6d8d`
**Files classified:** 15 authored/test surfaces plus generator-owned output
**Analogs found:** 15 / 15

All source locations below were read from `upstream/next`, not the stale local
worktree source. Generated output is intentionally not an implementation target.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `gsd-core/bin/shared/config-schema.manifest.json` | config | transform | same manifest's workflow entries | exact |
| `gsd-core/bin/shared/config-defaults.manifest.json` | config | transform | `workflow.agent_hint_routing` default | exact |
| `src/config.cts` | service | request-response | `workflow.agent_hint_routing` default + validator | exact |
| `gsd-core/workflows/execute-phase.md` | workflow controller | event-driven | per-plan executor-routing extraction | role/data-flow match |
| `gsd-core/workflows/execute-phase/steps/session-survivability-dispatch.md` | workflow fragment | event-driven | `per-plan-executor-routing.md` / `executor-isolation-dispatch.md` | role/data-flow match |
| `docs/CONFIGURATION.md` | documentation | transform | `workflow.agent_hint_routing` row | exact |
| `gsd-core/references/planning-config.md` | documentation | transform | `workflow.use_worktrees` row | exact |
| `docs/adr/3159-executor-session-survivability-dispatch.md` | ADR | file-I/O | `docs/adr/1143-claude-orchestration-capability.md` | role match |
| `docs/adr/README.md` | generated documentation | batch | ADR index generator contract | exact |
| `.changeset/<generated>.md` | release config | batch | contributor changeset contract | role match |
| `tests/config.test.cjs` | test | request-response | nested boolean config-set tests | exact |
| `tests/config-get-default.test.cjs` | test | request-response | schema-default absent-key tests | exact |
| `tests/execute-phase-active-flags.test.cjs` | test | event-driven | foreground session-manager dispatch assertions | exact flag behavior |
| `tests/runtime-converters.test.cjs` | test | transform | typed condition / no-runtime-name dispatch gate | exact projection policy |
| `tests/fixtures/install-tree/*.json` | generated fixture | batch | install-tree generator output | generated-only |

## Pattern Assignments

### Central public boolean registration

**Apply to:** `config-schema.manifest.json`, `config-defaults.manifest.json`, and `src/config.cts`.

**Closest analog:** `workflow.agent_hint_routing`.

`config-schema.manifest.json:17-39` is the canonical central-key whitelist. Add
`"workflow.session_outlives_turn"` in the existing `workflow.*` sequence; do not
add a workflow-local parser.

```json
"workflow.plan_review_convergence",
"workflow.agent_hint_routing"
```

`config-defaults.manifest.json:25-35` establishes the nested, canonical
new-project default. Add `"session_outlives_turn": true` beside the other
workflow defaults.

```json
"workflow": {
  "research": true,
  "plan_check": true,
  "verifier": true,
  "nyquist_validation": true,
  "ai_integration_phase": true,
  "agent_hint_routing": true
}
```

`src/config.cts:97-137` is the independent old/minimal-config resolution seam.
It must also gain a `true` schema default; the defaults manifest alone does not
make `config-get` succeed for a pre-feature config.

```ts
// #1689: per-plan agent_hint executor routing — default-on. A no-op for plans
// without an agent_hint field, so existing dispatch is byte-identical.
'workflow.agent_hint_routing': true,
```

Follow the exact type guard at `src/config.cts:828-833`, not truthiness or a
string comparison:

```ts
if (kp === 'workflow.agent_hint_routing') {
  if (typeof parsedValue !== 'boolean') {
    error(`Invalid workflow.agent_hint_routing '${val}'. Must be a boolean (true or false).`);
  }
}
```

### Absent-key resolution and its negative control

**Apply to:** `src/config.cts` and `tests/config-get-default.test.cjs`.

**Closest analog:** `SCHEMA_DEFAULTS` fallback used by `cmdConfigGet`.

`cmdConfigGet` has three missing-value paths, all of which call
`resolveSchemaDefault`: no `config.json` (`src/config.cts:1000-1015`), malformed
intermediate node (`1031-1042`), and final missing leaf (`1058-1065`). Do not
implement a shell fallback as the policy source; it would miss CLI callers and
can collapse absent into false.

```ts
const sd = resolveSchemaDefault(cwd, kp);
if (sd.found) { emitResolvedDefault(kp, sd.value, raw); return; }
```

Use the focused #1689 test owner at
`tests/agent-hint-routing-1689.test.cjs:215-247` as the compact behavioral
template: test a new project with no explicit key (`true`), set `false` and
read back `false`, and reject a non-boolean. Also use
`tests/config-get-default.test.cjs:350-405` for the independent no-explicit-key
and unknown-key controls. The required assertion is directional: absent and
explicit `true` must differ from explicit `false`; a pass on only one value
does not establish the opt-out branch.

### Runtime-loaded executor dispatch fragment

**Apply to:** `execute-phase.md` and new
`execute-phase/steps/session-survivability-dispatch.md`.

**Closest analog:** extracted per-plan executor routing.

The host workflow delegates focused policy to a fragment while retaining its
dispatch placeholder. `execute-phase.md:665-668` reads the routing fragment and
then uses the resolved `{EXECUTOR_TYPE}` in the shared Agent template. The
matching test at `tests/agent-hint-routing-1689.test.cjs:194-212` asserts both
the parent pointer and fragment contract.

```markdown
**Executor routing (#1689/#3370).** Per plan, run
`gsd-core/workflows/execute-phase/steps/per-plan-executor-routing.md` to set
`EXECUTOR_TYPE` for `subagent_type="{EXECUTOR_TYPE}"` below.
```

Follow this extraction form for session survivability: the parent resolves the
public key once and references the fragment at the executor dispatch decision;
the fragment owns only the true/false invocation choice. It must not re-resolve
`ISOLATION`, change `USE_WORKTREES`, or mention verifier dispatch. The existing
isolation fragment expressly says `ISOLATION` — not `RUNTIME` — selects fan-out
(`executor-isolation-dispatch.md:90-104`), so a host-name branch is prohibited.

### Literal foreground/background calls

**Apply to:** the new fragment and
`tests/execute-phase-active-flags.test.cjs`.

**Closest analogs:** executor background prescription and debug session-manager
foreground opt-out.

The unchanged default executor path is at
`execute-phase.md:690-698`:

```markdown
Dispatch each `Agent()` call **one at a time with `run_in_background: true`**.
```

The foreground contract is not prose: `debug.md:143-147` and `217-237` use
the literal argument on every dispatch:

```text
Agent(
  subagent_type="gsd-debug-session-manager",
  ...
  run_in_background=false
)
```

Copy the exhaustive-dispatch test shape from
`tests/execute-phase-active-flags.test.cjs:616-665`: collect every relevant
fenced `Agent(` block, assert the expected count, then assert each block carries
the literal false value. For #3159, add the complementary background test:
the default/true branch retains literal `run_in_background: true`; the
false branch has literal `false` and no executor background instruction. This
is the required negative control—checking a word such as “foreground” is not
evidence of a blocking invocation.

The existing #3177 tests at `execute-phase-active-flags.test.cjs:460-555` also
show scope-preserving assertions: preserve Claude’s actual background-default
statement, the existing multi-plan instruction, tool-availability gating, and
the separate Codex synchronous rule. These tests verify shipped workflow text,
not host-lifecycle reliability across all host versions.

### Runtime conversion and installed projection

**Apply to:** `tests/runtime-converters.test.cjs` and generated install-tree
fixtures through their generator.

**Closest analog:** capability/config-derived dispatch gating in
`tests/runtime-converters.test.cjs:1471-1508`.

```js
assert.ok(
  /If `FLATTEN` is `false`[\s\S]{0,500}?run_in_background=true/.test(manager),
  'manager.md: expected run_in_background dispatch gated on FLATTEN=false',
);
assert.ok(
  !/`RUNTIME` is `codex`[\s\S]{0,500}?run_in_background=true/.test(manager),
);
```

Use the same positive plus anti-runtime-name form for the new config gate. The
Hermes converter test at `tests/hermes-skills-migration.test.cjs:676-681` proves
that colon-prose `run_in_background: true` is converted to a native flag; keep
both dispatch values literal so projection code can observe them. This
establishes conversion of the asserted source forms only; it does not establish
that a real one-shot host session remains alive.

New step files are installable assets. Follow the existing generated fixture
workflow paths (for example `tests/fixtures/install-tree/claude.json` contains
`execute-phase/steps/per-plan-executor-routing.md`). Regenerate rather than
hand-edit fixture JSON; the generated result must include the new fragment for
every applicable runtime.

### Public documentation, ADR, and release metadata

**Apply to:** `docs/CONFIGURATION.md`, `gsd-core/references/planning-config.md`,
the new ADR, generated ADR index, and a changeset.

**Configuration docs analog:**
`docs/CONFIGURATION.md:408-411` places the operator row beside
`workflow.use_worktrees` and `workflow.agent_hint_routing`; use that table form.
`planning-config.md:251-279` uses the corresponding complete-reference table.
Both descriptions must say default `true`, false is an executor-only opt-out,
and must explicitly exclude tool availability, isolation selection, and verifier
dispatch.

**ADR analog:** `docs/adr/1143-claude-orchestration-capability.md:1-18` uses an
issue-prefixed title, metadata bullets, and an honest `Proposed` status. Apply
the naming/status/index contract from `docs/adr/README.md:16-24, 48-64`; keep
the new ADR `Proposed` until the decision is ratified after its implementation
is actually in force.

```markdown
# ADR-1143: ... [Proposed]

- **Status:** Proposed
- **Date:** 2026-06-12
- **Issue:** [#1143](https://github.com/open-gsd/gsd-core/issues/1143)
```

`docs/adr/README.md:154-165` makes the index generated: run
`node scripts/gen-adr-index.cjs --write`; do not author its index row. Add the
required `Added` changeset as a source artifact, following `CONTRIBUTING.md`.

## Shared Patterns

### One policy, two representations

The central manifest accepts the key, the defaults manifest writes it for new
projects, and `SCHEMA_DEFAULTS` gives old/minimal projects the same effective
value. All three are required. A successful `config-set` alone does not prove
that an absent key preserves existing behavior.

### Configuration/capability, never runtime identity

The `ISOLATION` fragment’s fail-closed vocabulary and the converter tests both
forbid selecting behavior by `$RUNTIME`. Session survival is supplied by the
integrator’s configuration; it is distinct from where a worker runs.

### Source text is the deployed workflow contract

Workflow tests may inspect precise source text because the Markdown is shipped
and converted. Constrain each assertion to executor Agent blocks and include
the opposite condition. Do not “test” the feature by counting all occurrences
of `run_in_background`, which would accidentally include debug/verifier paths.

### Generated artifacts are outputs

Do not edit `gsd-core/bin/lib/*`, ADR index rows, or install-tree fixture JSON
by hand. Build/generator commands own those outputs. The planning and
implementation checks must verify generated sync after the authored inputs are
changed.

## No Analog Found

None. The new fragment is an intentional extraction, with multiple existing
`execute-phase/steps/` analogs; the new ADR is an issue-scoped instance of the
existing corpus pattern.

## Metadata

**Analog search scope:** `src/`, `gsd-core/bin/shared/`, `gsd-core/workflows/`,
`docs/`, `tests/`, `scripts/` at `upstream/next`
**Strong analogs read:** 11
**Pattern extraction date:** 2026-08-28
