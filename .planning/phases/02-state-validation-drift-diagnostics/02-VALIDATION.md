---
phase: 2
slug: state-validation-drift-diagnostics
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-04
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node built-in `node:test` (Node >=22) |
| **Config file** | none — `scripts/run-tests.cjs` orchestrates suites |
| **Quick run command** | `npm run build:lib && node --test --test-name-pattern='state validate command' tests/state.test.cjs` |
| **Full suite command** | `npm test` |
| **Estimated runtime** | ~30 seconds for focused run |

---

## Sampling Rate

- **After every task commit:** Run `npm run build:lib && node --test --test-name-pattern='state validate command' tests/state.test.cjs`
- **After every plan wave:** Run `node scripts/run-tests.cjs --files state.test.cjs` and `npm run lint`
- **Before `$gsd-verify-work`:** `npm test` and `npm run lint:ci` must be green
- **Max feedback latency:** 30 seconds for the focused regression

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | STATE-02 | T-02-01 | Frontmatter is authoritative; canonical `Phase:` remains a fallback; disk drift remains observable | command regression | `node --test --test-name-pattern='state validate command' tests/state.test.cjs` | ✅ existing file, new cases required | ⬜ pending |
| 02-01-02 | 01 | 1 | QUALITY-02 | T-02-01 | Shipped-state fixtures fail loudly and cover known drift plus absent-boundary controls | command regression | `node --test --test-name-pattern='state validate command' tests/state.test.cjs` | ✅ existing file, new cases required | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `tests/state.test.cjs` with template-derived state-document fixtures and its source-resolution matrix.
- [ ] Add known-positive disk drift plus negative controls for legacy/canonical fallback, conflicts, unresolved sources, missing directories, and normalized equality.

Existing infrastructure covers the framework and helper needs.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
