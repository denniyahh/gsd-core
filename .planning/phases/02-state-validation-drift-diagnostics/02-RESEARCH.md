# Phase 2: State Validation Drift Diagnostics - Research

**Researched:** 2026-08-04
**Domain:** Node.js CLI state-document parsing and filesystem drift diagnostics
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

<!-- DATA_7K4Q2M9P_START -->
### Locked Decisions

### Phase-source precedence

- **D-01:** Resolve the active phase in this order: frontmatter `current_phase`, legacy body `Current Phase`, then canonical body `Phase:`.
- **D-02:** When frontmatter and canonical body `Phase:` disagree, frontmatter remains authoritative and `state.validate` reports phase-reference drift rather than resolving silently.

### Unresolvable active phase

- **D-03:** If no usable phase reference can be resolved, return `valid: false` with an actionable warning; a validator that cannot perform its promised disk check must not report clean validation.
- **D-04:** If a phase reference resolves but no matching directory exists in `.planning/phases/`, report missing-phase drift and return `valid: false`.

### Regression proof

- **D-05:** Build the main regression from the shipped `gsd-core/templates/state.md` shape, then introduce known on-disk drift in a matching phase directory.
- **D-06:** Focused coverage must separately exercise frontmatter, legacy `Current Phase`, canonical `Phase:`, and a no-source negative control; parser-only tests do not satisfy the phase.

### the agent's Discretion

- Choose the smallest compatible helper extraction and assertion wording that follows the existing state-module patterns.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
<!-- DATA_7K4Q2M9P_END -->
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STATE-02 | A contributor running `state.validate` on the shipped `STATE.md` shape receives active-phase drift findings from disk; resolution reads `current_phase` frontmatter first, then the canonical `Phase:` prose field. | Reuse the frontmatter/body/prose resolution chain already used by state readers, compare canonical phase keys, fail closed when the phase or directory is unavailable, and retain the existing drift scans. [VERIFIED: .planning/REQUIREMENTS.md:9-12; src/state.cts:1403-1429; src/state.cts:2755-2831] |
| QUALITY-02 | A maintainer can verify STATE-02 through a focused regression test that proves the validator reports drift for that normal state-document shape. | Extend the owning command suite with a template-derived CLI regression and explicit precedence/fallback/negative-control cases. [VERIFIED: .planning/REQUIREMENTS.md:13-15; tests/state.test.cjs:3060-3138; TESTING-STANDARDS.md:14-84] |
</phase_requirements>

## Summary

The defect is a missing subject-resolution step, not a missing disk scanner. `cmdStateValidate` currently reads only body field `Current Phase` and gates every phase-directory check on that value; the shipped template instead has canonical `Phase: [X] of [Y] ([Phase name])`, while a normal synchronized project also carries frontmatter `current_phase`. When resolution fails, the function reaches `valid = warnings.length === 0` and returns a clean result without checking disk. [VERIFIED: src/state.cts:2774-2783; src/state.cts:2830-2831; gsd-core/templates/state.md:9-35; .planning/STATE.md:1-18,29-34]

The needed parsing and normalization seams already exist in `src/state.cts` and `src/phase-id.cts`: `extractFrontmatter`, `stripFrontmatter`, `matchCurrentPositionSection`, `stateExtractField`, `parseProsePhaseField`, `phaseKeyFromToken`, and `phaseKeyFromDir`. The existing `scanPhasePlans` implementation must remain the sole plan/summary counter because it covers flat and nested layouts, derivative exclusions, superseded plans, and summary pairing. [VERIFIED: src/state.cts:18-52,1328-1332,1368-1375,1403-1429; src/phase-id.cts:560-608; src/plan-scan.cts:19-29,71-94,106-170]

A live reproduction in this session used one plan on disk and two otherwise equivalent state fixtures. The template-shaped/frontmatter case returned `{"valid":true,"warnings":[],"drift":{}}`; replacing its phase source with legacy `**Current Phase:** 2` made the existing command return `valid:false` with `plan_count` drift. This negative control establishes that the scanner and assertion target work when the gate opens; it does not establish that the proposed source-resolution repair has been implemented. [VERIFIED: live reproduction, 2026-08-04]

