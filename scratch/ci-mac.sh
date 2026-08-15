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

# Fast LAN rsync of repo + git metadata (excluding node_modules, local caches, and .local)
rsync -a --delete \
  --exclude 'node_modules' \
  --exclude '.local' \
  --exclude '.cache' \
  --exclude '*.tsbuildinfo' \
  "$LOCAL_ROOT/" "$REMOTE:$REMOTE_DIR/"

# Compute local package-lock.json hash
LOCKFILE_HASH="$(sha256sum "$LOCAL_ROOT/package-lock.json" | cut -d' ' -f1)"

# Command to execute
if [ $# -gt 0 ]; then
  COMMAND="$*"
else
  COMMAND="npm run check:env && npm run build && npm run lint:ci && npm test"
fi

# Execute on Mac with mise-pinned Node 22 and automatic npm ci if lockfile changed
ssh -t "$REMOTE" "zsh -lc '
  cd $REMOTE_DIR &&
  CACHED_HASH_FILE=~/.cache/gsd-core-pkg-lock.sha256
  CURRENT_HASH=\"$LOCKFILE_HASH\"
  
  if [ ! -d node_modules ] || [ ! -f \"\$CACHED_HASH_FILE\" ] || [ \"\$(cat \"\$CACHED_HASH_FILE\")\" != \"\$CURRENT_HASH\" ]; then
    echo \"🔄 Lockfile change or clean install detected. Running npm ci on Mac...\"
    mise exec -- npm ci --silent
    echo \"\$CURRENT_HASH\" > \"\$CACHED_HASH_FILE\"
  fi

  echo \"🚀 Running CI command on Mac: $COMMAND\"
  mise exec -- $COMMAND
'"
