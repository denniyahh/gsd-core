# Technology Stack

**Analysis Date:** 2026-08-02

## Languages

**Primary:**
- TypeScript 6.0.3 - Strict CommonJS-oriented runtime modules use the `.cts` extension under `src/`; `tsconfig.build.json` compiles them into `.cjs` files under `gsd-core/bin/lib/`.
- JavaScript (ES2022/CommonJS) - Package entry points, the installer, generated runtime modules, host plugins, hooks, build scripts, and tests live in `bin/`, `gsd-core/bin/`, `hooks/`, `pi/`, `.opencode/`, `scripts/`, and `tests/`.

**Secondary:**
- ECMAScript modules - Tooling configuration uses `.mjs`, notably `eslint.config.mjs` and `stryker.config.mjs`.
- POSIX shell - Portable launchers and security/build helpers use `.sh`, including `gsd-core/bin/gsd_run`, `gsd-core/workflows/_runtime-launcher.snippet.sh`, and scripts under `scripts/`.
- Markdown, JSON, YAML, and TOML-shaped artifacts - Commands, skills, agents, workflows, capabilities, templates, and host configuration projections are data-driven from `commands/`, `skills/`, `agents/`, `gsd-core/workflows/`, `gsd-core/templates/`, and `capabilities/`.

## Runtime

**Environment:**
- Node.js 22 or newer - Enforced by `package.json`; `.nvmrc` pins major version 22 for local development, while `.github/workflows/test.yml` exercises Node 22 and 24.
- ES2022 target - Runtime TypeScript is compiled with `target: "ES2022"` and NodeNext resolution in `tsconfig.build.json`.
- Host runtimes execute emitted artifacts in their native environments - Node, Bun, Python, Go, Electron, and sandboxed-web host characteristics are declared in `capabilities/*/capability.json`; GSD itself remains a Node-distributed package.

**Package Manager:**
- npm 10 or newer - Enforced by `package.json`; installation, builds, tests, packing, publishing, and update checks are npm-driven.
- Lockfile: present - `package-lock.json` uses lockfile version 3 and pins the resolved dependency graph.
- Published package: `@opengsd/gsd-core` 1.9.1 - Identity, binaries, package contents, and npm scripts are declared in `package.json` and generated into `gsd-core/bin/lib/package-identity.cjs`.

## Frameworks

**Core:**
- Node.js CLI/library architecture - There is no web application framework; `bin/install.js`, `gsd-core/bin/gsd-tools.cjs`, `gsd-core/bin/gsd_run`, and `bin/gsd-mcp-server.js` are the executable surfaces.
- Capability and descriptor system - Feature manifests in `capabilities/*/capability.json`, generated registry data in `gsd-core/bin/lib/capability-registry.cjs`, and host integration contracts in `src/host-integration.cts` drive runtime-specific behavior.
- Prompt/workflow distribution - Markdown command, skill, agent, workflow, and template assets in `commands/`, `skills/`, `agents/`, and `gsd-core/` are packaged and transformed for supported AI coding hosts by `bin/install.js` and `src/runtime-artifact-conversion.cts`.
- Model Context Protocol companion server - A hand-rolled stdio JSON-RPC 2.0 server in `src/mcp-server.cts` and `bin/gsd-mcp-server.js` avoids adding an MCP SDK dependency.

**Testing:**
- Node built-in test runner - Tests use `node:test` through the suite orchestrator in `scripts/run-tests.cjs`; commands are exposed by `package.json` as `test`, `test:unit`, `test:integration`, `test:install`, `test:security`, `test:slow`, and `test:qa`.
- fast-check 4.8.0 - Property-based tests use the development dependency declared in `package.json` and pinned in `package-lock.json`.
- c8 11.0.0 - V8 coverage collection and threshold enforcement are configured through `package.json` and merged across CI shards in `.github/workflows/test.yml`.
- Stryker 9.6.1 - Mutation testing is configured in `stryker.config.mjs`, invoked by `package.json`, and automated by `.github/workflows/mutation.yml`.

**Build/Dev:**
- TypeScript 6.0.3 - `tsconfig.build.json` compiles `src/**/*.cts` into CommonJS runtime artifacts; `tsconfig.json` provides the no-emit editor/CI typecheck profile.
- ESLint 9.39.4 with typescript-eslint 8.60.0 - Flat configuration and repository-specific AST rules live in `eslint.config.mjs` and `eslint-rules/`.
- Repository generators - `scripts/gen-capability-registry.cjs`, `scripts/gen-plugin-skills.cjs`, `scripts/gen-context-index.cjs`, `scripts/gen-loop-host-contract.cjs`, and related scripts materialize derived artifacts through the `build` and `regen:derived` commands in `package.json`.
- No bundler - Runtime output is direct TypeScript-to-CommonJS compilation plus copied/generated package assets, as defined by `tsconfig.build.json`, `scripts/build-hooks.js`, and `package.json`.

## Key Dependencies

