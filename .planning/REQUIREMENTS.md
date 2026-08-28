# Requirements: GSD Core Contributions

**Defined:** 2026-08-28
**Milestone:** v1.2 Executor Session Survivability
**Core Value:** Every contribution must make GSD more reliable without regressing its supported runtime and generated-artifact contracts.

## v1.2 Requirements

### Executor Session Survivability

- [ ] **SESSION-01**: A host integrator can configure executor dispatch for a session that does not outlive its turn, so `execute-phase` waits for each executor rather than orphaning asynchronous work.
- [ ] **SESSION-02**: A project with the setting absent or enabled retains the current background-dispatch behavior.
- [ ] **SESSION-03**: A contributor can discover the host-session assumption and opt-out behavior in an ADR and configuration reference.

### Verification

- [ ] **QUALITY-03**: A maintainer can verify both configuration values through behavioral configuration and workflow/projection tests, including negative controls for the opposite dispatch direction.
- [ ] **COMPAT-01**: Generated runtime artifacts remain synchronized with the canonical workflow after the dispatch condition is added.

## Future Requirements

- **STATE-03**: A contributor can invoke a documented `state.verify-against-disk` command for an explicit state-versus-disk verification pass.
- **PROGRESS-01**: A contributor receives a progress percentage that remains truthful when phase plan and summary counts do not correspond (ledger item 11).

## Out of Scope

| Feature | Reason |
|---------|--------|
| #3552 protected-branch warnings | Separate upstream PR; this milestone is dedicated to #3159. |
| Shape 2 dispatch/worktree rewrite | #3178 resolved it as orthogonal to session survivability and unavailable on the harness-worktree path. |
| Orchestrator-owned SUMMARY.md recovery | Complementary hardening, not part of the maintainer-approved #3159 scope. |
| DevFlow orchestration | Explicitly paused by the project owner. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SESSION-01 | Phase 3 | Pending |
| SESSION-02 | Phase 3 | Pending |
| SESSION-03 | Phase 3 | Pending |
| QUALITY-03 | Phase 3 | Pending |
| COMPAT-01 | Phase 3 | Pending |

**Coverage:**

- v1.2 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0 ✓

---
*Requirements defined: 2026-08-28*
*Last updated: 2026-08-28 after v1.2 milestone initialization*
