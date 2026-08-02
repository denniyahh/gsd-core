# Codebase Structure

**Analysis Date:** 2026-08-02

## Directory Layout

```text
gsd-core/
├── src/                         # Authored TypeScript/CommonJS runtime modules (`*.cts`)
│   ├── host-integration-adapters/
│   ├── installer-migrations/
│   └── observability/
├── bin/                         # Package-level installer and MCP binary entries
├── gsd-core/
│   ├── bin/                     # Installed runtime CLI, launcher, shared data, emitted libraries
│   │   ├── lib/
│   │   └── shared/
│   ├── workflows/               # Executable orchestration procedures
│   ├── references/              # Shared workflow/agent guidance and fixtures
│   ├── templates/               # Planning and analysis artifact templates
│   └── contexts/                # Shipped context assets
├── commands/gsd/                # Canonical agent command definitions
├── skills/gsd-*/                # Generated, committed plugin SKILL.md surfaces
├── agents/                      # Canonical specialist agent definitions
├── capabilities/                # Feature/runtime/reviewer manifests and hook fragments
├── hooks/                       # Authored lifecycle hooks; `hooks/dist/` is build output
├── .opencode/plugins/           # OpenCode package/file-copy adapter
├── pi/                          # pi programmatic extension
├── vscode/                      # VS Code desktop/web extension binding
├── scripts/                     # Build, generation, lint, release, and test orchestration
├── eslint-rules/                # Repository-specific ESLint rules
├── tests/                       # Node test suites, fixtures, QA scenarios, and helpers
├── docs/                        # ADRs, design/reference/how-to docs, translations
├── examples/                    # Example integrations and usage patterns
├── assets/                      # Images and package documentation assets
├── .changeset/                  # User-facing change fragments
├── package.json                 # Package entry points, scripts, dependencies, engines
├── tsconfig.build.json          # `src/**/*.cts` → `gsd-core/bin/lib/**/*.cjs`
└── eslint.config.mjs            # Flat ESLint configuration and local rules
```

## Directory Purposes

**`src/`:**

- Purpose: Canonical implementation of the runtime engine.
- Contains: 179 `.cts` files covering CLI domains, parsers, host integration, capability lifecycle, installation seams, safety, and observability.
- Key files: `src/command-routing-hub.cts`, `src/planning-workspace.cts`, `src/config-loader.cts`, `src/host-integration.cts`, `src/shell-command-projection.cts`
- Add runtime behavior here unless the target is one of the small tracked CommonJS source exceptions in `gsd-core/bin/lib/`.

**`src/host-integration-adapters/`:**

- Purpose: Hold host-specific bindings that satisfy the shared integration interfaces.
- Contains: Imperative hook bus and Cline SDK bindings.
- Key files: `src/host-integration-adapters/imperative-hook-bus.cts`, `src/host-integration-adapters/cline-sdk-binding.cts`
- Add a binding here only when a capability descriptor and the generic adapters in `src/adapter-declarative.cts` / `src/adapter-imperative.cts` cannot express it.

**`src/installer-migrations/`:**

- Purpose: Define ordered, idempotent installation cleanup/migration steps.
- Contains: Numeric migration modules loaded by `src/installer-migrations.cts`.
- Key files: `src/installer-migrations/000-first-time-baseline.cts`, `src/installer-migrations/007-retire-config-root-commonjs-marker.cts`
- Add migrations with the next zero-padded numeric prefix and keep detection/application/rollback behavior compatible with `src/installer-migrations.cts`.

**`src/observability/`:**

- Purpose: Define dispatch events, redaction, and opt-in logging.
- Contains: Event construction, logger implementations, and redaction rules.
- Key files: `src/observability/event.cts`, `src/observability/logger.cts`, `src/observability/redaction.cts`
- Route new dispatch telemetry through these modules; never log raw arguments directly.

**`bin/`:**

- Purpose: Expose package-level npm executables that are not copied as ordinary engine modules.
- Contains: The multi-runtime installer and companion MCP server shim.
- Key files: `bin/install.js`, `bin/gsd-mcp-server.js`, `bin/lib/ui-safety-gate.cjs`
- Keep entries thin except `bin/install.js`, which owns package materialization and host configuration.

