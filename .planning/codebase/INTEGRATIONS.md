# External Integrations

**Analysis Date:** 2026-08-02

## APIs & External Services

**AI Coding Hosts:**
- Claude Code, OpenCode, Kilo, Codex, Kimi CLI/Kimi Code, GitHub Copilot, Antigravity, Cursor, Windsurf/Devin Desktop, Augment, Trae, Qwen Code, Hermes Agent, Cline, CodeBuddy, and ZCode - `bin/install.js` projects shared commands, skills, agents, hooks, plugins, and settings into host-specific layouts declared in `capabilities/<runtime>/capability.json`.
  - SDK/Client: File-based host configuration, native plugin shims in `.opencode/plugins/gsd-core.js` and `pi/gsd.cjs`, hook scripts in `hooks/`, and the local MCP process in `bin/gsd-mcp-server.js`; there is no common remote host SDK.
  - Auth: Delegated to each installed host CLI/application; GSD does not collect host credentials in `bin/install.js` or `src/host-integration.cts`.
- VS Code and Pi - Additional host-interface descriptors live in `capabilities/vscode/capability.json` and `capabilities/pi/capability.json`; Pi uses the native extension `pi/gsd.cjs`, while VS Code is modeled as an MCP-capable sandboxed-web/palette host.
  - SDK/Client: Native extension or MCP transport declared in the relevant `capabilities/*/capability.json`.
  - Auth: Delegated to the host.

**Cross-AI Review:**
- Gemini CLI, Claude CLI, Codex CLI, CodeRabbit CLI, OpenCode, Qwen Code, Cursor Agent, Antigravity CLI, Kimi Code, Ollama, LM Studio, and llama.cpp - Reviewer lane declarations and invocation contracts are centralized in `src/review-lane-descriptor.cts`, resolved by `src/review-lane-invocation.cts`, and executed by `src/review-lane-runner.cts` through `gsd-core/bin/gsd-tools.cjs`.
  - SDK/Client: Bounded CLI subprocesses for external agents; built-in `fetch` against OpenAI-compatible `/v1/models` and `/v1/chat/completions` endpoints for local model servers.
  - Auth: External CLI credentials are inherited from each CLI; the default local endpoints in `src/review-lane-descriptor.cts` are unauthenticated localhost URLs.
- Local OpenAI-compatible servers - Ollama defaults to `http://localhost:11434`, LM Studio to `http://localhost:1234`, and llama.cpp to `http://localhost:8080`, configurable with `review.ollama_host`, `review.lm_studio_host`, and `review.llama_cpp_host` in `.planning/config.json` as consumed by `src/review-lane-descriptor.cts`.
  - SDK/Client: Node built-in `fetch` in the review-lane route of `gsd-core/bin/gsd-tools.cjs`.
  - Auth: Not configured by GSD; use host-local controls if the endpoint is exposed beyond localhost.

**Research & Web Search:**
- Brave Search API - The directly implemented remote search client in `src/commands.cts` calls `https://api.search.brave.com/res/v1/web/search`, with bounded timeout, retry/backoff for 429/5xx responses, and built-in `fetch`.
  - SDK/Client: Node built-in `fetch` in `src/commands.cts`.
  - Auth: `BRAVE_API_KEY`; optional timeout override `GSD_WEBSEARCH_TIMEOUT_MS`.
- Context7, Ref, Jina, Exa, Tavily, Perplexity, Firecrawl, and host WebSearch - `src/research-provider.cts` plans a provider waterfall and cache usage; these providers are expected as host tools/configured capabilities rather than direct SDK imports in this repository.
  - SDK/Client: Host-provided tools selected by `src/research-provider.cts`; only Brave has a first-party HTTP implementation in `src/commands.cts`.
  - Auth: Availability detection uses `REF_API_KEY`, `JINA_API_KEY`, `EXA_API_KEY`, `TAVILY_API_KEY`, `PERPLEXITY_API_KEY`, and `FIRECRAWL_API_KEY` in `src/config.cts`, or corresponding key files beneath `~/.gsd/`.

**Capability Distribution:**
- Git remotes, npm packages, HTTPS tarballs, and local directories - Third-party capabilities are classified, staged, validated, and version-checked by `src/capability-source.cts` and promoted/updated by `src/capability-lifecycle.cts`.
  - SDK/Client: Bounded `git clone`/`git ls-remote`, `npm pack`/`npm view`, system `tar`, and Node HTTPS transport through the shell projection seam.
  - Auth: Ambient Git/npm configuration outside the repository; no credentials are embedded in capability manifests under `capabilities/`.
