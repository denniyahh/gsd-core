# Project Research Summary

**Project:** GSD Core contributions
**Domain:** Upstream Node/TypeScript CLI reliability work across persisted project state and multi-runtime configuration
**Researched:** 2026-08-02
**Confidence:** HIGH for the two confirmed local defects and their repository seams; MEDIUM for any external-host behavior not exercised in a host harness.

## Executive Summary

This first milestone is a deliberately narrow upstream reliability contribution for `@opengsd/gsd-core`. It addresses two confirmed ledger items: STATE-01, where `state planned-phase` can replace authoritative `STATE.md` activity frontmatter with stale equal-date body prose, and EFFORT-01, where partial effort configuration can retune unrelated agents and where configured, installed, and runtime-effective effort are conflated. Experts should treat these as separate vertical slices: preserve state intent through the existing locked read-modify-write seam, and resolve effort policy once before adapting it to each runtime's native delivery mechanism.

The recommended roadmap starts with the state write contract because it is a contained data-integrity defect with a direct command-level reproducer. It then establishes a shared effective-effort precedence contract—manifest defaults overlaid by partial configuration, with agent overrides retaining precedence—before changing installer, sync, reporting, or documentation surfaces. Claude inheritance must be rendered by omitting `effort:` from installed frontmatter; Codex remains an invocation/configuration surface using supported `model_reasoning_effort` values. A single fake cross-runtime renderer would obscure this real host distinction.

The primary risks are broadening the state fix into a synchronization rewrite, allowing a policy fix to drift between runtime and install-time resolvers, and declaring resolver output "effective" when installed Claude artifacts are stale. Mitigate them with exact raw-file read-back assertions, a precedence matrix exercised through both resolution paths, explicit configured/installed/effective attribution, idempotent sync tests, and canonical-source regeneration/parity checks. Ledger items 6 and 7, DevFlow work, automatic synchronization, global-model precedence changes, and a configuration UI remain deferred.

## Key Findings

### Recommended Stack

The existing repository stack is sufficient. Implement in canonical TypeScript `.cts` sources, compile to the shipped CommonJS `.cjs` runtime, and use the existing Node 22+/npm 10+ toolchain and `node:test` suites. This milestone needs no new framework, database, runtime, or test dependency. The durable data surfaces are filesystem-backed configuration, installed agent artifacts, and `STATE.md`; tests must read those final files back rather than inspect only pure functions.

**Core technologies:**

- **Node.js 22+ and npm 10+:** contributor and CI environment — use repository scripts and `npm ci`.
- **TypeScript `.cts` compiled to CommonJS `.cjs`:** canonical implementation and distributed runtime — edit `src/`, then build; do not treat `gsd-core/bin/lib/` as canonical source.
- **Node `node:test` / `node:assert/strict`:** existing regression framework — place deterministic tests in the owning state, resolver, command, and installed-runtime suites.
- **Existing filesystem state/config artifacts:** `STATE.md`, project/default configuration, installed Claude Markdown, and Codex TOML — assert the serialized artifact each consumer actually uses.
- **Repository verification scripts:** build, focused tests, affected/install tests, generated-sync, and CI lint — guard generated/runtime parity after source or reference changes.

### Expected Features

**Must have (first-milestone table stakes):**

- **STATE-01 authoritative activity preservation:** `state planned-phase` retains authoritative `last_activity` and `last_activity_desc` when same-date body prose is stale, while preserving legitimate planned-phase body and status behavior.
- **STATE-01 command-level reproducer:** a full read-modify-write fixture asserts the final YAML frontmatter and expected body/progress mutation, not merely the command `updated` list.
- **EFFORT-01 partial-config merge:** unspecified routing tiers retain manifest defaults when a user supplies partial `agent_overrides` or `routing_tier_defaults`.
- **EFFORT-01 Claude inheritance:** a documented inheritance policy yields an omitted Claude `effort:` key and converges across sync dry-run/apply cycles.
- **EFFORT-01 value provenance:** inspection/reporting distinguishes configured policy from persisted installed value and actual/predicted runtime value where those differ.
- **EFFORT-01 documentation:** the model-profile reference accurately describes installation-time Claude effort, runtime-specific surfaces, explicit sync, and configuration scope.
- **QUALITY-01 cross-surface regressions:** focused state, resolver, sync, installer, and runtime-artifact tests protect the two delivered fixes.

**Should have (only if it stays within item 10):**

- **Additive effective-configuration metadata:** make runtime, source, and drift visible in existing query JSON without silently redefining current fields.
- **Actionable Claude drift reporting:** show pending `effort sync --apply` work without automatically modifying installed files.
- **Narrow ignored-global-model diagnostic:** document or report current scope instead of silently changing global model-default precedence.

**Defer (outside this milestone):**

- A global rewrite of STATE.md field synchronization or field ownership.
- A universal model/effort renderer, automatic install/sync after configuration edits, or a profile-management UI.
- Global model-default precedence migration, ledger items 6 and 7, DevFlow changes, and unrelated workflow work.