**Primary recommendation:** Modify only `cmdStateValidate` and `tests/state.test.cjs`: resolve all three locked sources using existing parsers, compare normalized identities, enumerate and match the phase directory by canonical key, emit warning-backed invalid results for conflict/unresolvable/missing-directory cases, and prove the full command path with a template-derived drift fixture.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Active-phase resolution | CLI / Runtime | — | `cmdStateValidate` owns state validation and already has every parsing dependency needed for the resolution chain. [VERIFIED: src/state.cts:18-52,2751-2832] |
| Phase-reference comparison | CLI / Runtime | Filesystem / Storage | Canonical phase-key helpers normalize document tokens and directory names before equality comparison. [VERIFIED: src/phase-id.cts:571-608] |
| Plan/summary and verification drift scan | Filesystem / Storage | CLI / Runtime | `scanPhasePlans` reads the phase artifacts; `cmdStateValidate` translates counts and verification state into its structured diagnostic result. [VERIFIED: src/plan-scan.cts:106-170; src/state.cts:2788-2819] |
| Regression proof | Test harness | CLI / Runtime | `runGsdTools` invokes the emitted CLI against an isolated project, exercising routing, parsing, directory lookup, scanning, and JSON output together. [VERIFIED: tests/helpers.cjs:29-123; src/state-command-router.cts:180-189; tests/state.test.cjs:3060-3138] |

## Project Constraints (from AGENTS.md)

- Preserve behavior across supported runtimes and verify generated artifacts when canonical inputs change. Edit the TypeScript source under `src/`, not ignored emitted `.cjs`; `npm run build:lib` regenerates the runtime artifact used by tests. [VERIFIED: AGENTS.md:13-16,28-39,82-88,328-335]
- Add a reproducing regression for this confirmed defect, run focused checks before broader suites, keep `.planning/` tracked, use Node.js 22+ and npm 10+, and do not invoke DevFlow. [VERIFIED: AGENTS.md:15-18]
- Put the regression in `tests/state.test.cjs`; do not create a one-off `bug-*` test file. Use two-space indentation, single quotes, semicolons, trailing commas, `node:` imports in new code, and line-array `.join('\n')` multiline fixtures. [VERIFIED: AGENTS.md:98-124]
- Use existing Markdown parsing, path projection, and filesystem portability seams; do not add ad hoc Markdown regexes, concatenate paths, call `process.exit()`, or introduce a new mutable global. [VERIFIED: AGENTS.md:121-138,209-213,326-335]
- Tests must parse structured results and exercise behavior; they must not use `.only`, raw sleeps, raw `fs.rmSync`, tautologies, source-grep assertions, hard-coded `/tmp`, CRLF-fragile splits, or unguarded nonportable subprocesses. [VERIFIED: AGENTS.md:119-125; TESTING-STANDARDS.md:14-84]

## Standard Stack

### Core

| Library / Seam | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Node.js standard library (`node:fs`, `node:path`) | >=22 | Read `STATE.md`, enumerate phase directories, and inspect artifacts | This is the repository's runtime substrate and engine floor; no new runtime package is needed. [VERIFIED: package.json:52-58; AGENTS.md:36-39,62-66] |
| TypeScript `.cts` source | 6.0.3 | Author the command repair with strict checking and emit CommonJS `.cjs` | `src/**/*.cts` is the source of truth and `tsconfig.build.json` emits to `gsd-core/bin/lib`. [VERIFIED: package.json:69-72,89-92; tsconfig.build.json:1-21] |
| Existing state/frontmatter/phase-id/plan-scan seams | repository source | Parse the document, normalize phase identity, and count artifacts | These seams already implement the repository's compatibility and safety rules; reuse avoids a divergent parser or scanner. [VERIFIED: src/state.cts:18-52; src/frontmatter.cts:174-227; src/phase-id.cts:571-608; src/plan-scan.cts:106-170] |
| `node:test` + `node:assert/strict` | Node >=22 built-in | Command-level regression coverage | The owning test file already uses these built-ins and the project test runner builds emitted artifacts before executing tests. [VERIFIED: tests/state.test.cjs:9-16; scripts/run-tests.cjs:43-127] |

