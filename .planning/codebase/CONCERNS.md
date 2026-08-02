# Codebase Concerns

**Analysis Date:** 2026-08-02

## Tech Debt

**Generated-artifact parity across runtimes:**
- Issue: One behavior may be represented in authored workflows, generated skills, capability registries, runtime adapters, and installed artifacts.
- Files: `gsd-core/workflows/`, `skills/`, `commands/`, `gsd-core/bin/lib/capability-registry.cjs`, `scripts/gen-plugin-skills.cjs`, `scripts/gen-capability-registry.cjs`.
- Impact: A locally correct edit can leave another runtime or generated surface stale.
- Current mitigation: `npm run lint:generated-sync`, registry validation, runtime-parity tests, and emitted-drift acknowledgements.
- Safe modification: Change the canonical source, regenerate derived artifacts, and run the affected parity and generated-sync checks before treating the change as complete.

**Large orchestration seams:**
- Issue: Several central files combine dispatch, parsing, compatibility behavior, and state transitions. Current sizes include `gsd-core/bin/gsd-tools.cjs` at 3,682 lines, `gsd-core/bin/lib/state-transition.cjs` at 1,697 lines, and `gsd-core/workflows/execute-phase.md` at 1,653 lines.
- Impact: Small behavioral changes can have a wide blast radius and can be difficult to review against every runtime path.
- Fix approach: Continue extracting bounded library functions and workflow step fragments only when a concrete change requires it; protect each extraction with focused regression and parity tests.

## Known Bugs

**`state planned-phase` can replace accurate activity frontmatter with stale body prose:**
- Status: Confirmed in `scratch/UPSTREAM-GSD-ISSUES.md` item 9 against the current source and an equal-date reproduction.
- Symptoms: `last_activity_desc` can be rewritten from stale body content even though frontmatter already contains the accurate completion record.
- Trigger: Frontmatter and body carry the same `last_activity` date but different descriptions when `state planned-phase` performs its body-to-frontmatter synchronization.
- Files: `gsd-core/bin/lib/state-transition.cjs`, `gsd-core/bin/lib/state.cjs`, and `gsd-core/bin/lib/state-document.cjs`.
- Root cause: `plannedPhaseCore` updates body fields, while the write seam later calls `syncStateFrontmatter`; the transition does not pass the new activity fields through the available authoritative-frontmatter channel.
- Workaround: Inspect the `.planning/STATE.md` diff after planning and restore the accurate activity description if it regresses.
- Fix approach: Pass the transition-owned `last_activity` and `last_activity_desc` values as authoritative frontmatter during the planned-phase write, then add an equal-date regression test.

**Model and effort resolution do not share one effective-value contract:**
- Status: Confirmed enhancement bundle in `scratch/UPSTREAM-GSD-ISSUES.md` item 10; individual behaviors are defensible, but the combined effective result is not reliably inferable from configuration alone.
- Symptoms: Installed Claude agent effort can disagree with runtime model resolution; partial effort overrides can collapse unspecified tier defaults; `inherit` is not represented consistently across effort surfaces.
- Files: `gsd-core/bin/lib/model-resolver.cjs`, `gsd-core/bin/lib/install-effort-resolver.cjs`, `gsd-core/bin/lib/config-loader.cjs`, `gsd-core/bin/lib/commands.cjs`, and `gsd-core/references/model-profiles.md`.
- Impact: Users can believe an agent will run with one reasoning effort while the installed or resolved agent uses another.
- Fix approach: Merge partial effort overrides over manifest tier defaults, represent Claude inheritance by omitted frontmatter, and make reporting distinguish configured, installed, and effective values.

## Safety and Compatibility Gaps

**No early integration-branch warning with `git.branching_strategy: "none"`:**
- Status: Validated safety enhancement in `scratch/UPSTREAM-GSD-ISSUES.md` item 6, not a violation of the documented current behavior.
- Risk: The default strategy commits to the current branch, so a phase started on an integration branch can accumulate many commits before `$gsd-ship` warns.
- Files: `gsd-core/references/planning-config.md`, `gsd-core/workflows/execute-phase.md`, and the commit path in `gsd-core/bin/lib/commands.cjs`.
- Recommendation: Warn at execute-phase start when strategy is `none` and the current branch resolves to the configured base branch; do not impose a blanket commit refusal because some callers intentionally commit there.

**Subagent availability is not the same as session survivability:**
- Status: Validated compatibility gap in `scratch/UPSTREAM-GSD-ISSUES.md` item 7; the historical one-shot-host failure has not been rerun in this repository.
- Risk: A host can expose an agent tool while terminating the parent session as soon as the turn ends, losing the opportunity to collect spawned work.
- File: `gsd-core/workflows/execute-phase.md`.
- Recommendation: Add an explicit host capability for whether a session can survive and collect asynchronous subagents; retain sequential fallback when it cannot.

## Security Considerations

**Untrusted planning content crosses prompt and command boundaries:**
- Risk: Repository-controlled Markdown can contain prompt-injection text, malicious links, Unicode concealment, or shell-like payloads that reach agent prompts and workflow command construction.
- Current mitigation: Dedicated adversarial fixtures under `tests/fixtures/adversarial/security/`, prompt/read injection scanners, secret-scan tests, write guards, timeout wrappers, and worktree path-safety checks.
- Recommendations: Treat new interpolation sites as security boundaries, avoid shell construction when structured arguments are available, and add adversarial regression cases for every new parser or prompt-ingestion path.

