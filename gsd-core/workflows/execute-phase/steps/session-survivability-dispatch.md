# Executor session-survivability dispatch

Read and follow this fragment from `execute-phase.md` step 3 after resolving
`SESSION_OUTLIVES_TURN`. It controls executor invocation only; it does not
change verifier dispatch, isolation selection, or worktree ownership.

## harness Agent dispatch

When `SESSION_OUTLIVES_TURN` is absent or `true`, retain the existing
asynchronous executor contract:

```text
Agent(
  subagent_type="{EXECUTOR_TYPE}",
  description="Execute plan {plan_number} of phase {phase_number}",
  run_in_background: true,
  prompt="{EXECUTOR_PROMPT}"
)
```

When `SESSION_OUTLIVES_TURN` is `false`, make the executor foreground and
collect its result before the next executor is dispatched:

```text
executor_result = Agent(
  subagent_type="{EXECUTOR_TYPE}",
  description="Execute plan {plan_number} of phase {phase_number}",
  run_in_background: false,
  prompt="{EXECUTOR_PROMPT}"
)
await executor_result
```

## orchestrator-worktree process dispatch

The isolation fragment receives `SESSION_OUTLIVES_TURN` as an already-resolved
value. Its true path background-spawns the resolved command; its false path
runs the same command synchronously and waits before the next executor.
