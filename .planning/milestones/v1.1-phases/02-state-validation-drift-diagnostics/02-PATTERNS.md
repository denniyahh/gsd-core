# Phase 2: State Validation Drift Diagnostics - Pattern Map

**Mapped:** 2026-08-04  
**Files analyzed:** 2 authored files  
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `src/state.cts` | service / CLI command handler | request-response, file-I/O | `src/state.cts` (`cmdStateSnapshot`, `cmdStatePrune`, `cmdStateValidate`) | exact module and flow |
| `tests/state.test.cjs` | command regression test | request-response, file-I/O | `tests/state.test.cjs` (`state validate command`, nested-layout regressions) | exact module and flow |

## Pattern Assignments

### `src/state.cts` (service / CLI command handler, request-response + file-I/O)

**Primary analog:** `src/state.cts` — `cmdStateValidate` (lines 2755-2832)  
**Resolution analog:** `src/state.cts` — `cmdStateSnapshot` (lines 1403-1429) and `cmdStatePrune` (lines 3018-3033)

Extend `cmdStateValidate`; do not add a new command, parser, or scanner. Its existing imports already include the required frontmatter, phase-key, path, and plan-scan seams (lines 9-52):

```typescript
import fs from 'node:fs';
import path from 'node:path';
// eslint-disable-next-line @typescript-eslint/no-require-imports
import phaseIdMod = require('./phase-id.cjs');
const { escapeRegex, parsePhaseFromProse, PHASE_NUMBER_TOKEN_SOURCE, phaseKeyFromToken, phaseKeyFromDir } = phaseIdMod;
// eslint-disable-next-line @typescript-eslint/no-require-imports
import planningWorkspace = require('./planning-workspace.cjs');
const { planningDir, planningPaths } = planningWorkspace;
// eslint-disable-next-line @typescript-eslint/no-require-imports
import frontmatter = require('./frontmatter.cjs');
const { extractFrontmatter, reconstructFrontmatter, stripFrontmatter } = frontmatter;
// eslint-disable-next-line @typescript-eslint/no-require-imports
import scanPhasePlans = require('./plan-scan.cjs');
```

**Independent phase-source resolution** — copy the extraction/scalar rules from lines 1403-1428. For this validator, retain each source in its own variable before applying the precedence expression, because the losing value is required to diagnose a frontmatter/prose conflict.

```typescript
const fm = extractFrontmatter(content, statePath) as Record<string, unknown>;
const body = stripFrontmatter(content);

const fmScalar = (key: string): string | null => {
  const v = fm[key];
  if (v === null || v === undefined) return null;
  if (typeof v === 'string') return v.trim() || null;
  if (typeof v === 'number' || typeof v === 'boolean') return String(v);
  return null;
};

const currentPositionScope = matchCurrentPositionSection(body) ?? body;
const prosePhase = parseProsePhaseField(stateExtractField(currentPositionScope, 'Phase'));
const currentPhase = fmScalar('current_phase') ?? stateExtractField(body, 'Current Phase') ?? prosePhase.phase;
```

`cmdStatePrune` has the same scalar boundary and phase-source precedence in a narrower command context (lines 3018-3033):

```typescript
const fm = extractFrontmatter(rawState, statePath) as Record<string, unknown>;
const body = stripFrontmatter(rawState);
const fmRawPhase = fm.current_phase;
const fmCurrentPhase =
  typeof fmRawPhase === 'string' ? (fmRawPhase.trim() || null)
    : typeof fmRawPhase === 'number' || typeof fmRawPhase === 'boolean' ? String(fmRawPhase)
      : null;
const positionSection = sliceCurrentPositionSection(body);
const prosePhase =
  positionSection !== null ? parseProsePhaseField(stateExtractField(positionSection, 'Phase')).phase : null;
const currentPhaseRaw = fmCurrentPhase ?? stateExtractField(body, 'Current Phase') ?? prosePhase;
```

