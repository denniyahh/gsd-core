<!-- GSD:project-start source:PROJECT.md -->

## Project

**GSD Core Contributions**

This is a contributor planning workspace for `@opengsd/gsd-core`, the workflow and runtime system used by AI coding agents. It organizes evidence-backed upstream bug fixes and useful features into focused, reviewable pull requests for maintainers and the people who rely on GSD across supported runtimes.

**Core Value:** Every contribution must make GSD more reliable without regressing its supported runtime and generated-artifact contracts.

### Constraints

- **Runtime support**: Preserve behavior across supported host runtimes and capability contracts — GSD is distributed beyond the current Codex session.
- **Generated artifacts**: Regenerate and verify derived registries, skills, and runtime artifacts when their canonical inputs change — stale generated output is a release risk.
- **Verification**: Add a reproducing regression test for each confirmed defect and run focused checks before broader suites — the project has extensive specialized test coverage.
- **Tooling**: Use Node.js 22+ and npm 10+ — enforced by `package.json`.
- **Planning storage**: Track `.planning/` in this fork — project context, requirements, roadmap, and verification history must travel with contribution work.
- **DevFlow**: Do not invoke DevFlow — the project owner has deferred its use.

<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->

## Technology Stack

## Languages

- TypeScript 6.0.3 - Strict CommonJS-oriented runtime modules use the `.cts` extension under `src/`; `tsconfig.build.json` compiles them into `.cjs` files under `gsd-core/bin/lib/`.
- JavaScript (ES2022/CommonJS) - Package entry points, the installer, generated runtime modules, host plugins, hooks, build scripts, and tests live in `bin/`, `gsd-core/bin/`, `hooks/`, `pi/`, `.opencode/`, `scripts/`, and `tests/`.
- ECMAScript modules - Tooling configuration uses `.mjs`, notably `eslint.config.mjs` and `stryker.config.mjs`.
- POSIX shell - Portable launchers and security/build helpers use `.sh`, including `gsd-core/bin/gsd_run`, `gsd-core/workflows/_runtime-launcher.snippet.sh`, and scripts under `scripts/`.
- Markdown, JSON, YAML, and TOML-shaped artifacts - Commands, skills, agents, workflows, capabilities, templates, and host configuration projections are data-driven from `commands/`, `skills/`, `agents/`, `gsd-core/workflows/`, `gsd-core/templates/`, and `capabilities/`.

## Runtime

- Node.js 22 or newer - Enforced by `package.json`; `.nvmrc` pins major version 22 for local development, while `.github/workflows/test.yml` exercises Node 22 and 24.
- ES2022 target - Runtime TypeScript is compiled with `target: "ES2022"` and NodeNext resolution in `tsconfig.build.json`.
- Host runtimes execute emitted artifacts in their native environments - Node, Bun, Python, Go, Electron, and sandboxed-web host characteristics are declared in `capabilities/*/capability.json`; GSD itself remains a Node-distributed package.
- npm 10 or newer - Enforced by `package.json`; installation, builds, tests, packing, publishing, and update checks are npm-driven.
- Lockfile: present - `package-lock.json` uses lockfile version 3 and pins the resolved dependency graph.
- Published package: `@opengsd/gsd-core` 1.9.1 - Identity, binaries, package contents, and npm scripts are declared in `package.json` and generated into `gsd-core/bin/lib/package-identity.cjs`.

## Frameworks

- Node.js CLI/library architecture - There is no web application framework; `bin/install.js`, `gsd-core/bin/gsd-tools.cjs`, `gsd-core/bin/gsd_run`, and `bin/gsd-mcp-server.js` are the executable surfaces.
- Capability and descriptor system - Feature manifests in `capabilities/*/capability.json`, generated registry data in `gsd-core/bin/lib/capability-registry.cjs`, and host integration contracts in `src/host-integration.cts` drive runtime-specific behavior.
- Prompt/workflow distribution - Markdown command, skill, agent, workflow, and template assets in `commands/`, `skills/`, `agents/`, and `gsd-core/` are packaged and transformed for supported AI coding hosts by `bin/install.js` and `src/runtime-artifact-conversion.cts`.
- Model Context Protocol companion server - A hand-rolled stdio JSON-RPC 2.0 server in `src/mcp-server.cts` and `bin/gsd-mcp-server.js` avoids adding an MCP SDK dependency.
- Node built-in test runner - Tests use `node:test` through the suite orchestrator in `scripts/run-tests.cjs`; commands are exposed by `package.json` as `test`, `test:unit`, `test:integration`, `test:install`, `test:security`, `test:slow`, and `test:qa`.
- fast-check 4.8.0 - Property-based tests use the development dependency declared in `package.json` and pinned in `package-lock.json`.
- c8 11.0.0 - V8 coverage collection and threshold enforcement are configured through `package.json` and merged across CI shards in `.github/workflows/test.yml`.
- Stryker 9.6.1 - Mutation testing is configured in `stryker.config.mjs`, invoked by `package.json`, and automated by `.github/workflows/mutation.yml`.
- TypeScript 6.0.3 - `tsconfig.build.json` compiles `src/**/*.cts` into CommonJS runtime artifacts; `tsconfig.json` provides the no-emit editor/CI typecheck profile.
- ESLint 9.39.4 with typescript-eslint 8.60.0 - Flat configuration and repository-specific AST rules live in `eslint.config.mjs` and `eslint-rules/`.
- Repository generators - `scripts/gen-capability-registry.cjs`, `scripts/gen-plugin-skills.cjs`, `scripts/gen-context-index.cjs`, `scripts/gen-loop-host-contract.cjs`, and related scripts materialize derived artifacts through the `build` and `regen:derived` commands in `package.json`.
- No bundler - Runtime output is direct TypeScript-to-CommonJS compilation plus copied/generated package assets, as defined by `tsconfig.build.json`, `scripts/build-hooks.js`, and `package.json`.