- npm registry - GSD checks its own latest `latest`/`next` versions through `npm view` in `gsd-core/bin/check-latest-version.cjs`; `src/package-legitimacy.cts` also queries npm registry metadata when evaluating package legitimacy.
  - SDK/Client: npm CLI and Node HTTPS.
  - Auth: None for public reads; release writes use npm trusted publishing in `.github/workflows/release.yml`.

**Release & Community Services:**
- GitHub - Source hosting, Actions CI, release branches/tags, GitHub Releases, issue/PR automation, and repository maintenance are defined throughout `.github/workflows/`; release scripts use the `gh` CLI from `.github/workflows/release.yml`.
  - SDK/Client: Git CLI, `gh` CLI, `actions/github-script`, and pinned GitHub Actions in `.github/workflows/`.
  - Auth: `GITHUB_TOKEN`/`GH_TOKEN`; elevated automation may use the repository secret exposed as `GSD_BOT_PR_TOKEN` in `.github/workflows/release.yml` and `.github/workflows/auto-backmerge.yml`.
- Discord - Release announcements are posted by `scripts/release-notes/discord-release-summary.cjs`, triggered from `.github/workflows/discord-changelog.yml` and `.github/workflows/release.yml`.
  - SDK/Client: Node built-in `fetch`.
  - Auth: `DISCORD_WEBHOOK_URL`, populated from the GitHub Actions secret named in the workflow.

**Local Tool Protocol:**
- Model Context Protocol - `src/mcp-server.cts` and `bin/gsd-mcp-server.js` expose command invocation plus `.planning` state read/write as line-delimited JSON-RPC 2.0 over stdio.
  - SDK/Client: Hand-rolled protocol implementation; no MCP SDK dependency.
  - Auth: None; the server is spawned locally and communicates through stdin/stdout rather than a listening socket.

## Data Storage

**Databases:**
- Not detected - No database server, ORM, SQL driver, or remote data-store client is declared in `package.json`; the state abstraction defaults to filesystem storage in `src/state-io.cts`.
  - Connection: Not applicable.
  - Client: Node filesystem APIs in `src/state-io.cts`, `src/state.cts`, and related modules.

**File Storage:**
- Project-local filesystem - Planning state, roadmaps, requirements, phases, workstreams, caches, audit traces, and generated artifacts live under `.planning/` through path and state owners such as `src/planning-workspace.cts`, `src/state.cts`, and `src/artifacts.cts`.
- User-local filesystem - Defaults, installed capabilities, API-key files, and shared research cache live under `~/.gsd/` as resolved by `src/config.cts`, `src/capability-source.cts`, and `src/research-store.cts`.
- Runtime configuration homes - The installer writes only to the selected target's declared config home or local project directory, based on `capabilities/<runtime>/capability.json` and `bin/install.js`.

**Caching:**
- JSON file cache - Research results use `.planning/research/.cache/` for project-tier data and `~/.gsd/research-cache/` for user-tier data in `src/research-store.cts`.
- npm/CI caches - GitHub Actions uses npm caching and an emitted-baseline cache in `.github/workflows/test.yml`; these are build infrastructure, not application data.
- No external cache service - No Redis, Memcached, or managed cache client appears in `package.json`.

## Authentication & Identity

**Auth Provider:**
- No application user authentication - GSD is a local CLI/package and has no accounts, sessions, or identity database in `src/` or `package.json`.
  - Implementation: External service identity is delegated to installed CLIs and CI-provided tokens; API integrations accept optional environment variables or `~/.gsd/` key files through `src/config.cts`.
- GitHub Actions identity - Workflow permissions are job-scoped under `.github/workflows/`; npm publication uses GitHub OIDC trusted publishing with `id-token: write` in `.github/workflows/release.yml`.
  - Implementation: `GITHUB_TOKEN`/`GH_TOKEN`, optional bot token fallback, and npm provenance flags; no npm token is stored in repository configuration.

## Monitoring & Observability

**Error Tracking:**
- None - No Sentry, Datadog, OpenTelemetry, Rollbar, Bugsnag, Honeycomb, or equivalent SDK is declared in `package.json` or imported by `src/`.

**Logs:**
- CLI stderr/stdout - Commands return structured output through `gsd-core/bin/gsd-tools.cjs`; dispatch failures emit redacted JSON lines to stderr via `src/observability/logger.cts`.
- Optional local audit trail - `GSD_AUDIT=1` or `audit.enabled: true` appends redacted JSONL events to `.planning/.gsd-trace.jsonl`; argument capture additionally requires `GSD_AUDIT_ARGS=1`, as implemented in `src/observability/logger.cts` and `src/observability/redaction.cts`.
- CI logs and artifacts - Test, coverage, mutation, install-smoke, security, and release evidence is retained by workflows under `.github/workflows/` using GitHub Actions logs, caches, and uploaded artifacts.

