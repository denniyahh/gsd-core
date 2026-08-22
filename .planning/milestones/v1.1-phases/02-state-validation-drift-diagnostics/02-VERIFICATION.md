---
phase: 02-state-validation-drift-diagnostics
verified: 2026-08-05T00:39:10Z
status: passed
score: 4/6 must-haves verified
behavior_unverified: 0
overrides_applied: 1
previous_status: gaps_found
superseded_by: "https://github.com/open-gsd/gsd-core/pull/3208"
superseded_at: 2026-08-22
gaps:
  - truth: "Per D-01 and D-03, state.validate selects only the scoped Current Position Phase fallback and fails closed when no usable phase source exists."
    status: failed
    reason: "cmdStateValidate substitutes the entire STATE.md body when Current Position is absent, allowing an unrelated archive Phase: line to become the active phase and return a clean result."
    artifacts:
      - path: "src/state.cts"
        issue: "Line 2786 uses matchCurrentPositionSection(body) ?? body before stateExtractField(..., 'Phase')."
      - path: "tests/state.test.cjs"
        issue: "The focused suite has no out-of-section Phase regression."
    missing:
      - "Treat an absent Current Position section as no canonical Phase source."
      - "Add a command-level archive/out-of-section Phase negative regression."
  - truth: "state.validate reports drift against the corresponding on-disk phase artifacts only when a unique canonical phase directory is selected."
    status: failed
    reason: "cmdStateValidate chooses the first matching directory returned by readdirSync; multiple directories that normalize to the same phase key make the scanned subject enumeration-order dependent and can hide drift."
    artifacts:
      - path: "src/state.cts"
        issue: "Line 2841 uses entries.find(...) instead of rejecting zero or multiple canonical directory matches."
      - path: "tests/state.test.cjs"
        issue: "The focused suite has no duplicate-canonical-directory regression."
    missing:
      - "Require exactly one canonical directory match; otherwise emit invalid phase_directory drift with candidate names."
      - "Add an ambiguity regression with opposite evidence in matching directories."
---

# Phase 2: State Validation Drift Diagnostics Verification Report

**Phase Goal:** Contributors can rely on `state.validate` to resolve the active phase from a normal shipped `STATE.md` document and report drift against the corresponding phase artifacts on disk.
**Verified:** 2026-08-05T00:39:10Z
**Status:** passed (superseded — see Supersession Note below)
**Re-verification:** No — initial verification

## Supersession Note (2026-08-22)

This report's original verdict was `gaps_found` (both gaps described in full below, unchanged,
as the historical record of this branch's own implementation). Per this workspace's contribution
contract (`scratch/FORK_NOTES.md`), real fixes to `gsd-core` do not ship through
`personal/workspace` — they are built in an isolated worktree off `upstream/next` and land there.

