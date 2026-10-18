#!/usr/bin/env bash
set -euo pipefail

# Automated PR Feedback & Status Monitor
# Inspects all open authored PRs for:
# 1. Maintainer review state & findings
# 2. Upstream drift against upstream/next
# 3. GitHub Actions CI check status on current HEAD_SHA via structured JSON
# 4. Action readiness: automated review comment proposal once 100% green + 0 drift

REPO="open-gsd/gsd-core"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Scanning All Open PRs for Maintainer Feedback & CI Status..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! command -v gh >/dev/null 2>&1; then
  echo "❌ Error: gh CLI is required." >&2
  exit 1
fi

PRS_JSON="$(gh pr list --repo "$REPO" --author "@me" --state open --json number,title,headRefName,headRefOid,url,updatedAt,reviewDecision 2>/dev/null || echo "[]")"
PR_COUNT="$(echo "$PRS_JSON" | jq '. | length')"

if [ "$PR_COUNT" -eq 0 ]; then
  echo "ℹ️  No open authored PRs found."
  exit 0
fi

echo "📋 Found $PR_COUNT open authored PR(s):"
echo ""

# Ensure upstream/next is fetched
git fetch upstream next --quiet 2>/dev/null || true

echo "$PRS_JSON" | jq -c '.[]' | while read -r pr; do
  PR_NUM="$(echo "$pr" | jq -r '.number')"
  PR_TITLE="$(echo "$pr" | jq -r '.title')"
  PR_BRANCH="$(echo "$pr" | jq -r '.headRefName')"
  PR_HEAD="$(echo "$pr" | jq -r '.headRefOid')"
  PR_URL="$(echo "$pr" | jq -r '.url')"
  PR_DECISION="$(echo "$pr" | jq -r '.reviewDecision // "NONE"')"

  echo "════════════════════════════════════════════════════════════"
  echo "🔹 PR #$PR_NUM: $PR_TITLE"
  echo "   Branch:  $PR_BRANCH"
  echo "   HEAD:    ${PR_HEAD:0:9}"
  echo "   URL:     $PR_URL"
  echo "   Review:  $PR_DECISION"

  # Upstream drift
  DRIFT_OK=false
  if git rev-parse --verify "refs/remotes/origin/$PR_BRANCH" >/dev/null 2>&1; then
    BEHIND="$(git rev-list --count "refs/remotes/origin/$PR_BRANCH"..upstream/next 2>/dev/null || echo "0")"
    if [ "$BEHIND" -gt 0 ]; then
      echo "   ⚠️  Drift:   $BEHIND commit(s) BEHIND upstream/next (rebase required!)"
    else
      echo "   ✅ Drift:   Synchronized with upstream/next (0 behind)"
      DRIFT_OK=true
    fi
  else
    echo "   ℹ️  Drift:   Branch origin/$PR_BRANCH not tracked locally"
  fi

  # CI Checks via JSON
  CHECKS_JSON="$(gh pr checks "$PR_NUM" --repo "$REPO" --json bucket,name,workflow 2>/dev/null || echo "[]")"
  TOTAL_CHECKS="$(echo "$CHECKS_JSON" | jq '. | length')"
  PASS_COUNT="$(echo "$CHECKS_JSON" | jq '[.[] | select(.bucket == "pass")] | length')"
  PENDING_COUNT="$(echo "$CHECKS_JSON" | jq '[.[] | select(.bucket == "pending")] | length')"
  FAIL_COUNT="$(echo "$CHECKS_JSON" | jq '[.[] | select(.bucket == "fail")] | length')"
  SKIP_COUNT="$(echo "$CHECKS_JSON" | jq '[.[] | select(.bucket == "skipping")] | length')"
  CANCEL_COUNT="$(echo "$CHECKS_JSON" | jq '[.[] | select(.bucket == "cancel")] | length')"

  CI_OK=false
  if [ "$TOTAL_CHECKS" -eq 0 ]; then
    echo "   ⏳ CI:      No check runs reported yet on ${PR_HEAD:0:9}"
  elif [ "$FAIL_COUNT" -gt 0 ] || [ "$CANCEL_COUNT" -gt 0 ]; then
    FAILED_NAMES="$(echo "$CHECKS_JSON" | jq -r '[.[] | select(.bucket == "fail" or .bucket == "cancel") | .name] | join(", ")')"
    echo "   ❌ CI:      Failing ($FAIL_COUNT failing, $CANCEL_COUNT cancelled, $PASS_COUNT passed)"
    echo "      Failed jobs: $FAILED_NAMES"
  elif [ "$PENDING_COUNT" -gt 0 ]; then
    PENDING_NAMES="$(echo "$CHECKS_JSON" | jq -r '[.[] | select(.bucket == "pending") | .name] | join(", ")')"
    echo "   ⏳ CI:      In progress ($PASS_COUNT passed, $PENDING_COUNT pending, $SKIP_COUNT skipped)"
    echo "      Pending jobs: $PENDING_NAMES"
  else
    echo "   ✅ CI:      100% green on ${PR_HEAD:0:9} ($PASS_COUNT checks passed, $SKIP_COUNT skipped)"
    CI_OK=true
  fi

  # Fetch latest review details
  REVIEWS_RAW="$(gh pr view "$PR_NUM" --repo "$REPO" --json reviews 2>/dev/null || echo "{}")"
  LATEST_REVIEW_STATE="$(echo "$REVIEWS_RAW" | jq -r '.reviews[-1].state // empty')"
  LATEST_REVIEW_AUTHOR="$(echo "$REVIEWS_RAW" | jq -r '.reviews[-1].author.login // empty')"

  if [ -n "$LATEST_REVIEW_STATE" ]; then
    echo "   👤 Latest Review: @$LATEST_REVIEW_AUTHOR ($LATEST_REVIEW_STATE)"
  fi

  # Re-review readiness evaluation
  if [ "$LATEST_REVIEW_STATE" = "CHANGES_REQUESTED" ]; then
    if [ "$DRIFT_OK" = true ] && [ "$CI_OK" = true ]; then
      echo "   🚀 Status: READY FOR RE-REVIEW! 0 drift, 100% green CI against ${PR_HEAD:0:9}."
      echo "      Run: gh pr comment $PR_NUM --repo $REPO --body \"@$LATEST_REVIEW_AUTHOR ...\""
    elif [ "$DRIFT_OK" = false ]; then
      echo "   🛑 Status: Blocked by upstream drift. Rebase onto upstream/next and re-push first."
    elif [ "$CI_OK" = false ]; then
      echo "   ⏳ Status: Waiting for CI completion against ${PR_HEAD:0:9}."
    fi
  elif [ "$LATEST_REVIEW_STATE" = "APPROVED" ]; then
    echo "   🎉 Status: Approved! Awaiting merge."
  fi
  echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