**`gsd-core/bin/`:**

- Purpose: Provide the portable runtime payload installed into host configuration directories.
- Contains: `gsd-core/bin/gsd-tools.cjs`, `gsd-core/bin/gsd_run`, build bootstrap helpers, `lib/`, and `shared/`.
- Key files: `gsd-core/bin/gsd-tools.cjs`, `gsd-core/bin/gsd_run`, `gsd-core/bin/ensure-runtime-build.cjs`, `gsd-core/bin/verify-reapply-patches.cjs`
- Add a package binary only through `package.json`; keep domain logic out of entry shims and under `src/`.

**`gsd-core/bin/lib/`:**

- Purpose: House the CommonJS runtime consumed by the CLI, installer, hooks, and host extensions.
- Contains: Mostly ignored TypeScript build output plus a small set of tracked CommonJS sources and generators.
- Key files: `gsd-core/bin/lib/capability-command-router.cjs`, `gsd-core/bin/lib/capability-validator.cjs`, `gsd-core/bin/lib/capability-registry.cjs`, `gsd-core/bin/lib/loop-host-contract.cjs`
- Edit a matching `src/<stem>.cts` whenever one exists. Directly edit tracked CommonJS-only sources only when no `src/<stem>.cts` exists.

**`gsd-core/bin/shared/`:**

- Purpose: Store tracked, host-neutral data consumed by runtime and installer modules.
- Contains: Configuration defaults/schema, model catalog, and runtime alias manifests.
- Key files: `gsd-core/bin/shared/config-defaults.manifest.json`, `gsd-core/bin/shared/config-schema.manifest.json`, `gsd-core/bin/shared/model-catalog.json`, `gsd-core/bin/shared/runtime-aliases.manifest.json`
- Update the canonical shared manifest and all generators/validators that derive views from it in the same change.

**`gsd-core/workflows/`:**

- Purpose: Hold executable orchestration procedures referenced by commands and skills.
- Contains: 115 Markdown workflows and nested step fragments.
- Key files: `gsd-core/workflows/plan-phase.md`, `gsd-core/workflows/execute-phase.md`, `gsd-core/workflows/map-codebase.md`, `gsd-core/workflows/plan-phase/steps/closed-phase-gate.md`
- Add one workflow per command stem; extract a nested `steps/*.md` file only when a workflow has a cohesive reusable or independently gated section.

**`gsd-core/references/`:**

- Purpose: Centralize shared rules, protocols, schemas, and specialist guidance loaded by workflows/agents.
- Contains: 115 Markdown/text/JSON reference assets and fixture subdirectories.
- Key files: `gsd-core/references/runtime-aware-dispatch.md`, `gsd-core/references/mandatory-initial-read.md`, `gsd-core/references/planning-config.md`, `gsd-core/references/worktree-path-safety.md`
- Put cross-workflow policy here and reference it explicitly from `<required_reading>` or execution context rather than copying it into multiple workflows.

**`gsd-core/templates/`:**

- Purpose: Define output contracts for planning, verification, research, UI, security, and codebase mapping artifacts.
- Contains: 46 Markdown/JSON templates, including `codebase/` and `research-project/` groups.
- Key files: `gsd-core/templates/state.md`, `gsd-core/templates/roadmap.md`, `gsd-core/templates/codebase/architecture.md`, `gsd-core/templates/AI-SPEC.md`
- Add a template only for a persisted artifact with a stable schema; keep workflow execution logic in `gsd-core/workflows/`.

**`commands/gsd/`:**

- Purpose: Serve as the canonical command frontmatter/body source for file-copy installs and generated plugin skills.
- Contains: 71 kebab-case Markdown command definitions.
- Key files: `commands/gsd/plan-phase.md`, `commands/gsd/execute-phase.md`, `commands/gsd/progress.md`, `commands/gsd/map-codebase.md`
- Add arguments, allowed tools, `requires`, objective, execution context, and concise orchestration instructions here; put the full procedure in the matching workflow.

**`skills/`:**