### Architecture Approach

Treat the work as two isolated vertical slices backed by shared repository conventions. STATE-01 belongs in the existing locked `STATE.md` pipeline: transition intent in `src/state-transition.cts`, command adapter and read-modify-write/synchronization in `src/state.cts`, then a single final document write. EFFORT-01 has a shared policy boundary but distinct consumers: runtime resolution (`src/model-resolver.cts`), installation-time resolution (`src/install-effort-resolver.cts`), artifact projection (`bin/install.js`), installed-Claude repair (`src/commands.cts`), and reporting/docs. Policy must be runtime-neutral; renderers own platform syntax; reporting owns attribution.

**Major components:**

1. **`plannedPhaseCore` in `src/state-transition.cts`:** owns only transition intent and the activity values it deliberately changes; it does not own locks, YAML serialization, or disk writes.
2. **`readModifyWriteStateMd` in `src/state.cts`:** sole lock/sync/write boundary; applies narrowly supplied authoritative frontmatter after body-derived fallback synchronization.
3. **Effective-effort policy in resolver modules:** merges manifest tier defaults with valid partial user overrides and models inheritance as semantic policy, before runtime adaptation.
4. **Runtime renderers and sync paths:** serialize Claude inheritance by omission; preserve Codex's existing supported effort/pinning rules; never leak Claude syntax into another runtime.
5. **Inspection/reporting and docs:** state whether a value is configured, installed, effective, predicted, or drifted rather than conflating sources.

### Critical Pitfalls

1. **Assuming `resync: false` preserves all frontmatter** — it protects progress behavior, but frontmatter synchronization still runs. Exercise `state planned-phase` end to end and assert the written YAML block.
2. **Freezing all frontmatter to solve STATE-01** — blanket preservation blocks valid status/template updates. Carry only transition-owned activity metadata through the existing authoritative seam and retain status compatibility coverage.
3. **Bypassing the state writer with a direct YAML write** — that skips locking, no-op handling, cache invalidation, and safe I/O. Keep the repair inside `readModifyWriteStateMd`.
4. **Replacing tier defaults when any effort block exists** — a small partial config can change many unnamed agents. Overlay valid user tier entries on manifest defaults and test every unaffected tier.
5. **Writing `effort: inherit` for Claude** — inheritance is an omitted host key, not a literal frontmatter value. Verify an apply followed by dry-run is clean.
6. **Equating a resolver result with installed Claude behavior** — resolver-only tests leave stale installed agents undetected. Verify config, report, sync output, actual frontmatter, and a second dry-run together.
7. **Editing distributed CJS directly or skipping generated parity** — change canonical sources, build outputs, inspect the diff, and run generated/runtime verification.

## Implications for Roadmap

Based on the combined evidence, use three implementation phases with quality gates embedded in each—not a broad configuration/state refactor.

### Phase 1: Planned-Phase State Integrity

**Rationale:** STATE-01 is a confirmed silent data-loss defect with a small, existing ownership seam. It has no dependency on item 10 and should establish the project’s raw-artifact verification standard first.

**Delivers:** A command-boundary regression with equal-date stale body prose; a narrow change that carries transition-authoritative activity metadata through `readModifyWriteStateMd`; preservation of valid planned-phase body, plan-count, and status behavior.

**Addresses:** STATE-01 and the STATE portion of QUALITY-01.

**Uses/implements:** `src/state-transition.cts`, `src/state.cts`, existing state document primitives, and `tests/state.test.cjs`/`tests/state-transition.test.cjs`.

**Avoids:** reliance on `resync: false`, body-only tests, direct YAML writes, and a frontmatter-always-wins rule.

### Phase 2: Effective-Effort Policy Contract

**Rationale:** Both runtime and install-time paths currently need the same precedence correction. Establishing the policy before touching artifact writers prevents divergent implementations and makes later renderer work mechanical.

**Delivers:** A defined configured-policy result; manifest defaults merged with partial tier overrides; preserved precedence for invocation, agent, tier, default, escalation, and invalid-value fallback cases; an inheritance sentinel that remains semantic until rendering.

**Addresses:** EFFORT-01 partial-configuration safety and the policy half of Claude inheritance.

**Uses/implements:** `src/model-resolver.cts`, `src/install-effort-resolver.cts`, configuration-loading behavior, and a shared matrix in `tests/model-resolver.test.cjs` plus installer/resolver-adjacent tests.

**Avoids:** silently changing global model precedence, reordering existing override precedence, treating inheritance as a concrete effort, or introducing a universal host renderer.

### Phase 3: Runtime Projection, Effective Reporting, and Documentation

**Rationale:** Once policy is stable, install/sync/reporting can correctly represent each host’s surface and expose drift without claiming uninstalled configuration is already active.