### Supporting

| Library / Seam | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `runGsdTools` | repository helper | Run the actual CLI with isolated environment and parsed stdout | Use for every acceptance case; parser-only calls do not satisfy QUALITY-02. [VERIFIED: tests/helpers.cjs:29-113; .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:26-33] |
| `createTempProject` / `cleanup` | repository helper | Create and safely remove isolated `.planning` fixtures | Use in the owning state suite; do not hand-roll temp cleanup. [VERIFIED: tests/helpers.cjs:115-155] |
| Node `--test-name-pattern` | stable in Node 22 | Run the changed suite in a focused loop | The option filters by JavaScript regular expression and does not alter the explicitly selected test file. [CITED: https://nodejs.org/download/release/latest-jod/docs/api/test.html] |

**Installation:** None. This phase adds no package and therefore requires no package-legitimacy audit. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:7-10,71-74]

## Architecture Patterns

### System Architecture Diagram

```text
CLI: gsd-tools state validate
  -> state command router
  -> cmdStateValidate
       -> read STATE.md
       -> reject binary/NUL corruption
       -> parse independent phase sources
          -> frontmatter current_phase -----------+
          -> legacy body Current Phase -----------+--> precedence winner
          -> Current Position body Phase: --------+
                  |                                     |
                  | conflict with frontmatter?          | no usable winner?
                  v                                     v
            record drift + warning              invalid + actionable warning
                  |
                  v
       -> enumerate .planning/phases directories
          -> canonical phase-key equality
             | match                         | no match/root absent
             v                               v
       scanPhasePlans + VERIFICATION     missing-phase drift + warning
             |
             v
       existing plan/status drift checks
             |
             v
       { valid, warnings, drift }
```

The router already maps the `validate` subcommand directly to `cmdStateValidate`; this phase does not need a new command surface. [VERIFIED: src/state-command-router.cts:180-189; .planning/REQUIREMENTS.md:17-29]

### Component Responsibilities

| Component | Responsibility in this phase | File |
|-----------|-------------------------------|------|
| Validator | Resolve sources, detect reference/directory failures, run existing scans, serialize the existing diagnostic contract | `src/state.cts` [VERIFIED: src/state.cts:2751-2832] |
| Frontmatter parser | Parse leading YAML-shaped state metadata | `src/frontmatter.cts` [VERIFIED: src/frontmatter.cts:174-227] |
| State body parser | Extract supported bold/plain/table fields | `src/state-document.cts` [VERIFIED: src/state-document.cts:214-232] |
| Phase identity owner | Parse prose phase values and normalize document/directory identities | `src/phase-id.cts` [VERIFIED: src/phase-id.cts:634-690,571-608] |
| Artifact scanner | Count valid flat/nested plans and matched summaries | `src/plan-scan.cts` [VERIFIED: src/plan-scan.cts:71-94,106-170] |
| Command regression suite | Prove the emitted CLI reaches disk drift for each source branch | `tests/state.test.cjs` [VERIFIED: tests/state.test.cjs:3060-3138,9560-9671] |

### Recommended Project Structure

```text
src/
└── state.cts                 # modify cmdStateValidate only
tests/
└── state.test.cjs            # add command-level regression cases
gsd-core/templates/
└── state.md                  # read-only canonical fixture source
```

This is a two-file authored change; `gsd-core/bin/lib/state.cjs` is generated and ignored, so it should be rebuilt for tests but not edited directly. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:71-74; AGENTS.md:328-335; scripts/run-tests.cjs:45-127]

### Pattern 1: Parse Sources Independently, Then Apply Precedence

Resolve frontmatter, legacy body, and canonical body into separate nullable values before selecting a winner. This is necessary because D-02 requires both frontmatter authority and visibility of disagreement; a single null-coalescing expression alone loses the losing source before it can be compared. The canonical `Phase:` lookup should stay scoped to `## Current Position`, with full-body fallback only when that section is absent, matching the established state reader. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:16-24; src/state.cts:1419-1429]

Normalize non-empty frontmatter scalars exactly as existing state readers do: accept string/number/boolean, trim strings, and reject arrays/objects. This prevents accidental `[object Object]` phase identities and preserves current compatibility. [VERIFIED: src/state.cts:1406-1417,3021-3028]