- Purpose: Provide committed Claude/Codex-compatible plugin skill packages derived from command definitions.
- Contains: 71 `skills/gsd-<stem>/SKILL.md` files.
- Key files: `skills/gsd-plan-phase/SKILL.md`, `skills/gsd-execute-phase/SKILL.md`, `skills/gsd-map-codebase/SKILL.md`
- Do not hand-edit generated skill bodies. Update `commands/gsd/<stem>.md` and regenerate through `scripts/gen-plugin-skills.cjs`.

**`agents/`:**

- Purpose: Define 34 independently dispatched specialist roles.
- Contains: `gsd-<role>.md` agent prompts with tool/frontmatter and strict process/output contracts.
- Key files: `agents/gsd-planner.md`, `agents/gsd-executor.md`, `agents/gsd-verifier.md`, `agents/gsd-codebase-mapper.md`
- Add a role only when it needs isolated context or a distinct output contract; wire it from the owning workflow and capability manifest.

**`capabilities/`:**

- Purpose: Declare first-party feature, runtime, and reviewer capabilities in one registry input.
- Contains: 44 `capability.json` manifests plus optional `fragments/` content.
- Key files: `capabilities/graphify/capability.json`, `capabilities/codex/capability.json`, `capabilities/security/capability.json`, `capabilities/research/fragments/plan-pre.md`
- Add a new capability at `capabilities/<id>/capability.json`; keep the directory name equal to the manifest `id`, then regenerate the registry.

**`hooks/`:**

- Purpose: Implement host lifecycle guards, context/status signals, commit/worktree checks, and update behavior.
- Contains: 27 authored top-level files, `hooks/lib/` helpers, generated `hooks/dist/`, and `hooks/hooks.json` registration metadata.
- Key files: `hooks/managed-hooks-registry.cjs`, `hooks/gsd-context-monitor.js`, `hooks/gsd-workflow-guard.js`, `hooks/lib/git-cmd.js`
- Add managed hook filenames to `hooks/managed-hooks-registry.cjs` and the build/install registry used by `scripts/build-hooks.js`.

**`.opencode/plugins/`:**

- Purpose: Adapt OpenCode events and package/file-copy layouts to the shared GSD hooks and command assets.
- Contains: One CommonJS plugin entry.
- Key files: `.opencode/plugins/gsd-core.js`
- Reuse shared hook/command behavior by subprocess rather than duplicating it in this adapter.

**`pi/`:**

- Purpose: Bind GSD commands, tools, and events to pi's programmatic extension API.
- Contains: One authored CommonJS extension copied with a `.js` destination suffix.
- Key files: `pi/gsd.cjs`
- Keep engine dispatch on the shared `dispatchGsdCommand` subprocess seam.

**`vscode/`:**

- Purpose: Package desktop and browser VS Code integration.
- Contains: Desktop extension, web extension, host binding, and extension manifest.
- Key files: `vscode/package.json`, `vscode/extension.js`, `vscode/browser.js`, `vscode/host-binding.js`
- Keep browser code zero-Node; put Node-dependent engine composition in `vscode/extension.js` / `vscode/host-binding.js`.

**`scripts/`:**

- Purpose: Build and generate derived assets, enforce architectural drift rules, run tests, and prepare releases.
- Contains: 92 files with `changeset/`, `lib/`, and `release-notes/` subdirectories.
- Key files: `scripts/run-tests.cjs`, `scripts/gen-capability-registry.cjs`, `scripts/gen-plugin-skills.cjs`, `scripts/build-hooks.js`, `scripts/lint-compiled-artifact-sync.cjs`
- Put reusable script helpers under `scripts/lib/`; keep product runtime code under `src/`.

**`eslint-rules/`:**

- Purpose: Enforce repository-specific architectural constraints beyond generic ESLint rules.
- Contains: Local rule definitions and tests/helpers under `eslint-rules/lib/`.
- Key files: `eslint-rules/index.js`, `eslint-rules/lib/no-adhoc-markdown-parsing.js`, `eslint-rules/lib/no-process-exit.js`
- Add a local rule when an architectural invariant is mechanically detectable across the repository.

