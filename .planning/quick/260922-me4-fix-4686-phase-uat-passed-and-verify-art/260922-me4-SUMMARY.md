# Quick Task Summary: 260922-me4 — fix(#4686) CLI gate verbs exit non-zero on negative verdict

## What Changed
- In [`src/verify.cts`](file:///var/home/denniyahh/Github/gsd-core-cli/src/verify.cts) (`cmdVerifyArtifacts`): imported `setPendingOutcome` from `./cli-exit.cjs`. After `output(...)` writes the artifact validation payload to stdout, if `!allPassed`, set `setPendingOutcome('FAIL')` and `process.exitCode = 1`.
- In [`src/phase.cts`](file:///var/home/denniyahh/Github/gsd-core-cli/src/phase.cts) (`cmdPhaseUatPassed`): imported `setPendingOutcome` from `./cli-exit.cjs`. After `output(...)` writes the UAT evaluation payload to stdout, if `!report.passed`, set `setPendingOutcome('FAIL')` and `process.exitCode = 1`.
- In [`tests/verify.test.cjs`](file:///var/home/denniyahh/Github/gsd-core-cli/tests/verify.test.cjs): updated legacy test assertions expecting exit code 0 on failing artifact checks to assert `result.exitCode === 1` and `result.success === false`. Added dedicated `#4686` regression test suite testing both `verify artifacts` and `query verify.artifacts` under default contract (v1) and `--exit-contract=v2`, along with positive controls (exit code 0).
- In [`tests/phase.test.cjs`](file:///var/home/denniyahh/Github/gsd-core-cli/tests/phase.test.cjs): updated legacy test assertions expecting exit code 0 on pending/failing UAT and stale/missing verification to assert `result.exitCode === 1` and `result.success === false`. Added dedicated `#4686` regression test suite testing `phase uat-passed` and `phase uat-passed --require-verification` under default contract (v1) and `--exit-contract=v2`, along with affirmative controls (exit code 0).
- In [`tests/qa/result.cjs`](file:///var/home/denniyahh/Github/gsd-core-cli/tests/qa/result.cjs) and [`tests/loop-walk.qa.test.cjs`](file:///var/home/denniyahh/Github/gsd-core-cli/tests/loop-walk.qa.test.cjs): updated the loop QA walk classifier `classify(raw)` to recognize gate predicates (`phase uat-passed`, `verify artifacts`, `query verify.artifacts`) exiting 1 with valid JSON stdout as reporting domain verdicts rather than crashes (`KIND.JSON`), unblocking `tests/qa/scenarios/uat-fail-then-remediate.json`. Added unit tests and negative controls.
- Created changeset at [`.changeset/4686-cli-gate-verbs-negative-exit.md`](file:///var/home/denniyahh/Github/gsd-core-cli/.changeset/4686-cli-gate-verbs-negative-exit.md).

## Verification
- Remote Mac runner (`mise run test:mac tests/verify.test.cjs`): 235 passed, 0 failed.
- Remote Mac runner (`mise run test:mac tests/phase.test.cjs`): 603 passed, 0 failed.
- Remote Mac runner (`mise run test:mac tests/loop-walk.qa.test.cjs`): 143 passed, 0 failed.
- Workflow byte ceilings & drift acks (`mise run check:budget`): passed.