## Key Dependencies

- `@anthropic-ai/claude-agent-sdk` ^0.2.84 (resolved 0.2.141) - The optional Claude Workflow backend gates on the installed SDK version in `src/claude-orchestration-command-router.cts`; workflow generation itself is implemented in `src/claude-orchestration.cts` and does not directly import SDK APIs.
- `ws` ^8.21.0 (resolved 8.21.0) - Declared as a production dependency in `package.json`; no first-party import is present in `src/`, `bin/`, `hooks/`, `scripts/`, `pi/`, or `.opencode/`, so do not assume it provides an active server surface without adding an explicit call site.
- Node standard library - Filesystem, path, process, child-process, crypto, HTTP(S), streams, and built-in `fetch` APIs are the main runtime substrate throughout `src/`, `bin/`, `hooks/`, and `scripts/`.
- `fallow` ^2.70.0 (resolved 2.70.0, optional) - Dead-code and duplication auditing is invoked as an external binary by `src/fallow-runner.cts`; the feature degrades with an actionable message when the binary is absent.
- `js-yaml` 4.2.1 - Development-time YAML parsing supports scripts and tests as declared in `package.json` and pinned in `package-lock.json`.
- Git, npm, and system `tar` - Capability sources can be cloned, packed, version-checked, and extracted through bounded subprocess seams in `src/capability-source.cts`; Git also underpins worktree and repository lifecycle operations across `src/`.
- No database client, ORM, cache client, or server framework - Persistent state and caches use JSON/Markdown files through modules such as `src/state-io.cts`, `src/state.cts`, and `src/research-store.cts`.

## Configuration

- Project configuration resolves from `.planning/config.json`, workstream-specific `.planning/workstreams/<name>/config.json`, and user defaults in `~/.gsd/defaults.json` through `src/config-loader.cts`, `src/config.cts`, and `src/planning-workspace.cts`.
- Runtime installation homes and overrides are descriptor-driven in `capabilities/*/capability.json`; examples include `CLAUDE_CONFIG_DIR`, `CODEX_HOME`, `OPENCODE_CONFIG_DIR`, and corresponding host-specific variables consumed by `bin/install.js`.
- Optional research integrations are detected through `BRAVE_API_KEY`, `EXA_API_KEY`, `TAVILY_API_KEY`, `PERPLEXITY_API_KEY`, `FIRECRAWL_API_KEY`, `REF_API_KEY`, and `JINA_API_KEY` in `src/config.cts`; no `.env` files are present in the repository.
- Optional operational controls include `GSD_WORKSTREAM` in `src/active-workstream-store.cts`, `GSD_AUDIT`/`GSD_AUDIT_ARGS` in `src/observability/logger.cts`, `GSD_AGENT_SDK_VERSION` in `src/claude-orchestration-command-router.cts`, and `GSD_WEBSEARCH_TIMEOUT_MS` in `src/commands.cts`.
- `package.json` - Engine constraints, dependency graph, bin entries, package file allowlist, build scripts, test suites, coverage gates, and publish lifecycle.
- `tsconfig.build.json` - Emitting strict TypeScript build; `tsconfig.json` - no-emit typecheck profile.
- `eslint.config.mjs` and `eslint-rules/` - Flat lint configuration and local reliability/portability rules.
- `stryker.config.mjs` - Mutation-test configuration.
- `.nvmrc` and `package-lock.json` - Node major and reproducible npm dependency graph.

## Platform Requirements

- Use Node.js >=22 and npm >=10, then install the lockfile graph with `npm ci`; the environment gate in `scripts/check-env.cjs` validates engines, lockfile presence, and lockfile synchronization.
- Keep Git available for tests and repository/worktree behavior, and keep system `tar` available when exercising capability package installation paths in `src/capability-source.cts`.
- Linux, macOS, and Windows are supported and tested; the CI matrices in `.github/workflows/test.yml` and `.github/workflows/install-smoke.yml` cover Ubuntu, macOS, and Windows with Node 22/24.
- Run `npm run build:lib` before directly invoking generated `gsd-core/bin/lib/*.cjs` modules; normal `prepare`, `pretest`, `prepack`, and first-run recovery paths are defined in `package.json` and `gsd-core/bin/ensure-runtime-build.cjs`.
- Primary deployment is a public npm package installed globally or into a project/runtime configuration directory by `bin/install.js`; there is no separately hosted application process.
- Packaged binaries are `gsd-core`, `gsd-tools`, `gsd_run`, and `gsd-mcp-server` as defined in `package.json`; the MCP server is a local stdio child process, not a network listener, per `bin/gsd-mcp-server.js`.
- Release publication targets npm with provenance and GitHub Releases through `.github/workflows/release.yml`; emitted commands, skills, agents, hooks, and engine files are the production artifacts listed in `package.json`.

