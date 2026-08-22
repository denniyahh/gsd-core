---
schema_version: 1
open_count: 1
waived_count: 0
fixed_count: 2
total_count: 3
last_updated: 2026-08-22T17:59:19.853Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 02 | deviation | tests/emitted-attribution.test.cjs | 3008 | Pre-existing emitted-attribution baseline failure is outside Plan 02-01's two-file scope | fixed |  | 2026-08-05T00:11:23.179Z | 2026-08-22T17:59:19.853Z |
| 2 | 02 | deviation | tests/issue-2765-brace-expansion-lockfile.test.cjs | 36 | Pre-existing brace-expansion@5.0.6 lockfile failure requires separately authorized dependency maintenance | fixed |  | 2026-08-05T00:11:24.222Z | 2026-08-22T17:35:34.195Z |
| 3 | 02 | unrun-verify | .planning/phases/02-state-validation-drift-diagnostics/02-01-PLAN.md |  | npm test was stopped after unrelated chunk-2 failures; remaining chunks were not completed | open |  | 2026-08-05T00:11:25.169Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "02",
    "file": "tests/emitted-attribution.test.cjs",
    "line": 3008,
    "description": "Pre-existing emitted-attribution baseline failure is outside Plan 02-01's two-file scope",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-05T00:11:23.179Z",
    "resolved_at": "2026-08-22T17:59:19.853Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "02",
    "file": "tests/issue-2765-brace-expansion-lockfile.test.cjs",
    "line": 36,
    "description": "Pre-existing brace-expansion@5.0.6 lockfile failure requires separately authorized dependency maintenance",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-05T00:11:24.222Z",
    "resolved_at": "2026-08-22T17:35:34.195Z"
  },
  {
    "id": 3,
    "kind": "unrun-verify",
    "phase": "02",
    "file": ".planning/phases/02-state-validation-drift-diagnostics/02-01-PLAN.md",
    "line": null,
    "description": "npm test was stopped after unrelated chunk-2 failures; remaining chunks were not completed",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-05T00:11:25.169Z",
    "resolved_at": null
  }
]
````
