#!/usr/bin/env node
/**
 * PR Feedback & CI Status Consumer
 *
 * Automatically monitors GitHub notifications and pull requests for:
 * 1. Maintainer reviews & review comments (with persistent watermark to avoid duplicate alerts)
 * 2. GitHub Actions CI status changes on the current HEAD_SHA (alerting on 100% green vs failure)
 * 3. Upstream drift detection against upstream/next
 * 4. Desktop notifications via notify-send and persistent markdown staging under scratch/feedback/
 *
 * Usage:
 *   node scratch/pr-feedback-consumer.cjs [--once] [--watch] [--interval <seconds>]
 */

const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

const REPO = 'open-gsd/gsd-core';
const WATERMARK_DIR = path.join(os.homedir(), '.config', 'gsd');
const WATERMARK_FILE = path.join(WATERMARK_DIR, 'pr-review-watermark.json');
const FEEDBACK_DIR = path.join(__dirname, 'feedback');

// Known bots to exclude
const BOT_AUTHORS = new Set([
  'github-actions[bot]',
  'codecov[bot]',
  'open-gsd-bot',
  'renovate[bot]',
  'dependabot[bot]'
]);

function ensureDirs() {
  if (!fs.existsSync(WATERMARK_DIR)) {
    fs.mkdirSync(WATERMARK_DIR, { recursive: true });
  }
  if (!fs.existsSync(FEEDBACK_DIR)) {
    fs.mkdirSync(FEEDBACK_DIR, { recursive: true });
  }
}

function loadWatermark() {
  ensureDirs();
  if (fs.existsSync(WATERMARK_FILE)) {
    try {
      return JSON.parse(fs.readFileSync(WATERMARK_FILE, 'utf-8'));
    } catch {
      return {};
    }
  }
  return {};
}

function saveWatermark(watermark) {
  ensureDirs();
  fs.writeFileSync(WATERMARK_FILE, JSON.stringify(watermark, null, 2), 'utf-8');
}

function runGh(args) {
  try {
    const res = spawnSync('gh', args, {
      encoding: 'utf-8',
      maxBuffer: 10 * 1024 * 1024
    });
    if (res.status !== 0) {
      return null;
    }
    return res.stdout;
  } catch {
    return null;
  }
}

function getMyUsername() {
  const out = runGh(['api', 'user', '-q', '.login']);
  return (out || '').trim();
}

function sendDesktopNotification(title, message) {
  try {
    spawnSync('notify-send', ['-a', 'GSD PR Monitor', title, message]);
  } catch {
    // notify-send optional
  }
}

function findWorktreeForBranch(branchName) {
  try {
    const res = spawnSync('git', ['worktree', 'list', '--porcelain'], { encoding: 'utf-8' });
    if (res.status !== 0 || !res.stdout) return null;
    const blocks = res.stdout.split('\n\n');
    for (const block of blocks) {
      const lines = block.split('\n');
      let wtPath = null;
      let wtBranch = null;
      for (const line of lines) {
        if (line.startsWith('worktree ')) {
          wtPath = line.slice('worktree '.length).trim();
        } else if (line.startsWith('branch ')) {
          wtBranch = line.slice('branch '.length).trim();
        }
      }
      if (wtPath && wtBranch && (wtBranch === `refs/heads/${branchName}` || wtBranch.endsWith(`/${branchName}`))) {
        return wtPath;
      }
    }
  } catch {
    return null;
  }
  return null;
}

function hasActiveAgentLock(prNumber) {
  if (!fs.existsSync(FEEDBACK_DIR)) return false;
  const files = fs.readdirSync(FEEDBACK_DIR);
  return files.some(f => f.startsWith(`PR-${prNumber}`) && f.endsWith('.lock'));
}