### Pattern 2: Compare Canonical Identity, Not Raw Spelling

Use `phaseKeyFromToken` for resolved references and `phaseKeyFromDir` for enumerated directory entries. Raw comparison would falsely classify `2` versus `02` or case variants as disagreement; prefix matching can select the wrong phase family and does not share the repository's phase-ID grammar. [VERIFIED: src/phase-id.cts:571-608; src/state.cts:2781-2787]

Recommendation: enumerate children under `planningPaths(cwd).phases`, filter directories, and select by canonical-key equality. Only then join the trusted enumerated directory name to the phases root. This both satisfies D-04 and avoids constructing a filesystem path directly from untrusted state text.

### Pattern 3: Fail Closed When Validation Could Not Run

Every unresolvable source, missing phases root, missing matching phase directory, or locked source conflict must add an actionable warning. Since `valid` is currently derived from `warnings.length === 0`, warning-backed failure preserves the existing output contract while preventing an unperformed check from looking clean. Conflict should not block scanning the authoritative frontmatter phase; report the conflict and continue the disk scan against the winner. [VERIFIED: src/state.cts:2771-2783,2830-2831; .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:18-24]

### Pattern 4: Prove the Whole Command Path

The main test should read the fenced Markdown fixture from `gsd-core/templates/state.md`, replace placeholders with a concrete phase/status, add the normal synchronized `current_phase` scalar, create the matching phase directory, and add a passed verification artifact while state still says executing. That existing drift path produces both a warning and structured `verification_status` drift without depending on the non-template `Total Plans in Phase` body field. [VERIFIED: gsd-core/templates/state.md:7-37; .planning/STATE.md:1-18; src/state.cts:2797-2806]

Add separate command cases for frontmatter, legacy `Current Phase`, canonical `Phase:`, frontmatter/body disagreement, no usable source, missing directory, and equivalent spellings such as `2`/`02`. Assert parsed JSON semantics (`valid`, warning presence/category, selected phase's disk evidence, structured drift), not full warning sentences. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:16-33; TESTING-STANDARDS.md:18-84]

### Anti-Patterns to Avoid

- **Adding another phase regex:** `parsePhaseFromProse` is the canonical anchored parser and already bounds name extraction. A local regex can reintroduce milestone-number mining or grammar drift. [VERIFIED: src/phase-id.cts:634-690]
- **Using `startsWith` directory matching:** it is a rendering heuristic, not canonical identity equality, and is the only remaining bespoke match in this validator. [VERIFIED: src/state.cts:2781-2787; src/phase-id.cts:571-608]
- **Reading `stateExtractField(content, ...)` from the combined document for the new phase chain:** frontmatter and body must be separated so precedence and conflict provenance remain observable. [VERIFIED: src/state.cts:1403-1429]
- **Returning clean validation when the phase root is absent:** D-04 applies when there is no matching phase directory, including an absent phases root. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:21-24]
- **Expanding into plan-count/progress synchronization:** the normal template has `Plan: [A] of [B]`, not `Total Plans in Phase`, and progress fixes are explicitly deferred. [VERIFIED: gsd-core/templates/state.md:30-37; .planning/REQUIREMENTS.md:17-29]
- **Testing only a helper/parser:** it can pass while `cmdStateValidate` still gates or routes incorrectly; QUALITY-02 requires real command output driven by disk artifacts. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:26-33,77-80]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML-like frontmatter parsing | Split/regex parser inside the validator | `extractFrontmatter` | It owns byte-zero fencing, CRLF handling, and unusable-input diagnostics. [VERIFIED: src/frontmatter.cts:174-227] |
| Markdown field extraction | New patterns for bold/plain/table shapes | `stateExtractField` | It already supports the three accepted body renderings. [VERIFIED: src/state-document.cts:214-232] |
| Section parsing | Ad hoc heading regex | `matchCurrentPositionSection` / shared sectionizer | The existing seam is level-bounded and CRLF-tolerant. [VERIFIED: src/state.cts:1320-1332; AGENTS.md:121-124] |
| `Phase:` value parsing | Local number regex | `parseProsePhaseField` → `parsePhaseFromProse` | The canonical parser is anchored and hardened against status/name ambiguity. [VERIFIED: src/state.cts:1368-1375; src/phase-id.cts:634-690] |
| Phase-directory matching | Padding plus `startsWith` | `phaseKeyFromToken` + `phaseKeyFromDir` | Canonical keys are padding-, case-, and project-code-insensitive. [VERIFIED: src/phase-id.cts:571-608] |
| Plan/summary counting | `readdirSync().filter()` in the validator | `scanPhasePlans` | The shared scan handles flat/nested layouts, exclusions, superseded plans, and matched summaries. [VERIFIED: src/plan-scan.cts:19-29,71-94,106-170] |
| CLI test process and fixture lifecycle | Raw `child_process`, `mkdtemp`, or cleanup | `runGsdTools`, `createTempProject`, `cleanup` | Helpers sandbox environment, retry killed subprocesses, and provide portable cleanup. [VERIFIED: tests/helpers.cjs:29-155] |