**Canonical reference and directory comparison** — use the phase-ID owner, not `startsWith` or padding logic. `src/phase-id.cts` lines 595-608 define the shared identity contract:

```typescript
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

Enumerate `planningPaths(cwd).phases`, restrict candidates with `isDirectory()`, compare `phaseKeyFromDir(entry.name) === phaseKeyFromToken(resolvedPhase)`, then join the trusted `entry.name`. This recognizes equivalent `2`/`02` spellings and avoids deriving a path from untrusted state text.

**Preserve the diagnostics contract** — `cmdStateValidate` lines 2762-2772 and 2830-2831 establish invalid-result and output shapes:

```typescript
const encErr = textEncodingError(content, 'STATE.md');
if (encErr) {
  output({ valid: false, warnings: [encErr], drift: {} }, raw, undefined);
  return;
}
const warnings: string[] = [];
const drift: Record<string, unknown> = {};

const valid = warnings.length === 0;
output({ valid, warnings, drift }, raw, undefined);
```

Use this same warning-backed failure contract for an unresolved phase source, frontmatter/prose conflict, a missing phase root, and a missing canonical directory match. Do not let an unavailable scan fall through to `valid: true`.

**Retain disk-drift scans** — lines 2788-2818 show the existing scanner and status-drift behavior to preserve after a directory is resolved:

```typescript
const phaseDirPath = path.join(phasesDir, phaseDir.name);
const { planCount: diskPlans, summaryCount: diskSummaries } = scanPhasePlans(phaseDirPath);

if (totalPlansInPhase !== null && diskPlans !== totalPlansInPhase) {
  warnings.push(`Plan count mismatch: STATE.md says ${totalPlansInPhase} plans, disk has ${diskPlans}`);
  drift['plan_count'] = { state: totalPlansInPhase, disk: diskPlans };
}

if (/status:\s*passed/i.test(vContent) && /executing/i.test(status)) {
  warnings.push(`Status drift: STATE.md says "${status}" but ${vf} shows verification passed — phase may be complete`);
  drift['verification_status'] = { state_status: status, verification: 'passed' };
}
```

Keep the local try/catch around unreadable individual verification files (lines 2800-2810). The new missing-root/missing-directory condition is different: it is an unperformed required validation and must be recorded as drift/warning before this best-effort file loop.

---

### `tests/state.test.cjs` (command regression test, request-response + file-I/O)

**Primary analog:** `tests/state.test.cjs` — `state validate command` block (lines 3060-3138)  
**Supporting analog:** `tests/state.test.cjs` — nested-layout validator regressions (lines 9568-9671)  
**Template-fixture analog:** `tests/state-transition.test.cjs` (lines 1402-1425, 1508-1521)

Add coverage inside the existing `describe('state validate command', ...)` block. It already owns fixture setup, cleanup, real CLI invocation, and JSON assertions:

```javascript
describe('state validate command', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createFixture();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });
});
```

Use the existing full-command test form from lines 3071-3089; parse the JSON result and assert behavioral properties rather than complete rendered warning text:

```javascript
const result = runGsdTools('state validate', tmpDir);
assert.ok(result.success, `Command failed: ${result.error}`);
const output = JSON.parse(result.output);
assert.ok(output.warnings.length > 0, 'Should have warnings when executing but verification passed');
assert.ok(output.warnings.some(w => /verif/i.test(w)), 'Warning should mention verification');
```

For a disk-driven positive case, use the shared top-level verification writer rather than duplicating its file format (`tests/state.test.cjs` lines 26-31):

```javascript
function writePassedVerification(tmpDir, phaseDirName, paddedPhase) {
  fs.writeFileSync(
    path.join(tmpDir, '.planning', 'phases', phaseDirName, `${paddedPhase}-VERIFICATION.md`),
    ['---', 'status: passed', '---', '', '# Verification', ''].join('\n'),
  );
}
```

The nested-plan tests show the desired assertion depth: verify `valid`, warning presence, and the semantic fields of structured drift rather than only warning prose (lines 9633-9641):

```javascript
const parsed = JSON.parse(result.output);
assert.ok(!parsed.valid, 'state validate should report invalid when plan counts differ');
assert.ok(parsed.warnings.length > 0, 'at least one drift warning expected');
assert.ok(parsed.drift.plan_count, 'plan_count drift object must be present');
assert.strictEqual(parsed.drift.plan_count.disk, 2, 'disk count must reflect nested scan (2 nested plans)');
assert.strictEqual(parsed.drift.plan_count.state, 5, 'state count from STATE.md must be 5');
```

**Shipped-template fixture** — derive the main fixture from `gsd-core/templates/state.md`, not a hand-written legacy `**Current Phase:**` document. The closest existing template extraction pattern is `tests/state-transition.test.cjs` lines 1407-1425 and 1512-1521:

```javascript
const REPO_ROOT = path.join(__dirname, '..');
const templatePath = path.join(REPO_ROOT, 'gsd-core', 'templates', 'state.md');

