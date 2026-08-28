# Retrospective: PR #3876 & Upstream Fix #3921 (Issue #3738)

**Topic:** Antigravity Global Install Path (`~/.gemini/config` vs `~/.gemini/antigravity`)  
**Context:** Upstream maintainer closed PR #3876 and landed the resolution in PR #3921 (commit `39673ae9`).  
**Purpose:** Record project-specific architectural invariants and general engineering practices learned from this review.

---

## 1. GSD Core Project-Specific Lessons

### A. Runtime Identity vs. Artifact Distribution (`configHome` vs. `artifactLayout[].home`)
- **The Concept:** In GSD Core, `configHome` defines the **entire runtime home** (governing configuration, settings JSON, hook bindings, launcher shims, migrations, and runtime identity).
- **The Lesson:** When a host runtime (like Antigravity or Codex) discovers global tools/agents in a separate folder from its settings, **do not change `configHome`**. Instead, use the ADR-1239 `home` override property on the global artifact layout descriptors:
  ```json
  "artifactLayout": {
    "global": [
      {
        "kind": "skills",
        "destSubpath": "skills",
        "prefix": "gsd-",
        "home": ".gemini/config",
        "converter": "convertClaudeCommandToAntigravitySkill"
      }
    ]
  }
  ```
- **Prior Art:** Always look at existing runtime descriptors (`capabilities/*/capability.json`, notably `codex` which uses `home: ".agents"`) before refactoring runtime resolver roots.

### B. Artifact Relocation Requires an Installer Migration
- **The Concept:** Moving the destination of installed files creates orphaned artifacts in existing installations.
- **The Lesson:** Whenever the default artifact path moves, implement an **Installer Migration** (e.g. `src/installer-migrations/010-antigravity-retire-confighome-artifacts.cts`) to:
  1. Detect manifest-managed legacy files in the retired location.
  2. Back up user-modified files before removal.
  3. Clean up obsolete GSD files while preserving unmanifested third-party files.
  4. Prune now-empty parent containers cleanly.

### C. Multi-Surface Resolver Invariants
- Runtime paths in GSD Core are consumed across multiple coupled systems:
  1. `capabilities/<runtime>/capability.json` & generated `capability-registry.cjs`.
  2. `src/runtime-homes.cts` (including helper candidate lists like `detectAntigravityDirAmbiguity`).
  3. `src/update-context.cts` and workflow discovery logic.
  4. `tests/helpers/install-shared.cjs` (test fixture lookup tables).
- Missing any one of these surfaces (e.g. omitting `'config'` from `detectAntigravityDirAmbiguity`) creates broken diagnostic reports and silent misdirection.

### D. Launcher Shim Fallback Chains
- In `gsd-core/workflows/_runtime-launcher.snippet.sh`, never *replace* a legacy path with a new path.
- Always **prepend** the new path to the fallback search chain so existing global installations running `/gsd-update` do not have their execution shims broken.

### E. Dual-Converter Synchronization (ADR-1508)
- GSD maintains identical content converter logic in `src/runtime-artifact-conversion.cts` (for runtime compilation) and `bin/install.js` (for standalone installation).
- Path rewrites (e.g. rewriting `~/.claude/skills` to `~/.gemini/config/skills`) must be applied symmetrically to both files.

### F. Changeset Formatting Rules
- Changeset fragments in `.changeset/*.md` must strictly follow the canonical format from `CONTRIBUTING.md`:
  `**<bold user-visible summary>** — <symptom-led explanation>.`
- Omission of the bold lead or terminating period violates repository linting conventions.

---

## 2. General Engineering & Contribution Best Practices

### A. Hermetic Testing & Negative Controls (Eliminate Dirty-Host Bias)
- **The Trap:** Tests passed locally because the local development machine had `~/.gemini/antigravity` physically present on disk.
- **The Rule:** Tests verifying filesystem fallbacks, installation paths, or default directory resolution **must sandbox `$HOME` and `$USERPROFILE`** to fresh temporary directories.
- **Negative Control:** Always test the negative condition (e.g., verifying behavior when the legacy directory does *not* exist). A test passing only because of ambient host state is a proxy illusion.

### B. Never "Bless" a Breaking Test
- When a change causes existing regression tests to fail:
  - **Wrong response:** Modifying or deleting the test expectation to silence the error (e.g. updating parity strings or deleting table rows).
  - **Right response:** Ask *what safety invariant this test was designed to protect*. A failing test is an alert that a contract or backward-compatibility guarantee was broken.

### C. Design for Upgrades, Not Just Clean Installs
- Greenfield development only considers where files belong on a clean machine.
- Production-grade engineering considers the full lifecycle:
  - What happens when a user updates from an older version?
  - Do older launchers know how to resolve the new paths?
  - Are old files safely cleaned up or will they cause stale shadowing?

### D. Use Co-Change and Dependency Analysis to Scope Blast Radius
- Before submitting changes to foundational configurations:
  - Inspect git co-change history (`git log --stat` on the target module) to see what test helpers, registry generators, and documentation files historically move together.
  - Review documentation across all surfaces (including localized `docs/{locale}/` trees).

### E. Strict CI Gate Discipline
- Never declare a PR ready or request maintainer review until **100% of CI matrix jobs** (Linux, macOS, Windows) are completely green.
- Investigate single-job or OS-specific failures as real signal rather than dismissing them as unrelated flakes.

### F. Strict PR Scope Isolation ("One Concern per PR")
- Avoid bundling drive-by dependency or lockfile changes (`package-lock.json`) with behavioral fixes.
- Keep diffs surgical so reviewers can verify intent without deciphering unrelated changes.