<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

## Naming Patterns

- Use lowercase kebab-case for production modules: `src/phase-id.cts`, `src/review-lane-invocation.cts`, and `src/observability/logger.cts` are representative. TypeScript runtime sources use `.cts` so `tsc` emits CommonJS `.cjs` artifacts under `gsd-core/bin/lib/`; edit `src/**/*.cts`, not the generated artifact, when both exist (`tsconfig.build.json`, `eslint.config.mjs`).
- Name tests after the owned module or behavior and end them in `.test.cjs`, such as `tests/phase-id.test.cjs` and `tests/markdown-sectionizer.test.cjs`. Insert a suite marker before `.test.cjs` only for a non-unit lane, for example `tests/prompt-injection-scan.security.test.cjs`, `tests/installer-migration-install.integration.test.cjs`, or `tests/loop-walk.qa.test.cjs` (`docs/TESTING-SUITES.md`).
- Name property-based files `*.property.test.cjs`, such as `tests/workflow-fragments.property.test.cjs`; load the deterministic shared configuration from `tests/helpers/fast-check-setup.cjs` (`TESTING-STANDARDS.md`).
- Add regression coverage to the owning module's existing test file. Do not add new top-level `tests/bug-NNNN-*.test.cjs` files; the identity ratchet is enforced by `scripts/lint-regression-test-names.cjs` and documented in `docs/TESTING-SUITES.md`.
- Use lowercase kebab-case for scripts and custom ESLint rules, for example `scripts/run-affected-tests.cjs` and `eslint-rules/no-source-grep.cjs`. Shared test support belongs in `tests/helpers/*.cjs`; reusable data belongs in an appropriately named subtree of `tests/fixtures/` (`CONTRIBUTING.md`).
- Use camelCase for functions and methods: `normalizeHost`, `writeSetComplete`, and `warnUnusableInput` in `src/review-lane-invocation.cts`, `src/write-set.cts`, and `src/unusable-input.cts` are representative.
- Prefix module-private test seams or internal state with `_` when the name is intentionally exposed or retained for testing, for example `_resetUnusableInputWarningsForTests` and `_warnedUnusableInputs` in `src/unusable-input.cts`. ESLint permits unused arguments and variables beginning with `_` (`eslint.config.mjs`).
- Use verb-led names that state the operation and result: `parseWorkflowSections`, `composeWorkflow`, `resolveLanePlan`, `createTempProject`, and `runGsdTools` in `src/workflow-fragments.cts`, `src/review-lane-invocation.cts`, and `tests/helpers.cjs`.
- Use camelCase for local variables and parameters (`resolvedParentTraceId`, `includeArgs`, `promptPath`) as shown in `src/observability/event.cts` and `src/review-lane-invocation.cts`.
- Use SCREAMING_SNAKE_CASE for module constants, frozen vocabularies, regex sources, thresholds, and reason enums, such as `UNUSABLE_REASON` in `src/unusable-input.cts`, `LANE_UNAVAILABLE` in `src/review-lane-invocation.cts`, and `OVERALL_LINES` in `scripts/check-coverage-gate.cjs`.
- Use snake_case strings for serialized reason codes and wire values, while keeping the JavaScript identifier uppercase/camelCase: `FRONTMATTER_UNTERMINATED: 'frontmatter_unterminated'` in `src/unusable-input.cts` is the canonical shape.
- Prefer `const`; use `let` only for reassignment. `no-var` is an error and `prefer-const` is a warning for CommonJS production and script files (`eslint.config.mjs`).
- Use PascalCase for interfaces, type aliases, classes, and discriminated-union members, for example `ResolveResult`, `SpawnPlan`, `DispatchEvent`, and `ExitError` in `src/review-lane-invocation.cts`, `src/observability/event.cts`, and `src/cli-exit.cts`.
- Define serialized outcomes as discriminated unions with literal `ok`, `kind`, or `transport` fields; `Result<T>` in `src/write-set.cts` and `ResolveResult` in `src/review-lane-invocation.cts` are the patterns to copy.
- Derive string-union types from frozen value objects when the runtime vocabulary must also be exported, for example `UnusableReason` from `UNUSABLE_REASON` in `src/unusable-input.cts`.

## Code Style

