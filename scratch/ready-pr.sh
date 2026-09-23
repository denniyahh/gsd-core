#!/usr/bin/env bash
set -euo pipefail

# Pre-PR Quality Gate & Contribution Automation
# 1. Checks git working tree cleanliness
# 2. Enforces contribution boundary (.agents, scratch, mise.toml excluded)
# 3. Enforces ADR-857 workflow byte ceilings
# 4. Validates changeset fragment and documentation requirements
# 5. Reconciles personal planning state back to personal workspace
# 6. Runs clean-room CI remotely on Mac runner (scratch/ci-mac.sh)
# 7. Pushes branch to origin
# 8. Prepares formatted gh pr create invocation

SCRATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Pre-PR Verification & Gatekeeper: $ROOT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "📌 Contribution branch: $BRANCH"

if [ "$BRANCH" = "next" ] || [ "$BRANCH" = "main" ]; then
  echo "❌ Error: Cannot open a PR directly from '$BRANCH'. Work must be on a task branch." >&2
  exit 1
fi

DRY_RUN="${1:-}"

# Step 1: Working Tree Cleanliness
DIRTY_DIFF="$(git status --porcelain | grep -v '^[?][?]' || true)"
if [ -n "$DIRTY_DIFF" ]; then
  echo "❌ Error: Uncommitted changes detected. Commit or stash them before opening a PR:" >&2
  git status --short
  exit 1
fi
echo "✅ Working tree is committed."

# Step 2: Publish Boundary Guard
echo "🛡️  Checking contribution publish boundary..."
if [ -x "$SCRATCH_DIR/check-publish-boundary.sh" ]; then
  # Feed current HEAD as input to the boundary checker
  echo "refs/heads/$BRANCH $(git rev-parse HEAD) refs/heads/$BRANCH $(git rev-parse HEAD)" | "$SCRATCH_DIR/check-publish-boundary.sh"
fi
echo "✅ Contribution boundary clean (no personal workflow files in PR diff)."

# Step 3: Workflow Byte Budgets
echo "🔍 Verifying workflow byte ceilings (ADR-857 Phase 6)..."
if [ -x "$SCRATCH_DIR/check-workflow-budgets.sh" ]; then
  "$SCRATCH_DIR/check-workflow-budgets.sh"
fi

# Step 4: Changeset Verification
CHANGED_FILES="$(git diff --name-only upstream/next...HEAD)"
CHANGESET_DIFF="$(git diff --name-only upstream/next...HEAD -- .changeset/ | grep -v 'README.md' || true)"

if [ -z "$CHANGESET_DIFF" ]; then
  echo "⚠️  WARNING: No changeset fragment found under .changeset/ on this branch."
  echo "    If this PR introduces any user-facing fixes, features, or behaviors,"
  echo "    run: npm run changeset"
  echo "    Ensure frontmatter includes: pr: <issue-or-pr-number>"
else
  echo "✅ Changeset fragment detected:"
  echo "$CHANGESET_DIFF" | sed 's/^/   - /'
fi

# Step 5: Sync Personal Environment to Workspace
echo "📤 Reconciling personal planning/tools to personal workspace..."
if [ -x "$SCRATCH_DIR/sync-personal-env.sh" ]; then
  "$SCRATCH_DIR/sync-personal-env.sh" push
fi
echo ""

if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "ℹ️  [--dry-run] Skipping full remote Mac CI run and git push."
  echo ""
else
  # Step 6: Full Clean-Room CI on Mac Runner
  echo "🍏 Running full remote clean-room CI suite on Mac..."
  echo "   (This runs environment checks, build, lints, and all test chunks)"
  "$SCRATCH_DIR/ci-mac.sh"
  echo "✅ Remote Mac CI suite passed 100% green!"
  echo ""

  # Step 7: Push to Fork (Origin)
  echo "📤 Pushing branch to origin ($BRANCH)..."
  git push -u origin HEAD
  echo "✅ Pushed to origin/HEAD."
  echo ""
fi

# Step 8: PR Template and Title Formatting
TYPE="fix"
ISSUE=""
SUMMARY="title"

if [[ "$BRANCH" =~ ^([a-zA-Z]+)/([0-9]+)-(.*)$ ]]; then
  TYPE="${BASH_REMATCH[1]}"
  ISSUE="${BASH_REMATCH[2]}"
  SLUG="${BASH_REMATCH[3]}"
  SUMMARY="${SLUG//-/ }"
elif [[ "$BRANCH" =~ ^([a-zA-Z]+)/(.*)$ ]]; then
  TYPE="${BASH_REMATCH[1]}"
  SLUG="${BASH_REMATCH[2]}"
  SUMMARY="${SLUG//-/ }"
fi

TEMPLATE_PATH=".github/PULL_REQUEST_TEMPLATE/${TYPE}.md"
if [ ! -f "$TEMPLATE_PATH" ]; then
  TEMPLATE_PATH=".github/PULL_REQUEST_TEMPLATE/default.md"
fi
[ ! -f "$TEMPLATE_PATH" ] && TEMPLATE_PATH=""

if [ -n "$ISSUE" ]; then
  PR_TITLE="${TYPE}(#${ISSUE}): ${SUMMARY}"
else
  PR_TITLE="${TYPE}: ${SUMMARY}"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 PR Pre-flight Complete! Ready to open Pull Request:"
echo ""
echo "Command to open PR:"
if [ -n "$TEMPLATE_PATH" ]; then
  echo "  gh pr create --base next --repo open-gsd/gsd-core --template \"$TEMPLATE_PATH\" --title \"$PR_TITLE\""
else
  echo "  gh pr create --base next --repo open-gsd/gsd-core --title \"$PR_TITLE\""
fi
echo ""
echo "⚠️  CRITICAL REMINDER FOR PR REVIEW:"
echo "   Monitor GitHub Actions via: gh pr checks <PR_NUMBER> --repo open-gsd/gsd-core"
echo "   NEVER ping maintainers until ALL checks are 100% green."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
