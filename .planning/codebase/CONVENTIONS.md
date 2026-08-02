# Coding Conventions

**Analysis Date:** 2026-08-02

## Naming Patterns

**Files:**
- Use lowercase kebab-case for production modules: `src/phase-id.cts`, `src/review-lane-invocation.cts`, and `src/observability/logger.cts` are representative. TypeScript runtime sources use `.cts` so `tsc` emits CommonJS `.cjs` artifacts under `gsd-core/bin/lib/`; edit `src/**/*.cts`, not the generated artifact, when both exist (`tsconfig.build.json`, `eslint.config.mjs`).
- Name tests after the owned module or behavior and end them in `.test.cjs`, such as `tests/phase-id.test.cjs` and `tests/markdown-sectionizer.test.cjs`. Insert a suite marker before `.test.cjs` only for a non-unit lane, for example `tests/prompt-injection-scan.security.test.cjs`, `tests/installer-migration-install.integration.test.cjs`, or `tests/loop-walk.qa.test.cjs` (`docs/TESTING-SUITES.md`).
- Name property-based files `*.property.test.cjs`, such as `tests/workflow-fragments.property.test.cjs`; load the deterministic shared configuration from `tests/helpers/fast-check-setup.cjs` (`TESTING-STANDARDS.md`).
- Add regression coverage to the owning module's existing test file. Do not add new top-level `tests/bug-NNNN-*.test.cjs` files; the identity ratchet is enforced by `scripts/lint-regression-test-names.cjs` and documented in `docs/TESTING-SUITES.md`.
- Use lowercase kebab-case for scripts and custom ESLint rules, for example `scripts/run-affected-tests.cjs` and `eslint-rules/no-source-grep.cjs`. Shared test support belongs in `tests/helpers/*.cjs`; reusable data belongs in an appropriately named subtree of `tests/fixtures/` (`CONTRIBUTING.md`).

**Functions:**
- Use camelCase for functions and methods: `normalizeHost`, `writeSetComplete`, and `warnUnusableInput` in `src/review-lane-invocation.cts`, `src/write-set.cts`, and `src/unusable-input.cts` are representative.
- Prefix module-private test seams or internal state with `_` when the name is intentionally exposed or retained for testing, for example `_resetUnusableInputWarningsForTests` and `_warnedUnusableInputs` in `src/unusable-input.cts`. ESLint permits unused arguments and variables beginning with `_` (`eslint.config.mjs`).
- Use verb-led names that state the operation and result: `parseWorkflowSections`, `composeWorkflow`, `resolveLanePlan`, `createTempProject`, and `runGsdTools` in `src/workflow-fragments.cts`, `src/review-lane-invocation.cts`, and `tests/helpers.cjs`.

**Variables:**
- Use camelCase for local variables and parameters (`resolvedParentTraceId`, `includeArgs`, `promptPath`) as shown in `src/observability/event.cts` and `src/review-lane-invocation.cts`.
- Use SCREAMING_SNAKE_CASE for module constants, frozen vocabularies, regex sources, thresholds, and reason enums, such as `UNUSABLE_REASON` in `src/unusable-input.cts`, `LANE_UNAVAILABLE` in `src/review-lane-invocation.cts`, and `OVERALL_LINES` in `scripts/check-coverage-gate.cjs`.
- Use snake_case strings for serialized reason codes and wire values, while keeping the JavaScript identifier uppercase/camelCase: `FRONTMATTER_UNTERMINATED: 'frontmatter_unterminated'` in `src/unusable-input.cts` is the canonical shape.
- Prefer `const`; use `let` only for reassignment. `no-var` is an error and `prefer-const` is a warning for CommonJS production and script files (`eslint.config.mjs`).

**Types:**
- Use PascalCase for interfaces, type aliases, classes, and discriminated-union members, for example `ResolveResult`, `SpawnPlan`, `DispatchEvent`, and `ExitError` in `src/review-lane-invocation.cts`, `src/observability/event.cts`, and `src/cli-exit.cts`.
- Define serialized outcomes as discriminated unions with literal `ok`, `kind`, or `transport` fields; `Result<T>` in `src/write-set.cts` and `ResolveResult` in `src/review-lane-invocation.cts` are the patterns to copy.
- Derive string-union types from frozen value objects when the runtime vocabulary must also be exported, for example `UnusableReason` from `UNUSABLE_REASON` in `src/unusable-input.cts`.

## Code Style

**Formatting:**
- No Prettier or Biome configuration is present. Match the hand-formatted style in `src/**/*.cts` and `tests/**/*.test.cjs`: two-space indentation, single-quoted strings, semicolons, trailing commas in multiline arrays/objects/parameter lists, and braces on the same line.
- Use LF, UTF-8, a final newline, and no trailing whitespace. Markdown alone preserves intentional trailing whitespace (`.editorconfig`).
- Break complex expressions and argument lists across lines with trailing commas rather than compressing them; `src/review-lane-invocation.cts` and `tests/workflow-fragments.property.test.cjs` show the prevailing layout.
- Build multiline fixture content as an array of lines followed by `.join('\n')` to prevent indentation bleed; this is prescribed in `CONTRIBUTING.md` and used in `tests/loop-walk.qa.test.cjs`.
- Use `node:` prefixes for Node built-ins (`node:fs`, `node:path`, `node:test`, `node:assert/strict`) in new code and tests, following `src/io.cts` and `tests/installer-migration-install.integration.test.cjs`.

