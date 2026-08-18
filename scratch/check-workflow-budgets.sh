#!/usr/bin/env bash
# Personal pre-flight check for workflow size ceilings and emitted drift acknowledgments.
# ADR-857 Phase 6: execute-phase.md <= 93400 (margin ceiling), plan-phase.md <= 94519.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

ERRORS=0

echo "🔍 Checking workflow byte ceilings (ADR-857 Phase 6)..."

node -e "
const fs = require('fs');
const path = require('path');
const { lfByteCount } = require('./scripts/workflow-size.cjs');

const limits = {
  'gsd-core/workflows/execute-phase.md': { max: 93400, name: 'execute-phase.md (margin ceiling)' },
  'gsd-core/workflows/plan-phase.md': { max: 94519, name: 'plan-phase.md (pre-phase-6 baseline)' }
};

let failed = false;
for (const [relPath, cfg] of Object.entries(limits)) {
  const fullPath = path.join(process.cwd(), relPath);
  if (fs.existsSync(fullPath)) {
    const bytes = lfByteCount(fullPath);
    if (bytes > cfg.max) {
      console.error(\`❌ \${cfg.name} exceeded byte ceiling: \${bytes} > \${cfg.max} (overflow: +\${bytes - cfg.max} bytes)\`);
      failed = true;
    } else {
      console.log(\`✅ \${cfg.name}: \${bytes} bytes (budget: \${cfg.max}, margin: \${cfg.max - bytes} bytes)\`);
    }
  }
}

if (failed) process.exit(1);
" || ERRORS=$((ERRORS + 1))

echo "🔍 Checking emitted drift acknowledgments..."
node scripts/lint-emitted-drift-ack.cjs || ERRORS=$((ERRORS + 1))

if [ "$ERRORS" -gt 0 ]; then
  echo "❌ Pre-flight checks failed ($ERRORS error(s))." >&2
  exit 1
fi

echo "✅ All workflow budget and drift ack checks passed!"
