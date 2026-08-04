---
phase: 01-planned-phase-state-integrity
reviewed: 2026-08-04T14:51:58Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - src/state.cts
  - tests/state.test.cjs
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-08-04T14:51:58Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The working-tree change is relevant to STATE-01, and mutating `rmwOptions.authoritativeFm` inside the locked callback is effective: `readModifyWriteStateMd` invokes the callback before both `syncStateFrontmatter(..., options.authoritativeFm)` and the post-preservation authoritative reassertion. The implementation therefore preserves the ordinary same-date fixture's activity pair.

It is not shippable as submitted. The focused suite completed with 327/328 tests passing and failed only in the new conflict regression because that test asserts a status value outside the established contract. The implementation also trims the values it labels authoritative, and two test-oracle choices weaken the promised exact final-artifact contract. The competing `worktree-agent-p01-1785744886` implementation avoids these defects by retaining raw values, asserting `executing`, using `yaml.JSON_SCHEMA`, and checking the full transition description.

Test limitation: the passing activity assertions before the status failure establish preservation for one ordinary scalar fixture; they do not establish byte-exact preservation for all valid YAML scalars or make the new suite green. The initial sandboxed run failed with subprocess `EPERM`; the reported 327/328 result is from the required escalated rerun. `git diff --check` passed, which establishes whitespace cleanliness only.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: New regression fails the repository's established status contract

**Classification:** BLOCKER

**File:** `/var/home/denniyahh/Github/gsd-core/tests/state.test.cjs:2982`

**Issue:** The test expects `frontmatter.status === 'ready_to_execute'`, but `normalizeStateStatus('Ready to execute', ...)` intentionally returns `executing`, and existing state tests enforce that mapping. The focused suite fails at this assertion (`actual: 'executing'`, `expected: 'ready_to_execute'`), so the submitted change leaves the required test lane red. This is not evidence of a production regression; it is an incorrect new oracle.

**Fix:** Assert the established serialized contract:

```js
assert.equal(frontmatter.status, 'executing');
```

### CR-02: The preservation path rewrites the values it calls authoritative

**Classification:** BLOCKER

**File:** `/var/home/denniyahh/Github/gsd-core/src/state.cts:2685-2703`

**Issue:** Both frontmatter values are assigned through `.trim()` and those trimmed copies are later reasserted. A valid quoted YAML scalar such as `last_activity_desc: "  authoritative description  "` is parsed with its intentional inner whitespace intact, but this path silently serializes it back without that whitespace. Worse, trimming before the conflict comparison can turn a genuinely different body description into an apparent equality, skip `authoritativeFm`, and allow body-derived data to win. STATE-01 promises retention of the authoritative values, not normalized substitutes.

**Fix:** Keep raw values for equality and reassertion; use trimming only to validate non-emptiness, as the competing implementation does:

```ts
const frontmatterDate = preFm['last_activity'];
const frontmatterDescription = preFm['last_activity_desc'];

if (
  typeof frontmatterDate === 'string' && frontmatterDate.trim().length > 0 &&
  typeof frontmatterDescription === 'string' && frontmatterDescription.trim().length > 0 &&
  bodyActivity.date === frontmatterDate &&
  typeof bodyActivity.description === 'string' && bodyActivity.description.trim().length > 0 &&
  bodyActivity.description !== frontmatterDescription
) {
  rmwOptions.authoritativeFm = {
    last_activity: frontmatterDate,
    last_activity_desc: frontmatterDescription,
  };
}
```

## Warnings

### WR-01: Date coercion makes the raw-frontmatter oracle accept non-equivalent output

**Classification:** WARNING

**File:** `/var/home/denniyahh/Github/gsd-core/tests/state.test.cjs:18-25`

**Issue:** `yaml.load` uses the default schema, so YAML timestamps become `Date` objects, and `yamlDate()` then truncates them to ten characters. An accidental value such as `2020-09-10T23:59:59Z` would satisfy the assertion for `2020-09-10`. That is a proxy for the required exact serialized frontmatter value, not proof of it.

**Fix:** Parse with `yaml.JSON_SCHEMA`, assert the result is a mapping, remove `yamlDate`, and compare the scalar directly:

```js
const parsed = yaml.load(match[1], { schema: yaml.JSON_SCHEMA });
assert.ok(parsed && typeof parsed === 'object' && !Array.isArray(parsed));
return parsed;
// ...
assert.equal(frontmatter.last_activity, '2020-09-10');
```

### WR-02: The negative control accepts a truncated transition description

**Classification:** WARNING

**File:** `/var/home/denniyahh/Github/gsd-core/tests/state.test.cjs:2989-3002`

**Issue:** The non-conflict fixture omits `Last Activity Description`, then expects only `Phase 1 planning complete`, which is incidentally parsed from the Current Position prose. The planned-phase intent writes the fuller description `Phase 1 planning complete — 3 plans ready` when the canonical field exists, and the phase plan explicitly requires that value in this boundary case. The current test therefore proves merely that some new-looking description appeared; it does not prove that the transition's intended metadata won when authority should be absent.

**Fix:** Give the boundary fixture a canonical `Last Activity Description` field, then assert the full intended value:

```js
assert.equal(
  frontmatter.last_activity_desc,
  'Phase 1 planning complete — 3 plans ready',
);
```

---

_Reviewed: 2026-08-04T14:51:58Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