function extractFileTemplate(fileContent) {
  const match = fileContent.match(/```markdown\r?\n([\s\S]*?)```/);
  assert.ok(match, 'No ```markdown code block found in template file');
  return match[1];
}

const content = fs.readFileSync(templatePath, 'utf-8');
const body = extractFileTemplate(content);
assert.ok(body.trimStart().startsWith('---'));
```

For the Phase 2 regression, add loud assertions that the expected placeholders/replacements are present before writing the derived `STATE.md`; this prevents a broken fixture constructor from being mistaken for a validator regression. Then create a matching phase directory and passed verification while template-derived state remains executing, and assert `verification_status` drift.

The same suite must include separate command cases for frontmatter, legacy `Current Phase`, canonical scoped `Phase:`, a no-source negative control, frontmatter/canonical disagreement, missing directory/root, and `2`/`02` equivalence. The no-source and missing-directory cases must assert invalid output plus a warning; the equivalent-spelling case must assert no phase-reference or missing-directory false drift.

## Shared Patterns

### Frontmatter/body boundary

**Sources:** `src/state.cts` lines 1403-1429; `src/state.cts` lines 3018-3033  
**Apply to:** `cmdStateValidate`

Always call `extractFrontmatter(content, statePath)` and `stripFrontmatter(content)` before resolving the three phase sources. Accept only non-empty string/number/boolean frontmatter values; arrays and objects mean no usable source. Scope canonical `Phase:` to `## Current Position`, falling back to the complete body only when that section is absent.

### Canonical phase identity and safe path construction

**Source:** `src/phase-id.cts` lines 595-608  
**Apply to:** source-conflict comparison and phase-directory lookup

Compare `phaseKeyFromToken()` values, and derive directory identity with `phaseKeyFromDir()` from enumerated directory names. The normalizer is the negative control for raw formatting: `2` and `02` must resolve to the same phase.

### Disk scan ownership

**Source:** `src/plan-scan.cts` lines 106-170  
**Apply to:** resolved phase scanning in `cmdStateValidate`

Continue to delegate plan and summary counts to `scanPhasePlans()`. It handles both root and nested `plans/` files, outline exclusion, superseded plans, and matched summary counting; do not replace it with a local `readdirSync().filter()` count.

### CLI test and cleanup seam

**Source:** `tests/helpers.cjs` lines 39-123 and 130-155  
**Apply to:** all added tests

Use the existing `runGsdTools()` and suite cleanup. These tests must execute the emitted CLI and parse its JSON, not invoke a private parser/helper; command success alone does not establish the required drift semantics.

## No Analog Found

None. Both authored changes extend established state-validation and owning-test patterns.

## Metadata

**Analog search scope:** `src/state.cts`, `src/phase-id.cts`, `src/plan-scan.cts`, `tests/state.test.cjs`, `tests/helpers.cjs`, `tests/state-transition.test.cjs`, `gsd-core/templates/state.md`  
**Files scanned:** 7  
**Pattern extraction date:** 2026-08-04
