---
date: "2026-08-28 19:24"
promoted: false
---

Feature #3159 development brief — approved scope only

Objective: give hosts whose parent session ends with the turn an explicit opt-out from background executor dispatch, without changing the default behavior of supported runtimes.

Maintainer decision:
- Implement shape 1 only: an opt-out configuration key and an ADR.
- Do not implement shape 2 (worktree-creation serialization / synchronous parallel dispatch). Spike #3178 found it does not solve session survivability and is not implementable on the Claude harness-worktree path.
- Do not bundle orchestrator-owned SUMMARY.md recovery (shape 3).
- The stale Claude dispatch prose was split to #3177 and is already fixed on upstream/next.

Proposed implementation contract:
1. Add a boolean workflow configuration key for session survivability. The current schema has workflow.* and executor.* namespaces but no execution.* namespace; prefer workflow.session_outlives_turn, default true.
2. When the value is absent or true, preserve current dispatch instructions and background behavior exactly.
3. When false, force each executor Agent call to run in the foreground with run_in_background: false and await it before dispatching the next executor. Do not merely omit the argument: Claude backgrounds agents by default.
4. Preserve all existing tool-availability, isolation, worktree, completion, and recovery behavior outside this dispatch choice.

Required deliverables:
- docs/adr/3159-*.md recording the host-assumption decision and the default-preserving opt-out.
- Schema/default registration and loader whitelist through the canonical configuration manifests plus the config-get default path.
- execute-phase workflow branch on the resolved value.
- docs/CONFIGURATION.md entry, regenerated derived artifacts/goldens, and an Added changeset.
- Behavioral CLI tests for config-set/config-get true and false; workflow/projection tests for both dispatch directions, including the negative control that false never leaves a background dispatch path and true/unset still does.

Planning boundary:
- #3159 must be a dedicated upstream feature PR. Do not combine it with the separate #3552 protected-branch contribution currently bundled into local Phase 3.
- Before authoring a formal PLAN.md, run GSD discussion to lock the config-key name/scope and whether Phase 3 is split into separate contributor-planning phases, then run GSD plan-phase with research and plan verification.