**`tests/`:**

- Purpose: Verify runtime modules, installers, generated parity, security boundaries, host bindings, and workflow contracts.
- Contains: 899 test/fixture/helper files with focused groups under `tests/dispatch/`, `tests/observability/`, `tests/qa/`, `tests/fixtures/`, and `tests/helpers/`.
- Key files: `tests/command-routing-hub.test.cjs`, `tests/gsd-mcp-server.test.cjs`, `tests/sdk-smoke.test.cjs`, `tests/helpers/clock.cjs`
- Co-locate new tests in `tests/` by feature stem; use a subgroup only when the suite owns shared fixtures or a distinct harness.

**`docs/`:**

- Purpose: Explain architecture, operational usage, schemas, decisions, and translated documentation.
- Contains: 373 files under `adr/`, `design/`, `reference/`, `how-to/`, `tutorials/`, security/research sections, and locale trees.
- Key files: `docs/adr/README.md`, `docs/adr/0174-retire-gsd-sdk-package-boundary.md`, `docs/reference/host-integration-interface.md`, `docs/reference/planning-artifacts.md`
- Record stable architecture decisions under `docs/adr/`; put normative user/developer API descriptions under `docs/reference/`.

## Key File Locations

**Entry Points:**

- `bin/install.js`: npm `gsd-core` installer/uninstaller.
- `gsd-core/bin/gsd-tools.cjs`: npm `gsd-tools` runtime CLI.
- `gsd-core/bin/gsd_run`: shell-safe launcher used by workflows.
- `bin/gsd-mcp-server.js`: npm stdio MCP server.
- `.opencode/plugins/gsd-core.js`: OpenCode plugin binding.
- `pi/gsd.cjs`: pi extension binding.
- `vscode/extension.js`: VS Code desktop entry.
- `vscode/browser.js`: VS Code web entry.

**Configuration:**

- `package.json`: package files, binary mappings, build/test/lint scripts, engines, and dependencies.
- `tsconfig.json`: editor/type-check base configuration.
- `tsconfig.build.json`: production TypeScript build boundary and output directory.
- `eslint.config.mjs`: repository lint rules and file-specific constraints.
- `stryker.config.mjs`: mutation-test configuration.
- `mise.toml`: repository task/tool environment configuration.
- `gsd-core/bin/shared/config-schema.manifest.json`: canonical configuration schema data.
- `gsd-core/bin/shared/config-defaults.manifest.json`: canonical default values.
- `gsd-core/bin/shared/model-catalog.json`: canonical model/effort catalog.

**Core Logic:**

- `src/command-routing-hub.cts`: typed per-family dispatch.
- `src/cjs-command-router-adapter.cts`: CLI-family-to-hub adapter.
- `src/planning-workspace.cts`: `.planning` paths, workstream routing, and locks.
- `src/config-loader.cts`: merged and federated project configuration.
- `src/host-integration.cts`: host capability negotiation contract.
- `src/runtime-artifact-layout.cts`: descriptor-driven install layouts.
- `src/runtime-artifact-conversion.cts`: runtime syntax/body conversion.
- `src/shell-command-projection.cts`: safe cross-platform subprocess/filesystem projection.
- `src/security.cts`: prompt/path/input security helpers.
- `gsd-core/bin/gsd-tools.cjs`: top-level command dispatch composition.

**Testing:**

- `tests/*.test.cjs`: primary unit/integration suites named by feature.
- `tests/dispatch/`: dispatch-focused test group.
- `tests/observability/`: logger/event/redaction tests.
- `tests/qa/`: scenario, smell-ratchet, and QA report suites.
- `tests/fixtures/`: committed positive/adversarial/install-tree fixtures.
- `tests/helpers/`: shared clocks, processes, fixtures, and assertion helpers.
- `scripts/run-tests.cjs`: suite discovery and execution entry.
- `TESTING-STANDARDS.md`: project test contract.

**Documentation:**

- `README.md`: package overview and installation entry.
- `CONTRIBUTING.md`: change, generation, testing, and release requirements.
- `docs/adr/README.md`: ADR lifecycle and index.
- `docs/reference/`: normative GSD interface/artifact/configuration references.
- `CHANGELOG.md`: release history generated from changesets.

