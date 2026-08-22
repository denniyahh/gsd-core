# Mac CI Handoff: linked-worktree metadata failure

**Observed:** 2026-08-18 on `feat/3552-protected-branch-warnings`

## Reproduction

Run from the contribution worktree:

```bash
./scratch/ci-mac.sh "npm run check:env && npm run build && npm run lint:ci && npm test"
```

The Mac runner now sees Node 24 correctly when the injected `mise.toml` pins `node = "24"`.
Environment checks and the full build pass. `lint:ci` then fails at
`scripts/lint-compiled-artifact-sync.cjs`:

```text
fatal: not a git repository: /var/home/denniyahh/Github/gsd-core/.git/worktrees/gsd-core-protected-branch-warnings
```

## Root cause

`ci-mac.sh` rsyncs the linked worktree's `.git` file to macOS. That file points to the Linux
absolute worktree-admin path under `/var/home/denniyahh/Github/gsd-core/.git/worktrees/`, which
does not exist on the Mac. Git-dependent checks therefore fail after the code has been copied.

## Impact

This is a CI helper portability problem, not an #3552 source failure. It prevents the Mac runner
from completing `lint:ci` and the test suite. The local Linux run already passed the focused
#3552 tests, build, generated-sync, drift-ack, and owner-suite checks.

## Likely fix boundary

Update `scratch/ci-mac.sh` so the remote checkout has valid Git metadata—e.g. sync the source tree
without copying a host-specific linked-worktree `.git` file, then initialize or clone a valid
remote-side repository before running Git-dependent commands. Re-test from a linked worktree and
from a normal checkout; the fix must not weaken the PR publish-boundary guard.