- No Prettier or Biome configuration is present. Match the hand-formatted style in `src/**/*.cts` and `tests/**/*.test.cjs`: two-space indentation, single-quoted strings, semicolons, trailing commas in multiline arrays/objects/parameter lists, and braces on the same line.
- Use LF, UTF-8, a final newline, and no trailing whitespace. Markdown alone preserves intentional trailing whitespace (`.editorconfig`).
- Break complex expressions and argument lists across lines with trailing commas rather than compressing them; `src/review-lane-invocation.cts` and `tests/workflow-fragments.property.test.cjs` show the prevailing layout.
- Build multiline fixture content as an array of lines followed by `.join('\n')` to prevent indentation bleed; this is prescribed in `CONTRIBUTING.md` and used in `tests/loop-walk.qa.test.cjs`.
- Use `node:` prefixes for Node built-ins (`node:fs`, `node:path`, `node:test`, `node:assert/strict`) in new code and tests, following `src/io.cts` and `tests/installer-migration-install.integration.test.cjs`.
- Run `npm run lint` for ESLint and `npm run lint:ci` for the full repository lint/generator/contract gate (`package.json`, `.github/workflows/test.yml`). TypeScript source is checked with `typescript-eslint` recommended type-aware rules using `tsconfig.build.json` (`eslint.config.mjs`).
- Treat `no-var`, `n/no-process-exit`, and `n/no-path-concat` as hard production constraints. Translate CLI exits through `ExitError`/`runMain` instead of calling `process.exit()` (`src/cli-exit.cts`, `eslint.config.mjs`).
- Use the shared markdown sectionizer instead of ad hoc Markdown parsing, normalize filesystem paths before embedding them in content, and provide retry/platform handling around atomic rename operations. These are errors under `local/no-adhoc-markdown-parsing`, `local/normalize-path-in-content`, and `local/require-fs-op-fallback` (`eslint.config.mjs`, `src/markdown-sectionizer.cts`, `src/shell-command-projection.cts`).
- In tests, do not commit `.only`, raw sleeps, raw `fs.rmSync`, tautological assertions, source-grep assertions, hardcoded `/tmp` paths, POSIX-only path/mode assertions, CRLF-fragile splits, or unguarded nonportable process execution. The enforceable forms are errors in the `tests/**/*.test.cjs` block of `eslint.config.mjs` and implemented under `eslint-rules/*.cjs`.
- Unused variables, some legacy generic-quality rules, and elapsed-time assertions remain warnings in selected scopes, but new code should not introduce them (`eslint.config.mjs`, `TESTING-STANDARDS.md`).

## Import Organization

- No TypeScript path aliases are configured. Use explicit relative paths (`./foo.cjs`, `../gsd-core/bin/lib/foo.cjs`) as shown in `tsconfig.build.json`, `src/workflow-fragments.cts`, and `tests/workflow-fragments.property.test.cjs`.
- Resolve filesystem locations with `node:path` and `__dirname`; do not assemble paths with string concatenation. `n/no-path-concat` enforces this for production CommonJS (`eslint.config.mjs`), while `tests/helpers.cjs` centralizes common test paths.

## Error Handling

- At parse and validation boundaries, return explicit discriminated results rather than ambiguous `null` when absence and failure must be distinguished. Copy `{ ok: true; value } | { ok: false; reason }` from `src/write-set.cts` or the richer `ResolveResult` from `src/review-lane-invocation.cts`.
- Use frozen reason vocabularies and stable snake_case codes; callers and tests assert on the typed code rather than rendered prose (`src/unusable-input.cts`, `src/io.cts`, `TESTING-STANDARDS.md`).
- For CLI entry points, throw `ExitError` or return an exit code and let `runMain()` set `process.exitCode`; do not call `process.exit()` because it can truncate output and violates `n/no-process-exit` (`src/cli-exit.cts`, `scripts/run-affected-tests.cjs`).
- Catch only where a fallback is part of the contract. Preserve the cause where useful, return a documented conservative fallback, and keep best-effort diagnostics from throwing; `warnUnusableInput()` in `src/unusable-input.cts` and `createDefaultLogger()` in `src/observability/logger.cts` demonstrate never-throw diagnostic seams.
- When handling filesystem portability, use the shared projection/retry functions rather than raw unguarded operations (`src/shell-command-projection.cts`, `eslint-rules/require-fs-op-fallback.cjs`).

## Logging

- Create immutable structured dispatch events through `makeDispatchEvent()` and pass them to the logger rather than scattering console output (`src/observability/event.cts`, `src/command-routing-hub.cts`).
- Emit newline-delimited JSON for structured audit/error logging, redact sensitive fields through the observability layer, and keep success paths silent (`src/observability/logger.cts`, `src/observability/redaction.cts`).
- Reserve human-readable stderr diagnostics for actionable degraded-input and top-level CLI failures. Make them bounded, sanitized, deduplicated where repeated, and non-throwing (`src/unusable-input.cts`, `src/cli-exit.cts`).
- Avoid `console.log` in library code. When tests must capture legacy console behavior, restore the original method in a cleanup seam (`tests/helpers.cjs`, `tests/installer-migration-install.integration.test.cjs`).

## Comments

