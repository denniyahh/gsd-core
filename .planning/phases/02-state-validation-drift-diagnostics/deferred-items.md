# Deferred Items

## 2026-08-04 — Plan 02-01 broad-suite baseline failures

- `tests/emitted-attribution.test.cjs` fails its real-tree differential against `origin/next@f4185554ea08` because the branch already carries unattributed emitted-path changes, unacknowledged workflow growth, and a stale `execute-phase.md` acknowledgment. Plan 02-01 changes only `src/state.cts` and `tests/state.test.cjs`; emitted provenance and acknowledgment repair is outside this plan.
- `tests/issue-2765-brace-expansion-lockfile.test.cjs` finds `brace-expansion@5.0.6`, below its required patched floor of `5.0.9`. Plan 02-01 forbids dependency and lockfile changes, so this requires separately authorized dependency maintenance.
- The full `npm test` run was stopped after these two failures made the gate non-green; chunks after the active third chunk were not completed. Focused state-validation tests, the complete owning `state.test.cjs` suite, `npm run lint`, and `npm run lint:ci` passed.