function dispatchAgentAction(worktreeDir, prompt, lockFile) {
  const agyBin = fs.existsSync('/home/denniyahh/.local/bin/agy')
    ? '/home/denniyahh/.local/bin/agy'
    : 'agy';

  const logsDir = path.join(__dirname, 'logs');
  if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
  }
  const timestamp = Date.now();
  const logFile = path.join(logsDir, `agent-${path.basename(worktreeDir)}-${timestamp}.log`);
  console.log(`🤖 Dispatching autonomous agent in ${worktreeDir}...`);
  console.log(`📝 Agent log: ${logFile}`);

  const wrapperScriptPath = path.join(logsDir, `dispatch-${timestamp}.sh`);
  const safePrompt = prompt.replace(/"/g, '\\"').replace(/\$/g, '\\$');
  const cleanupScript = `#!/usr/bin/env bash
"${agyBin}" -p "${safePrompt}" --mode auto --dangerously-skip-permissions
EXIT_CODE=$?
rm -f "${lockFile}"
rm -f "${wrapperScriptPath}"
exit $EXIT_CODE
`;
  fs.writeFileSync(wrapperScriptPath, cleanupScript, { mode: 0o755 });

  const out = fs.openSync(logFile, 'a');
  const err = fs.openSync(logFile, 'a');

  const child = spawn('bash', [wrapperScriptPath], {
    cwd: worktreeDir,
    detached: true,
    stdio: ['ignore', out, err],
    env: {
      ...process.env,
      PATH: `/home/denniyahh/.local/bin:/home/linuxbrew/.linuxbrew/bin:${process.env.PATH}`
    }
  });
  child.unref();
  console.log(`🚀 Agent process spawned (PID ${child.pid}).`);
}

function fetchOpenPrs() {
  const out = runGh([
    'pr', 'list',
    '--repo', REPO,
    '--author', '@me',
    '--state', 'open',
    '--json', 'number,title,headRefName,headRefOid,url,updatedAt,reviewDecision'
  ]);
  if (!out) return [];
  try {
    return JSON.parse(out);
  } catch {
    return [];
  }
}

function checkPrDrift(branchName) {
  try {
    const res = spawnSync('git', ['rev-parse', '--verify', `refs/remotes/origin/${branchName}`], { encoding: 'utf-8' });
    if (res.status !== 0) return null;
    const behindOut = spawnSync('git', ['rev-list', '--count', `refs/remotes/origin/${branchName}..upstream/next`], { encoding: 'utf-8' });
    if (behindOut.status === 0) {
      const behind = parseInt((behindOut.stdout || '').trim(), 10);
      return isNaN(behind) ? 0 : behind;
    }
  } catch {
    return null;
  }
  return null;
}

function checkPrCi(prNumber) {
  const out = runGh(['pr', 'checks', String(prNumber), '--repo', REPO, '--json', 'bucket,name,workflow']);
  if (!out) return null;
  let checks;
  try {
    checks = JSON.parse(out);
  } catch {
    return null;
  }
  if (!Array.isArray(checks) || checks.length === 0) return null;

  // Filter out advisory-only checks that fail prior to maintainer review (#5607)
  const effectiveChecks = checks.filter(c => !/reviewed or maintainer/i.test(c.name || ''));
  const total = effectiveChecks.length;
  const pass = effectiveChecks.filter(c => c.bucket === 'pass').length;
  const pending = effectiveChecks.filter(c => c.bucket === 'pending').length;
  const fail = effectiveChecks.filter(c => c.bucket === 'fail').length;
  const cancel = effectiveChecks.filter(c => c.bucket === 'cancel').length;
  const skip = effectiveChecks.filter(c => c.bucket === 'skipping').length;

  let status = 'in_progress';
  if (pending === 0) {
    if (fail === 0 && cancel === 0) {
      status = 'success';
    } else {
      status = 'failure';
    }
  }

  const failedJobs = effectiveChecks.filter(c => c.bucket === 'fail' || c.bucket === 'cancel').map(c => c.name);

  return {
    status,
    total,
    pass,
    pending,
    fail,
    cancel,
    skip,
    failedJobs
  };
}