**Key insight:** The phase is an orchestration repair across existing parsing and scanning seams. New parsers or scanners would enlarge the defect surface without adding a required capability.

## Common Pitfalls

### Pitfall 1: Precedence Works but Conflict Disappears

**What goes wrong:** A coalescing chain selects frontmatter correctly but never records that canonical body `Phase:` points elsewhere.

**Why it happens:** The losing source is discarded before identities are compared.

**How to avoid:** Retain all three parsed values, compare canonical keys, select by D-01, report D-02 conflict, and scan the authoritative winner.

**Warning signs:** A test with frontmatter phase 2 and body phase 1 is `valid:true`, or the validator scans phase 1. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:16-24]

### Pitfall 2: Equivalent Formatting Becomes False Drift

**What goes wrong:** `2` and `02` are reported as disagreeing or fail to match the same directory.

**Why it happens:** Raw strings or padding heuristics are compared rather than phase keys.

**How to avoid:** Normalize both document values and directory names through the phase-ID owner.

**Warning signs:** A `2`/`02` negative-space test produces phase-reference or missing-directory drift. [VERIFIED: src/phase-id.cts:571-608]

### Pitfall 3: Archived `Phase:` Wins

**What goes wrong:** A historical phase line elsewhere in `STATE.md` shadows the active position.

**Why it happens:** `stateExtractField` returns the first matching body occurrence when used document-wide.

**How to avoid:** Scope canonical `Phase:` to the Current Position section, as `cmdStateSnapshot` and `buildStateFrontmatter` already do.

**Warning signs:** Adding an earlier archive section changes the resolved active phase. [VERIFIED: src/state.cts:1335-1347,1419-1429,1577-1587]

### Pitfall 4: Missing Directory Still Looks Clean

**What goes wrong:** A resolved phase with no root/match skips the scan and falls through to `valid:true`.

**Why it happens:** Existence is used only as an `if` gate instead of a validation outcome.

**How to avoid:** Treat absent root and absent canonical match as warning-backed missing-phase drift.

**Warning signs:** `warnings` remains empty after deleting the target phase directory. [VERIFIED: src/state.cts:2779-2787,2830-2831; .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:21-24]

### Pitfall 5: The Main Regression Uses a Non-Shipped Field

**What goes wrong:** A plan-count test adds `Total Plans in Phase`, proving legacy behavior rather than the shipped shape.

**Why it happens:** Existing tests use legacy bold fields and are copied unchanged.

**How to avoid:** Drive the main regression through the shipped template and use passed-verification/status drift, which only needs template/synchronized fields.

**Warning signs:** The main fixture contains `**Current Phase:**` or `**Total Plans in Phase:**`. [VERIFIED: gsd-core/templates/state.md:9-37; tests/state.test.cjs:3071-3130]

### Pitfall 6: A Passing Focused Suite Is Overclaimed

**What goes wrong:** Existing legacy tests pass and are reported as proof of STATE-02.

**Why it happens:** The current suite opens the old gate but contains no template/frontmatter/canonical/no-source acceptance matrix.

**How to avoid:** Demonstrate red-before/fix-after for the new template-derived case and retain a negative control that must produce the opposite result.

