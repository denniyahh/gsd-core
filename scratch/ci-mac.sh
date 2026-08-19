#!/usr/bin/env bash
set -euo pipefail

# Configuration
REMOTE="${GSD_CI_REMOTE:-mac}"
REMOTE_DIR="${GSD_CI_REMOTE_DIR:-~/builds/gsd-core}"
LOCAL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Quick connectivity probe (1 second timeout)
if ! ssh -q -o ConnectTimeout=2 -o BatchMode=yes "$REMOTE" exit 0; then
  echo "❌ Error: Cannot connect to Mac remote '$REMOTE' via SSH." >&2
  echo "Please verify that the Mac is awake and connected to the local network." >&2
  exit 1
fi

# Ensure remote directory exists
ssh "$REMOTE" "mkdir -p $REMOTE_DIR ~/.cache"

# Fast LAN rsync of the working tree. .git is deliberately EXCLUDED and
# handled separately below: when LOCAL_ROOT is a linked git worktree (not
# the main clone), its .git is a pointer FILE to this machine's own
# .git/worktrees/<name> directory, which cannot resolve on a remote host —
# rsyncing it verbatim leaves the remote with a git repo that fails on
# every git invocation ("fatal: not a git repository: ...").
rsync -a --delete \
  --filter='P /node_modules' \
  --filter='P /gsd-core/bin/lib' \
  --filter='P /.cache' \
  --filter='P /*.tsbuildinfo' \
  --filter='P /.git' \
  --filter='- /node_modules' \
  --filter='- /.local' \
  --filter='- /.cache' \
  --filter='- /*.tsbuildinfo' \
  --filter='- /.git' \
  "$LOCAL_ROOT/" "$REMOTE:$REMOTE_DIR/"

# Give the remote copy real, working git history — matching this worktree's
# current branch/commit and remotes — without disturbing the files rsync
# just wrote. `reset --mixed` (not --hard) moves the branch ref and index to
# the target commit but leaves the working tree alone, so any uncommitted
# local changes rsync carried over survive as a diff instead of being wiped.
#
# History travels as a git bundle, not a fetch from origin: a contribution
# branch worked from a linked worktree is routinely local-only (unpushed), so
# `git fetch origin <branch>` fails outright when origin has never seen it.
# A bundle of everything reachable from HEAD is self-contained and correct
# whether or not the branch exists on any remote.
LOCAL_BRANCH="$(git -C "$LOCAL_ROOT" rev-parse --abbrev-ref HEAD)"
ORIGIN_URL="$(git -C "$LOCAL_ROOT" remote get-url origin)"
UPSTREAM_URL="$(git -C "$LOCAL_ROOT" remote get-url upstream 2>/dev/null || true)"

BUNDLE_LOCAL="$(mktemp)"
git -C "$LOCAL_ROOT" bundle create -q "$BUNDLE_LOCAL" HEAD
REMOTE_BUNDLE=/tmp/gsd-ci-git.bundle
scp -q "$BUNDLE_LOCAL" "$REMOTE:$REMOTE_BUNDLE"

# Built as a real script and shipped as a file (not an inline ssh command
# string): the remote's login shell is fish, which cannot parse the
# bash/zsh quoting ($'...' escapes, nested single-quotes) an inline
# multi-line command would need — a file sidesteps that entirely.
REMOTE_GIT_SCRIPT_LOCAL="$(mktemp)"
trap 'rm -f "$REMOTE_GIT_SCRIPT_LOCAL" "$BUNDLE_LOCAL"' EXIT

{
  echo "set -e"
  echo "cd $REMOTE_DIR"
  echo "if ! git rev-parse --git-dir >/dev/null 2>&1; then"
  echo "  echo '🔧 No usable git repo on remote — initializing'"
  echo "  rm -rf .git"
  echo "  git init -q"
  echo "fi"
  echo "git remote set-url origin '$ORIGIN_URL' 2>/dev/null || git remote add origin '$ORIGIN_URL'"
  if [ -n "$UPSTREAM_URL" ]; then
    echo "git remote set-url upstream '$UPSTREAM_URL' 2>/dev/null || git remote add upstream '$UPSTREAM_URL'"
  fi
  echo "git fetch --quiet '$REMOTE_BUNDLE' HEAD"
  echo "git reset --mixed --quiet FETCH_HEAD"
  echo "git branch -M '$LOCAL_BRANCH'"
  echo "git add -A"
  echo "rm -f '$REMOTE_BUNDLE'"
} > "$REMOTE_GIT_SCRIPT_LOCAL"

ssh "$REMOTE" "cat > /tmp/gsd-ci-git-adopt.zsh" < "$REMOTE_GIT_SCRIPT_LOCAL"
ssh "$REMOTE" zsh /tmp/gsd-ci-git-adopt.zsh

# Compute local package-lock.json hash
LOCKFILE_HASH="$(sha256sum "$LOCAL_ROOT/package-lock.json" | cut -d' ' -f1)"

# Command to execute
if [ $# -gt 0 ]; then
  COMMAND="$*"
else
  COMMAND="npm run check:env && npm run build && npm run lint:ci && npm test"
fi

# Execute on Mac with mise-pinned Node 24 and automatic npm ci if lockfile changed.
#
# GIT_CONFIG_GLOBAL/SYSTEM=/dev/null below make every git subprocess the test
# suite spawns see a clean, default config — never written to ~/.gitconfig.
# This Mac's real ~/.gitconfig sets both commit.gpgsign=true (signs with an
# SSH key `mise exec`'s environment can't load, so fixture commits fail with
# "failed to write commit object") and core.hooksPath=~/.config/git/hooks.
#
# An earlier version of this override tried to neutralize just those two
# keys individually (gpgsign=false, hooksPath repointed at an empty dir).
# That repointed value was STILL a non-default hooksPath, and dozens of
# commit-docs-guard and pr-subrepo tests assert default (unset) hooksPath
# behavior in throwaway repos they create — so the "fix" broke ~25 tests
# that had nothing to do with gpg signing. Blanking the config files
# entirely, rather than overriding specific keys, is what GitHub Actions
# runners actually have (no config at all), so it's the correct target to
# match rather than a narrower approximation of it.
ssh -t "$REMOTE" "zsh -lc '
  cd $REMOTE_DIR &&
  CACHED_HASH_FILE=~/.cache/gsd-core-pkg-lock.sha256
  CURRENT_HASH=\"$LOCKFILE_HASH\"

  if [ ! -d node_modules ] || [ ! -f \"\$CACHED_HASH_FILE\" ] || [ \"\$(cat \"\$CACHED_HASH_FILE\")\" != \"\$CURRENT_HASH\" ]; then
    echo \"🔄 Lockfile change or clean install detected. Running npm ci on Mac...\"
    mise exec -- npm ci --silent
    rm -f tsconfig.build.tsbuildinfo
    mise exec -- npm run build:lib --silent
    echo \"\$CURRENT_HASH\" > \"\$CACHED_HASH_FILE\"
  fi

  if [ ! -d gsd-core/bin/lib ] || [ -z \"\$(ls -A gsd-core/bin/lib 2>/dev/null)\" ]; then
    mise exec -- npm run build:lib --silent
  fi

  export GIT_CONFIG_GLOBAL=/dev/null
  export GIT_CONFIG_SYSTEM=/dev/null

  echo \"🚀 Running CI command on Mac: $COMMAND\"
  mise exec -- $COMMAND
'"