## CI/CD & Deployment

**Hosting:**
- npm public registry - `@opengsd/gsd-core` is published with public access and provenance from `.github/workflows/release.yml`; package contents and binaries are controlled by `package.json`.
- GitHub Releases - Release candidates and stable tags/releases are created through `gh release` in `.github/workflows/release.yml`.
- User/runtime machines - Installed production files execute locally inside supported AI coding hosts; `bin/install.js` owns global/local installation and `capabilities/*/capability.json` owns target layouts.

**CI Pipeline:**
- GitHub Actions - `.github/workflows/test.yml` runs scoped and full multi-OS Node 22/24 tests, lint, sharded coverage, QA loop checks, and required-status aggregation.
- Security and quality gates - `.github/workflows/security-scan.yml`, `.github/workflows/mutation.yml`, `.github/workflows/install-smoke.yml`, `.github/workflows/changeset-required.yml`, and `.github/workflows/docs-required.yml` cover scanning, mutation testing, package installation, changesets, and documentation contracts.
- Repository automation - Issue/PR labeling, validation, cleanup, duplicate handling, version gates, stale cleanup, branch automation, and back-merges are implemented as workflows under `.github/workflows/`.
- Release pipeline - `.github/workflows/release.yml` validates versions, builds and tests artifacts, publishes `next` or `latest`, creates GitHub Releases, posts Discord announcements, and verifies the published npm version.

## Environment Configuration

**Required env vars:**
- Core local use: none - `bin/install.js`, `gsd-core/bin/gsd-tools.cjs`, and filesystem state work without external credentials.
- Direct Brave web search: `BRAVE_API_KEY`; timeout tuning: `GSD_WEBSEARCH_TIMEOUT_MS` in `src/commands.cts`.
- Optional research-provider discovery: `EXA_API_KEY`, `TAVILY_API_KEY`, `PERPLEXITY_API_KEY`, `FIRECRAWL_API_KEY`, `REF_API_KEY`, and `JINA_API_KEY` in `src/config.cts`.
- Claude Workflow backend override: `GSD_AGENT_SDK_VERSION` in `src/claude-orchestration-command-router.cts`; the installed package version is used when the override is absent.
- GitHub CI/release: `GITHUB_TOKEN` or `GH_TOKEN`; workflows may map the `GSD_BOT_PR_TOKEN` secret in `.github/workflows/release.yml` and `.github/workflows/auto-backmerge.yml`.
- Discord announcements: `DISCORD_WEBHOOK_URL` in `scripts/release-notes/discord-release-summary.cjs`.
- Runtime config overrides: variables such as `CLAUDE_CONFIG_DIR`, `OPENCODE_CONFIG_DIR`, `CODEX_HOME`, `KIMI_CONFIG_DIR`, `CURSOR_CONFIG_DIR`, and peer host variables declared in `capabilities/*/capability.json` and surfaced by `bin/install.js`.

**Secrets location:**
- No `.env` files are present in the repository; do not add provider values to `package.json`, `.planning/config.json`, or committed capability manifests.
- Local provider credentials may be supplied via process environment or dedicated key files beneath `~/.gsd/`, whose names and existence checks are defined in `src/config.cts`; values are read at runtime and are not part of this map.
- GitHub secrets remain in repository/environment secret storage and are referenced symbolically by `.github/workflows/release.yml`, `.github/workflows/discord-changelog.yml`, and `.github/workflows/auto-backmerge.yml`.

## Webhooks & Callbacks

**Incoming:**
- No application webhook endpoints - The local MCP server in `src/mcp-server.cts` uses stdio only, and no HTTP server framework or listening route exists in `package.json` or `src/`.
- GitHub event triggers - Repository automation reacts declaratively to pull requests, pushes, issues, reviews, comments, releases, schedules, and manual dispatch in `.github/workflows/`; GitHub owns the inbound webhook surface.

**Outgoing:**
- Discord release webhook - `scripts/release-notes/discord-release-summary.cjs` posts release summaries when invoked by `.github/workflows/discord-changelog.yml` or `.github/workflows/release.yml`.
- GitHub API operations - `gh` and `actions/github-script` create releases and manage issues, PRs, labels, approvals, branches, and comments from workflows under `.github/workflows/`.
- No product callback endpoints - Review lanes return through child-process stdout/files or local OpenAI-compatible HTTP responses in `src/review-lane-runner.cts`; capability sources are pull-based in `src/capability-source.cts`.

---

*Integration audit: 2026-08-02*
