# Testing Patterns

**Analysis Date:** 2026-08-02

## Test Framework

**Runner:**
- Node.js built-in `node:test` on Node 22+; do not introduce Jest, Mocha, Chai, or another external runner (`package.json`, `CONTRIBUTING.md`).
- Repository harness: `scripts/run-tests.cjs`. It builds missing/stale TypeScript artifacts and hooks, discovers `tests/**/*.test.cjs`, filters by suite suffix, balances/shards by `tests/test-timings.json`, and invokes Node's runner cross-platform (`scripts/run-tests.cjs`).
- Config: no Jest/Vitest config. Suite policy is defined in `docs/TESTING-SUITES.md`; npm entry points are defined in `package.json`; lint-time test constraints are defined in `eslint.config.mjs`.

**Assertion Library:**
- `node:assert/strict`, normally loaded as `const assert = require('node:assert/strict');` (`tests/phase-id.test.cjs`, `CONTRIBUTING.md`). Use exact structural assertions such as `equal`, `deepEqual`, `throws`, and `rejects` against behavior and typed results.

**Run Commands:**
```bash
npm test                              # Build prerequisites and run all 725 test files
npm run test:unit                     # Default fast lane: unmarked *.test.cjs files
npm run test:integration              # Cross-module *.integration.test.cjs files
npm run test:install                  # Real sandbox install/uninstall files
npm run test:security                 # Hostile-input *.security.test.cjs files
npm run test:slow                     # Explicit >5s/high-memory files
npm run test:qa                       # Stateful end-to-end loop walks
npm run test:affected                 # Select tests from the changed-file mapping
npm run test:coverage                 # Full c8 run with global line/branch thresholds
npm run test:coverage:unit            # Unit coverage plus the repository coverage gate
npm run test:mutation                 # Full/local Stryker mutation run
npm run build:lib && node --test --watch tests/phase-id.test.cjs  # Focused watch; no npm watch script exists
```

## Test File Organization

**Location:**
- Tests are separate from production code under `tests/`; production modules live under `src/` and compile to `gsd-core/bin/lib/` (`tsconfig.build.json`, `scripts/run-tests.cjs`). The current tree contains 725 `*.test.cjs` files: 713 unit, 1 integration, 3 install, 6 security, 1 slow, and 1 QA, classified by `scripts/run-tests.cjs`.
- Shared utilities belong in `tests/helpers.cjs` or a focused module under `tests/helpers/`, such as `tests/helpers/fast-check-setup.cjs` and `tests/helpers/cli-negative.cjs`.
- Reusable data lives under `tests/fixtures/`. Adversarial parser data belongs under `tests/fixtures/adversarial/<input-type>/`; representative user-derived gate corpora belong under `tests/fixtures/representative/<gate>/` with a provenance `MANIFEST.json` (`CONTRIBUTING.md`).
- Stateful QA-walk infrastructure is isolated under `tests/qa/`, with scenarios in `tests/qa/scenarios/` and fixtures in `tests/qa/fixtures/` (`tests/loop-walk.qa.test.cjs`).

**Naming:**
- Unit: `tests/<feature>.test.cjs`, for example `tests/phase-id.test.cjs`.
- Property: `tests/<feature>.property.test.cjs`, for example `tests/workflow-fragments.property.test.cjs`; it remains in the unit suite unless another suite marker is also used (`docs/TESTING-SUITES.md`).
- Non-unit: `tests/<feature>.<suite>.test.cjs`, where `<suite>` is `integration`, `install`, `security`, `slow`, or `qa` (`docs/TESTING-SUITES.md`).
- Add regressions to the owning module file, commonly in a `describe('regressions')` block. New `tests/bug-NNNN-*.test.cjs` files are prohibited by `scripts/lint-regression-test-names.cjs` (`docs/TESTING-SUITES.md`).

**Structure:**
```text
tests/
├── <module>.test.cjs                    # Fast unit/behavior coverage
├── <module>.property.test.cjs           # Deterministic fast-check invariants
├── <flow>.<suite>.test.cjs              # integration/install/security/slow/qa
├── helpers.cjs                          # Shared CLI/temp/cleanup helpers
├── helpers/                             # Focused reusable test support
├── fixtures/
│   ├── adversarial/<input-type>/        # Malformed/hostile reusable data
│   └── representative/<gate>/           # Provenance-labeled real reports
└── qa/                                  # Loop-walk harness, scenarios, fixtures, oracles
```