**Linting:**
- Run `npm run lint` for ESLint and `npm run lint:ci` for the full repository lint/generator/contract gate (`package.json`, `.github/workflows/test.yml`). TypeScript source is checked with `typescript-eslint` recommended type-aware rules using `tsconfig.build.json` (`eslint.config.mjs`).
- Treat `no-var`, `n/no-process-exit`, and `n/no-path-concat` as hard production constraints. Translate CLI exits through `ExitError`/`runMain` instead of calling `process.exit()` (`src/cli-exit.cts`, `eslint.config.mjs`).
- Use the shared markdown sectionizer instead of ad hoc Markdown parsing, normalize filesystem paths before embedding them in content, and provide retry/platform handling around atomic rename operations. These are errors under `local/no-adhoc-markdown-parsing`, `local/normalize-path-in-content`, and `local/require-fs-op-fallback` (`eslint.config.mjs`, `src/markdown-sectionizer.cts`, `src/shell-command-projection.cts`).
- In tests, do not commit `.only`, raw sleeps, raw `fs.rmSync`, tautological assertions, source-grep assertions, hardcoded `/tmp` paths, POSIX-only path/mode assertions, CRLF-fragile splits, or unguarded nonportable process execution. The enforceable forms are errors in the `tests/**/*.test.cjs` block of `eslint.config.mjs` and implemented under `eslint-rules/*.cjs`.
- Unused variables, some legacy generic-quality rules, and elapsed-time assertions remain warnings in selected scopes, but new code should not introduce them (`eslint.config.mjs`, `TESTING-STANDARDS.md`).

## Import Organization

**Order:**
1. Place a file-level documentation block and, for hand-written CommonJS, `'use strict';` before imports when the module uses that marker; see `tests/workflow-fragments.property.test.cjs` and `scripts/run-tests.cjs`.
2. Import Node built-ins first, using `node:` specifiers where the source already follows the modern form; see `src/io.cts` and `tests/loop-walk.qa.test.cjs`.
3. Import third-party dependencies next, such as `fast-check` through `tests/helpers/fast-check-setup.cjs` or ESLint packages in `eslint.config.mjs`.
4. Import local production modules, then shared test helpers and fixtures. Use destructuring for named CommonJS exports in tests (`tests/phase-id.test.cjs`, `tests/helpers.cjs`).
5. Keep TypeScript `import type` declarations separate when practical, and always include the emitted `.cjs` suffix in relative TypeScript import specifiers (`src/review-lane-runner.cts`, `src/roadmap-parser.cts`). Use `import x = require('./x.cjs')` only for CommonJS-style `export =` modules (`src/config-loader.cts`).

**Path Aliases:**
- No TypeScript path aliases are configured. Use explicit relative paths (`./foo.cjs`, `../gsd-core/bin/lib/foo.cjs`) as shown in `tsconfig.build.json`, `src/workflow-fragments.cts`, and `tests/workflow-fragments.property.test.cjs`.
- Resolve filesystem locations with `node:path` and `__dirname`; do not assemble paths with string concatenation. `n/no-path-concat` enforces this for production CommonJS (`eslint.config.mjs`), while `tests/helpers.cjs` centralizes common test paths.

## Error Handling

**Patterns:**
- At parse and validation boundaries, return explicit discriminated results rather than ambiguous `null` when absence and failure must be distinguished. Copy `{ ok: true; value } | { ok: false; reason }` from `src/write-set.cts` or the richer `ResolveResult` from `src/review-lane-invocation.cts`.
- Use frozen reason vocabularies and stable snake_case codes; callers and tests assert on the typed code rather than rendered prose (`src/unusable-input.cts`, `src/io.cts`, `TESTING-STANDARDS.md`).
- For CLI entry points, throw `ExitError` or return an exit code and let `runMain()` set `process.exitCode`; do not call `process.exit()` because it can truncate output and violates `n/no-process-exit` (`src/cli-exit.cts`, `scripts/run-affected-tests.cjs`).
- Catch only where a fallback is part of the contract. Preserve the cause where useful, return a documented conservative fallback, and keep best-effort diagnostics from throwing; `warnUnusableInput()` in `src/unusable-input.cts` and `createDefaultLogger()` in `src/observability/logger.cts` demonstrate never-throw diagnostic seams.
- When handling filesystem portability, use the shared projection/retry functions rather than raw unguarded operations (`src/shell-command-projection.cts`, `eslint-rules/require-fs-op-fallback.cjs`).

## Logging

**Framework:** Structured in-house observability; direct `process.stderr.write` only at CLI/diagnostic boundaries (`src/observability/event.cts`, `src/observability/logger.cts`, `src/unusable-input.cts`).

