#!/usr/bin/env bash
set -euo pipefail

# Focused test runner for Mac remote clean-room environment.
# Always prefer this during development, TDD, and iterative fixes over full CI runs.

SCRATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CI_MAC="$SCRATCH_DIR/ci-mac.sh"

if [ ! -x "$CI_MAC" ]; then
  echo "❌ Error: $CI_MAC not found or not executable." >&2
  exit 1
fi

if [ $# -eq 0 ]; then
  echo "🎯 Focused Mac Test Runner" >&2
  echo "Usage: $0 <test-file(s) | flags...>" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  $0 tests/verify.test.cjs" >&2
  echo "  $0 tests/phase.test.cjs tests/verify.test.cjs" >&2
  echo "  $0 --test-name-pattern='cmdVerifyArtifacts' tests/verify.test.cjs" >&2
  echo "  $0 --suite unit" >&2
  echo "" >&2
  echo "💡 Note: Reserve full CI ('mise run check' / '$CI_MAC') for final pre-push verification." >&2
  exit 1
fi

# Route --suite invocations through scripts/run-tests.cjs
if [ "$1" = "--suite" ]; then
  exec "$CI_MAC" "node scripts/run-tests.cjs $*"
fi

# Otherwise construct the node --test command
TEST_CMD="node --test"
for arg in "$@"; do
  TEST_CMD+=" $(printf %q "$arg")"
done

exec "$CI_MAC" "$TEST_CMD"
