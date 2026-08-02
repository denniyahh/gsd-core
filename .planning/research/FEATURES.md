# Feature Landscape

**Domain:** Upstream GSD Core reliability contribution: planned-phase state preservation and effective model/effort configuration
**Researched:** 2026-08-02
**Confidence:** HIGH — requirements are based on confirmed current-source reproductions, the project acceptance requirements, and existing test contracts.

## Table Stakes

Features users and maintainers need for the first contribution milestone. IDs map directly to the active project requirements and issue-ledger items.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **STATE-01 / item 9: preserve authoritative planned-phase activity frontmatter** | Planning a new phase must not silently overwrite the preceding phase's accurate completion description with stale same-date body prose. This is a confirmed, repeatable data-loss defect. | Med | Given equal `last_activity` dates but differing body/frontmatter descriptions, `state.planned-phase` must retain the transition-owned or existing authoritative frontmatter value. Assert final `STATE.md` frontmatter, not only the command's `updated` list. Preserve intentional status normalization (`Ready to execute` → `executing`) as existing behavior. |
| **STATE-01: honest command-level regression coverage** | The current output can report only `Status` while changing unrelated fields; a pure-transform test would miss the write/sync defect. | Med | Add the reproducing fixture to the owning state suite (`tests/state.test.cjs` is the mapped location) and execute the full read–modify–write command path. Assert body changes required by planning still occur, while `last_activity_desc` does not regress. |
| **EFFORT-01 / item 10: partial effort configuration preserves manifest tier defaults** | Naming a few agents must not retune every unnamed agent. The current partial config can change 23 installed agents; that makes configuration unsafe to reason about. | Med | Merge `effort.routing_tier_defaults` over manifest defaults before applying `effort.default`/per-agent overrides. Regression matrix: no effort block, partial `agent_overrides`, partial tier map, explicit tier map, and unaffected agents at light/standard/heavy tiers. |
| **EFFORT-01 / item 10: declarable Claude inheritance** | A user selecting inheritance must get Claude's documented behavior: omitted `effort:` frontmatter and session inheritance, with subsequent sync/install retaining that omission. | Med | Accept a documented inheritance configuration value, render it by omitting `effort:` for Claude only, and make dry-run/apply idempotent when the key is absent. Do not emit a literal unsupported Claude `effort: inherit`. |
| **EFFORT-01 / item 10: distinguish configured, installed, and effective values** | `resolve-execution` must not present a resolver value as the value a Claude agent actually uses when installed frontmatter differs. | High | Report provenance or separately named values sufficient to tell: configuration-resolved value, installed Claude frontmatter value (including inherit/omitted), and runtime-effective value. For spawn-argument runtimes, retain their invocation-time reporting. Avoid changing existing fields without a compatibility plan. |
| **EFFORT-01 / item 10: explain the runtime/install split and configuration scope** | The docs currently claim model and effort share precedence, but source confirms Claude effort is materialized at install/sync time and global defaults have different scope. | Low | Update the canonical model-profile guidance to state which mechanism resolves each runtime, when `effort sync --apply` is necessary, and what happens when project config causes global model defaults to be ignored. The docs must describe, not erase, platform differences. |
| **QUALITY-01: focused, cross-surface verification** | Each milestone fix needs a reproducing regression and evidence that its actual delivery surface is correct. | Med | Item 9: state command-level test. Item 10: resolver + installed-frontmatter/sync fixture matrix, including a Claude inheritance assertion and a non-Claude invocation surface. Run focused suites first, then affected-test selection; run generated/parity checks if canonical generated artifacts change. |

## Differentiators

Useful additions only when they directly make the confirmed item-10 contract inspectable; do not let them displace the table stakes above.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **One explicit effective-configuration inspection schema** | Maintainers and users can diagnose a mismatch without reading resolvers or installed files manually. | Med | Prefer additive JSON metadata/provenance on the existing query over a separate interactive UI. It must identify the runtime and the source/time of each result, not imply all runtimes have the same application mechanism. |
| **Actionable drift state for Claude effort** | A config change that has not been synchronized becomes visible before users assume it is active. | Med | Dry-run may report pending frontmatter changes and recommend `effort sync --apply`; it must not mutate agent files automatically or claim the unsynced config is effective. |
| **Narrow ignored-global-model diagnostic** | A project with global model defaults gets a clear explanation rather than silent non-application. | Low | Warning/reporting is sufficient for this milestone if changing global model precedence would affect established project isolation semantics. |

## Anti-Features

