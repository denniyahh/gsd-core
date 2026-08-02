# Domain Pitfalls

**Domain:** Upstream GSD Core contributions — planned-phase state metadata and model/effort resolution
**Researched:** 2026-08-02
**Confidence:** HIGH for repository-local behavior; external-host behavior is not asserted as reproduced.

## Critical Pitfalls

### Pitfall 1: Treating `resync: false` as a frontmatter-preservation guarantee
**Applies to:** Item 9

**What goes wrong:** `cmdStatePlannedPhase` already calls `readModifyWriteStateMd` with `resync: false`, but that option preserves `progress.*`; it still calls `syncStateFrontmatter`. A narrow patch that relies on `resync: false`, or tests only the pure `plannedPhaseCore`, can leave `last_activity` and `last_activity_desc` vulnerable to body-derived replacement.

**Known fact:** `readModifyWriteStateMd` invokes `syncStateFrontmatter` after the transform, including with `resync: false` (`gsd-core/bin/lib/state.cjs`). The confirmed ledger reproduction is the equal-date case: accurate frontmatter activity metadata and stale prose body content.

**Warning signs:** A unit test of `plannedPhaseCore` passes while a command-level fixture changes YAML frontmatter; `updated` only lists body fields; a diff shows a stale description copied from `## Current Position`.

**Prevention:** Define explicit field ownership for this transition and pass only its authoritative values through the existing `authoritativeFm` seam, or add an equally narrow preservation rule. Add a `tests/state.test.cjs` command-level fixture with equal `last_activity` dates, a stale body description, and authoritative frontmatter; assert the complete YAML block after `state planned-phase`, not merely command success or body text.

**Relevant paths:** `gsd-core/bin/lib/state.cjs` (`syncStateFrontmatter`, `readModifyWriteStateMd`, `cmdStatePlannedPhase`); `gsd-core/bin/lib/state-transition.cjs` (`plannedPhaseCore`); `tests/state.test.cjs`; `tests/state-transition.test.cjs`.

### Pitfall 2: Over-broad preservation freezes legitimate planned-phase changes
**Applies to:** Item 9

**What goes wrong:** A blanket “frontmatter always wins” rule fixes the reproduced stale-description case but prevents valid transition-owned updates or violates existing template-aware status behavior. It can also make a newly created or template `STATE.md` remain stale.

**Known fact:** `plannedPhaseCore` intentionally makes template-aware body updates and existing regression tests assert that terminal/template statuses can advance while executor-authored statuses are preserved. The ledger explicitly treats the `Ready to execute` → frontmatter `executing` mapping as current intentional behavior, not item 9’s confirmed defect.

**Warning signs:** Existing planned-phase tests for terminal status or pipe-table layouts fail; the new test passes only because all frontmatter fields are frozen; a new project’s metadata is never initialized.

**Prevention:** Scope preservation to the authoritative activity fields and the transition/document shape that establishes ownership. Keep tests for: template/terminal status advancement, executor-authored status preservation, plain-label and pipe-table layouts, missing frontmatter, and the equal-date stale-description regression. Do not change `normalizeStateStatus` as incidental cleanup unless the issue scope and compatibility contract are separately approved.

