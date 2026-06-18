#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hz-read-only-bootstrap-ct202-owner-node-non-authority-evidence"
DOC="docs/${PHASE}.md"

echo "=== ${PHASE} smoke ==="

test -f "$DOC"

grep -F "Phase 14J-HZ - Read-only bootstrap CT202 owner-node non-authority evidence" "$DOC" >/dev/null
grep -F "Mutation scope:" "$DOC" >/dev/null
grep -F "docs/smoke only" "$DOC" >/dev/null
grep -F "Commit: \`e696b1f\`" "$DOC" >/dev/null
grep -F "laptop-local app table count: \`39\`" "$DOC" >/dev/null
grep -F "CT202 owner node: \`pveso\`" "$DOC" >/dev/null
grep -F "CT202 status: \`running\`" "$DOC" >/dev/null
grep -F "CT202 onboot/autostart: \`0\`" "$DOC" >/dev/null
grep -F "service enabled state: \`disabled\`" "$DOC" >/dev/null
grep -F "service active state: \`inactive\`" "$DOC" >/dev/null
grep -F "listener count on \`7070\`: \`0\`" "$DOC" >/dev/null
grep -F "listener count on \`8787\`: \`0\`" "$DOC" >/dev/null
grep -F "listener count on \`8765\`: \`0\`" "$DOC" >/dev/null
grep -F "DB size: \`262144\`" "$DOC" >/dev/null
grep -F "DB quick_check: \`ok\`" "$DOC" >/dev/null
grep -F "STRICT_BOOTSTRAP_RESULT=PASS_CT202_OWNER_NODE_AND_NON_AUTHORITY_VERIFIED" "$DOC" >/dev/null
grep -F "This phase does not approve any real CT202 mutation." "$DOC" >/dev/null

if grep -E '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|token=|secret=|password=|api[_-]?key=|Authorization:' "$DOC" >/dev/null; then
  echo "FAIL: doc appears to contain raw network address or secret-like material"
  exit 1
fi

echo "PASS: ${PHASE} doc smoke passed"
