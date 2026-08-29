---
phase: 3
slug: configured-session-survivability-dispatch
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-08-28
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node built-in test runner via `scripts/run-tests.cjs` |
| **Config file** | `package.json`, `tsconfig.build.json`, and repository test helpers |
| **Quick run command** | `npm run build:lib && node --test tests/config.test.cjs tests/config-get-default.test.cjs tests/execute-phase-active-flags.test.cjs tests/runtime-converters.test.cjs tests/adr-index-gate.test.cjs` |
| **Full suite command** | `mise run check:budget && npm run build && npm run lint:ci && npm test` |
| **Estimated runtime** | Not measured; run focused checks first, then record any full-suite constraint in the phase summary |

---

## Sampling Rate

- **After every task commit:** Run the quick command above, narrowed to the touched owner where practical.
- **After every plan wave:** Run `npm run lint:generated-sync` after generated artifacts change.
- **Before `$gsd-verify-work`:** Run the full suite command and `npm run test:install` when emitted install projections changed.
- **Max feedback latency:** No fixed duration asserted; bounded test commands only.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | SESSION-01, SESSION-02 | T-03-01 | Invalid values cannot coerce into a lifecycle mode; absent, true, and false remain distinct. | CLI integration | `node --test tests/config.test.cjs tests/config-get-default.test.cjs` | ✅ | ⬜ pending |
| 03-01-02 | 01 | 1 | SESSION-01, SESSION-02, QUALITY-03 | T-03-02 | Executor-only false mode contains an explicit awaited foreground dispatch while default/true retains background dispatch. | Workflow-product and projection | `node --test tests/execute-phase-active-flags.test.cjs tests/runtime-converters.test.cjs` | ✅ | ⬜ pending |
| 03-01-03 | 01 | 1 | SESSION-03, COMPAT-01 | — | ADR, configuration reference, derived index, and install projections are synchronized. | Generator and install integration | `node scripts/gen-adr-index.cjs --check && npm run lint:generated-sync && npm run test:install` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Extend existing configuration, workflow-product, converter, ADR-index, and install-projection test owners; do not create a top-level issue-number test file.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| A real wrapper host terminates the parent turn while `workflow.session_outlives_turn: false` is set. | SESSION-01 | The external host lifecycle is outside GSD's unit/install harness. | Run the host's one-shot integration flow and confirm executor completion is collected before the parent exits. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Full-suite and install-projection checks are recorded before verification
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
