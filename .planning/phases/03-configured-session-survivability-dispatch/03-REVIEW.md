---
phase: 03-configured-session-survivability-dispatch
reviewed: 2026-08-30T17:20:56Z
depth: external-maintainer
review_source: GitHub PR #4035
reviewer: trek-e
pr: 4035
issue: 3159
head_sha: e58dbfcfb979d4b68e525e5b27da7ba1b69f383a
files_reviewed: 35
files_reviewed_list:
  - .changeset/plucky-goats-wake.md
  - docs/CONFIGURATION.md
  - docs/INVENTORY-MANIFEST.json
  - docs/adr/3159-executor-session-survivability-dispatch.md
  - docs/adr/README.md
  - gsd-core/bin/shared/config-defaults.manifest.json
  - gsd-core/bin/shared/config-schema.manifest.json
  - gsd-core/references/planning-config.md
  - gsd-core/workflows/execute-phase.md
  - gsd-core/workflows/execute-phase/steps/executor-isolation-dispatch.md
  - gsd-core/workflows/execute-phase/steps/session-survivability-dispatch.md
  - src/config.cts
  - tests/config-get-default.test.cjs
  - tests/config.test.cjs
  - tests/execute-phase-active-flags.test.cjs
  - tests/fixtures/install-tree/antigravity.json
  - tests/fixtures/install-tree/augment.json
  - tests/fixtures/install-tree/claude-local.json
  - tests/fixtures/install-tree/claude.json
  - tests/fixtures/install-tree/cline.json
  - tests/fixtures/install-tree/codebuddy.json
  - tests/fixtures/install-tree/codex.json
  - tests/fixtures/install-tree/copilot.json
  - tests/fixtures/install-tree/cursor.json
  - tests/fixtures/install-tree/hermes.json
  - tests/fixtures/install-tree/kilo.json
  - tests/fixtures/install-tree/kimi-code.json
  - tests/fixtures/install-tree/kimi.json
  - tests/fixtures/install-tree/opencode.json
  - tests/fixtures/install-tree/pi.json
  - tests/fixtures/install-tree/qwen.json
  - tests/fixtures/install-tree/trae.json
  - tests/fixtures/install-tree/windsurf.json
  - tests/fixtures/install-tree/zcode.json
  - tests/runtime-converters.test.cjs
findings:
  critical: 1
  warning: 4
  info: 2
  total: 7
status: issues_found
review_status: changes_requested
---

# Phase 03: External Maintainer Code Review Report