function checkPrFeedbackAndStatus(pr, myUsername, watermark) {
  const prNumber = pr.number;
  const prWatermark = watermark[prNumber] || {
    lastReviewTime: null,
    seenCommentIds: [],
    lastCiHead: null,
    lastCiStatus: null
  };
  const seenIds = new Set(prWatermark.seenCommentIds || []);

  // 1. Fetch reviews
  const reviewsRaw = runGh(['api', `repos/${REPO}/pulls/${prNumber}/reviews`]);
  const reviews = reviewsRaw ? JSON.parse(reviewsRaw) : [];

  // 2. Fetch issue comments
  const issueCommentsRaw = runGh(['api', `repos/${REPO}/issues/${prNumber}/comments`]);
  const issueComments = issueCommentsRaw ? JSON.parse(issueCommentsRaw) : [];

  // 3. Fetch PR review comments (inline comments)
  const reviewCommentsRaw = runGh(['api', `repos/${REPO}/pulls/${prNumber}/comments`]);
  const reviewComments = reviewCommentsRaw ? JSON.parse(reviewCommentsRaw) : [];

  const newReviews = [];
  const newComments = [];

  for (const review of reviews) {
    const author = review.user ? review.user.login : '';
    if (author === myUsername || BOT_AUTHORS.has(author)) continue;
    if (review.state === 'PENDING') continue;

    const submittedAt = review.submitted_at;
    if (prWatermark.lastReviewTime && submittedAt <= prWatermark.lastReviewTime) {
      continue;
    }
    newReviews.push(review);
  }

  const allComments = [...issueComments, ...reviewComments];
  for (const comment of allComments) {
    const author = comment.user ? comment.user.login : '';
    if (author === myUsername || BOT_AUTHORS.has(author)) continue;
    if (seenIds.has(comment.id)) continue;

    newComments.push(comment);
    seenIds.add(comment.id);
  }

  // Determine latest review time
  let latestReviewTime = prWatermark.lastReviewTime;
  for (const r of newReviews) {
    if (!latestReviewTime || r.submitted_at > latestReviewTime) {
      latestReviewTime = r.submitted_at;
    }
  }

  // 4. CI checks & Upstream drift
  const headOid = pr.headRefOid || '';
  const shortHead = headOid.slice(0, 9);
  const ciInfo = checkPrCi(prNumber);
  const drift = checkPrDrift(pr.headRefName);

  let ciEvent = null;
  if (ciInfo) {
    const isNewHead = prWatermark.lastCiHead !== headOid;
    const isStatusChanged = prWatermark.lastCiStatus !== ciInfo.status;

    if (ciInfo.status !== 'in_progress' && (isNewHead || isStatusChanged)) {
      ciEvent = {
        prNumber,
        headOid,
        shortHead,
        status: ciInfo.status,
        pass: ciInfo.pass,
        fail: ciInfo.fail,
        failedJobs: ciInfo.failedJobs,
        drift
      };
    }

    prWatermark.lastCiHead = headOid;
    prWatermark.lastCiStatus = ciInfo.status;
  }

  // Update watermark
  prWatermark.lastReviewTime = latestReviewTime;
  prWatermark.seenCommentIds = Array.from(seenIds);
  watermark[prNumber] = prWatermark;

  const hasFeedback = newReviews.length > 0 || newComments.length > 0;
  if (!hasFeedback && !ciEvent) {
    return null;
  }

  return {
    pr,
    newReviews,
    newComments,
    ciEvent,
    ciInfo,
    drift
  };
}

