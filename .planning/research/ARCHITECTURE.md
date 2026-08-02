# Architecture Patterns

**Domain:** Upstream GSD Core reliability fixes — STATE.md transition integrity and model/effort resolution
**Researched:** 2026-08-02

## Recommended Architecture

Treat the two ledger items as separate vertical slices. Item 9 belongs entirely to the locked `STATE.md` read-modify-write pipeline. Item 10 has one shared policy boundary but three deliberately different consumers: runtime resolution, install-time projection, and installed-Claude synchronization. Do not make either change in a workflow Markdown file or in runtime-specific adapters first.

```text
Item 9: plan-phase workflow
  -> `state planned-phase` CLI adapter (`src/state.cts`)
  -> pure intent transform (`src/state-transition.cts`)
  -> locked write + frontmatter sync/preservation (`src/state.cts`)
  -> `.planning/STATE.md`

Item 10: config layers + manifest defaults
  -> shared effective-effort policy (pure)
  -> runtime query: `model-resolver.cts` / `resolve-execution`
  -> projection: `bin/install.js` (Claude `.md`, Codex `.toml`)
  -> repair: `commands.cts` / `effort sync` (installed Claude agents)
  -> truthful query/reporting plus `model-profiles.md`
```

### Verified Current Source Facts

| Component | Responsibility | Communicates With |
|-----------|----------------|-------------------|
| `src/state-transition.cts` | `plannedPhaseCore` changes body fields and retains the original frontmatter while returning an intent-level `updated` list. It knows `status`, `last_activity`, and `last_activity_desc` are classified fields, but it does not pass authoritative values to the write seam. | `src/state.cts` adapter and `state-document.cts` field primitives |
| `src/state.cts` | `cmdStatePlannedPhase` wraps the transition in `readModifyWriteStateMd(..., { resync: false, deriveProgressKeys: true })`; the write seam locks, syncs frontmatter, then applies preservation. `ReadModifyWriteOptions` already supports `authoritativeFm`. | `src/state-transition.cts`, `.planning/STATE.md` |
| `src/model-resolver.cts` | Runtime query policy calls `loadConfig(cwd)` and emits a universal configured effort from `resolveEffortInternal`; its accepted `EFFORT_SET` has no `inherit`. When any `effort` block exists, a missing tier mapping falls through rather than using manifest tier defaults. | `src/config-loader.cts`, model catalog/profile modules, `resolve-model`/`resolve-execution` commands |
| `src/install-effort-resolver.cts` | Installer/sync-only resolver reads home defaults and project config, merges some effort fields, then resolves a scalar effort. It has the same partial-tier-default fall-through. | `bin/install.js`, `src/commands.cts` |
| `bin/install.js` | Projects canonical agent Markdown into runtime artifacts. Claude gets injected `effort:` frontmatter; Codex emits `model_reasoning_effort` only when a model is pinned. | `src/install-effort-resolver.cts`, runtime layout/conversion, installed runtime homes |
| `src/commands.cts` | `cmdEffortSync` reuses the install-time resolver and rewrites installed Claude agent frontmatter; current helper always adds or replaces `effort:`. | Installed `~/.claude/agents/gsd-*.md` files |
| `src/config-loader.cts` | Project configs and `~/.gsd/defaults.json` are different resolution branches: global defaults are read only when no `.planning/` exists for runtime model resolution. | `model-resolver.cts` |

### Component Boundaries

1. **State intent owns only fields the transition intentionally changes.** `plannedPhaseCore` should produce both changed body text and authoritative frontmatter values for those fields. It must not absorb disk scanning, locking, YAML serialization, or generic preservation policy.
2. **The STATE write seam owns synchronization and accounting.** `readModifyWriteStateMd` is the sole lock/write boundary. It should apply intent-owned values after lossy body derivation and expose the final frontmatter changes in its result, or accept a callback/result shape that lets the CLI report them. Preserve the existing `resync: false` protection against half-planned progress snapshots.
3. **One effective-effort policy owns precedence and inheritance semantics.** Define/configure the universal result before adapting it: manifest tier defaults merged with partial user tier overrides; agent override wins; `inherit` is a semantic value, not a renderer-specific string.
4. **Renderers own runtime representation only.** Claude maps universal `inherit` to an omitted frontmatter key; Codex keeps its existing model-pinned gate and maps supported values into TOML; unsupported runtimes receive no Claude-only key. The model resolver must not read installed agent files as its only source of policy.
5. **Reporting owns attribution.** A query must label values as `configured`/`resolved` versus `installed`/`effective` when the runtime uses persisted artifacts. Do not report one scalar as effective for Claude unless it has verified the installed frontmatter or explicitly says it is predicted.

### Data Flow

**Item 9 (target flow):** `plan-phase.md` invokes `state planned-phase` → `cmdStatePlannedPhase` creates a `plannedPhase` intent → `transitionCore` returns body text plus intent-owned frontmatter (`status`, activity date/description only when actually changed) → `readModifyWriteStateMd` holds the lock, derives fallback frontmatter, applies generic preservation, then applies authoritative intent values and computes a frontmatter diff → writes one complete `STATE.md` document and returns/report final changed fields.

**Item 10 (target flow):** home defaults + project/workstream config + manifest defaults → pure effective-policy result (including source/precedence and `inherit`) → runtime resolver emits the configured/predicted value → installer and `effort sync` call the same policy → runtime renderer either omits or writes its native representation → query reporting compares with persisted target where applicable and identifies drift.

## Patterns to Follow

### Pattern 1: Intent-first values through a locked synchronization seam

**What:** Use the existing `authoritativeFm` option rather than adding a second STATE.md writer. Extend the transition result/adapter so values are supplied only for fields this intent owns and changed.