Explicit deferrals prevent this milestone from becoming a runtime/configuration redesign.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Rewrite all STATE.md synchronization or redefine all field ownership** | Item 9 is a narrow equal-date preservation defect. Broad changes risk status, count, and legacy-template compatibility regressions across the dual body/frontmatter representation. | Pass only the planned transition's authoritative activity values through the existing write seam; protect with the exact full-command regression. |
| **Treat every frontmatter field as immutable during planned-phase** | Some fields are intentionally updated/normalized by planning. Blanket preservation would break valid state transitions. | Preserve the identified authoritative activity metadata while retaining documented planned-phase changes. |
| **Force one shared runtime resolver for model and effort** | Claude uses installed frontmatter while Codex-style runtimes can use invocation arguments; the platform surfaces genuinely differ. | Define one *reporting/precedence contract* with runtime-specific application adapters. |
| **Silently change global model-default precedence** | Changing whether `~/.gsd/defaults.json` applies to projects may unexpectedly override project intent and broaden the milestone into configuration-policy migration. | Report or document the current scope first; propose any precedence change separately with migration analysis. |
| **Automatic reinstall/sync after every config edit** | This creates unexpected writes to installed runtime artifacts and complicates cross-runtime behavior. | Keep `effort sync --apply` explicit; make drift and the necessary action visible. |
| **New profile editor, dashboard, or bulk model-management UI** | The acceptance problem is correctness and observability of existing CLI/config surfaces, not a new management product. | Improve existing query output, docs, and focused commands only. |
| **Ledger items 6 or 7, DevFlow changes, unrelated workflow work** | PROJECT.md explicitly defers them from this first milestone. | Keep requirements and tests scoped to items 9 and 10. |

## Feature Dependencies

```text
STATE-01 authoritative field ownership
  → planned-phase write seam preserves frontmatter
  → command-level equal-date regression (QUALITY-01)

EFFORT-01 partial-config merge
  → install-time resolution and sync rendering
  → installed Claude frontmatter assertions

EFFORT-01 inheritance representation
  → omission-aware frontmatter writer/sync idempotency
  → effective-value/provenance reporting
  → documentation of runtime/install split
```

## MVP Recommendation

Prioritize:

1. **Item 9 preservation plus its command-level reproducer** — closes the confirmed silent state-corruption case with the smallest safe ownership change.
2. **Item 10 partial-override merge and Claude inheritance semantics** — prevents unrequested fleet-wide effort changes and makes the intended session-inherit setting durable.
3. **Item 10 effective/provenance reporting plus docs** — makes the corrected behavior understandable across resolver, install, and runtime surfaces.

Defer: automatic synchronization, global model-precedence changes, a unified cross-runtime resolver, and any UI/config-editor work. Each changes policy or delivery surface beyond the two confirmed ledger items.

## Regression and Compatibility Implications

- Keep existing `resolve-execution` consumers compatible: introduce explicit/additive provenance fields or a versioned contract rather than repurposing `effort` silently.
- Test both dry-run and apply behavior for `effort sync`; absence of a Claude `effort:` field must be a stable desired state, not perpetual drift.
- Preserve safety behavior: sync writes only regular installed agent files and existing invalid/unknown agent/config handling remains fail-safe.
- If authored references, registry metadata, or installed artifacts change, regenerate canonical derivatives and run generated-sync plus relevant runtime-parity checks. If only libraries/tests change, verify the affected-test selection still covers the command and installed-runtime seams.
- The project test policy requires Node's built-in `node:test`, `node:assert/strict`, owning-module regression placement, deterministic fixtures, and cleanup through `tests/helpers.cjs`; do not add a new test framework or an isolated `bug-*` test file.

## Sources

- `PROJECT.md` active requirements and out-of-scope boundaries (local planning authority; 2026-08-02).
- `scratch/UPSTREAM-GSD-ISSUES.md`, items 9 and 10: current-source reproductions and explicitly bounded suggested fixes (local upstream issue ledger; 2026-08-02).
- `gsd-core/bin/lib/state-transition.cjs`, `state.cjs`, `model-resolver.cjs`, `install-effort-resolver.cjs`, and `commands.cjs`: current implementation and delivery surfaces (official project source, inspected 2026-08-02).
- `gsd-core/references/model-profiles.md`: current documented model/effort claim (official project reference, inspected 2026-08-02).
- `.planning/codebase/CONCERNS.md` and `TESTING.md`: mapped risk and test conventions (local architecture/test evidence; 2026-08-02).