**Warning signs:** The focused suite reports only the four existing cases. In this session those four passed in 1.54 seconds, but that result establishes only the legacy command paths, not the requested repair. [VERIFIED: focused test run, 2026-08-04; tests/state.test.cjs:3060-3138]

## Code Examples

Verified patterns from repository and official sources:

### Established Frontmatter-First Resolution Chain

<!-- DATA_R8V3N6C1_START -->
```typescript
// Source: src/state.cts:1426-1429
const currentPositionScope = matchCurrentPositionSection(body) ?? body;
const prosePhase = parseProsePhaseField(stateExtractField(currentPositionScope, 'Phase'));
const currentPhase = fmScalar('current_phase') ?? stateExtractField(body, 'Current Phase') ?? prosePhase.phase;
```
<!-- DATA_R8V3N6C1_END -->

For validation, compute the three operands separately before applying this precedence so disagreement remains observable. [VERIFIED: src/state.cts:1419-1429; .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:16-24]

### Canonical Document/Directory Identity

<!-- DATA_T5J9W2L4_START -->
```typescript
// Source: src/phase-id.cts:595-608
function phaseKeyFromToken(token: unknown): string {
  const stripped = String(token)
    .split('-')
    .map(segment => segment.replace(/^0+(?=\d)/, ''))
    .join('-');
  return normalizePhaseName(stripped).toUpperCase();
}

function phaseKeyFromDir(dirName: string): string {
  return phaseKeyFromToken(extractPhaseToken(dirName));
}
```
<!-- DATA_T5J9W2L4_END -->

These functions are already imported into `src/state.cts`, so canonical matching needs no new dependency. [VERIFIED: src/state.cts:18-20]

### Focused Command-Level Test Invocation

<!-- DATA_F3H7B1Q8_START -->
```bash
npm run build:lib
node --test --test-name-pattern='state validate command' tests/state.test.cjs
```
<!-- DATA_F3H7B1Q8_END -->

The command completed successfully in this session with the four existing matching tests. Node's official documentation confirms that name patterns are regular expressions and do not change the explicit file selection. This result does not cover the not-yet-added STATE-02 regression cases. [VERIFIED: focused test run, 2026-08-04] [CITED: https://nodejs.org/download/release/latest-jod/docs/api/test.html]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `cmdStateValidate` uses only body `Current Phase` and prefix-matches a padded directory name. | Other state readers already use frontmatter → legacy field → scoped canonical `Phase:` and the phase-ID module provides canonical token/directory keys. | Present repository state as of 2026-08-04 | Phase 2 should bring validation into parity with existing state readers rather than inventing a new convention. [VERIFIED: src/state.cts:1419-1429,2751-2787,3008-3033; src/phase-id.cts:571-608] |
| Validator silently skips when it cannot find a phase subject/root/match. | Locked phase behavior requires warning-backed invalid output for unresolvable or missing-phase cases. | Phase 2 decision, 2026-08-04 | `valid:true` will once again mean the promised disk check was able to run. [VERIFIED: src/state.cts:2781-2831; .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:21-24] |
| Existing command tests construct legacy bold-field documents. | Required regression derives the normal document from the shipped state template and proves disk drift through the CLI. | Phase 2 decision, 2026-08-04 | QUALITY-02 covers the actual failure shape rather than only the old compatible shape. [VERIFIED: tests/state.test.cjs:3071-3130; .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:26-33] |

**Deprecated/outdated:**

- Treating `Current Phase` as the validator's only phase source is incompatible with the shipped template and synchronized frontmatter contract. [VERIFIED: src/state.cts:2774-2783; gsd-core/templates/state.md:9-35; .planning/STATE.md:1-18]
- Using a clean result as the fallback for an unperformed scan is explicitly superseded by D-03/D-04. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:21-24]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. All factual claims are verified from repository source/tests or cited official documentation. Exact new warning text and structured drift-key naming remain implementation discretion and should be asserted behaviorally, not treated as a locked research assumption. | — | — |

## Open Questions