## Test Structure

**Suite Organization:**
```javascript
'use strict';

const { describe, test, beforeEach, afterEach } = require('node:test');
const assert = require('node:assert/strict');
const { createTempProject, cleanup } = require('./helpers.cjs');
const feature = require('../gsd-core/bin/lib/feature.cjs');

describe('feature', () => {
  let projectDir;

  beforeEach(() => {
    projectDir = createTempProject('feature-');
  });

  afterEach(() => {
    cleanup(projectDir);
  });

  test('returns the typed success result for valid input', () => {
    const result = feature.run({ projectDir, value: 'valid' });
    assert.deepEqual(result, { ok: true, value: 'valid' });
  });

  test('rejects malformed input without mutating the project', () => {
    const result = feature.run({ projectDir, value: '../../outside' });
    assert.equal(result.ok, false);
    assert.equal(result.reason, 'invalid_value');
  });
});
```
The import/hook/typed-assertion shape is defined in `CONTRIBUTING.md` and appears throughout `tests/phase-id.test.cjs` and `tests/loop-walk.qa.test.cjs`.

**Patterns:**
- Use `describe()` to group a module or behavior and `test()` for cases. `it()` exists in legacy files but new examples and contributor guidance use `test()` (`CONTRIBUTING.md`, `tests/workflow-fragments.property.test.cjs`).
- Prefer shared `beforeEach`/`afterEach` when cases have identical fixture lifecycles. Use `t.after()` for resources unique to one case (`CONTRIBUTING.md`, `tests/loop-walk.qa.test.cjs`).
- Always clean temporary directories through `cleanup()` from `tests/helpers.cjs`; raw `fs.rmSync` in tests is an ESLint error because the helper includes the Windows EBUSY retry budget (`eslint.config.mjs`).
- Do not use `try/finally` inside test bodies for cleanup. Register cleanup with hooks so assertion failures cannot bypass or mask teardown (`CONTRIBUTING.md`).
- Exercise exported functions, typed seams, or the real CLI. Do not read implementation source and assert on its text, and do not assert on raw stdout/stderr except limited process-contract checks (`TESTING-STANDARDS.md`, `eslint-rules/no-source-grep.cjs`).
- Every changed input boundary should cover applicable negative space: missing, empty, whitespace, malformed, out-of-range, duplicate/conflicting, hostile, filesystem failure, concurrency/retry, cross-platform newline/path, and a real regression fixture (`CONTRIBUTING.md`).
- Assert negative side effects as well as the error result: no outside file, no partial write, no stack trace, no secret leak, or no shell interpolation (`TEST-EXAMPLES.md`).
- Keep tests deterministic. Raw sleeps and elapsed-time assertions are prohibited or warned; inject a clock and use `node:test` mock timers for time/concurrency contracts (`TESTING-STANDARDS.md`, `eslint.config.mjs`).

## Mocking

**Framework:** `node:test`'s `mock` API, especially `mock.method()` and `t.mock.timers`; no standalone mocking dependency (`TESTING-STANDARDS.md`, `TEST-EXAMPLES.md`).

**Patterns:**
```javascript
const { test, mock } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');

test('preserves the original when the atomic rename fails', (t) => {
  const renameMock = mock.method(fs, 'renameSync', () => {
    const error = new Error('injected rename failure');
    error.code = 'ENOSPC';
    throw error;
  });
  t.after(() => renameMock.mock.restore());

  assert.throws(
    () => writeState(),
    (error) => error.code === 'ENOSPC',
  );
});
```
This fault-injection shape is prescribed in `TEST-EXAMPLES.md`; production examples use the same dependency-boundary strategy in `tests/installer-migration-install.integration.test.cjs`.