- Document contracts, invariants, security/portability rationale, and non-obvious tradeoffs. `src/unusable-input.cts`, `src/review-lane-invocation.cts`, and `scripts/run-tests.cjs` model the expected "why"-focused commentary.
- Reference the owning ADR/issue when a constraint exists to prevent a known regression, but do not use comments as a substitute for a behavioral test (`TESTING-STANDARDS.md`, `CONTRIBUTING.md`).
- Preserve local rule exemptions only when they carry the required explicit rationale, such as `// eslint-disable-next-line ... -- reason` or an owner comment recognized by the matching lint script (`eslint.config.mjs`, `scripts/lint-phase-id-drift.cjs`).
- Use section-divider comments in long modules to make conceptual boundaries visible, as in `src/review-lane-invocation.cts` and `src/phase-id.cts`.
- Add JSDoc/TSDoc to exported behavior and non-obvious internal seams. State parameters, return semantics, side effects, failure behavior, and invariants where types alone are insufficient (`src/io.cts`, `src/observability/event.cts`).
- Use TypeScript types as the primary shape documentation in `src/**/*.cts`; avoid duplicating obvious type information in prose. CommonJS helpers may use `@param`, `@returns`, and `@type` annotations (`tests/helpers.cjs`, `stryker.config.mjs`).

## Function Design

- Prefer a typed options object for functions with multiple inputs or optional seams, such as `ResolveInput` in `src/review-lane-invocation.cts` and `WarnUnusableInputArgs` in `src/unusable-input.cts`.
- Use dependency injection for clocks, process execution, filesystem behavior, and configuration when deterministic testing requires it; production defaults may be supplied in the options object (`TESTING-STANDARDS.md`, `src/review-lane-runner.cts`).
- Do not coerce malformed external values into plausible configuration silently. Validate shape at the boundary and return a typed failure or conservative fallback (`src/review-lane-invocation.cts`, `CONTRIBUTING.md`).
- Prefer total functions and explicit result objects for boundary/policy decisions (`src/review-lane-invocation.cts`, `src/write-set.cts`).
- Use `null` only when it unambiguously means absence and is part of the established API, such as `isEmptyReview()`'s surrounding resolver helpers in `src/review-lane-invocation.cts`; do not let parse corruption collapse into the same sentinel (`src/unusable-input.cts`).
- Freeze shared event/vocabulary objects when consumers depend on immutability or exhaustive keys (`src/observability/event.cts`, `src/unusable-input.cts`).

## Module Design

- Newer TypeScript modules may use named `export` declarations for typed APIs (`src/workflow-fragments.cts`, `src/write-set.cts`). Migrated legacy modules commonly end with one `export = { ... }` object so emitted CommonJS remains compatible (`src/io.cts`, `src/phase-id.cts`). Match the module being edited; do not mix export strategies casually.
- CommonJS tests, helpers, scripts, and ESLint rules use `require()` plus `module.exports` (`tests/helpers.cjs`, `tests/qa/result.cjs`, `eslint-rules/no-source-grep.cjs`).
- Export the smallest stable behavioral surface. Test-only seams are explicitly named as such; avoid exposing internals solely to permit source-text assertions (`src/unusable-input.cts`, `TESTING-STANDARDS.md`).
- General-purpose barrel files are not the dominant pattern. Import the owning module directly, such as `./phase-id.cjs` or `./markdown-sectionizer.cjs` (`src/commands.cts`, `src/roadmap-parser.cts`).
- Small intentional aggregators exist for test fixtures and module compatibility, such as `tests/qa/fixtures/index.cjs`; keep these explicit and domain-scoped rather than creating a repository-wide barrel.

<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

## System Overview

```text

```

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Package installer | Select runtimes and profiles, transform artifacts, install hooks/agents/skills, run migrations, and write manifests/configuration | `bin/install.js` |
| Workflow launcher | Provide a portable executable that delegates workflow shell calls to the Node CLI | `gsd-core/bin/gsd_run` |
| Runtime CLI | Parse global flags, resolve project/workstream context, route commands, capture large output, and normalize errors | `gsd-core/bin/gsd-tools.cjs` |
| Host command table | Route non-toggleable core command families such as state, phase, roadmap, and verification | `gsd-core/bin/gsd-tools.cjs` |
| Capability registry | Index first-party feature/runtime manifests by command, skill, agent, config key, loop point, and profile | `gsd-core/bin/lib/capability-registry.cjs` |
| Capability overlay loader | Compose consented third-party capability declarations with the first-party registry without executing them during load | `src/capability-loader.cts` |
| Command routing hub | Invoke one command-family registry through a typed, no-throw `Result` contract and optional audit logger | `src/command-routing-hub.cts` |
| Family router adapter | Translate CLI family handlers into hub registries and translate typed hub failures back to CLI errors | `src/cjs-command-router-adapter.cts` |
| Planning workspace | Resolve flat/project/workstream `.planning` paths and serialize mutations with a liveness-aware lock | `src/planning-workspace.cts` |
| Configuration | Load root/workstream configuration, defaults, federated capability keys, schema validation, and compatibility normalization | `src/config-loader.cts` |
| Host integration contract | Define and negotiate host axes for command, dispatch, model, hooks, state, and artifact behavior | `src/host-integration.cts` |
| Public host SDK | Publish the frozen negotiation/adapters/handshake surface for external host bindings | `src/host-integration-sdk.cts` |
| Runtime artifact projection | Resolve descriptor-driven layouts and convert command/agent/skill content for each supported runtime | `src/runtime-artifact-layout.cts` |
| Workflow composition | Parse conditional workflow fragments and compose them within a budget before runtime-specific conversion | `src/workflow-fragments.cts` |
| MCP bridge | Expose command invocation and state I/O through line-delimited stdio JSON-RPC | `src/mcp-server.cts` |
| Hook bundle | Enforce/read/inject lifecycle safeguards and context signals in supported hosts | `hooks/` |

