# Technology Stack

**Project:** GSD Core contribution milestone — planned-phase STATE frontmatter and effective model/effort
**Researched:** 2026-08-02

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why |
|---|---:|---|---|
| Node.js | 22+ | Contributor and CI runtime | Confirmed by `package.json`, `.nvmrc`, and CI. Do not introduce a runtime or a framework for either fix. |
| npm | 10+ | Locked dependency install and scripts | Confirmed engine floor and lockfile workflow. Use `npm ci` before verification. |
| TypeScript `.cts` → CommonJS `.cjs` | TypeScript 6.0.3 | Canonical implementation and shipped runtime | Change `src/*.cts`, then compile with `npm run build:lib`; do not hand-edit `gsd-core/bin/lib/*.cjs` as the source of truth. |
| Node built-in test runner | Node 22+ | Unit, CLI, installed-runtime, and integration regression tests | Existing suites use `node:test`; matching the existing seam gives focused, reproducible checks without adding a test framework. |

### Database

| Technology | Version | Purpose | Why |
|---|---:|---|---|
| Filesystem-backed Markdown/JSON configuration | Existing | `STATE.md`, project config, global defaults, and installed agent frontmatter | These fixes are representation/precedence defects, not database work. Treat frontmatter and emitted agent files as durable state that must be read back in tests. |

### Infrastructure

| Technology | Version | Purpose | Why |
|---|---:|---|---|
| `scripts/run-tests.cjs` / npm suites | Existing | Repository test orchestration | Use the defined suites rather than bespoke shell harnesses; they encode the project’s test taxonomy. |
| `npm run lint:generated-sync` | Existing | Derived artifact drift gate | Required after canonical `src/` or shipped-reference changes. It detects stale compiled/generated artifacts and registries. |
| Minimal runtime install fixture | Existing test helper | Verify Claude effort-sync behavior after installation | `effort sync` runs against installed `gsd-core/bin/lib`, so resolver-only tests cannot prove the shipped behavior. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| `node:test` + `node:assert/strict` | Node built-in | Regression assertions | Add the item-9 CLI/read-back case to `tests/state.test.cjs`; add item-10 matrix assertions to existing resolver/commands/install suites. |
| `fast-check` | Existing dev dependency | Property coverage | Do not use for these first regressions; the defects require small named fixtures with exact provenance and emitted-artifact assertions. |
| `c8` | Existing dev dependency | Coverage gate | Run the unit coverage suite once focused tests pass; it protects the compiled runtime modules touched by either fix. |

## Confirmed Contribution Seams

### STATE-01: planned-phase frontmatter preservation

**Confirmed source path:** `src/state-transition.cts` owns `plannedPhaseCore`; `src/state.cts` owns `readModifyWriteStateMd` and `syncStateFrontmatter`. The field classification already marks `last_activity_desc` as body-sourced with `preserve-when-unchanged`; the planned-phase adapter uses the read-modify-write seam with `resync: false`.

**Recommendation:** keep the fix inside these state seams. The command-level transition must explicitly preserve or reassert the transition-authoritative activity metadata before the generic body-to-frontmatter synchronizer can reuse stale prose. Do not solve it by weakening global synchronization for every command, and do not make status normalization an incidental part of this narrow fix unless its own reproducible contract is separately accepted.

**Required regression shape:** in `tests/state.test.cjs`, write a full `STATE.md` fixture whose frontmatter has the authoritative `last_activity` and `last_activity_desc`, while its body has an equal-date stale `Last activity:` prose description. Execute `state planned-phase`, then parse/read the *raw written file* and assert the authoritative frontmatter description survives. Also assert the legitimate body/plan-count update still occurs. A pure `plannedPhaseCore` test alone is insufficient because the loss occurs in the read-modify-write post-sync seam.

### EFFORT-01: effective model and reasoning-effort consistency

**Confirmed source paths:** `src/model-resolver.cts` computes runtime resolution; `src/install-effort-resolver.cts` resolves installation-time Claude effort; `src/commands.cts` exposes `resolve-execution` and `effort sync`; `gsd-core/references/model-profiles.md` states the user contract. The current code intentionally has host-specific propagation: `resolve-execution` reports a channel, Claude uses frontmatter, and Codex uses `model_reasoning_effort`.

**Recommendation:** define an explicit three-value contract per agent: **configured** (resolved policy), **rendered** (runtime-specific value/channel), and **effective** (what the installed/runtime host will consume). Preserve the host split; do not force Claude install-time frontmatter and Codex invocation-time configuration through one fake common mechanism. For Claude inheritance, model it as an omitted `effort:` key, not an invented frontmatter literal. Merge a partial `routing_tier_defaults` map over manifest defaults so a named override cannot silently reset unrelated agents to the generic default.

**Required regression matrix:**

