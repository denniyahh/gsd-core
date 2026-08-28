# Phase 3: Configured Session-Survivability Dispatch - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-28
**Phase:** 3-configured-session-survivability-dispatch
**Areas discussed:** Config contract, False-mode dispatch, Opt-out boundary

---

## Config contract

| Option | Description | Selected |
|--------|-------------|----------|
| `workflow.session_outlives_turn` | Fits the existing workflow configuration namespace; absent/true preserves the current behavior. | ✓ |
| New `execution.*` namespace | Introduces a new top-level configuration namespace for this one workflow behavior. | |

**User's choice:** Proceed with the recommended `workflow.session_outlives_turn` contract.
**Notes:** The setting is default-preserving and is the only approved config surface for #3159.

---

## False-mode dispatch

| Option | Description | Selected |
|--------|-------------|----------|
| Awaited foreground executor agents | Keep executor roles and isolation, with explicit `run_in_background: false`. | ✓ |
| Inline execute-plan work | Bypass executor subagents and perform plan work in the orchestrator. | |

**User's choice:** Proceed with the recommended awaited foreground executor path.
**Notes:** Omitting the flag is not safe because the host backgrounds agents by default.

---

## Opt-out boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Executor agents only | Matches #3159's approved executor-dispatch scope. | ✓ |
| All execute-phase subagents | Extend the setting to verifier dispatch as well. | |

**User's choice:** Proceed with the recommended executor-only boundary.
**Notes:** Verifier behavior remains unchanged and is outside this feature.

---

## the agent's Discretion

None.

## Deferred Ideas

None.