## Pattern Overview

- Treat `commands/gsd/*.md`, `gsd-core/workflows/*.md`, `agents/*.md`, and `capabilities/*/capability.json` as declarative inputs; use `scripts/gen-plugin-skills.cjs`, `scripts/gen-capability-registry.cjs`, and `bin/install.js` to project them to host-specific surfaces.
- Put deterministic runtime behavior in seam-oriented modules under `src/`; compile `.cts` to `.cjs` with `tsconfig.build.json` because the installed engine and host adapters consume CommonJS.
- Route toggleable feature families through the generated capability registry and core families through `HOST_COMMAND_ROUTERS` in `gsd-core/bin/gsd-tools.cjs`.
- Route subcommands through `routeHubCommandFamily` from `src/cjs-command-router-adapter.cts`; use `src/command-routing-hub.cts` for typed success/failure results and synchronous dispatch isolation.
- Resolve every project artifact path through `src/project-root.cts` and `src/planning-workspace.cts`; active workstreams change the effective `.planning` subtree through `GSD_WORKSTREAM`.
- Keep host variability in `capabilities/<runtime>/capability.json`, `src/host-integration.cts`, and runtime artifact adapters; do not scatter new runtime-name conditionals through domain modules.

## Layers

- Purpose: Present named GSD operations to host agents and declare arguments, tool permissions, dependencies, and execution context.
- Location: `commands/gsd/`, `skills/`
- Contains: Canonical command Markdown in `commands/gsd/*.md` and committed generated plugin skills in `skills/gsd-*/SKILL.md`.
- Depends on: Workflow and reference assets in `gsd-core/workflows/` and `gsd-core/references/`.
- Used by: Runtime command loaders and host-specific installation performed by `bin/install.js`.
- Purpose: Define multi-step agent procedures, required readings, subagent contracts, gates, and writes to planning artifacts.
- Location: `gsd-core/workflows/`
- Contains: Lifecycle workflows, scoped step fragments such as `gsd-core/workflows/plan-phase/steps/`, and loop-host markers consumed by capability composition.
- Depends on: Shared guidance in `gsd-core/references/`, output shapes in `gsd-core/templates/`, and deterministic queries exposed by `gsd-core/bin/gsd-tools.cjs`.
- Used by: Command files in `commands/gsd/`, generated skills in `skills/`, and installed host artifacts.
- Purpose: Isolate planner, executor, reviewer, mapper, and specialist responsibilities in independently dispatched agent prompts.
- Location: `agents/`
- Contains: Frontmatter plus role/process contracts such as `agents/gsd-planner.md`, `agents/gsd-executor.md`, and `agents/gsd-codebase-mapper.md`.
- Depends on: Workflows and references under `gsd-core/` and runtime conversion performed by `bin/install.js` / `src/runtime-artifact-conversion.cts`.
- Used by: Orchestrating workflows such as `gsd-core/workflows/plan-phase.md` and `gsd-core/workflows/execute-phase.md`.
- Purpose: Install one canonical asset corpus into the configuration layout and syntax expected by each host.
- Location: `bin/install.js`, `src/runtime-artifact-layout.cts`, `src/runtime-artifact-conversion.cts`, `src/install-engine.cts`, `src/runtime-hooks-surface.cts`
- Contains: Runtime descriptors, artifact layout resolution, frontmatter/body conversion, hook registration, profile staging, and rollback-aware installer migrations.
- Depends on: Runtime manifests in `capabilities/`, canonical commands in `commands/gsd/`, agents in `agents/`, hooks in `hooks/`, and package payload in `gsd-core/`.
- Used by: The `gsd-core` npm binary declared in `package.json`.
- Purpose: Bind GSD into hosts whose extension model is programmatic rather than file-only.
- Location: `.opencode/plugins/gsd-core.js`, `pi/gsd.cjs`, `vscode/extension.js`, `vscode/browser.js`, `vscode/host-binding.js`
- Contains: Event translation, command/LM-tool registration, host model/storage adapters, and subprocess reuse.
- Depends on: The installed engine in `gsd-core/bin/`, shared hooks in `hooks/`, and the host integration SDK in `src/host-integration-sdk.cts`.
- Used by: OpenCode, pi, and VS Code extension hosts.
- Purpose: Provide one process boundary for deterministic workflow queries and mutations.
- Location: `gsd-core/bin/gsd-tools.cjs`, `src/*-command-router.cts`, `src/command-routing-hub.cts`
- Contains: Argument normalization, project/workstream resolution, capability and host routing, typed errors, and output capture.
- Depends on: Generated registry `gsd-core/bin/lib/capability-registry.cjs` and compiled domain modules under `gsd-core/bin/lib/`.
- Used by: `gsd-core/bin/gsd_run`, workflows, hooks, MCP, and host extensions.
- Purpose: Parse and mutate roadmap/state/configuration/plans, calculate lifecycle transitions, validate artifacts, manage worktrees/workstreams, and perform feature operations.
- Location: `src/`
- Contains: Modules such as `src/state.cts`, `src/phase.cts`, `src/roadmap.cts`, `src/verification.cts`, `src/workstream.cts`, `src/graphify.cts`, and `src/audit.cts`.
- Depends on: Shared leaf seams including `src/io.cts`, `src/security.cts`, `src/shell-command-projection.cts`, `src/planning-workspace.cts`, and Markdown parsers.
- Used by: Command routers and public host adapters.
- Purpose: Centralize project-root discovery, `.planning` layout, state document parsing, lock discipline, safe writes, and host-negotiated state I/O.
- Location: `src/project-root.cts`, `src/planning-workspace.cts`, `src/state-document.cts`, `src/state-io.cts`, `src/write-set.cts`
- Contains: Root/workstream path projection, lock acquisition, filesystem adapters, atomic write plans, and state field transformations.
- Depends on: Node filesystem/path APIs and safe platform operations in `src/shell-command-projection.cts`.
- Used by: Most stateful domain modules under `src/`.
- Purpose: Turn authored TypeScript, manifests, hooks, and commands into package/install artifacts and verify no generated drift exists.
- Location: `scripts/`, `tsconfig.build.json`, `gsd-core/bin/lib/`, `hooks/dist/`, `skills/`
- Contains: TypeScript build, capability registry generation, plugin skill generation, hook distribution, manifest synchronization, and drift linters.
- Depends on: Authored sources in `src/`, `capabilities/`, `commands/gsd/`, and `hooks/`.
- Used by: npm build/publish and CI scripts declared in `package.json`.