**Relevant paths:** `gsd-core/bin/lib/state-transition.cjs`; `gsd-core/bin/lib/state-document.cjs` (`normalizeStateStatus`); `tests/state.test.cjs` (planned-phase, bug #1070, and #1257 cases).

### Pitfall 3: Bypassing the state write seam to force a YAML fix
**Applies to:** Item 9

**What goes wrong:** Directly writing frontmatter from the transition can dodge the immediate resync bug but bypasses locking, no-op protection, preservation, disk-scan cache invalidation, and platform-safe I/O in the shared state writer. That reintroduces lost-update or stale-progress failures under concurrent state changes.

**Known fact:** The state seam holds a lock across read–transform–write and contains explicit preservation/no-op logic. The codebase concerns identify dual `STATE.md` representation and concurrent state operations as fragile areas.

**Warning signs:** A patch adds `writeFileSync`/raw YAML reconstruction in `state-transition`; it works in one fixture but skips existing lock-focused behavior; no test exercises the CLI path.

**Prevention:** Route the fix through `readModifyWriteStateMd` and its options rather than adding a side write. Run the owning state tests plus the new end-to-end regression; inspect the resulting `STATE.md` diff for unrelated frontmatter changes.

**Relevant paths:** `gsd-core/bin/lib/state.cjs`; `gsd-core/bin/lib/state-transition.cjs`; `tests/state.test.cjs`.

### Pitfall 4: Mistaking the reported `updated` array for the complete mutation set
**Applies to:** Item 9

**What goes wrong:** `plannedPhaseCore` reports body changes, while frontmatter synchronization can make additional changes. A test that asserts only JSON output or the `updated` array can approve a silent metadata regression.

**Known fact:** The item-9 ledger records five frontmatter changes while the command reported only `Status`; it directs contributors to inspect the frontmatter diff rather than trust the report.

**Warning signs:** Test assertions stop at `{ updated: [...] }`; review says the command changed only one field without showing the on-disk file; equal-date activity metadata is absent from fixtures.

**Prevention:** Assert serialized frontmatter values and body values separately after the command. For the regression fixture, verify preservation of authoritative `last_activity` and `last_activity_desc`, intentional status behavior, and expected `progress.total_plans` semantics.

**Relevant paths:** `tests/state.test.cjs`; `gsd-core/bin/lib/state.cjs`; `scratch/UPSTREAM-GSD-ISSUES.md` item 9.

### Pitfall 5: Replacing tier defaults instead of merging a partial effort block
**Applies to:** Item 10

**What goes wrong:** Adding one `agent_overrides` or one `routing_tier_defaults` entry can cause unspecified light/standard/heavy agents to fall through to `effort.default`/`high`, silently changing many generated Claude agents.

**Known fact:** `resolveInstallTimeEffort` currently uses manifest tier defaults only when the entire `effort` config is absent; item 10 records a verified 23-agent dry-run change from a partial block. Existing resolver tests also encode the current fallback behavior, so changing it without updating the expected precedence matrix creates inconsistent contracts.

**Warning signs:** A minimal config change produces a large `effort sync --dry-run` diff; tests cover only the named override; unmapped tier agents change effort; install-time and runtime resolvers disagree about unspecified tiers.

**Prevention:** Make the effective tier map a merge of manifest defaults and valid user entries before agent resolution. Add a matrix test for empty effort config, only `agent_overrides`, one tier override, all tier overrides, invalid tier values, unknown agents, and `effort.default`. Assert unchanged efforts for every unspecified tier, not just the selected agent.

**Relevant paths:** `gsd-core/bin/lib/install-effort-resolver.cjs` (`resolveInstallTimeEffort`); `gsd-core/bin/lib/model-resolver.cjs` (`resolveEffortInternal`, `EFFORT_SET`); `tests/model-resolver.test.cjs`; `tests/commands.test.cjs`.

### Pitfall 6: Representing Claude effort inheritance as `effort: inherit`
**Applies to:** Item 10

**What goes wrong:** The desired Claude behavior is omission of the `effort:` key so the host inherits the session effort. Emitting the string `inherit` assumes a host value that the local ledger says is not valid for Claude effort frontmatter; treating absent, `null`, and `inherit` as interchangeable also makes sync re-add a key that was intentionally removed.

**Known fact:** The ledger verified that the current allowed effort set excludes `inherit`, and `cmdEffortSync` treats an absent frontmatter value as drift against a concrete target. The platform-specific host interpretation is documented as a compatibility requirement in the ledger; it must remain a conditional claim unless checked against the relevant host’s current documentation during implementation.

**Warning signs:** Generated Claude agents contain `effort: inherit`; `effort sync --apply` changes a deliberately omitted key on every invocation; an apply immediately followed by dry-run still reports drift.

**Prevention:** Extend configuration validation/resolution with an explicit inheritance sentinel, but have the Claude frontmatter writer remove/omit the key. Add idempotence tests: apply inheritance, assert no `effort:` line, then dry-run/apply again and assert zero changes. Keep runtime adapters separate: do not infer that omission or an `inherit` literal has identical meaning outside Claude.

**Relevant paths:** `gsd-core/bin/lib/model-resolver.cjs`; `gsd-core/bin/lib/install-effort-resolver.cjs`; `gsd-core/bin/lib/commands.cjs` (`cmdEffortSync`); `tests/commands.test.cjs`; `tests/runtime-converters.test.cjs`; `gsd-core/references/model-profiles.md`.

### Pitfall 7: Fixing resolver output while leaving installed agents stale
**Applies to:** Item 10

**What goes wrong:** `resolve-execution` is a runtime/config calculation; Claude effort is installed frontmatter. Changing a pure resolver or its JSON presentation without testing a real sync means users still execute the old installed effort. Conversely, making `resolve-execution` read an installed file without distinguishing configured and effective values can conceal stale installation state.

**Known fact:** Item 10a records that removing an installed agent’s effort key can leave `resolve-execution` reporting `high`. The codebase concerns identify the missing cross-surface effective-effort contract as a test gap.

**Warning signs:** Unit resolver tests pass but `~/.claude/agents`-style fixture output differs; a config change is asserted without `effort sync`; user-facing output has one ambiguous `effort` field with no provenance.

**Prevention:** Choose and document a stable report schema that separates configured/resolved value from installed/effective value (or explicitly reads the installed value for Claude). Add an end-to-end fixture: project config → `resolve-execution` → Claude agent fixture → `effort sync --apply` → read frontmatter → second dry-run. Assert every reported field against the correct source.

**Relevant paths:** `gsd-core/bin/lib/model-resolver.cjs`; `gsd-core/bin/lib/commands.cjs`; `gsd-core/bin/lib/install-effort-resolver.cjs`; `tests/model-resolver.test.cjs`; `tests/commands.test.cjs`.

## Moderate Pitfalls

### Pitfall 1: Accidentally changing model-layer precedence while repairing effort
**Applies to:** Item 10

**What goes wrong:** The global defaults file has different current behavior for project model resolution and install-time effort resolution. “Symmetrizing” it by changing model layering would expand a focused effort fix into a potentially breaking configuration change.

**Known fact:** The ledger verifies the asymmetry and classifies item 10 as an enhancement bundle, not a single defect. It recommends either coherent base-layer semantics or an explicit warning; neither should be silently bundled with the tier-default/inheritance corrections.

**Prevention:** Decide the scope in a written contract before code changes. If model precedence remains unchanged, add an explicit diagnostic/documentation test rather than changing its resolver. Test bare directory, project with config, project with `.planning/` but no config, and global defaults fixtures independently.

**Relevant paths:** `gsd-core/bin/lib/config-loader.cjs`; `gsd-core/bin/lib/model-resolver.cjs`; `gsd-core/bin/lib/install-effort-resolver.cjs`; `tests/model-resolver.test.cjs`; `scratch/UPSTREAM-GSD-ISSUES.md` item 10.

### Pitfall 2: Losing invocation overrides, dynamic escalation, or invalid-value fallbacks
**Applies to:** Item 10

**What goes wrong:** A merged-default implementation may reorder precedence or treat `inherit` as a concrete effort level. That can override explicit CLI values, break dynamic escalation, or turn invalid configuration into a valid-looking inherited value.

**Known fact:** Existing resolver tests cover invocation override precedence, agent override precedence, tier defaults, `effort.default`, dynamic escalation, and invalid values. These are compatibility constraints, not optional coverage.

**Prevention:** Write a single precedence table in tests and run it through both runtime and install-time resolver paths where applicable. Ensure `inherit` is handled before numeric escalation/`nextEffort` logic and never emitted as a Claude concrete effort value.

**Relevant paths:** `gsd-core/bin/lib/model-resolver.cjs`; `gsd-core/bin/lib/install-effort-resolver.cjs`; `tests/model-resolver.test.cjs`.

### Pitfall 3: Editing compiled/runtime artifacts without preserving generated-artifact parity
**Applies to:** Items 9 and 10

**What goes wrong:** This repository distributes compiled/runtime modules and generated artifacts across several host runtimes. Editing a copied `gsd-core/bin/lib/*.cjs` file without its canonical source, or changing a workflow/reference without regeneration, can pass a local test while shipping stale behavior elsewhere.

**Known fact:** The codebase map identifies generated-artifact parity as a primary repository risk and names generated-sync and runtime-parity checks as the mitigation.

**Prevention:** Locate the canonical TypeScript/CommonJS source before editing, regenerate required outputs, run `npm run lint:generated-sync`, and run affected/runtime-parity checks selected by the changed surfaces. Inspect `git diff` for generated changes rather than assuming the build captured them.

**Relevant paths:** `src/`; `gsd-core/bin/lib/`; `scripts/gen-plugin-skills.cjs`; `scripts/gen-capability-registry.cjs`; `tests/`; `.planning/codebase/CONCERNS.md`.

## Minor Pitfalls

### Pitfall 1: Conflating repository facts with unsupported-host claims
**Applies to:** Item 10

**What goes wrong:** A contributor can correctly observe a GSD resolver/install mismatch but overstate what Codex, Claude, or another external host will do without a current host-specific verification.

**Prevention:** Label local source/fixture behavior as verified, and label host behavior as a compatibility assumption unless checked against current official documentation or a reproducible harness. Keep host-specific adapter tests separate from resolver tests.

**Relevant paths:** `gsd-core/references/model-profiles.md`; runtime converter/adapter tests; `scratch/UPSTREAM-GSD-ISSUES.md` item 10.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Item 9: state write ownership | A body-only fix misses the later frontmatter sync | Reproduce through `state planned-phase`; assert final YAML frontmatter and body. |
| Item 9: status compatibility | Fixing activity preservation changes the intentional `Ready to execute` normalization | Retain existing #1070/#1257 coverage and keep normalization out of scope unless separately specified. |
| Item 9: write safety | Direct YAML write bypasses lock/preservation behavior | Use `readModifyWriteStateMd` and its existing options/seams. |
| Item 10: partial effort config | One override resets unnamed agent tiers | Merge manifest tier defaults first; test each unspecified tier. |
| Item 10: inheritance | `inherit` is written as a literal or sync never converges | Omit Claude `effort:` and prove apply/dry-run idempotence. |
| Item 10: effective reporting | Resolver JSON and installed Claude agents disagree | Test config, resolver report, sync result, installed frontmatter, and second dry-run as one contract. |
| Both items: release verification | Local CJS edit or narrow unit test hides generated/runtime drift | Change canonical source, regenerate, run focused tests plus generated-sync and affected parity checks. |

## Sources

- Repository-local primary evidence (HIGH): [`.planning/PROJECT.md`](../PROJECT.md), [`.planning/codebase/CONCERNS.md`](../codebase/CONCERNS.md), and [`.planning/codebase/TESTING.md`](../codebase/TESTING.md).
- Confirmed reproduction ledger (HIGH for stated local reproductions; not external-host claims): [`scratch/UPSTREAM-GSD-ISSUES.md`](../../scratch/UPSTREAM-GSD-ISSUES.md), items 9 and 10.
- Current implementation and regression suite inspected 2026-08-02 (HIGH): `gsd-core/bin/lib/state.cjs`, `state-transition.cjs`, `state-document.cjs`, `model-resolver.cjs`, `install-effort-resolver.cjs`, `commands.cjs`, `tests/state.test.cjs`, `tests/state-transition.test.cjs`, `tests/model-resolver.test.cjs`, and `tests/commands.test.cjs`.
