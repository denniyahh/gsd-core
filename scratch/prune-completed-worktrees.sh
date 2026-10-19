#!/usr/bin/env bash
set -euo pipefail

# Automatically discovers and prunes git worktrees for PRs that have been merged or closed upstream.
# Safe & hermetic: skips primary checkouts and uncommitted/dirty working trees.

REPO="open-gsd/gsd-core"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Inspecting Worktrees for Merged/Closed PRs..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! command -v gh >/dev/null 2>&1; then
  echo "❌ Error: gh CLI is required to check PR statuses." >&2
  exit 1
fi

# Fetch all authored PRs (open, closed, merged)
PRS_JSON="$(gh pr list --repo "$REPO" --author "@me" --state all --limit 50 --json number,title,headRefName,state,url 2>/dev/null || echo "[]")"

# Read worktree list in porcelain format
# format:
# worktree <path>
# HEAD <sha>
# branch refs/heads/<branch>
# (empty line)

WORKTREE_PATH=""
WORKTREE_BRANCH=""
PRUNED_COUNT=0

while IFS= read -r line; do
  if [[ "$line" =~ ^worktree\ (.*) ]]; then
    WORKTREE_PATH="${BASH_REMATCH[1]}"
    WORKTREE_BRANCH=""
  elif [[ "$line" =~ ^branch\ refs/heads/(.*) ]]; then
    WORKTREE_BRANCH="${BASH_REMATCH[1]}"
  elif [ -z "$line" ] && [ -n "$WORKTREE_PATH" ]; then
    # Skip main checkout and personal workspace
    BASENAME="$(basename "$WORKTREE_PATH")"
    if [ "$BASENAME" = "gsd-core" ] || [ "$BASENAME" = "gsd-core-personal-workspace" ] || [ "$WORKTREE_BRANCH" = "next" ] || [ "$WORKTREE_BRANCH" = "personal/workspace" ]; then
      WORKTREE_PATH=""
      WORKTREE_BRANCH=""
      continue
    fi

    if [ -n "$WORKTREE_BRANCH" ]; then
      # Find matching PR by headRefName
      PR_INFO="$(echo "$PRS_JSON" | jq -r --arg b "$WORKTREE_BRANCH" '.[] | select(.headRefName == $b) | "\(.number)\t\(.state)\t\(.title)\t\(.url)"' | head -n 1)"
      if [ -n "$PR_INFO" ]; then
        PR_NUM="$(echo "$PR_INFO" | cut -f1)"
        PR_STATE="$(echo "$PR_INFO" | cut -f2)"
        PR_TITLE="$(echo "$PR_INFO" | cut -f3)"
        PR_URL="$(echo "$PR_INFO" | cut -f4)"

        if [ "$PR_STATE" = "MERGED" ] || [ "$PR_STATE" = "CLOSED" ]; then
          STATE_ICON="🟣"
          [ "$PR_STATE" = "CLOSED" ] && STATE_ICON="⚪"
          echo "$STATE_ICON PR #$PR_NUM is $PR_STATE ($PR_TITLE)"
          # Check if worktree is clean
          DIRTY="$(git -C "$WORKTREE_PATH" status --porcelain 2>/dev/null | grep -v '^[?][?]' || true)"
          if [ -z "$DIRTY" ]; then
            echo "   Removing clean worktree: $WORKTREE_PATH"
            git worktree remove "$WORKTREE_PATH" --force
            echo "   Deleting local branch: $WORKTREE_BRANCH"
            git branch -D "$WORKTREE_BRANCH" 2>/dev/null || true
            # Best effort delete on origin
            git push origin --delete "$WORKTREE_BRANCH" 2>/dev/null || true
            echo "   ✅ Pruned $PR_STATE PR #$PR_NUM worktree ($WORKTREE_PATH)"
            PRUNED_COUNT=$((PRUNED_COUNT + 1))
          else
            echo "   ⚠️  Worktree has uncommitted tracked changes; skipping removal:"
            git -C "$WORKTREE_PATH" status --short
          fi
        else
          echo "🟢 PR #$PR_NUM is OPEN ($PR_TITLE) -> keeping active worktree: $WORKTREE_PATH"
        fi
      fi
    fi

    WORKTREE_PATH=""
    WORKTREE_BRANCH=""
  fi
done < <(git worktree list --porcelain; echo "")

# Clean up any orphaned local branches for merged/closed PRs without active worktrees
ORPHANED_BRANCHES=0
ACTIVE_BRANCHES="$(git worktree list --porcelain | grep '^branch refs/heads/' | sed 's|^branch refs/heads/||')"

while read -r branch; do
  [ -z "$branch" ] && continue
  case "$branch" in
    main|next|personal/*) continue ;;
    *)
      PR_INFO="$(echo "$PRS_JSON" | jq -r --arg b "$branch" '.[] | select(.headRefName == $b) | "\(.number)\t\(.state)\t\(.title)"' | head -n 1)"
      if [ -n "$PR_INFO" ]; then
        B_NUM="$(echo "$PR_INFO" | cut -f1)"
        B_STATE="$(echo "$PR_INFO" | cut -f2)"
        B_TITLE="$(echo "$PR_INFO" | cut -f3)"
        if [ "$B_STATE" = "MERGED" ] || [ "$B_STATE" = "CLOSED" ]; then
          if ! echo "$ACTIVE_BRANCHES" | grep -qx "$branch"; then
            echo "🧹 Deleting orphaned local branch for $B_STATE PR #$B_NUM ($branch): $B_TITLE"
            git branch -D "$branch" 2>/dev/null || true
            ORPHANED_BRANCHES=$((ORPHANED_BRANCHES + 1))
          fi
        fi
      fi
      ;;
  esac
done < <(git for-each-ref --format='%(refname:short)' refs/heads/)

echo ""
TOTAL_CLEANED=$((PRUNED_COUNT + ORPHANED_BRANCHES))
if [ "$TOTAL_CLEANED" -gt 0 ]; then
  echo "🎉 Pruned $PRUNED_COUNT worktree(s) and $ORPHANED_BRANCHES orphaned branch(es)."
else
  echo "✅ No merged or closed PR worktrees or orphaned branches required pruning."
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