**Worktree and path operations are high-impact:**
- Risk: Incorrect path validation can write outside the intended project or clean the wrong worktree.
- Current mitigation: `gsd-core/references/worktree-path-safety.md`, worktree safety tests, orphan detection tests, symlink perturbation fixtures, and pathspec regression coverage.
- Recommendations: Preserve fail-closed path normalization and resolve exact targets before cleanup or merge operations.

## Performance and Scaling

**Repository-wide verification is broad:**
- Observation: The repository contains 897 test files and multiple generated-sync, install, runtime-parity, QA, security, coverage, and mutation suites.
- Concern: Running every gate for a narrow change can be expensive; skipping the relevant specialized gate can miss runtime-specific regressions.
- Measurement: No timing benchmark was run during this mapping pass, so no latency claim is made.
- Improvement path: Use focused regression tests while iterating, then run affected-test selection plus the mandatory generated/parity checks for the changed surfaces.

**Supported-runtime matrix multiplies change cost:**
- Current scope: Claude, Codex, Gemini, OpenCode, Cursor, Windsurf, Copilot, Kilo, Kimi, and other generated/install targets appear across adapters and tests.
- Limit: A behavior that depends on host capabilities cannot safely be inferred from runtime name alone.
- Scaling path: Keep capability negotiation centralized and generated; avoid adding runtime-name branches inside individual workflows.

## Fragile Areas

**Dual STATE.md representation:**
- Why fragile: State exists in both YAML frontmatter and human-readable body fields, with normalization and preservation rules deciding which source wins.
- Files: `gsd-core/bin/lib/state.cjs`, `gsd-core/bin/lib/state-document.cjs`, `gsd-core/bin/lib/state-transition.cjs`.
- Common failures: A transition updates the body correctly and a later synchronization step re-derives unrelated frontmatter, or status normalization changes the apparent meaning.
- Safe modification: Define field ownership explicitly, pass authoritative values through the write seam, and test the full command-level read-modify-write path rather than only the pure transition.
- Test coverage: Extensive state and transition suites exist, but the item-9 equal-date stale-description case is not identified by the current test search.

**Model/effort configuration layering:**
- Why fragile: Project config, global defaults, profile tables, per-agent overrides, runtime adapters, and installed agent frontmatter participate at different times.
- Files: `gsd-core/bin/lib/model-resolver.cjs`, `gsd-core/bin/lib/install-effort-resolver.cjs`, `gsd-core/bin/lib/config-loader.cjs`.
- Safe modification: Specify precedence for both model and effort, test partial overrides, and verify emitted/installed artifacts in addition to pure resolver output.

**Generated registry and workflow contracts:**
- Why fragile: Registry declarations, workflow enforcement, and generated documentation can describe the same gate through different code paths.
- Common failures: A declaration exists but is not the path that actually enforces behavior, or generated output drifts from its source.
- Safe modification: Trace a capability from canonical declaration through generation to runtime invocation and test both declaration parity and behavior.

## Dependencies at Risk

**Host-agent SDK and runtime APIs:**
- Risk: Agent dispatch, model aliases, effort support, and lifecycle behavior depend on host versions and capabilities outside this package.
- Impact: A valid workflow on one host can degrade or fail on another even when the same GSD artifacts are installed.
- Current mitigation: Runtime adapters, capability registry checks, minimum-version gates, and fail-closed fallbacks.
- Recommendation: Prefer capability-based negotiation and keep unsupported paths explicit; do not assume tool presence implies lifecycle support.

**Node.js version floor:**
- Requirement: `package.json` requires Node.js 22 or newer and npm 10 or newer.
- Impact: Contributors or installers using older runtimes cannot rely on the test/build behavior.
- Recommendation: Keep the engine requirement visible in installer diagnostics and CI matrices.

## Test Coverage Gaps

**Equal-date planned-phase activity preservation:**
- What's not tested: A command-level case where body and frontmatter have the same activity date but different descriptions, and planned-phase must preserve or intentionally replace the authoritative value.
- Risk: Activity history can regress silently while the command reports a narrow update list.
- Priority: High.
- Difficulty: Low to medium; extend `tests/state.test.cjs` with a complete STATE.md fixture and assert the final frontmatter.

**One-shot host lifecycle behavior:**
- What's not tested: An external host that exposes subagent dispatch but cannot keep the parent session alive to collect results.
- Risk: Executor work can finish without being integrated or recorded.
- Priority: Medium for unsupported hosts, higher if such a host becomes supported.
- Difficulty: High; requires a host-level integration harness rather than a pure unit test.

**Cross-surface effective effort reporting:**
- What's not tested as one contract: Configured profile plus partial overrides through runtime resolution, installed Claude frontmatter, Codex spawn effort, and user-facing reporting.
- Risk: Each individual test can pass while the end-to-end effective value remains inconsistent.
- Priority: Medium-high.
- Difficulty: Medium; compose existing resolver and installed-runtime fixtures into a matrix test.

---

*Concerns audit: 2026-08-02*
*Update as issues are fixed or new ones discovered*