**When:** A body transform has more precise data than `buildStateFrontmatter` can reconstruct from free-form historical prose.

**Example:**

```typescript
readModifyWriteStateMd(statePath, transform, cwd, {
  resync: false,
  deriveProgressKeys: true,
  authoritativeFm: {
    // only fields owned and intentionally changed by plannedPhase
    last_activity_desc: plannedDescription,
  },
});
```

The exact status policy needs an explicit product decision: preservation of a prior shipped-phase status and representing “Ready to execute” must not be silently conflated with “executing.”

### Pattern 2: Policy → renderer → artifact verification

**What:** Resolve a typed universal effort result first, then render it separately for Claude/Codex. Tests assert both the policy result and the serialized installed artifact.

**When:** A setting is configured once but consumed at different times or through runtime-specific channels.

**Example:**

```typescript
const resolved = resolveEffectiveEffort(configLayers, agent);
// Claude: inherit => omit `effort:`; value => emit native frontmatter.
// Codex: only emit model_reasoning_effort when the model remains pinned.
```

### Anti-Patterns to Avoid

### Anti-Pattern 1: Fixing stale STATE data with another body heuristic

**Why bad:** The failing layout has no `Last Activity Description` body field. Adding another broad prose scan repeats the ambiguity that caused the overwrite.

**Instead:** Carry the transition’s explicit value via `authoritativeFm`; use body parsing only as fallback for transforms without intent-owned data.

### Anti-Pattern 2: Making Claude’s installed frontmatter the universal resolver

**Why bad:** It makes configuration results dependent on an installation that may be absent or stale, and cannot represent Codex’s per-agent TOML gate.

**Instead:** Keep a pure policy result and inspect artifacts only to report Claude effective/drift state.

### Anti-Pattern 3: Adding `inherit` as a literal Claude frontmatter value

**Why bad:** Claude inheritance is represented by absence. A literal leaks an internal policy token into host syntax.

**Instead:** Have the Claude renderer and `effort sync` delete/omit the key for `inherit`; add idempotence tests for the absent-key state.

## Suggested Build and Verification Order

1. **Item 9: reproduce at the command boundary, then repair the write contract.**
   - Add a fixture in `tests/state.test.cjs` with equal `last_activity` dates but divergent accurate frontmatter and stale body description; invoke `state planned-phase` and assert final frontmatter, body, and reported changes.
   - Add a focused pure transition assertion in `tests/state-transition.test.cjs` only for the transition-result contract, then modify `src/state-transition.cts` and `src/state.cts` together. This keeps the lock/write ownership intact.
   - Run the focused state suites after `npm run build:lib`, because tests import `gsd-core/bin/lib/*.cjs` emitted from `src/*.cts`.

2. **Item 10a/10c/10d: establish the shared effective-effort contract before artifact changes.**
   - Change the canonical policy/types and both callers (`src/model-resolver.cts`, `src/install-effort-resolver.cts`) in one phase, avoiding separate, drifting precedence edits.
   - Add a resolver matrix in `tests/model-resolver.test.cjs` and installer-focused tests in `tests/install-runtime-artifacts.test.cjs`: partial tier override retains manifest values; explicit agent override wins; `inherit` stays semantic until rendering.

3. **Item 10a/10b presentation and installer/sync projection.**
   - Update `bin/install.js` and `src/commands.cts` to make Claude omission/removal idempotent, preserve the existing Codex pinning gate, and report configured versus installed/effective effort without claiming stale predictions are active.
   - Cover installed-runtime execution in `tests/effort-sync-installed-runtime.test.cjs`, sync behavior in `tests/commands.test.cjs`, and projection in `tests/install-runtime-artifacts.test.cjs` plus `tests/codex-config.test.cjs`.
   - Then update `gsd-core/references/model-profiles.md` so documentation describes the install-time/runtime distinction and sync requirement.

4. **Regenerate and verify package surfaces last.**
   - Build generated CommonJS after source edits; run focused tests first, then `npm run test:affected`, `npm run test:install`, and `npm run lint:generated-sync`. Do not change generated artifacts by hand.

This order puts the single-file state mutation first, establishes item 10 policy before any runtime artifact writer, and keeps documentation last so it describes a verified contract rather than an intermediate implementation.

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| STATE.md writes | One lock + atomic full-document write; correctness dominates. | Same local-workspace lock model; retain no-op guard. | No shared service involved; avoid adding cross-project state. |
| Runtime matrix | Claude/Codex artifact fixtures catch primary divergence. | Expand fixture matrix for supported host renderers. | Keep policy runtime-neutral and renderers table-driven; runtime-name forks become release risk. |
| Config drift | `effort sync` makes it visible/reparable. | Report configured vs installed values and batch dry-run changes. | Preserve deterministic resolver outputs and idempotent installs for fleet automation. |

## Sources

- Verified local source: `src/state-transition.cts`, `src/state.cts`, `src/state-document.cts`, `src/model-resolver.cts`, `src/install-effort-resolver.cts`, `src/config-loader.cts`, `src/commands.cts`, and `bin/install.js` (reviewed 2026-08-02).
- Verified local regression surfaces: `tests/state.test.cjs`, `tests/state-transition.test.cjs`, `tests/model-resolver.test.cjs`, `tests/commands.test.cjs`, `tests/effort-sync-installed-runtime.test.cjs`, `tests/install-runtime-artifacts.test.cjs`, and `tests/codex-config.test.cjs`.
- Issue evidence: `scratch/UPSTREAM-GSD-ISSUES.md` items 9 and 10; architecture risk context: `.planning/codebase/CONCERNS.md`.
