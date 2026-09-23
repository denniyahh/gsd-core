#!/usr/bin/env bash
set -euo pipefail

# Resumes work on a task branch after a pause:
# 1. Inspects local git working tree hygiene
# 2. Checks divergence against upstream/next
# 3. Pulls fresh personal planning & tooling (sync:env)
# 4. Verifies memtrace service & Mac runner connectivity
# 5. Verifies ADR-857 workflow byte ceilings
# 6. Displays active issue status & focused test guidance

SCRATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Resuming Task in: $ROOT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "📌 Current branch: $BRANCH"

# 1. Local Working Tree Check
DIRTY_COUNT="$(git status --porcelain | grep -v '^[?][?]' | wc -l || true)"
UNTRACKED_COUNT="$(git status --porcelain | grep '^[?][?]' | wc -l || true)"
if [ "$DIRTY_COUNT" -gt 0 ]; then
  echo "⚠️  Working tree has $DIRTY_COUNT uncommitted modification(s):"
  git status --short
elif [ "$UNTRACKED_COUNT" -gt 0 ]; then
  echo "ℹ️  Working tree is clean, but has $UNTRACKED_COUNT untracked file(s)."
else
  echo "✅ Working tree is clean."
fi
echo ""

# 2. Upstream Divergence Check
echo "🔍 Fetching latest upstream/next..."
git fetch upstream next --quiet 2>/dev/null || echo "⚠️  Could not fetch upstream/next (offline?)"

if git rev-parse --verify upstream/next >/dev/null 2>&1; then
  BEHIND="$(git rev-list --count HEAD..upstream/next)"
  AHEAD="$(git rev-list --count upstream/next..HEAD)"

  if [ "$BEHIND" -gt 0 ]; then
    echo "⚠️  Branch is $BEHIND commit(s) BEHIND upstream/next!"
    echo "    Recent upstream commits:"
    git log -n 3 --oneline upstream/next
    echo "    👉 To align with upstream, consider running: git rebase upstream/next"
  else
    echo "✅ Up to date with upstream/next (0 commits behind)."
  fi

  if [ "$AHEAD" -gt 0 ]; then
    echo "🌿 Branch has $AHEAD local commit(s) ahead of upstream/next."
  fi
fi
echo ""

# 3. Sync Personal Environment
if [ -x "$SCRATCH_DIR/sync-personal-env.sh" ]; then
  "$SCRATCH_DIR/sync-personal-env.sh" pull
  echo ""
fi

# 4. Service & Runner Health
if command -v systemctl >/dev/null 2>&1; then
  if systemctl --user is-active --quiet memtrace 2>/dev/null; then
    echo "🧠 memtrace.service is active and healthy."
  else
    echo "⚠️  memtrace.service is NOT running. Run: systemctl --user start memtrace"
  fi
fi

if ssh -T -q -o ConnectTimeout=2 -o BatchMode=yes mac exit 0 2>/dev/null; then
  echo "🍏 Remote Mac runner ('mac') is awake and reachable."
else
  echo "⚠️  Remote Mac runner ('mac') is unreachable. Check network/wake status."
fi
echo ""

# 5. Workflow Budget Check
if [ -x "$SCRATCH_DIR/check-workflow-budgets.sh" ]; then
  "$SCRATCH_DIR/check-workflow-budgets.sh"
  echo ""
fi

# 6. Issue Context
if [[ "$BRANCH" =~ ([0-9]+) ]]; then
  ISSUE_NUM="${BASH_REMATCH[1]}"
  if command -v gh >/dev/null 2>&1; then
    echo "📋 Upstream Issue #$ISSUE_NUM status:"
    gh issue view "$ISSUE_NUM" --repo open-gsd/gsd-core --json state,title,url --template '   Title: {{.title}}{{"\n"}}   State: {{.state}}{{"\n"}}   URL:   {{.url}}{{"\n"}}' 2>/dev/null || echo "   (Could not query issue #$ISSUE_NUM)"
    echo ""
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 Ready to proceed with work!"
echo "   Run focused tests on Mac:  mise run test:mac <file>"
echo "   Inspect active diff:        git diff upstream/next...HEAD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