function processFeedbackItem(item, watermark, autoAct = false) {
  const { pr, newReviews, newComments, ciEvent, ciInfo, drift } = item;
  const prNumber = pr.number;
  const prWatermark = watermark[prNumber] || {};

  if (newReviews.length > 0 || newComments.length > 0) {
    console.log(`\n🔔 New maintainer feedback detected on PR #${pr.number}: ${pr.title}`);

    let report = `# Maintainer Feedback for PR #${pr.number}\n\n`;
    report += `- **PR Title**: ${pr.title}\n`;
    report += `- **Branch**: \`${pr.headRefName}\`\n`;
    report += `- **URL**: ${pr.url}\n`;
    report += `- **Timestamp**: ${new Date().toISOString()}\n\n`;

    if (newReviews.length > 0) {
      report += `## Reviews (${newReviews.length})\n\n`;
      for (const r of newReviews) {
        report += `### Review by @${r.user.login} (${r.state}) — ${r.submitted_at}\n\n`;
        if (r.body) {
          report += `${r.body}\n\n`;
        }
        sendDesktopNotification(
          `PR #${pr.number} Review: ${r.state}`,
          `@${r.user.login} submitted a review on "${pr.title}"`
        );
      }
    }

    if (newComments.length > 0) {
      report += `## Comments (${newComments.length})\n\n`;
      for (const c of newComments) {
        const fileInfo = c.path ? ` on \`${c.path}:${c.line || c.original_line || 'diff'}\`` : '';
        report += `### Comment by @${c.user.login}${fileInfo} — ${c.created_at}\n\n`;
        report += `${c.body}\n\n`;
        if (c.diff_hunk) {
          report += `\`\`\`diff\n${c.diff_hunk}\n\`\`\`\n\n`;
        }
        sendDesktopNotification(
          `PR #${pr.number} Comment`,
          `@${c.user.login}${fileInfo}: ${(c.body || '').slice(0, 100)}`
        );
      }
    }

    const feedbackFile = path.join(FEEDBACK_DIR, `PR-${pr.number}-feedback.md`);
    fs.writeFileSync(feedbackFile, report, 'utf-8');
    console.log(`📄 Feedback saved to: ${feedbackFile}`);

    // Auto-act on review feedback if requested
    if (autoAct) {
      const wtPath = findWorktreeForBranch(pr.headRefName);
      if (wtPath && fs.existsSync(wtPath)) {
        if (!hasActiveAgentLock(pr.number)) {
          const lockFile = path.join(FEEDBACK_DIR, `PR-${pr.number}.lock`);
          fs.writeFileSync(lockFile, JSON.stringify({ startedAt: new Date().toISOString(), pr: pr.number, type: 'review' }));
          dispatchAgentAction(
            wtPath,
            `Maintainer review feedback was received on PR #${pr.number} (${pr.title}). ` +
            `Read ${feedbackFile}, inspect reviewer comments and diffs, apply required fixes in this worktree, ` +
            `run focused tests, ensure zero upstream drift (git fetch upstream next && git rev-list --count HEAD..upstream/next), ` +
            `and force-push updated branch to origin.`,
            lockFile
          );
        } else {
          console.log(`🔒 Active agent lock already present for PR #${pr.number} — skipping duplicate dispatch.`);
        }
      } else {
        console.log(`⚠️  Could not locate active worktree for branch ${pr.headRefName}.`);
      }
    }
  }

  // Handle CI completion event
  if (ciEvent) {
    const { status, shortHead, headOid, pass, fail, failedJobs, drift: driftCount } = ciEvent;
    if (status === 'success') {
      if (driftCount === 0) {
        console.log(`\n🚀 PR #${pr.number} CI 100% GREEN on ${shortHead} with 0 drift — READY FOR RE-REVIEW!`);
        sendDesktopNotification(
          `🚀 PR #${pr.number} Ready for Re-Review!`,
          `All ${pass} CI checks passed on ${shortHead} with 0 drift.`
        );

        if (autoAct && prWatermark.lastCommentedHead !== headOid) {
          console.log(`💬 Auto-posting maintainer re-review request comment on PR #${pr.number}...`);
          const commentBody = `@trek-e All GitHub Actions CI checks have completed successfully (100% green, ${pass}/${pass} checks passing) against commit \`${shortHead}\` with 0 upstream drift on \`upstream/next\`. This PR is ready for maintainer re-review.`;
          const commentRes = runGh(['pr', 'comment', String(pr.number), '--repo', REPO, '--body', commentBody]);
          if (commentRes !== null) {
            prWatermark.lastCommentedHead = headOid;
            saveWatermark(watermark);
            console.log(`✅ Maintainer re-review request posted on PR #${pr.number}.`);
          }
        }
      } else {
        console.log(`\n⚠️  PR #${pr.number} CI passed on ${shortHead}, but branch is ${driftCount} commits behind upstream/next.`);
        sendDesktopNotification(
          `⚠️ PR #${pr.number} CI Passed (Drift Detected)`,
          `Checks passed on ${shortHead}, but branch is ${driftCount} behind upstream/next.`
        );

        if (autoAct) {
          const wtPath = findWorktreeForBranch(pr.headRefName);
          if (wtPath && fs.existsSync(wtPath)) {
            if (!hasActiveAgentLock(pr.number)) {
              const lockFile = path.join(FEEDBACK_DIR, `PR-${pr.number}.lock`);
              fs.writeFileSync(lockFile, JSON.stringify({ startedAt: new Date().toISOString(), pr: pr.number, type: 'rebase' }));
              dispatchAgentAction(
                wtPath,
                `PR #${pr.number} passed CI on commit ${shortHead}, but is now ${driftCount} commits behind upstream/next. ` +
                `Rebase the branch onto upstream/next (git fetch upstream next && git rebase upstream/next), ` +
                `verify workflow budgets, and force-push to origin to re-trigger clean CI.`,
                lockFile
              );
            } else {
              console.log(`🔒 Active agent lock already present for PR #${pr.number} — skipping duplicate dispatch.`);
            }
          }
        }
      }
    } else if (status === 'failure') {
      console.log(`\n❌ PR #${pr.number} CI FAILED on ${shortHead} (${fail} failing): ${failedJobs.join(', ')}`);
      sendDesktopNotification(
        `❌ PR #${pr.number} CI Failed`,
        `Failed on ${shortHead}: ${failedJobs.slice(0, 3).join(', ')}`
      );

      if (autoAct) {
        const wtPath = findWorktreeForBranch(pr.headRefName);
        if (wtPath && fs.existsSync(wtPath)) {
          if (!hasActiveAgentLock(pr.number)) {
            const lockFile = path.join(FEEDBACK_DIR, `PR-${pr.number}.lock`);
            fs.writeFileSync(lockFile, JSON.stringify({ startedAt: new Date().toISOString(), pr: pr.number, type: 'ci-failure', headOid }));
            dispatchAgentAction(
              wtPath,
              `CI failed on PR #${pr.number} for commit ${shortHead}. Failed jobs: ${failedJobs.join(', ')}. ` +
              `Inspect the failures using gh api for failed job logs, diagnose the issue, apply fixes in this worktree, ` +
              `run focused tests, verify workflow budgets, commit and push to origin.`,
              lockFile
            );
          } else {
            console.log(`🔒 Active agent lock already present for PR #${pr.number} — skipping duplicate dispatch.`);
          }
        }
      }
    }
  }
}