## Naming Conventions

**Files:**

- Use kebab-case `.cts` for runtime modules: `src/planning-workspace.cts`, `src/model-resolver.cts`.
- Suffix command-family adapters with `-command-router.cts`: `src/state-command-router.cts`, `src/graphify-command-router.cts`.
- Give an installer migration a three-digit order prefix: `src/installer-migrations/007-retire-config-root-commonjs-marker.cts`.
- Match command and workflow stems exactly: `commands/gsd/plan-phase.md` ↔ `gsd-core/workflows/plan-phase.md`.
- Prefix agent definitions with `gsd-`: `agents/gsd-plan-checker.md`.
- Name tests `<feature>.test.cjs`: `tests/command-routing-hub.test.cjs`.
- Use uppercase artifact template/report names where the persisted contract is uppercase: `gsd-core/templates/VALIDATION.md`, `gsd-core/templates/codebase/architecture.md`.

**Directories:**

- Name a generated skill directory `skills/gsd-<command-stem>/`: `skills/gsd-plan-phase/`.
- Name a capability directory exactly after its lowercase manifest id: `capabilities/graphify/`.
- Use plural functional groups for broad corpora: `workflows/`, `references/`, `templates/`, `tests/`, `scripts/`.
- Use a nested directory only for a cohesive namespace or fixture family: `src/observability/`, `tests/qa/`, `gsd-core/workflows/plan-phase/steps/`.

## Where to Add New Code

**New Runtime Domain Feature:**

- Primary code: `src/<feature>.cts`
- Family router: `src/<feature>-command-router.cts` when the feature exposes three or more related subcommands.
- Tests: `tests/<feature>.test.cjs` and `tests/<feature>-command-router.test.cjs` as needed.
- Registration: `gsd-core/bin/gsd-tools.cjs` for a core, non-toggleable family; `capabilities/<feature>/capability.json` for a toggleable feature.
- Build output: Let `tsconfig.build.json` emit `gsd-core/bin/lib/<feature>.cjs`; do not create it manually.

**New Capability:**

- Declaration: `capabilities/<id>/capability.json`
- Optional workflow contributions: `capabilities/<id>/fragments/<loop-point>.md`
- Runtime implementation: `src/<id>.cts` and `src/<id>-command-router.cts`
- Tests: `tests/<id>.test.cjs`, registry/activation tests under `tests/` when new descriptor axes are involved.
- Generated index: Rebuild `gsd-core/bin/lib/capability-registry.cjs` with `scripts/gen-capability-registry.cjs`.

**New Agent Command / Skill:**

- Canonical command: `commands/gsd/<stem>.md`
- Full procedure: `gsd-core/workflows/<stem>.md`
- Generated plugin skill: `skills/gsd-<stem>/SKILL.md` via `scripts/gen-plugin-skills.cjs`
- Dependency metadata: Add every referenced GSD command stem to `requires` in `commands/gsd/<stem>.md`; `scripts/lint-skill-deps.cjs` enforces closure.
- Tests: Add structural/installation coverage under `tests/` for new command discovery, conversion, and install parity.

**New Agent Role:**

- Definition: `agents/gsd-<role>.md`
- Owning workflow: `gsd-core/workflows/<orchestrator>.md`
- Capability ownership: Add the role stem to `capabilities/<feature>/capability.json` when it belongs to a feature capability.
- Tests: Add agent roster/install/conversion assertions under `tests/`.

**New Runtime / Host:**

- Descriptor: `capabilities/<runtime>/capability.json`
- Generic projection support: Extend `src/runtime-artifact-conversion.cts`, `src/runtime-artifact-layout.cts`, or `src/runtime-hooks-surface.cts` only for behavior not expressible by existing descriptor axes.
- Programmatic binding: Add a focused top-level adapter directory/file following `.opencode/plugins/gsd-core.js`, `pi/gsd.cjs`, or `vscode/` only when the host has an extension API.
- Tests: Add install-tree, descriptor validation, host binding, and runtime parity coverage in `tests/fixtures/install-tree/` and `tests/`.
- Documentation: Add verified axes to `docs/reference/host-integration-capability-matrix.md`.

