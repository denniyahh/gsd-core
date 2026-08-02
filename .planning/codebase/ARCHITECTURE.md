<!-- refreshed: 2026-08-02 -->
# Architecture

**Analysis Date:** 2026-08-02

## System Overview

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Agent-facing orchestration assets                       │
├──────────────────────┬──────────────────────┬───────────────────────────────┤
│ Commands and skills  │ Workflow procedures  │ Agent roles and capabilities  │
│ `commands/gsd/`      │ `gsd-core/workflows/`│ `agents/`, `capabilities/`    │
│ `skills/`            │ `gsd-core/references/`                              │
└───────────┬──────────┴───────────┬──────────┴───────────────┬───────────────┘
            │                      │                          │
            ▼                      ▼                          ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                  Host projection and integration layer                     │
│ `bin/install.js`, `hooks/`, `.opencode/plugins/`, `pi/`, `vscode/`          │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │ invokes / embeds / spawns
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Runtime command and dispatch layer                       │
│ `gsd-core/bin/gsd-tools.cjs` → capability routers / host routers / hub      │
│ authored in `src/`, emitted to `gsd-core/bin/lib/`                          │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                  Domain services and project state                         │
│ `src/state.cts`, `src/phase.cts`, `src/roadmap.cts`, `src/workstream.cts`   │
│ project artifacts under `.planning/`; runtime artifacts under host homes    │
└─────────────────────────────────────────────────────────────────────────────┘
```

The repository is one npm package with two cooperating products: declarative Markdown orchestration consumed by coding agents, and a Node/CommonJS runtime that provides deterministic state, routing, installation, validation, and host-integration operations. The authored runtime is primarily `src/**/*.cts`; `tsconfig.build.json` emits it as CommonJS into `gsd-core/bin/lib/**/*.cjs`.

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

**Overall:** Declarative orchestration over a modular synchronous engine, with manifest-driven feature/runtime registration and generated distribution artifacts.

**Key Characteristics:**

- Treat `commands/gsd/*.md`, `gsd-core/workflows/*.md`, `agents/*.md`, and `capabilities/*/capability.json` as declarative inputs; use `scripts/gen-plugin-skills.cjs`, `scripts/gen-capability-registry.cjs`, and `bin/install.js` to project them to host-specific surfaces.
- Put deterministic runtime behavior in seam-oriented modules under `src/`; compile `.cts` to `.cjs` with `tsconfig.build.json` because the installed engine and host adapters consume CommonJS.
- Route toggleable feature families through the generated capability registry and core families through `HOST_COMMAND_ROUTERS` in `gsd-core/bin/gsd-tools.cjs`.
- Route subcommands through `routeHubCommandFamily` from `src/cjs-command-router-adapter.cts`; use `src/command-routing-hub.cts` for typed success/failure results and synchronous dispatch isolation.
- Resolve every project artifact path through `src/project-root.cts` and `src/planning-workspace.cts`; active workstreams change the effective `.planning` subtree through `GSD_WORKSTREAM`.
- Keep host variability in `capabilities/<runtime>/capability.json`, `src/host-integration.cts`, and runtime artifact adapters; do not scatter new runtime-name conditionals through domain modules.

## Layers

**Agent Command Surface:**

- Purpose: Present named GSD operations to host agents and declare arguments, tool permissions, dependencies, and execution context.
- Location: `commands/gsd/`, `skills/`
- Contains: Canonical command Markdown in `commands/gsd/*.md` and committed generated plugin skills in `skills/gsd-*/SKILL.md`.
- Depends on: Workflow and reference assets in `gsd-core/workflows/` and `gsd-core/references/`.
- Used by: Runtime command loaders and host-specific installation performed by `bin/install.js`.

**Workflow Orchestration:**

- Purpose: Define multi-step agent procedures, required readings, subagent contracts, gates, and writes to planning artifacts.
- Location: `gsd-core/workflows/`
- Contains: Lifecycle workflows, scoped step fragments such as `gsd-core/workflows/plan-phase/steps/`, and loop-host markers consumed by capability composition.
- Depends on: Shared guidance in `gsd-core/references/`, output shapes in `gsd-core/templates/`, and deterministic queries exposed by `gsd-core/bin/gsd-tools.cjs`.
- Used by: Command files in `commands/gsd/`, generated skills in `skills/`, and installed host artifacts.

**Role Definitions:**

- Purpose: Isolate planner, executor, reviewer, mapper, and specialist responsibilities in independently dispatched agent prompts.
- Location: `agents/`
- Contains: Frontmatter plus role/process contracts such as `agents/gsd-planner.md`, `agents/gsd-executor.md`, and `agents/gsd-codebase-mapper.md`.
- Depends on: Workflows and references under `gsd-core/` and runtime conversion performed by `bin/install.js` / `src/runtime-artifact-conversion.cts`.
- Used by: Orchestrating workflows such as `gsd-core/workflows/plan-phase.md` and `gsd-core/workflows/execute-phase.md`.

**Host Projection and Packaging:**

- Purpose: Install one canonical asset corpus into the configuration layout and syntax expected by each host.
- Location: `bin/install.js`, `src/runtime-artifact-layout.cts`, `src/runtime-artifact-conversion.cts`, `src/install-engine.cts`, `src/runtime-hooks-surface.cts`
- Contains: Runtime descriptors, artifact layout resolution, frontmatter/body conversion, hook registration, profile staging, and rollback-aware installer migrations.
- Depends on: Runtime manifests in `capabilities/`, canonical commands in `commands/gsd/`, agents in `agents/`, hooks in `hooks/`, and package payload in `gsd-core/`.
- Used by: The `gsd-core` npm binary declared in `package.json`.

**Host Bindings:**

- Purpose: Bind GSD into hosts whose extension model is programmatic rather than file-only.
- Location: `.opencode/plugins/gsd-core.js`, `pi/gsd.cjs`, `vscode/extension.js`, `vscode/browser.js`, `vscode/host-binding.js`
- Contains: Event translation, command/LM-tool registration, host model/storage adapters, and subprocess reuse.
- Depends on: The installed engine in `gsd-core/bin/`, shared hooks in `hooks/`, and the host integration SDK in `src/host-integration-sdk.cts`.
- Used by: OpenCode, pi, and VS Code extension hosts.

**CLI Dispatch:**

- Purpose: Provide one process boundary for deterministic workflow queries and mutations.
- Location: `gsd-core/bin/gsd-tools.cjs`, `src/*-command-router.cts`, `src/command-routing-hub.cts`
- Contains: Argument normalization, project/workstream resolution, capability and host routing, typed errors, and output capture.
- Depends on: Generated registry `gsd-core/bin/lib/capability-registry.cjs` and compiled domain modules under `gsd-core/bin/lib/`.
- Used by: `gsd-core/bin/gsd_run`, workflows, hooks, MCP, and host extensions.

**Domain Services:**

- Purpose: Parse and mutate roadmap/state/configuration/plans, calculate lifecycle transitions, validate artifacts, manage worktrees/workstreams, and perform feature operations.
- Location: `src/`
- Contains: Modules such as `src/state.cts`, `src/phase.cts`, `src/roadmap.cts`, `src/verification.cts`, `src/workstream.cts`, `src/graphify.cts`, and `src/audit.cts`.
- Depends on: Shared leaf seams including `src/io.cts`, `src/security.cts`, `src/shell-command-projection.cts`, `src/planning-workspace.cts`, and Markdown parsers.
- Used by: Command routers and public host adapters.

**Persistence and Artifact I/O:**

- Purpose: Centralize project-root discovery, `.planning` layout, state document parsing, lock discipline, safe writes, and host-negotiated state I/O.
- Location: `src/project-root.cts`, `src/planning-workspace.cts`, `src/state-document.cts`, `src/state-io.cts`, `src/write-set.cts`
- Contains: Root/workstream path projection, lock acquisition, filesystem adapters, atomic write plans, and state field transformations.
- Depends on: Node filesystem/path APIs and safe platform operations in `src/shell-command-projection.cts`.
- Used by: Most stateful domain modules under `src/`.

**Build and Generated Artifacts:**

- Purpose: Turn authored TypeScript, manifests, hooks, and commands into package/install artifacts and verify no generated drift exists.
- Location: `scripts/`, `tsconfig.build.json`, `gsd-core/bin/lib/`, `hooks/dist/`, `skills/`
- Contains: TypeScript build, capability registry generation, plugin skill generation, hook distribution, manifest synchronization, and drift linters.
- Depends on: Authored sources in `src/`, `capabilities/`, `commands/gsd/`, and `hooks/`.
- Used by: npm build/publish and CI scripts declared in `package.json`.

## Data Flow

### Primary Workflow Request Path

1. A host exposes a command/skill such as `commands/gsd/plan-phase.md`, whose execution context points to `gsd-core/workflows/plan-phase.md` (`commands/gsd/plan-phase.md:1`).
2. The workflow invokes `gsd_run`, which locates and delegates to `gsd-core/bin/gsd-tools.cjs` (`gsd-core/bin/gsd_run:1`).
3. The CLI parses global flags, resolves the project/worktree/workstream, and normalizes dotted commands in `main()` (`gsd-core/bin/gsd-tools.cjs:3358`).
4. `runCommand()` tries first-party capability dispatch, consented overlay dispatch, and the core host dispatch table in that order (`gsd-core/bin/gsd-tools.cjs:3619`).
5. A family router such as `src/state-command-router.cts` builds handlers and delegates to `routeHubCommandFamily` (`src/state-command-router.cts:68`).
6. `src/command-routing-hub.cts` validates the family/subcommand, invokes the synchronous handler, converts throws to typed results, and optionally emits audit events (`src/command-routing-hub.cts:268`).
7. Domain modules resolve `.planning` paths with `src/planning-workspace.cts`, parse or mutate artifacts, and emit JSON/raw output through `src/io.cts` (`src/planning-workspace.cts:122`).

### Runtime Installation Flow

1. The npm `gsd-core` binary starts at `bin/install.js`, selects runtime(s), scope, and profile, and calls `installAllRuntimes()` (`bin/install.js:13148`).
2. `install()` resolves its descriptor-driven install plan from the generated capability registry (`bin/install.js:9873`; `src/runtime-config-adapter-registry.cts:179`).
3. Profile staging selects command and agent closure from `commands/gsd/` and `agents/`, while `src/runtime-artifact-layout.cts` and `src/runtime-artifact-conversion.cts` produce runtime-specific names/frontmatter/body content (`bin/install.js:10015`).
4. The installer copies `gsd-core/`, transformed commands/skills/agents, and the managed hook set from `hooks/`, then writes runtime configuration and an install manifest (`bin/install.js:9353`).
5. Finalization validates host configuration and retains rollback callbacks for migration/materialization failures (`bin/install.js:13185`).

### Capability Registration and Dispatch

1. Each first-party declaration lives at `capabilities/<id>/capability.json`; feature capabilities may name command router modules and runtime capabilities declare host/install axes (`capabilities/graphify/capability.json:1`; `capabilities/codex/capability.json:1`).
2. `scripts/gen-capability-registry.cjs` validates every declaration and writes `gsd-core/bin/lib/capability-registry.cjs` (`scripts/gen-capability-registry.cjs:396`).
3. `dispatchCapabilityCommand()` resolves a feature family, confines the router module to `gsd-core/bin/lib/`, and calls its named export synchronously (`gsd-core/bin/gsd-tools.cjs:370`).
4. `dispatchOverlayCapabilityCommand()` loads only accepted overlay declarations and realpath-confines router code to the capability install root (`gsd-core/bin/gsd-tools.cjs:501`).

### MCP / Programmatic Host Flow

1. A host launches `bin/gsd-mcp-server.js`, which delegates to `runServer()` in the compiled `src/mcp-server.cts` module (`bin/gsd-mcp-server.js:22`).
2. The server parses line-delimited JSON-RPC, exposes command and state tools, and uses `dispatchGsdCommand` or `createStateIO` (`src/mcp-server.cts:110`).
3. Command dispatch uses the same bounded `gsd-tools.cjs` subprocess seam as `pi/gsd.cjs` and `vscode/extension.js`; state requests use the negotiated adapter from `src/state-io.cts`.

**State Management:**

- Store durable project state as Markdown/JSON below `.planning/`, using the canonical path map returned by `planningPaths()` in `src/planning-workspace.cts`.
- Route active workstreams to `.planning/workstreams/<name>/` via `src/active-workstream-store.cts` and `GSD_WORKSTREAM`; keep root configuration available as an overlay through `src/config-loader.cts`.
- Guard concurrent `.planning` mutation with `withPlanningLock()` in `src/planning-workspace.cts`; use the state-specific lock/write helpers in `src/state.cts` and atomic write primitives in `src/write-set.cts` where those modules require narrower transactions.
- Keep host session/transient data in runtime-specific configuration homes, `.planning/.gsd-trace.jsonl`, or the OS temp directory as owned by `src/observability/logger.cts`, `src/io.cts`, and hook files in `hooks/`.

## Key Abstractions

**Capability Manifest:**

- Purpose: Declare a feature, runtime, or reviewer contribution and its commands, config schema, hooks, gates, profiles, and host behavior.
- Examples: `capabilities/graphify/capability.json`, `capabilities/codex/capability.json`, `capabilities/security/capability.json`
- Pattern: Validated declarative plugin descriptor compiled into a first-party registry and composable with consented overlays by `src/capability-loader.cts`.

**Command Family Router:**

- Purpose: Bind CLI arguments to a cohesive domain module without putting subcommand logic in `gsd-tools.cjs`.
- Examples: `src/state-command-router.cts`, `src/phase-command-router.cts`, `src/graphify-command-router.cts`
- Pattern: Build an explicit handler object and call `routeHubCommandFamily` from `src/cjs-command-router-adapter.cts`.

**Command Routing Hub:**

- Purpose: Standardize synchronous dispatch and the closed `UnknownCommand` / `InvalidArgs` / `HandlerRefusal` / `HandlerFailure` taxonomy.
- Examples: `src/command-routing-hub.cts`, `src/cjs-command-router-adapter.cts`
- Pattern: Per-family registry injection returning discriminated result objects; the hub never writes process output or exits.

**Planning Workspace:**

- Purpose: Convert a repository root plus optional project/workstream into canonical artifact paths and lock ownership.
- Examples: `src/planning-workspace.cts`, `src/active-workstream-store.cts`, `src/workstream.cts`
- Pattern: Functional path projection plus small injected adapter/clock seams for tests.

**Host Integration Axes:**

- Purpose: Negotiate command surface, dispatch depth/isolation, model control, hooks, state, artifacts, runtime, transport, and reasoning effort.
- Examples: `src/host-integration.cts`, `src/host-integration-sdk.cts`, `capabilities/codex/capability.json`
- Pattern: Closed vocabularies, fail-closed defaults, declarative runtime descriptors, and a frozen external SDK surface.

**Artifact Converter / Layout:**

- Purpose: Project canonical Claude-style command/agent content into the filename, frontmatter, nesting, and path syntax expected by each runtime.
- Examples: `src/runtime-artifact-conversion.cts`, `src/runtime-artifact-layout.cts`, `src/install-profiles.cts`
- Pattern: Descriptor-selected converter names and staged temporary trees consumed by `bin/install.js`.

**Workflow Fragment Composer:**

- Purpose: Apply conditional sections and size budgets before runtime-specific path/tool rewrites.
- Examples: `src/workflow-fragments.cts`, `src/context-composer.cts`, `capabilities/research/fragments/plan-pre.md`
- Pattern: Parse to typed fragments, compose a plan, then render; callers own final presentation.

## Entry Points

**Installer CLI:**

- Location: `bin/install.js`
- Triggers: npm binary `gsd-core` from `package.json`.
- Responsibilities: Install/uninstall/update artifacts for selected hosts, preserve user customizations, run installer migrations, and validate configuration.

**Runtime Tools CLI:**

- Location: `gsd-core/bin/gsd-tools.cjs`
- Triggers: npm binary `gsd-tools`, `gsd-core/bin/gsd_run`, workflow shell blocks, hooks, extensions, and MCP subprocess dispatch.
- Responsibilities: Resolve project context and execute all deterministic query/mutation command families.

**Portable Workflow Launcher:**

- Location: `gsd-core/bin/gsd_run`
- Triggers: Shell commands emitted in workflow Markdown.
- Responsibilities: Resolve its real install location and `exec node gsd-tools.cjs` with unchanged arguments.

**MCP Server:**

- Location: `bin/gsd-mcp-server.js`
- Triggers: npm binary `gsd-mcp-server` over stdio.
- Responsibilities: Serve JSON-RPC initialization, tool discovery, command invocation, and state I/O.

**OpenCode Plugin:**

- Location: `.opencode/plugins/gsd-core.js`
- Triggers: OpenCode plugin discovery from a package tree or installed config tree.
- Responsibilities: Register package-tree artifacts when needed and translate host events to shared hook subprocesses.

**pi Extension:**

- Location: `pi/gsd.cjs`
- Triggers: pi extension discovery after install projection.
- Responsibilities: Register imperative commands/tools/events and reuse the engine subprocess and shared hooks.

**VS Code Extension:**

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

**What happens:** A change is made directly in an ignored file such as `gsd-core/bin/lib/state.cjs` or `hooks/dist/gsd-context-monitor.js`.
**Why it's wrong:** `npm run build:lib` and `npm run build:hooks` overwrite the edit; CI drift checks compare the generated surfaces to `src/state.cts` and `hooks/gsd-context-monitor.js`.
**Do this instead:** Edit `src/state.cts` or the authored file under `hooks/`, then rebuild through scripts in `package.json`.

### Treating an Unconfigured Hub as the Global Engine

**What happens:** A host adapter calls `createHub()` with no per-family registry and expects every GSD command to be available.
**Why it's wrong:** `src/command-routing-hub.cts` is intentionally a narrow per-family dispatcher; an empty registry returns an unknown command and no fully populated global hub factory exists.
**Do this instead:** Use the shared bounded `dispatchGsdCommand` seam from `src/shell-command-projection.cts`, as `src/mcp-server.cts`, `pi/gsd.cjs`, and `vscode/extension.js` do.

### Hard-Coding `.planning` Paths in Domain Logic

**What happens:** A module joins `cwd/.planning/...` directly and ignores active project/workstream routing.
**Why it's wrong:** The operation can read or write the wrong state when `GSD_PROJECT` or `GSD_WORKSTREAM` is active, and it bypasses shared locking/path validation.
**Do this instead:** Use `planningDir()`, `planningRoot()`, or `planningPaths()` from `src/planning-workspace.cts` and the owning state/write helper.

### Adding a Runtime Through Scattered Conditionals

**What happens:** Host checks such as `if (runtime === 'new-host')` are added across `bin/install.js`, domain modules, and converters.
**Why it's wrong:** Install layout, hooks, capability negotiation, and artifact conversion drift because multiple independent runtime lists become authoritative.
**Do this instead:** Add `capabilities/<runtime>/capability.json`, implement only the converter/host binding seams absent from the descriptor vocabulary, and consume it through `src/runtime-config-adapter-registry.cts` and `src/runtime-artifact-layout.cts`.

### Updating Only One Command Surface

**What happens:** A workflow or command is added under only `skills/`, `commands/gsd/`, or `gsd-core/workflows/`.
**Why it's wrong:** Plugin installs, file-copy installs, dependency closure, and execution-context references disagree.
**Do this instead:** Author the command in `commands/gsd/<stem>.md`, its procedure in `gsd-core/workflows/<stem>.md`, update required capabilities/agents, and regenerate `skills/gsd-<stem>/SKILL.md` with `scripts/gen-plugin-skills.cjs`.

### Bypassing Capability Registration

**What happens:** A toggleable feature command is inserted directly into `HOST_COMMAND_ROUTERS` in `gsd-core/bin/gsd-tools.cjs`.
**Why it's wrong:** Feature activation, install profiles, federated config, and third-party-compatible registry behavior no longer govern the command.
**Do this instead:** Declare the family and router in `capabilities/<feature>/capability.json`; reserve `HOST_COMMAND_ROUTERS` for non-toggleable core commands.

## Error Handling

**Strategy:** Keep pure dispatch typed and non-throwing, translate expected CLI failures to reason-coded diagnostics at router/entry boundaries, and fail closed at trust, path, schema, and unsupported-host seams.

**Patterns:**

- Return the closed discriminated union from `src/command-routing-hub.cts`; convert unexpected throws to `HandlerFailure` and keep the hub free of stdout/stderr/process-exit behavior.
- Use `ERROR_REASON` and `error()` from `src/io.cts` for expected CLI failures; `--json-errors` produces parseable `{ ok, reason, message }` output.
- Throw `ExitError` and invoke `runMain()` from `src/cli-exit.cts` at standalone script boundaries that must set an exit code without tearing down pending output/cleanup.
- Surface unknown host/capability/schema/path states as errors or degraded results rather than inferring support; examples live in `src/host-integration.cts`, `src/runtime-config-adapter-registry.cts`, and `src/capability-loader.cts`.
- Keep hooks advisory and non-blocking only where the hook contract says failure must not stop the host; authored examples live in `hooks/gsd-context-monitor.js` and `hooks/gsd-update-banner.js`.

## Cross-Cutting Concerns

**Logging:** Dispatch is silent by default through the no-op logger in `src/observability/logger.cts`; opt-in `GSD_AUDIT=1` / configuration emits redacted JSONL to `.planning/.gsd-trace.jsonl` and structured error events to stderr.

**Validation:** Validate at boundaries through `src/config-schema.cts`, `gsd-core/bin/lib/capability-validator.cjs`, `src/security.cts`, `src/unusable-input.cts`, `src/worktree-safety.cts`, schema-specific parsers, and generated-drift checks under `scripts/`.

**Authentication:** No end-user authentication subsystem exists in `src/`; external capability installation uses explicit trust/consent and content hashes in `src/capability-trust.cts`, `src/capability-consent.cts`, `src/capability-ledger.cts`, and `src/capability-lock.cts`.

**Security:** Confine paths and subprocess argv through `src/security.cts` and `src/shell-command-projection.cts`; sanitize untrusted prompt/Markdown inputs before orchestration and realpath-confine overlay code in `gsd-core/bin/gsd-tools.cjs`.

**Configuration:** Treat `gsd-core/bin/shared/config-schema.manifest.json` and `gsd-core/bin/shared/config-defaults.manifest.json` as canonical shared data, and merge capability-owned keys through `src/federated-config.cts` / `src/config-loader.cts`.

---

*Architecture analysis: 2026-08-02*
