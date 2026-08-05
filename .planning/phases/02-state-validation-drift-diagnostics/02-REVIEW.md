---
phase: 02-state-validation-drift-diagnostics
reviewed: 2026-08-05T00:33:32Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - src/state.cts
  - tests/state.test.cjs
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-08-05T00:33:32Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The validator's new fail-closed behavior still has two false-clean paths. It accepts a `Phase:` field outside the canonical Current Position section, and it silently chooses one directory when multiple on-disk directories normalize to the selected phase key. Both defects allow `state validate` to report `valid: true` without establishing that it scanned the intended phase.

The 14 focused command tests pass, but neither ambiguity is covered. Independent command-level probes reproduced both failures and included opposite-result controls, so the green focused suite does not license a clean review.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 [BLOCKER]: A non-canonical `Phase:` field is promoted to the active phase

**File:** `/var/home/denniyahh/Github/gsd-core/src/state.cts:2786`

**Issue:** When `matchCurrentPositionSection(body)` returns `null`, the implementation falls back to searching the entire body for the first generic `Phase:` field. That contradicts the phase contract, which defines the third-precedence source as the Current Position-scoped `Phase:` field. An archive, decision table, or other unrelated section can therefore become the validation target. A fixture containing only `## Archive` plus `Phase: 2 of 2 (Old)` and an empty `02-live` directory returned `{ "valid": true, "warnings": [], "drift": {} }`; the negative control with the archive `Phase:` removed correctly returned unresolved `phase_reference` drift. The validator can therefore certify a state document that has no usable active-phase source.

**Fix:** Do not substitute the full body when the Current Position section is absent. Preserve `null` so the unresolved-source branch fires, and add a command regression with an out-of-section `Phase:` field.

```typescript
const currentPositionScope = matchCurrentPositionSection(body);
const currentPositionRaw = currentPositionScope === null
  ? null
  : stateExtractField(currentPositionScope, 'Phase');
```

### CR-02 [BLOCKER]: Duplicate canonical phase directories are resolved arbitrarily

**File:** `/var/home/denniyahh/Github/gsd-core/src/state.cts:2841`

**Issue:** `entries.find(...)` accepts the first directory whose canonical key matches the selected phase and ignores additional matches. Directory spellings such as `02-a`, `02-b`, `2-b`, and project-code-prefixed variants normalize to the same key, so a drifted or partially migrated project can have more than one candidate. Which subtree is scanned then depends on directory enumeration order, and evidence in the ignored candidate is invisible. A fixture with executing phase 2, empty `02-a`, and passed verification under `02-b` returned clean; the positive control with only `02-b` correctly returned `verification_status` drift. This is the same false-clean outcome the phase was intended to eliminate.

**Fix:** Collect all canonical matches. Proceed only when exactly one exists; otherwise return `valid: false` with actionable `phase_directory` drift (for example, `reason: 'ambiguous'` plus the candidate names). Add a command regression that plants opposite disk evidence in two matching directories.

```typescript
const phaseDirs = entries.filter(
  entry => entry.isDirectory() && phaseKeyFromDir(entry.name) === selectedPhaseKey,
);
if (phaseDirs.length !== 1) {
  warnings.push(`Cannot validate phase drift: expected one directory for phase ${currentPhase}, found ${phaseDirs.length}`);
  drift['phase_directory'] = {
    reason: phaseDirs.length === 0 ? 'not_found' : 'ambiguous',
    selected: currentPhase,
    candidates: phaseDirs.map(entry => entry.name),
  };
  output({ valid: false, warnings, drift }, raw, undefined);
  return;
}
const phaseDirName = phaseDirs[0].name;
```

---

_Reviewed: 2026-08-05T00:33:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
