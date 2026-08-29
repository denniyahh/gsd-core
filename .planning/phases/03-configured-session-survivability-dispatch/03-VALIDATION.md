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

**Task 03-01-01 baseline:** `upstream/next` = `b811ea16fc4a044dc16b36af91d7cee9d5375727` (fetched and confirmed as an ancestor of the implementation branch on 2026-08-29).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | — | — | Establish the current upstream/next implementation baseline without overwriting local work. | Preflight | `git fetch upstream && git merge-base --is-ancestor upstream/next HEAD && git diff --check && npm run check:env` | ✅ | ⬜ pending |
| 03-01-02 | 01 | 1 | SESSION-01, SESSION-02, QUALITY-03 | T-03-01, T-03-02, T-03-03 | Executor-only false mode contains an explicit awaited foreground dispatch while default/true retains background dispatch. | Configuration and workflow-product | `npm run build:lib && node --test tests/config.test.cjs tests/config-get-default.test.cjs tests/execute-phase-active-flags.test.cjs` | ✅ | ⬜ pending |
| 03-02-01 | 02 | 2 | SESSION-03 | — | ADR and generated index remain synchronized. | Generator | `node scripts/gen-adr-index.cjs --check && npm run lint:generated-sync` | ✅ | ⬜ pending |
| 03-02-02 | 02 | 2 | QUALITY-03, COMPAT-01 | T-03-02, T-03-03 | Runtime conversion and install projections preserve both dispatch directions. | Projection and install integration | `npm run build:lib && node --test tests/runtime-converters.test.cjs tests/adr-index-gate.test.cjs && npm run test:install && npm run lint:generated-sync` | ✅ | ⬜ pending |
| 03-02-03 | 02 | 2 | — | — | Complete post-verification ship handoff only after a real PR exists and the generated changeset passes lint. | Ship handoff | `GITHUB_BASE_REF=next node scripts/changeset/lint.cjs` | ✅ | ⬜ pending |

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