None blocking. The exact warning sentence and new structured drift-key labels are intentionally not prescribed because CONTEXT delegates assertion wording; the plan should require semantic assertions and stable machine-readable drift without coupling tests to full prose. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:31-33; TESTING-STANDARDS.md:18-68]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | build, CLI, tests | ✓ | 26.6.0 | Project/CI floor is 22. [VERIFIED: environment probe, 2026-08-04; package.json:52-54] |
| npm | build and repository scripts | ✓ | 11.18.0 | Project/CI floor is 10. [VERIFIED: environment probe, 2026-08-04; package.json:52-55] |
| Git | tracked planning artifact and commit | ✓ | 2.55.0 | — [VERIFIED: environment probe, 2026-08-04] |
| ripgrep | repository investigation | ✓ | 15.2.0 | — [VERIFIED: environment probe, 2026-08-04] |

**Missing dependencies with no fallback:** None. [VERIFIED: environment probe, 2026-08-04]

**Missing dependencies with fallback:** None. [VERIFIED: environment probe, 2026-08-04]

No external service or new package is required for implementation. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:7-10,71-74]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node built-in `node:test`, Node >=22 [VERIFIED: tests/state.test.cjs:9-16; package.json:52-54] |
| Config file | none; repository orchestration is `scripts/run-tests.cjs` [VERIFIED: package.json:125-140; scripts/run-tests.cjs:1-43] |
| Quick run command | `npm run build:lib && node --test --test-name-pattern='state validate command' tests/state.test.cjs` [VERIFIED: focused test run, 2026-08-04] |
| Owning-file run | `node scripts/run-tests.cjs --files state.test.cjs` [VERIFIED: scripts/run-tests.cjs:6-17,539-580] |
| Full suite command | `npm test` [VERIFIED: package.json:105-106,125-131] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STATE-02 | Template-derived document with usable frontmatter reaches passed-verification disk drift | command regression | `node --test --test-name-pattern='state validate command' tests/state.test.cjs` | ❌ Wave 0 case in existing file |
| STATE-02 | Legacy `Current Phase` and canonical `Phase:` independently reach the same disk drift path | command regression | same | ❌ Wave 0 cases in existing file |
| STATE-02 | Frontmatter wins over disagreeing canonical body while conflict drift is reported | command regression | same | ❌ Wave 0 case in existing file |
| STATE-02 | Missing/unusable source and missing matching phase directory are invalid with actionable warnings | negative command regression | same | ❌ Wave 0 cases in existing file |
| STATE-02 | Equivalent `2`/`02` references do not create false conflict/missing-directory drift | negative-space command regression | same | ❌ Wave 0 case in existing file |
| QUALITY-02 | Main shipped-shape fixture proves full validator output, not parser extraction | command regression | same | ❌ Wave 0 case in existing file |

### Sampling Rate

- **Red proof before implementation:** Run the new template-derived case alone and record that it returns clean validation despite known disk drift. This is the confirmed failure; the existing four-case suite passing is not red proof. [VERIFIED: live reproduction, 2026-08-04; TESTING-STANDARDS.md:54-68]
- **Per task commit:** `npm run build:lib && node --test --test-name-pattern='state validate command' tests/state.test.cjs`
- **Per wave merge:** `node scripts/run-tests.cjs --files state.test.cjs` plus `npm run lint`
- **Phase gate:** `npm test` and `npm run lint:ci`; full suite green before `$gsd-verify-work`. [VERIFIED: package.json:105-140; AGENTS.md:121-124]

### Wave 0 Gaps

- [ ] Extend the existing `state validate command` block in `tests/state.test.cjs` with the template-derived drift test and the D-06 source matrix. [VERIFIED: tests/state.test.cjs:3060-3138]
- [ ] Add explicit conflict, unresolved-source, missing-root/missing-directory, and normalized-equality cases so both failure and negative space are covered. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:16-33; TESTING-STANDARDS.md:78-84]
- [ ] Confirm the template extraction/replacement fails loudly if the fenced product shape cannot be found or concrete substitutions do not occur; otherwise a fixture-construction failure can masquerade as a validator failure. [VERIFIED: gsd-core/templates/state.md:7-93; TESTING-STANDARDS.md:39-60]