## Data Flow

### Primary Workflow Request Path

### Runtime Installation Flow

### Capability Registration and Dispatch

### MCP / Programmatic Host Flow

- Store durable project state as Markdown/JSON below `.planning/`, using the canonical path map returned by `planningPaths()` in `src/planning-workspace.cts`.
- Route active workstreams to `.planning/workstreams/<name>/` via `src/active-workstream-store.cts` and `GSD_WORKSTREAM`; keep root configuration available as an overlay through `src/config-loader.cts`.
- Guard concurrent `.planning` mutation with `withPlanningLock()` in `src/planning-workspace.cts`; use the state-specific lock/write helpers in `src/state.cts` and atomic write primitives in `src/write-set.cts` where those modules require narrower transactions.
- Keep host session/transient data in runtime-specific configuration homes, `.planning/.gsd-trace.jsonl`, or the OS temp directory as owned by `src/observability/logger.cts`, `src/io.cts`, and hook files in `hooks/`.

## Key Abstractions

- Purpose: Declare a feature, runtime, or reviewer contribution and its commands, config schema, hooks, gates, profiles, and host behavior.
- Examples: `capabilities/graphify/capability.json`, `capabilities/codex/capability.json`, `capabilities/security/capability.json`
- Pattern: Validated declarative plugin descriptor compiled into a first-party registry and composable with consented overlays by `src/capability-loader.cts`.
- Purpose: Bind CLI arguments to a cohesive domain module without putting subcommand logic in `gsd-tools.cjs`.
- Examples: `src/state-command-router.cts`, `src/phase-command-router.cts`, `src/graphify-command-router.cts`
- Pattern: Build an explicit handler object and call `routeHubCommandFamily` from `src/cjs-command-router-adapter.cts`.
- Purpose: Standardize synchronous dispatch and the closed `UnknownCommand` / `InvalidArgs` / `HandlerRefusal` / `HandlerFailure` taxonomy.
- Examples: `src/command-routing-hub.cts`, `src/cjs-command-router-adapter.cts`
- Pattern: Per-family registry injection returning discriminated result objects; the hub never writes process output or exits.
- Purpose: Convert a repository root plus optional project/workstream into canonical artifact paths and lock ownership.
- Examples: `src/planning-workspace.cts`, `src/active-workstream-store.cts`, `src/workstream.cts`
- Pattern: Functional path projection plus small injected adapter/clock seams for tests.
- Purpose: Negotiate command surface, dispatch depth/isolation, model control, hooks, state, artifacts, runtime, transport, and reasoning effort.
- Examples: `src/host-integration.cts`, `src/host-integration-sdk.cts`, `capabilities/codex/capability.json`
- Pattern: Closed vocabularies, fail-closed defaults, declarative runtime descriptors, and a frozen external SDK surface.
- Purpose: Project canonical Claude-style command/agent content into the filename, frontmatter, nesting, and path syntax expected by each runtime.
- Examples: `src/runtime-artifact-conversion.cts`, `src/runtime-artifact-layout.cts`, `src/install-profiles.cts`
- Pattern: Descriptor-selected converter names and staged temporary trees consumed by `bin/install.js`.
- Purpose: Apply conditional sections and size budgets before runtime-specific path/tool rewrites.
- Examples: `src/workflow-fragments.cts`, `src/context-composer.cts`, `capabilities/research/fragments/plan-pre.md`
- Pattern: Parse to typed fragments, compose a plan, then render; callers own final presentation.

## Entry Points