**What to Mock:**
- Mock external I/O at a real seam: filesystem failure, child-process invocation, network client, environment/config lookup, or clock (`TESTING-STANDARDS.md`, `TEST-EXAMPLES.md`).
- Restore every method mock with `t.after()` or an approved shared hook; do not leak monkey-patched globals into the next test (`TEST-EXAMPLES.md`).
- For clocks, inject the clock into production logic and drive `t.mock.timers` rather than waiting on the OS scheduler (`TESTING-STANDARDS.md`).

**What NOT to Mock:**
- Do not replace the system under test or its business/policy logic with a hardcoded answer. The body must traverse the behavior named by the test (`TESTING-STANDARDS.md`).
- Do not mock parsers by generating fixtures from the same parser/writer grammar. Gate fixtures must have independent provenance so the test can expose an assumption the implementation does not already know (`CONTRIBUTING.md`).
- Do not mock the entire CLI for command-contract tests. Execute `gsd-core/bin/gsd-tools.cjs` with argv arrays via `runGsdTools()` or `spawnSync(process.execPath, [...])` (`tests/helpers.cjs`, `TEST-EXAMPLES.md`).

## Fixtures and Factories

**Test Data:**
```javascript
const { createTempProject, cleanup } = require('./helpers.cjs');

test('ignores headings inside fenced code blocks', (t) => {
  const projectDir = createTempProject('roadmap-parser-');
  t.after(() => cleanup(projectDir));

  const roadmap = [
    '# Roadmap',
    '',
    '```md',
    '## Phase 999: decoy',
    '```',
    '',
    '## Phase 1: real phase',
  ].join('\n');

  const parsed = parseRoadmap(roadmap);
  assert.deepEqual(parsed.phases.map((phase) => phase.number), ['1']);
});
```
The no-indentation-bleed fixture form is defined in `CONTRIBUTING.md` and demonstrated in `TEST-EXAMPLES.md`.

**Location:**
- Use inline arrays joined with `\n` for small, case-specific documents (`CONTRIBUTING.md`, `tests/loop-walk.qa.test.cjs`).
- Put reusable malformed data in `tests/fixtures/adversarial/<type>/`; cover CRLF/LF, fences, duplicate keys, Unicode, traversal, NUL/replacement characters, and bounded oversized input as appropriate (`CONTRIBUTING.md`).
- Put real user-report fixtures in `tests/fixtures/representative/<gate>/MANIFEST.json` with source issue and expected/current verdict metadata; drive them through the real gate entry point (`CONTRIBUTING.md`).
- Use `tests/helpers.cjs` factories: `createTempProject()` for `.planning/` structure, `createTempGitProject()` for Git-dependent behavior, `createTempDir()` for bare storage, and `runGsdTools()` for CLI execution (`tests/helpers.cjs`).
- Property tests must import `tests/helpers/fast-check-setup.cjs`, which pins `numRuns: 200` and seed `42` unless `GSD_FC_SEED` is explicitly supplied for local exploration.

## Coverage

**Requirements:**
- `npm run test:coverage` enforces at least 70% lines and 60% branches over `gsd-core/bin/lib/*.cjs` through c8 (`package.json`).
- The unit coverage gate also requires 70% overall lines, 60% overall branches, and 70% per-file branch coverage for `state.cjs`, `phase.cjs`, `verify.cjs`, and `init.cjs` (`scripts/check-coverage-gate.cjs`). CI merges raw coverage from three unit shards before applying this gate (`.github/workflows/test.yml`).
- CI applies a separate 55% line floor to `scripts/**/*.cjs` (`package.json`, `.github/workflows/test.yml`).
- Mutation testing uses Stryker against built `gsd-core/bin/lib/**/*.cjs`. The target/high threshold is 80%, local fallback break threshold is 60%, and CI injects per-module ratchets currently ranging from 52% to 80% from `scripts/mutation-matrix.cjs` (`stryker.config.mjs`). Treat surviving mutants as missing behavioral coverage, not as an informational metric (`TESTING-STANDARDS.md`).

**View Coverage:**
```bash
npm run test:coverage              # Execute all suites and print gated c8 coverage
npm run test:coverage:unit         # Execute unit lane, write text + JSON summary, run gate
npm run test:coverage:report       # Re-report existing coverage/tmp data and run gate
npm run test:coverage:scripts-floor # Apply the scripts/ coverage floor to existing data
```
Coverage artifacts are written under `coverage/`; mutation HTML is written to `reports/mutation/mutation.html` (`package.json`, `stryker.config.mjs`).

## Test Types

**Unit Tests:**
- The unmarked `*.test.cjs` lane is the default fast suite and currently contains 713 files. Use it for pure logic and focused CLI behavior without network or unrelated cross-entry-point orchestration (`docs/TESTING-SUITES.md`, `scripts/run-tests.cjs`).
- Parser, transformer, budget/limit, and bijective contracts should add deterministic fast-check invariants such as round-trip, monotonicity, boundary containment, or idempotency (`TESTING-STANDARDS.md`, `tests/workflow-fragments.property.test.cjs`).
- Rule implementations have behavioral rule tests such as `tests/no-path-literal-in-assert.rule.test.cjs`; test the AST rule's accepted/rejected behavior rather than its source text (`eslint-rules/no-path-literal-in-assert.cjs`).

**Integration Tests:**
- Use `*.integration.test.cjs` for flows crossing modules or entry points; `tests/installer-migration-install.integration.test.cjs` exercises the public installer seam (`docs/TESTING-SUITES.md`).
- Use `*.install.test.cjs` for real install/uninstall against sandbox roots, such as `tests/release-tarball-smoke.install.test.cjs`. These are slower and only run in full CI conditions defined by `.github/workflows/test.yml`.
- Use `*.security.test.cjs` for hostile payloads and prompt-injection/secret-scanning behavior, such as `tests/prompt-injection-scan.security.test.cjs` (`docs/TESTING-SUITES.md`).
- Use `*.slow.test.cjs` for routines consistently exceeding five seconds or consuming substantial memory, such as `tests/graphify-auto-update.slow.test.cjs` (`docs/TESTING-SUITES.md`).

**E2E Tests:**
- The `qa` suite is the repository's E2E layer. `tests/loop-walk.qa.test.cjs` drives the real `gsd-tools` binary through multi-step scenarios against one accumulating temporary project, while `tests/qa/oracles.cjs` checks invariants after each step (`docs/TESTING-SUITES.md`).
- Scenario definitions live in `tests/qa/scenarios/*.json`; mutations, result classification, reports, and fixture resolution live under `tests/qa/*.cjs` (`tests/qa/scenario.cjs`, `tests/qa/loop-walk.cjs`).
- Playwright/Cypress/browser E2E tooling is not used; the product's end-to-end surface is CLI/filesystem workflow execution (`package.json`, `tests/loop-walk.qa.test.cjs`).

## Common Patterns

**Async Testing:**
```javascript
const { test } = require('node:test');
const assert = require('node:assert/strict');

test('returns a structured refusal when the lane is unavailable', async () => {
  const result = await probeLane({
    plan,
    spawn: async () => ({ status: 1, stdout: '', stderr: 'unavailable' }),
  });

  assert.equal(result.ok, false);
  assert.equal(result.reason, 'probe_failed');
});
```
Use an `async` test and `await` the behavior directly. For rejected promises, use `await assert.rejects(...)`; do not synchronize with `setTimeout`, `sleep`, `delay`, or elapsed-wall-clock assertions (`TESTING-STANDARDS.md`, `eslint.config.mjs`).

**Error Testing:**
```javascript
test('rejects duplicate keys deterministically', () => {
  assert.throws(
    () => parseFrontmatter('---\ntitle: First\ntitle: Second\n---\n'),
    (error) =>
      error.code === 'duplicate_frontmatter_key' &&
      error.key === 'title',
  );
});

test('returns a typed validation failure', () => {
  const result = resolveLanePlan(invalidInput);
  assert.equal(result.ok, false);
  assert.equal(result.reason, 'malformed_lane');
});
```
Use `assert.throws`/`assert.rejects` only when throwing is the contract; otherwise assert the discriminant and stable reason code on the returned result (`src/write-set.cts`, `src/review-lane-invocation.cts`, `TEST-EXAMPLES.md`). Also assert the absence of unsafe side effects for failure paths (`TEST-EXAMPLES.md`).

---

*Testing analysis: 2026-08-02*