No framework/config/fixture-helper installation gap exists. [VERIFIED: tests/state.test.cjs:9-16; tests/helpers.cjs:115-155]

## Security Domain

Security enforcement is enabled at ASVS level 1. [VERIFIED: .planning/config.json:20-49]

OWASP ASVS 5.0.0 is the current stable ASVS release; its chapter numbering differs from the legacy V2–V6 labels in the research template. The phase-specific assessment below retains the requested labels for planner compatibility and treats local state-file parsing as the applicable input-validation concern. [CITED: https://github.com/OWASP/ASVS]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No identity/authentication surface is in the phase boundary. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:7-10] |
| V3 Session Management | no | The command reads project state and disk artifacts; it does not create or manage user sessions. [VERIFIED: src/state.cts:2751-2832] |
| V4 Access Control | no | The phase adds no authorization policy or external privilege boundary. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:7-10] |
| V5 Input Validation | yes | Keep corruption rejection, scalar-shape checks, anchored canonical phase parsing, normalized identity comparison, and enumeration-before-path-join. [VERIFIED: src/state.cts:2762-2769,1406-1417; src/phase-id.cts:634-690,571-608] |
| V6 Cryptography | no | No secrets, keys, signatures, encryption, or hashing are introduced by the scoped repair. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:7-10] |

### Known Threat Patterns for Node.js Local State Validation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path confusion/traversal from crafted phase text | Tampering | Compare the parsed phase key against keys derived from enumerated child directory names; join only the enumerated name under `planningPaths(cwd).phases`. [VERIFIED: src/phase-id.cts:571-608; src/state.cts:2779-2789] |
| Regex CPU exhaustion from crafted `Phase:` prose | Denial of Service | Reuse `parsePhaseFromProse`, whose phase match is anchored and whose name captures are length-bounded. [VERIFIED: src/phase-id.cts:634-690] |
| Binary/NUL state input treated as absent fields | Tampering / Denial of Service | Preserve the existing early `textEncodingError` invalid result before phase resolution. [VERIFIED: src/state.cts:2762-2769] |
| Array/object `current_phase` coerced to a plausible string | Spoofing / Tampering | Accept only non-empty string, number, or boolean scalars, matching existing state readers. [VERIFIED: src/state.cts:1406-1417,3021-3028] |
| Missing source/root/match reported as clean | Spoofing | Fail closed with warning-backed `valid:false`; include negative controls for each absent boundary. [VERIFIED: .planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md:21-29; TESTING-STANDARDS.md:78-84] |

## Sources

### Primary (HIGH confidence)

- `src/state.cts` — validator implementation, established source precedence, section scoping, and drift contract.
- `src/frontmatter.cts` — frontmatter parsing contract.
- `src/state-document.cts` — supported state body field extraction.
- `src/phase-id.cts` — canonical prose parsing and phase-key normalization.
- `src/plan-scan.cts` — artifact counting semantics.
- `gsd-core/templates/state.md` — shipped state-document body/frontmatter shape.
- `tests/state.test.cjs`, `tests/helpers.cjs`, `TESTING-STANDARDS.md`, `docs/TESTING-SUITES.md` — owning suite, fixture helpers, and test rigor/placement contracts.
- `.planning/phases/02-state-validation-drift-diagnostics/02-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` — locked scope and acceptance contract.
- Live reproduction and focused test run on 2026-08-04 — defect/negative-control separation and current suite baseline.

### Secondary (MEDIUM confidence)

- https://nodejs.org/download/release/latest-jod/docs/api/test.html — official Node.js 22 test-name filtering behavior.
- https://github.com/OWASP/ASVS — official ASVS current stable version and versioned-reference guidance.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new package; versions and seams verified in repository metadata/source.
- Architecture: HIGH — traced from CLI router through the exact validator, parser, normalizer, and disk scanner.
- Pitfalls: HIGH — derived from the live defect reproduction, locked decisions, existing regression suite, and repository test rules.
- External documentation: MEDIUM — official sources found through web-search fallback; the research confidence seam classifies verified `websearch` as MEDIUM.

**Research date:** 2026-08-04
**Valid until:** 2026-09-03 (30 days; implementation is repository-local and stable, while external documentation is not decision-critical)