- Location: `bin/install.js`
- Triggers: npm binary `gsd-core` from `package.json`.
- Responsibilities: Install/uninstall/update artifacts for selected hosts, preserve user customizations, run installer migrations, and validate configuration.
- Location: `gsd-core/bin/gsd-tools.cjs`
- Triggers: npm binary `gsd-tools`, `gsd-core/bin/gsd_run`, workflow shell blocks, hooks, extensions, and MCP subprocess dispatch.
- Responsibilities: Resolve project context and execute all deterministic query/mutation command families.
- Location: `gsd-core/bin/gsd_run`
- Triggers: Shell commands emitted in workflow Markdown.
- Responsibilities: Resolve its real install location and `exec node gsd-tools.cjs` with unchanged arguments.
- Location: `bin/gsd-mcp-server.js`
- Triggers: npm binary `gsd-mcp-server` over stdio.
- Responsibilities: Serve JSON-RPC initialization, tool discovery, command invocation, and state I/O.
- Location: `.opencode/plugins/gsd-core.js`
- Triggers: OpenCode plugin discovery from a package tree or installed config tree.
- Responsibilities: Register package-tree artifacts when needed and translate host events to shared hook subprocesses.
- Location: `pi/gsd.cjs`
- Triggers: pi extension discovery after install projection.
- Responsibilities: Register imperative commands/tools/events and reuse the engine subprocess and shared hooks.
- Location: `vscode/extension.js`, `vscode/browser.js`
- Triggers: VS Code desktop or web extension activation declared by `vscode/package.json`.
- Responsibilities: Register command palette/chat/LM-tool surfaces; desktop binds Node engine seams, while browser mode provides a zero-Node discoverability surface and points full dispatch to MCP.

## Architectural Constraints

- **Runtime module format:** Author runtime modules as `.cts` under `src/` and import sibling build artifacts with `.cjs` specifiers; `tsconfig.build.json` emits NodeNext CommonJS into `gsd-core/bin/lib/`.
- **Threading:** Core routing and filesystem operations are synchronous on the Node event loop; bounded child processes provide host/MCP reuse, while limited async edges include MCP stream iteration, host APIs, and installer finalization in `bin/` / `vscode/` / `pi/`.
- **Command handlers:** First-party and overlay capability routers must be synchronous; `dispatchCapabilityCommand()` rejects Promise-returning routers in `gsd-core/bin/gsd-tools.cjs`.
- **Project mutations:** Resolve the repository/worktree root before stateful commands and serialize shared `.planning` writes through `src/planning-workspace.cts` or the owning domain lock.
- **Global state:** Module-level state exists for lock ownership in `src/planning-workspace.cts`, JSON error mode in `src/io.cts`, warning/config caches in `src/config-loader.cts`, and test-injectable registries in `src/capability-loader.cts`; do not make request semantics depend on new mutable globals.
- **Circular imports:** A static scan of `src/**/*.cts` imports finds no cross-module cycles; preserve the leaf-seam direction centered on `src/shell-command-projection.cts`, `src/io.cts`, `src/planning-workspace.cts`, and parsing utilities.
- **Generated files:** Do not edit ignored compiled modules in `gsd-core/bin/lib/`, ignored hook outputs in `hooks/dist/`, generated skills in `skills/`, or generated registries such as `gsd-core/bin/lib/capability-registry.cjs` directly; edit their sources and run the generator/build declared in `package.json`.
- **Host descriptors:** Runtime differences belong in `capabilities/<runtime>/capability.json`; `src/runtime-config-adapter-registry.cts` and `src/runtime-artifact-layout.cts` fail loudly when required descriptor axes are absent.
- **Browser boundary:** `vscode/browser.js` must remain free of Node APIs and must not import `vscode/host-binding.js` or engine modules with filesystem/process transitive dependencies.
- **Third-party execution:** Load overlays through `src/capability-loader.cts`; command router modules require consent and realpath confinement enforced by `gsd-core/bin/gsd-tools.cjs`.

## Anti-Patterns

### Editing Emitted Runtime Artifacts

### Treating an Unconfigured Hub as the Global Engine

### Hard-Coding `.planning` Paths in Domain Logic

### Adding a Runtime Through Scattered Conditionals

### Updating Only One Command Surface

### Bypassing Capability Registration

## Error Handling

- Return the closed discriminated union from `src/command-routing-hub.cts`; convert unexpected throws to `HandlerFailure` and keep the hub free of stdout/stderr/process-exit behavior.
- Use `ERROR_REASON` and `error()` from `src/io.cts` for expected CLI failures; `--json-errors` produces parseable `{ ok, reason, message }` output.
- Throw `ExitError` and invoke `runMain()` from `src/cli-exit.cts` at standalone script boundaries that must set an exit code without tearing down pending output/cleanup.
- Surface unknown host/capability/schema/path states as errors or degraded results rather than inferring support; examples live in `src/host-integration.cts`, `src/runtime-config-adapter-registry.cts`, and `src/capability-loader.cts`.
- Keep hooks advisory and non-blocking only where the hook contract says failure must not stop the host; authored examples live in `hooks/gsd-context-monitor.js` and `hooks/gsd-update-banner.js`.

## Cross-Cutting Concerns

<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:

- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