**Delivers:** Idempotent Claude frontmatter omission/removal for inheritance; retained Codex runtime constraints; additive configured/installed/effective or predicted reporting; installed-runtime sync tests; and accurate `model-profiles.md` guidance.

**Addresses:** EFFORT-01 inheritance, effective-value consistency, documentation, and the remaining QUALITY-01 cross-surface coverage.

**Uses/implements:** `bin/install.js`, `src/commands.cts`, installed artifact converters, `tests/commands.test.cjs`, `tests/effort-sync-installed-runtime.test.cjs`, `tests/install-runtime-artifacts.test.cjs`, `tests/codex-config.test.cjs`, and `gsd-core/references/model-profiles.md`.

**Avoids:** automatic synchronization, literal Claude inheritance values, stale effective claims, and Claude-specific frontmatter leaking into Codex.

### Phase Ordering Rationale

- Phase 1 is independent and confines a data-integrity repair to one locked write pipeline.
- Phase 2 must precede Phase 3 because projection, synchronization, and reporting need one stable precedence/inheritance policy to consume.
- Phase 3 groups every persisted/runtime delivery surface so a change cannot pass pure resolver tests while leaving installed artifacts stale.
- Each phase adds its owning regression first, then runs focused checks; only after source/reference changes should package-wide derived/runtime gates execute.

### Research Flags

Phases likely needing deeper research during planning:

- **Phase 2:** confirm the exact typed policy/result shape and precedence compatibility against all existing resolver cases; this is local-code research, not a reason to broaden model precedence.
- **Phase 3:** recheck current official Claude and Codex host contracts immediately before accepting syntax/behavior claims; verify host adapters with hermetic installed-artifact fixtures.

Phases with standard patterns (skip a broad research phase):

- **Phase 1:** the repository already supplies a confirmed reproduction, source seam, writer option, and owning test suite. Plan narrowly from those local facts.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Node/npm, TypeScript-to-CJS build flow, scripts, source paths, and test ownership were confirmed in the repository research. |
| Features | HIGH | First-milestone requirements map directly to PROJECT.md and confirmed ledger items 9 and 10. |
| Architecture | HIGH | State and effort component boundaries were traced in local source and regression suites. |
| Pitfalls | HIGH (local); MEDIUM (host semantics) | State/sync/default-merge failures are locally evidenced; external host interpretation must remain tied to current official documentation or a harness. |

**Overall confidence:** HIGH for the recommended three-phase roadmap and local acceptance criteria.

### Gaps to Address

- **State status ownership:** Item 9 must not silently redefine the existing `Ready to execute` to `executing` normalization. Preserve its current tests; change it only under separately accepted scope.
- **Public reporting schema:** Decide whether provenance is additive fields or a versioned output contract before implementation, to avoid breaking `resolve-execution` consumers.
- **Global defaults asymmetry:** Local research confirms different model and effort resolution branches. Do not "symmetrize" them here; add only a diagnostic/documentation clarification unless a separate migration is approved.
- **External host claims:** The Claude omission and Codex effort recommendations are source-backed compatibility guidance, not a substitute for fresh official-documentation review and hermetic artifact tests at implementation time.
- **Generated/release surface:** Determine exactly which generated references and installed-runtime checks are affected by the final changed files, then run the repository-defined gates rather than assuming focused unit tests are sufficient.

## Sources

### Primary — confirmed local evidence (HIGH)

- [.planning/PROJECT.md](../PROJECT.md) — active scope, constraints, and explicit deferrals for the first milestone.
- [STACK.md](STACK.md), [FEATURES.md](FEATURES.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [PITFALLS.md](PITFALLS.md) — synthesized research inputs, each based on inspected repository source/test seams and the issue ledger.
- `scratch/UPSTREAM-GSD-ISSUES.md`, items 9 and 10 — confirmed reproductions and bounded issue context.
- `src/state-transition.cts`, `src/state.cts`, `src/model-resolver.cts`, `src/install-effort-resolver.cts`, `src/commands.cts`, and `bin/install.js` — implementation boundaries.
- `tests/state.test.cjs`, `tests/state-transition.test.cjs`, `tests/model-resolver.test.cjs`, `tests/commands.test.cjs`, `tests/effort-sync-installed-runtime.test.cjs`, `tests/install-runtime-artifacts.test.cjs`, and `tests/codex-config.test.cjs` — regression surfaces.

### External source-backed recommendations (HIGH, revalidate at implementation)

- [OpenAI Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference) — supported `model_reasoning_effort` configuration and precedence guidance.
- [Claude Code custom subagents reference](https://code.claude.com/docs/en/sub-agents) — optional subagent `effort` frontmatter and session inheritance by omission.

### Deferred / non-authoritative for this milestone

- Ledger items 6 and 7, DevFlow orchestration, global model-precedence migration, automatic sync, and UI/editor work are intentionally not roadmap inputs beyond documenting their deferral.

---
*Research completed: 2026-08-02*
*Ready for roadmap: yes*
