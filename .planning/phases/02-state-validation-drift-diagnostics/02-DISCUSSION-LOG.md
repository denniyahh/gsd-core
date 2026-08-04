# Phase 2: State Validation Drift Diagnostics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-04
**Phase:** 2-state-validation-drift-diagnostics
**Areas discussed:** Phase-source precedence, unresolvable active phase, regression fixture

---

## Phase-source precedence

| Option | Description | Selected |
|--------|-------------|----------|
| Frontmatter → legacy `Current Phase` → canonical `Phase:` | Restores shipped-template behavior while preserving legacy documents. | ✓ |
| Frontmatter → canonical `Phase:` only | Matches the narrowest wording but drops legacy-only compatibility. | |

**User's choice:** Preserve the legacy fallback between frontmatter and canonical prose.
**Notes:** When frontmatter and prose disagree, frontmatter is authoritative and the disagreement is reported as drift.

---

## Unresolvable active phase

| Option | Description | Selected |
|--------|-------------|----------|
| Fail validation with an actionable warning | `valid: false` because the required disk check could not run. | ✓ |
| Warn but remain valid | Signal reduced coverage without affecting validation gates. | |

**User's choice:** Fail validation for absent or unusable phase references.
**Notes:** A resolved phase with no directory also reports missing-phase drift and returns `valid: false`.

---

## Regression fixture

| Option | Description | Selected |
|--------|-------------|----------|
| Shipped-template fixture | Start from `gsd-core/templates/state.md` and introduce known disk drift. | ✓ |
| Compact hand-written fixture | Use a smaller normal-shape `STATE.md` fixture. | |

**User's choice:** Use the shipped template shape.
**Notes:** Cover frontmatter, legacy `Current Phase`, canonical `Phase:`, and the no-source negative control separately.

---

## the agent's Discretion

- Select the smallest compatible helper extraction and behavioral assertion form.

## Deferred Ideas

- Item 11 progress reporting and a `state.verify-against-disk` command remain outside Phase 2.