| Case | Required assertion | Best existing test surface |
|---|---|---|
| Partial `effort.agent_overrides` only | Unspecified light/standard/heavy agents retain manifest tier defaults | `tests/model-resolver.test.cjs` plus an install-time resolver test nearby |
| Claude `inherit` | Sync/install omits `effort:` and a second dry-run is idempotent | `tests/commands.test.cjs` and `tests/effort-sync-installed-runtime.test.cjs` |
| Claude configured vs installed | Reporting labels the installed-frontmatter value or explicitly distinguishes it from policy resolution | `tests/model-resolver.test.cjs` + a hermetic installed-agent fixture |
| Codex | Output emits `model_reasoning_effort` only for a supported effort; no Claude-frontmatter assumption leaks into it | `tests/model-resolver.test.cjs` / `tests/effort-surface-axis.test.cjs` |
| Docs | The profile reference describes runtime/install split and inheritance accurately | `tests/docs-parity-live-registry.test.cjs` if the documentation change touches registered facts; otherwise direct document assertions only where an existing suite owns them |

Official host contracts make this separation non-negotiable: Codex accepts `model_reasoning_effort` values `minimal` through `xhigh`, while Claude Code treats subagent `effort` as optional frontmatter and inherits the session effort when it is omitted. [OpenAI Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference) [Claude Code subagent frontmatter reference](https://code.claude.com/docs/en/sub-agents)

## Verification Gates

Run these in order after each focused change. Commands are recommendations based on current package scripts and test ownership; none were executed by this research task.

1. **Environment and compilation**

   ```bash
   npm ci
   npm run check:env
   npm run build:lib
   ```

   The compiled `gsd-core/bin/lib/*.cjs` tree is what tests and installed runtime paths execute.

2. **Focused STATE-01 gate**

   ```bash
   node --test tests/state.test.cjs tests/state-transition.test.cjs tests/state-command-cutover.test.cjs
   ```

   Add and run the equal-date raw-frontmatter read-back regression first. Keep a control assertion that a changed body source may still legitimately update its derived field.

3. **Focused EFFORT-01 gate**

   ```bash
   node --test tests/model-resolver.test.cjs tests/commands.test.cjs tests/effort-surface-axis.test.cjs tests/effort-sync-installed-runtime.test.cjs tests/install-runtime-artifacts.test.cjs
   ```

   Use isolated temporary config and runtime homes. Never point `effort sync --apply` at a contributor’s real agent directory.

4. **Derived and policy gates**

   ```bash
   npm run lint
   npm run lint:generated-sync
   npm run test:unit
   npm run test:coverage:unit
   ```

   `lint:generated-sync` is mandatory if a canonical source or shipped reference changes. The coverage run is the practical regression gate for the compiled runtime modules.

5. **Release-surface confidence before an upstream PR**

   ```bash
   npm run test:install
   npm run lint:ci
   ```

   Run `test:install` whenever effort-sync/install output changes. Run `lint:ci` as the final repository-defined aggregate gate, after narrower failures have been fixed.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|---|---|---|---|
| STATE preservation | Command-level authoritative value through existing RMW seam | Global preference for frontmatter over body | Would change unrelated state commands and can retain stale frontmatter when the current command intentionally changed the body source. |
| Effort inheritance | Omit Claude `effort:` for `inherit`; render Codex configuration separately | Write `effort: inherit` everywhere | Claude’s documented inheritance mechanism is omission, so a literal would be an unsupported host contract. |
| Partial tiers | Overlay user tiers on manifest tiers | Replace the whole tier map when any effort block exists | Recreates the confirmed unrelated-agent downgrade/upgrade failure. |
| Verification | Hermetic CLI + raw artifact read-back | Resolver/pure-function assertions only | Pure resolver tests miss installation-time frontmatter and post-sync serialization. |
| Scope | Two independently reviewable fixes with dedicated regression tests | Broad config/state refactor | Raises runtime and generated-artifact risk without advancing STATE-01/EFFORT-01. |

## Installation

```bash
# Contributor setup (Node 22+, npm 10+)
npm ci
npm run check:env
npm run build:lib

# Focused verification examples
node --test tests/state.test.cjs tests/state-transition.test.cjs
node --test tests/model-resolver.test.cjs tests/commands.test.cjs tests/effort-sync-installed-runtime.test.cjs
```

## Sources

- Repository primary source: `package.json`, `src/state.cts`, `src/state-transition.cts`, `src/model-resolver.cts`, `src/install-effort-resolver.cts`, and `src/commands.cts` (HIGH — checked in this worktree, 2026-08-02).
- Repository primary tests: `tests/state.test.cjs`, `tests/state-transition.test.cjs`, `tests/model-resolver.test.cjs`, `tests/commands.test.cjs`, `tests/effort-surface-axis.test.cjs`, and `tests/effort-sync-installed-runtime.test.cjs` (HIGH — checked in this worktree, 2026-08-02).
- [OpenAI Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference) (HIGH — current official documentation; `model_reasoning_effort` values and override precedence).
- [Claude Code custom subagents reference](https://code.claude.com/docs/en/sub-agents) (HIGH — current official documentation; optional `effort` frontmatter defaults to session inheritance and model precedence).