**Critical:**
- `@anthropic-ai/claude-agent-sdk` ^0.2.84 (resolved 0.2.141) - The optional Claude Workflow backend gates on the installed SDK version in `src/claude-orchestration-command-router.cts`; workflow generation itself is implemented in `src/claude-orchestration.cts` and does not directly import SDK APIs.
- `ws` ^8.21.0 (resolved 8.21.0) - Declared as a production dependency in `package.json`; no first-party import is present in `src/`, `bin/`, `hooks/`, `scripts/`, `pi/`, or `.opencode/`, so do not assume it provides an active server surface without adding an explicit call site.
- Node standard library - Filesystem, path, process, child-process, crypto, HTTP(S), streams, and built-in `fetch` APIs are the main runtime substrate throughout `src/`, `bin/`, `hooks/`, and `scripts/`.

**Infrastructure:**
- `fallow` ^2.70.0 (resolved 2.70.0, optional) - Dead-code and duplication auditing is invoked as an external binary by `src/fallow-runner.cts`; the feature degrades with an actionable message when the binary is absent.
- `js-yaml` 4.2.1 - Development-time YAML parsing supports scripts and tests as declared in `package.json` and pinned in `package-lock.json`.
- Git, npm, and system `tar` - Capability sources can be cloned, packed, version-checked, and extracted through bounded subprocess seams in `src/capability-source.cts`; Git also underpins worktree and repository lifecycle operations across `src/`.
- No database client, ORM, cache client, or server framework - Persistent state and caches use JSON/Markdown files through modules such as `src/state-io.cts`, `src/state.cts`, and `src/research-store.cts`.

## Configuration

**Environment:**
- Project configuration resolves from `.planning/config.json`, workstream-specific `.planning/workstreams/<name>/config.json`, and user defaults in `~/.gsd/defaults.json` through `src/config-loader.cts`, `src/config.cts`, and `src/planning-workspace.cts`.
- Runtime installation homes and overrides are descriptor-driven in `capabilities/*/capability.json`; examples include `CLAUDE_CONFIG_DIR`, `CODEX_HOME`, `OPENCODE_CONFIG_DIR`, and corresponding host-specific variables consumed by `bin/install.js`.
- Optional research integrations are detected through `BRAVE_API_KEY`, `EXA_API_KEY`, `TAVILY_API_KEY`, `PERPLEXITY_API_KEY`, `FIRECRAWL_API_KEY`, `REF_API_KEY`, and `JINA_API_KEY` in `src/config.cts`; no `.env` files are present in the repository.
- Optional operational controls include `GSD_WORKSTREAM` in `src/active-workstream-store.cts`, `GSD_AUDIT`/`GSD_AUDIT_ARGS` in `src/observability/logger.cts`, `GSD_AGENT_SDK_VERSION` in `src/claude-orchestration-command-router.cts`, and `GSD_WEBSEARCH_TIMEOUT_MS` in `src/commands.cts`.

**Build:**
- `package.json` - Engine constraints, dependency graph, bin entries, package file allowlist, build scripts, test suites, coverage gates, and publish lifecycle.
- `tsconfig.build.json` - Emitting strict TypeScript build; `tsconfig.json` - no-emit typecheck profile.
- `eslint.config.mjs` and `eslint-rules/` - Flat lint configuration and local reliability/portability rules.
- `stryker.config.mjs` - Mutation-test configuration.
- `.nvmrc` and `package-lock.json` - Node major and reproducible npm dependency graph.

## Platform Requirements

**Development:**
- Use Node.js >=22 and npm >=10, then install the lockfile graph with `npm ci`; the environment gate in `scripts/check-env.cjs` validates engines, lockfile presence, and lockfile synchronization.
- Keep Git available for tests and repository/worktree behavior, and keep system `tar` available when exercising capability package installation paths in `src/capability-source.cts`.
- Linux, macOS, and Windows are supported and tested; the CI matrices in `.github/workflows/test.yml` and `.github/workflows/install-smoke.yml` cover Ubuntu, macOS, and Windows with Node 22/24.
- Run `npm run build:lib` before directly invoking generated `gsd-core/bin/lib/*.cjs` modules; normal `prepare`, `pretest`, `prepack`, and first-run recovery paths are defined in `package.json` and `gsd-core/bin/ensure-runtime-build.cjs`.

**Production:**
- Primary deployment is a public npm package installed globally or into a project/runtime configuration directory by `bin/install.js`; there is no separately hosted application process.
- Packaged binaries are `gsd-core`, `gsd-tools`, `gsd_run`, and `gsd-mcp-server` as defined in `package.json`; the MCP server is a local stdio child process, not a network listener, per `bin/gsd-mcp-server.js`.
- Release publication targets npm with provenance and GitHub Releases through `.github/workflows/release.yml`; emitted commands, skills, agents, hooks, and engine files are the production artifacts listed in `package.json`.

---

*Stack analysis: 2026-08-02*