function checkAllOnce(autoAct = false) {
  console.log('🔍 Checking GitHub notification stream for maintainer feedback & CI status on open PRs...');
  if (autoAct) {
    console.log('⚡ Auto-action enabled: will auto-comment when 100% green and dispatch agent on failures/reviews.');
  }
  const myUsername = getMyUsername();
  if (!myUsername) {
    console.error('❌ Failed to authenticate with gh CLI.');
    process.exit(1);
  }

  // Update upstream/next quietly
  spawnSync('git', ['fetch', 'upstream', 'next', '--quiet'], { encoding: 'utf-8' });

  const prs = fetchOpenPrs();
  console.log(`📋 Found ${prs.length} open authored PRs in ${REPO}.`);

  const watermark = loadWatermark();
  let foundAny = false;

  for (const pr of prs) {
    const item = checkPrFeedbackAndStatus(pr, myUsername, watermark);
    if (item) {
      foundAny = true;
      processFeedbackItem(item, watermark, autoAct);
    }
  }

  saveWatermark(watermark);

  if (!foundAny) {
    console.log('✅ No new maintainer feedback or completed CI events.');
  }
}

function main() {
  const args = process.argv.slice(2);
  const isWatch = args.includes('--watch');
  const autoAct = args.includes('--auto-act') || process.env.GSD_PR_AUTO_ACT === '1';
  const intervalIdx = args.indexOf('--interval');
  const intervalSeconds = intervalIdx !== -1 && args[intervalIdx + 1] ? parseInt(args[intervalIdx + 1], 10) : 60;

  if (isWatch) {
    console.log(`👀 Watching GitHub notifications for ${REPO} every ${intervalSeconds}s (Ctrl+C to stop)...`);
    checkAllOnce(autoAct);
    setInterval(() => checkAllOnce(autoAct), intervalSeconds * 1000);
  } else {
    checkAllOnce(autoAct);
  }
}

main();
