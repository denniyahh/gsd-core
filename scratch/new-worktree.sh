#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "Usage: mise run start:wt <type> <issue-number> <slug>" >&2
  echo "Example: mise run start:wt fix 3158 branch-guard" >&2
  exit 1
fi

TYPE="$1"
ISSUE="$2"
SLUG="$3"
BRANCH="${TYPE}/${ISSUE}-${SLUG}"
ROOT="$(git rev-parse --show-toplevel)"
PARENT_DIR="$(dirname "$ROOT")"
WORKTREE_DIR="${PARENT_DIR}/gsd-core-${SLUG}"

echo "🔄 Fetching latest upstream/next..."
git fetch upstream next

if [ -d "$WORKTREE_DIR" ]; then
  echo "❌ Error: Target worktree directory already exists: $WORKTREE_DIR" >&2
  exit 1
fi

echo "🌿 Creating worktree at $WORKTREE_DIR on branch $BRANCH from upstream/next..."
git worktree add -b "$BRANCH" "$WORKTREE_DIR" upstream/next

echo "📦 Injecting personal workflow capabilities (mise.toml, scratch/ci-mac.sh, .agents/)..."
cp "$ROOT/mise.toml" "$WORKTREE_DIR/mise.toml" 2>/dev/null || true
mkdir -p "$WORKTREE_DIR/scratch"
cp "$ROOT/scratch/ci-mac.sh" "$WORKTREE_DIR/scratch/" 2>/dev/null || true
if [ -d "$ROOT/.agents" ]; then
  cp -r "$ROOT/.agents" "$WORKTREE_DIR/" 2>/dev/null || true
fi

echo "✅ Worktree initialized with Mac CI runner & personal workflow!"
echo "👉 Next steps:"
echo "   cd $WORKTREE_DIR"
echo "   mise run check"