**Patterns:**
- Create immutable structured dispatch events through `makeDispatchEvent()` and pass them to the logger rather than scattering console output (`src/observability/event.cts`, `src/command-routing-hub.cts`).
- Emit newline-delimited JSON for structured audit/error logging, redact sensitive fields through the observability layer, and keep success paths silent (`src/observability/logger.cts`, `src/observability/redaction.cts`).
- Reserve human-readable stderr diagnostics for actionable degraded-input and top-level CLI failures. Make them bounded, sanitized, deduplicated where repeated, and non-throwing (`src/unusable-input.cts`, `src/cli-exit.cts`).
- Avoid `console.log` in library code. When tests must capture legacy console behavior, restore the original method in a cleanup seam (`tests/helpers.cjs`, `tests/installer-migration-install.integration.test.cjs`).

## Comments

**When to Comment:**
- Document contracts, invariants, security/portability rationale, and non-obvious tradeoffs. `src/unusable-input.cts`, `src/review-lane-invocation.cts`, and `scripts/run-tests.cjs` model the expected "why"-focused commentary.
- Reference the owning ADR/issue when a constraint exists to prevent a known regression, but do not use comments as a substitute for a behavioral test (`TESTING-STANDARDS.md`, `CONTRIBUTING.md`).
- Preserve local rule exemptions only when they carry the required explicit rationale, such as `// eslint-disable-next-line ... -- reason` or an owner comment recognized by the matching lint script (`eslint.config.mjs`, `scripts/lint-phase-id-drift.cjs`).
- Use section-divider comments in long modules to make conceptual boundaries visible, as in `src/review-lane-invocation.cts` and `src/phase-id.cts`.

**JSDoc/TSDoc:**
- Add JSDoc/TSDoc to exported behavior and non-obvious internal seams. State parameters, return semantics, side effects, failure behavior, and invariants where types alone are insufficient (`src/io.cts`, `src/observability/event.cts`).
- Use TypeScript types as the primary shape documentation in `src/**/*.cts`; avoid duplicating obvious type information in prose. CommonJS helpers may use `@param`, `@returns`, and `@type` annotations (`tests/helpers.cjs`, `stryker.config.mjs`).

## Function Design

**Size:** Keep pure transforms and policy predicates small and separately testable (`src/write-set.cts`, `src/observability/event.cts`). Large orchestration modules exist, but new logic should be extracted at a real reusable seam rather than added as another copied parser, filesystem primitive, or command projection (`src/markdown-sectionizer.cts`, `src/shell-command-projection.cts`, `CONTRIBUTING.md`).

**Parameters:**
- Prefer a typed options object for functions with multiple inputs or optional seams, such as `ResolveInput` in `src/review-lane-invocation.cts` and `WarnUnusableInputArgs` in `src/unusable-input.cts`.
- Use dependency injection for clocks, process execution, filesystem behavior, and configuration when deterministic testing requires it; production defaults may be supplied in the options object (`TESTING-STANDARDS.md`, `src/review-lane-runner.cts`).
- Do not coerce malformed external values into plausible configuration silently. Validate shape at the boundary and return a typed failure or conservative fallback (`src/review-lane-invocation.cts`, `CONTRIBUTING.md`).

**Return Values:**
- Prefer total functions and explicit result objects for boundary/policy decisions (`src/review-lane-invocation.cts`, `src/write-set.cts`).
- Use `null` only when it unambiguously means absence and is part of the established API, such as `isEmptyReview()`'s surrounding resolver helpers in `src/review-lane-invocation.cts`; do not let parse corruption collapse into the same sentinel (`src/unusable-input.cts`).
- Freeze shared event/vocabulary objects when consumers depend on immutability or exhaustive keys (`src/observability/event.cts`, `src/unusable-input.cts`).

## Module Design

**Exports:**
- Newer TypeScript modules may use named `export` declarations for typed APIs (`src/workflow-fragments.cts`, `src/write-set.cts`). Migrated legacy modules commonly end with one `export = { ... }` object so emitted CommonJS remains compatible (`src/io.cts`, `src/phase-id.cts`). Match the module being edited; do not mix export strategies casually.
- CommonJS tests, helpers, scripts, and ESLint rules use `require()` plus `module.exports` (`tests/helpers.cjs`, `tests/qa/result.cjs`, `eslint-rules/no-source-grep.cjs`).
- Export the smallest stable behavioral surface. Test-only seams are explicitly named as such; avoid exposing internals solely to permit source-text assertions (`src/unusable-input.cts`, `TESTING-STANDARDS.md`).

**Barrel Files:**
- General-purpose barrel files are not the dominant pattern. Import the owning module directly, such as `./phase-id.cjs` or `./markdown-sectionizer.cjs` (`src/commands.cts`, `src/roadmap-parser.cts`).
- Small intentional aggregators exist for test fixtures and module compatibility, such as `tests/qa/fixtures/index.cjs`; keep these explicit and domain-scoped rather than creating a repository-wide barrel.

---

*Convention analysis: 2026-08-02*