**Reviewed:** 2026-08-30T17:20:56Z  
**Source:** [PR #4035](https://github.com/open-gsd/gsd-core/pull/4035)  
**Reviewer:** `trek-e`  
**Review type:** Maintainer review, latest submitted review  
**Head reviewed:** `e58dbfcfb9794d4b68e525e5b27da7ba1b69f383a`  
**Status:** changes requested

## Summary

The maintainer considers the configuration wiring, ADR, scope fence, and general design sound. The latest review found no blocker-level issue, but approval remains blocked by one dispatch-template correctness concern plus six convention, coverage, documentation, and design-judgment findings.

The frontmatter maps the maintainer's labels to the canonical planning review tiers: **Major → critical**, **Minor → warning**, and **Nit → info**. This preserves the repository's downstream `critical`/`warning`/`info` shape while retaining the original labels below.

The prior review's stale install-tree blocker was reported as addressed after rebasing and regenerating fixtures. The author also reported completing the changeset wording, completion-fallback wording, and deliberate workflow-growth acknowledgment cleanups. Those are recorded as review history, not as independently re-run verification in this artifact.

## Narrative Findings (Maintainer review)

### Critical Issues

#### CR-01 [MAJOR]: Harness dispatch template is incomplete

**File:** `gsd-core/workflows/execute-phase/steps/session-survivability-dispatch.md:246`

The harness `Agent()` template omits the isolation flag (`{harnessFlag}`), `model=`, and the full executor prompt, replacing the latter with an undefined `{EXECUTOR_PROMPT}` token. Because `execute-phase.md` presents this fragment as supplying literal background and foreground calls, a host model could dispatch the incomplete call verbatim. The maintainer relates this to the documented #3637 failure mode, where a stripped executor prompt loses role, required-reading, and skip semantics and can force-stage ignored files.

**Requested action:** Preserve the full existing harness dispatch contract in both literal branches, vary only the session-survivability argument, and add regression coverage equivalent to `tests/executor-isolation-prompt-contract.test.cjs` for this harness fragment.

### Warning Issues

#### WR-01 [MINOR]: Normalize `Agent()` keyword syntax

**File:** `gsd-core/workflows/execute-phase/steps/session-survivability-dispatch.md:16`

The template mixes colon syntax (`run_in_background: true/false`) with equals-sign syntax (`subagent_type="..."`, `description="..."`), unlike the repository's other `Agent()` templates.

**Requested action:** Use the repository's consistent equals-sign keyword syntax throughout the literal calls.

#### WR-02 [MINOR]: Add feature documentation parity

**Files:** `docs/FEATURES.md`, `docs/features/<slug>.md`

The new `workflow.session_outlives_turn` toggle has no feature fragment and no regenerated `FEATURES.md` entry, unlike the analogous `workflow.use_worktrees` toggle.

**Requested action:** Add the appropriate feature document and regenerate the generated feature index.

#### WR-03 [MINOR]: Cover the sequential/no-isolation path explicitly

**File:** `gsd-core/workflows/execute-phase.md:806`

The `isolation=none` / `workflow.use_worktrees=false` executor path is not explicitly wired to `SESSION_OUTLIVES_TURN`, and the behavior is not covered by the ADR or new tests.

**Requested action:** Explicitly specify the flag's behavior for this third executor path and add corresponding documentation and regression coverage.

#### WR-04 [MINOR]: Reconcile defensive normalization symmetry

**File:** `gsd-core/workflows/execute-phase.md:159`

`SESSION_OUTLIVES_TURN` is defensively re-normalized after `config-get`, while the sibling `USE_WORKTREES` value is not, despite being resolved and consumed similarly.

**Requested action:** Reconcile the two normalization paths so the defensive coding is intentional and consistent.

### Informational/Nit Issues

#### IR-01 [NIT]: Decide the config-read failure direction

**File:** `gsd-core/workflows/execute-phase.md:104`

Unexpected or failed configuration output normalizes to `true`, selecting background dispatch. This follows the existing absent-means-enabled convention, but it can select the orphaning-prone behavior for the exact hosts this feature is intended to protect.

**Requested action:** Make an explicit maintainer decision to retain this fail-open behavior (with rationale) or change the fallback direction. The review identifies this as a design judgment, not a confirmed defect.

#### IR-02 [NIT]: Align the configuration-row wording

**File:** `docs/CONFIGURATION.md:420`

`Added in #3159` combines a version-style prefix with an issue number and does not match neighboring documentation conventions.

**Requested action:** Use the repository's established bare issue-reference or version-reference form.

## Review History

### 2026-08-29 review — addressed blocker

The first maintainer review requested changes because the then-current head had 19 install-tree fixture mismatches after `next` advanced with `scripts/lib/ndjson-reporter.cjs`. It also flagged changeset lead wording, completion-fallback wording, the absent inline `run_in_background` parameter, and the fail-open behavior.

The author's [follow-up comment](https://github.com/open-gsd/gsd-core/pull/4035#issuecomment-5466373023) reported:

- rebasing onto current `next` and regenerating all 19 install-tree fixtures;
- adding the `Emitted-Drift-Ack-Growth` trailer;
- applying the changeset and completion-fallback wording cleanups; and
- verifying the current head's checks.

The latest review removed the stale-fixture blocker but retained the seven findings documented above.

## Verification Limits

This artifact records the maintainer's submitted review and the PR metadata fetched from GitHub. It is not a new independent code review, does not prove the requested changes have been implemented, and does not establish that the current PR has passed any checks after the latest review. No source files were changed while recording this artifact.

---

_Recorded: 2026-09-01_  
_Reviewer source: GitHub maintainer review by `trek-e`_  
_Implementation status: not started_