The underlying defect this phase exists to close (`state.validate` cannot reliably resolve the
active phase — tracked as `scratch/UPSTREAM-GSD-ISSUES.md` entry 12) was fixed and merged through
that proper channel: [upstream PR #3208](https://github.com/open-gsd/gsd-core/pull/3208), authored
by the same contributor, merged into `next` on 2026-08-11, resolving
[upstream issue #3162](https://github.com/open-gsd/gsd-core/issues/3162). That fix is more complete
than this branch's own attempt (110 lines changed in `src/state.cts`, 301 lines of new regression
coverage) and independently closes both gaps recorded below.

**This branch's own `src/state.cts` still contains the original, gapped implementation** —
`personal/workspace` has not synced with `next` (496 commits behind as of this note) and per the
contribution contract above, is not meant to carry the fix locally. The phase is being marked
`passed`/complete on the strength of the upstream resolution, not because the two gaps below were
fixed in this repository's own working tree. A future sync of `personal/workspace` with `next` will
bring the real fix in and should be expected to change `src/state.cts` around the lines these gaps
cite.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Per D-01, select frontmatter `current_phase`, then legacy `Current Phase`, then only the canonical Current Position `Phase:` field. | ✗ FAILED | `src/state.cts:2786` falls back to the whole body. Independent emitted-CLI probe with only `## Archive` / `Phase: 2...` returned `{ valid: true, warnings: [], drift: {} }`. |
| 2 | Per D-02, report canonical source conflicts while scanning the authoritative winner. | ✓ VERIFIED | The focused emitted-CLI conflict test passed: frontmatter phase 2 remains selected, `phase_reference.reason` is `conflict`, and phase-2 verification drift is reported. |
| 3 | Per D-03, no usable source returns invalid, actionable `phase_reference` drift. | ✗ FAILED | An ordinary no-source fixture passes, but the archive-only `Phase:` probe is semantically no usable source and returns clean due to the unscoped fallback in truth 1. |
| 4 | Per D-04, an absent phases root or canonical directory match returns invalid `phase_directory` drift. | ✓ VERIFIED | Focused command tests for missing root and no match passed and code emits `missing_root` / `not_found`. This does not cover ambiguous duplicate matches (blocking gap below). |
| 5 | Per D-05/D-06, the shipped template reaches known on-disk drift and a clean control can return no drift. | ✓ VERIFIED | `template frontmatter phase reaches passed-verification drift on disk` and its clean control passed through the emitted CLI. |
| 6 | Canonical-key equality treats `2` and `02` as equal and scan paths use enumerated directory names, not raw state text. | ✓ VERIFIED | Template `2`/`02` clean control passed; crafted path-like input passed its outside-root negative test. `src/state.cts:2848` joins the enumerated name. |

**Score:** 4/6 truths verified (0 present, behavior-unverified)

The two confirmed false-clean paths mean the phase goal is not achieved: a clean result does not reliably establish that the intended active phase was resolved and scanned.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `src/state.cts` | Frontmatter-first resolution and warning-backed disk drift diagnostics. | ⚠️ PARTIAL — BLOCKER | Exists, is substantive, and is wired to the CLI, but its source scoping and directory selection admit two false-clean results. |
| `tests/state.test.cjs` | Shipped-template command regression plus precedence/failure/normalization controls. | ⚠️ PARTIAL — BLOCKER | Exists, is substantive, and runs against the emitted CLI; 14 focused tests pass, but both reproduced false-clean paths lack regressions. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `cmdStateValidate` | frontmatter/state-document extractors | Independent source extraction before D-01 selection | ⚠️ PARTIAL — BLOCKER | Imports and calls are present at `src/state.cts:2774-2787`; `?? body` breaks Current Position scoping. |
| `cmdStateValidate` | `phaseKeyFromToken` / `phaseKeyFromDir` | Canonical key comparison against phase directories | ⚠️ PARTIAL — BLOCKER | Keys are used at `2810-2813` and `2841-2842`, but `find` accepts an arbitrary first match. |
| `cmdStateValidate` | `scanPhasePlans` | Scan an enumerated phase directory | ⚠️ PARTIAL — BLOCKER | `scanPhasePlans` is called with an enumerated name at `2860`, yet selection is not unique. |
| `tests/state.test.cjs` | shipped template and emitted `gsd-tools` CLI | Template fixture + `runGsdTools('state validate')` | ✓ WIRED | Template helper at lines 33-44 and command tests at lines 3085-3299 execute the emitted CLI. |

`verify.key-links` reported four unverified links because the plan records symbol-qualified `from` values and an escaped pattern that its generic parser cannot consume. The manual traces above are the implementation evidence; the parser result is not treated as proof of broken imports.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `src/state.cts::cmdStateValidate` | selected phase and drift fields | Parsed `STATE.md`, enumerated `.planning/phases` entries, and scanned phase files | Yes, in focused fixtures and independent probes | ⚠️ HOLLOW ON AMBIGUITY | It reads real disk data, but can read the wrong candidate or an unrelated body field. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Planned focused command matrix | `npm run build:lib && node --test --test-name-pattern='state validate command' tests/state.test.cjs` | 14/14 passed | ✓ PASS |
| Owning state suite regression | `node scripts/run-tests.cjs --files state.test.cjs` | Exited successfully; runner selected `state.test.cjs` | ✓ PASS |
| Reject unscoped archive `Phase:` | Independent emitted-CLI temp-fixture probe | Archive-only `Phase:` returned `valid: true`; removing it returned unresolved `phase_reference` drift | ✗ FAIL |
| Reject duplicate canonical phase directories | Independent emitted-CLI temp-fixture probe | `02-a` empty + `02-b` passed verification returned `valid: true`; single `02-b` returned verification drift | ✗ FAIL |

The passing tests establish their covered cases only. They do not establish behavior for unrelated body fields or multiple normalized directory candidates; the two negative controls demonstrate that distinction directly.

### Probe Execution

No phase-declared or conventional `probe-*.sh` scripts were found. The command-level tests and independent emitted-CLI probes above are the runnable evidence.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| STATE-02 | 02-01 | Shipped state shape resolves active phase and reports disk drift. | ✗ BLOCKED | The normal shipped-template case passes, but archive `Phase:` and duplicate canonical-directory inputs can return clean without proving the intended target was scanned. |
| QUALITY-02 | 02-01 | Focused regression verifies STATE-02. | ⚠️ PARTIAL | A focused emitted-CLI regression exists and passes, but it omits both reproduced false-clean paths, so it is insufficient evidence for the full repair. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `src/state.cts` | 2786 | Whole-body fallback for a scoped field | 🛑 Blocker | Archive or unrelated `Phase:` text can certify a document with no active phase. |
| `src/state.cts` | 2841 | First canonical directory match | 🛑 Blocker | Enumeration order can hide artifact drift in another matching directory. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in the two phase-modified files. Existing placeholder references are unrelated state-template handling and tests, not phase stubs.

### Human Verification Required

None. Both gaps are deterministic command-level failures and have automated reproduction; no human judgment can resolve them.

### Gaps Summary

Two root causes block goal completion:

1. The canonical prose fallback is not limited to `## Current Position`, violating D-01/D-03 and allowing a false clean result.
2. Canonical directory matching is not one-to-one, so a false clean result can hide disk drift under another matching directory.

No later milestone phase exists in the roadmap to defer either issue. No verification overrides were present or suggested: these are implementation defects, not intentional alternative behavior.

## Scope and Limits

- This verification rebuilt the emitted library, ran the 14-test focused command matrix, ran the complete owning `state.test.cjs` file, and executed two independent temporary-fixture CLI probes with opposite-result controls.
- It did not run the full workspace suite. The phase summary reports that the prior full-suite attempt was incomplete and non-green; that claim was not used as positive evidence here. Consequently, this report does not establish repository-wide or cross-platform regression freedom.
- The report only owns this verification artifact. The pre-existing modified `.planning/config.json` was left untouched.

---

_Verified: 2026-08-05T00:39:10Z_
_Verifier: the agent (gsd-verifier)_