**New Hook:**

- Implementation: `hooks/gsd-<purpose>.js` or `hooks/gsd-<purpose>.sh`
- Shared helper: `hooks/lib/<helper>.js` only when multiple hooks consume it.
- Managed inventory: `hooks/managed-hooks-registry.cjs` and the copy inventory in `scripts/build-hooks.js`.
- Generated output: `hooks/dist/` through `npm run build:hooks`.
- Tests: `tests/<hook-purpose>.test.cjs` plus runtime registration/install parity tests.

**New Template or Reference:**

- Persisted artifact schema: `gsd-core/templates/<artifact>.md` or a scoped subdirectory such as `gsd-core/templates/codebase/`.
- Shared workflow rule/protocol: `gsd-core/references/<topic>.md`.
- Consumer wiring: Reference it explicitly from `commands/gsd/`, `gsd-core/workflows/`, or `agents/`; do not rely on implicit discovery.

**Utilities:**

- Shared runtime helpers: `src/<topic>.cts` when consumed by product modules.
- Script-only helpers: `scripts/lib/<topic>.cjs` when consumed only by build/lint/release scripts.
- Hook-only helpers: `hooks/lib/<topic>.js` when consumed only by hooks.
- Test-only helpers: `tests/helpers/<topic>.cjs`.

## Special Directories

**`gsd-core/bin/lib/`:**

- Purpose: Installed CommonJS engine surface.
- Generated: Mixed. Most files matching `src/**/*.cts` are ignored build output; tracked CommonJS-only files include `gsd-core/bin/lib/capability-command-router.cjs`, `gsd-core/bin/lib/capability-validator.cjs`, `gsd-core/bin/lib/legacy-cleanup.cjs`, `gsd-core/bin/lib/profile-pipeline-command-router.cjs`, and `gsd-core/bin/lib/stale-bake-guard.cjs`. `gsd-core/bin/lib/capability-registry.cjs`, `gsd-core/bin/lib/loop-host-contract.cjs`, and `gsd-core/bin/lib/package-identity.cjs` are generated tracked artifacts.
- Committed: Mixed; check for a matching `src/<stem>.cts` and `git ls-files` before editing.

**`hooks/dist/`:**

- Purpose: Distribution-ready copies of authored hooks and helpers.
- Generated: Yes, by `scripts/build-hooks.js`.
- Committed: No; ignored by `.gitignore`.

**`skills/`:**

- Purpose: Plugin-discoverable skill packages.
- Generated: Yes, from `commands/gsd/*.md` by `scripts/gen-plugin-skills.cjs` using the runtime artifact converter.
- Committed: Yes; `scripts/gen-plugin-skills.cjs --check` detects drift.

**`capabilities/*/fragments/`:**

- Purpose: Capability-owned contributions injected at declared workflow loop points.
- Generated: No.
- Committed: Yes; each fragment is validated through the owning `capability.json` and registry generator.

**`tests/fixtures/install-tree/`:**

- Purpose: Golden installation-layout fixtures for supported runtimes/profiles.
- Generated: Yes, through `scripts/gen-install-tree-fixtures.cjs` when explicitly refreshed.
- Committed: Yes; installation tests consume these fixtures.

**`.changeset/`:**

- Purpose: Record user-facing package changes for automated changelog/version processing.
- Generated: No; contributors add fragments through `scripts/changeset/new.cjs` or manually following the schema.
- Committed: Yes; archived fragments live under `.changeset/archived/`.

**`.planning/`:**

- Purpose: Hold project-local GSD state, roadmap, requirements, phase artifacts, workstreams, graphs, audit trace, and this codebase map.
- Generated: Yes, by GSD workflows and runtime commands.
- Committed: Project-policy dependent; path resolution and locking are owned by `src/planning-workspace.cts`.

**`node_modules/`:**

- Purpose: Local npm dependency installation.
- Generated: Yes, by npm.
- Committed: No; excluded from source mapping and package contents.

---

*Structure analysis: 2026-08-02*
