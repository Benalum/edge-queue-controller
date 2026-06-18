#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ia-real-mutation-boundary-preflight-checklist-no-apply"
DOC="docs/${PHASE}.md"

echo "=== ${PHASE} smoke ==="

test -f "$DOC"

grep -F "Phase 14J-IA - Real-mutation boundary preflight checklist, no apply" "$DOC" >/dev/null
grep -F "docs/smoke only" "$DOC" >/dev/null
grep -F "This phase does not approve any real mutation." "$DOC" >/dev/null
grep -F "Commit: \`4a4459a\`" "$DOC" >/dev/null
grep -F "CT202 owner node: \`pveso\`" "$DOC" >/dev/null
grep -F "CT202 service enabled state: \`disabled\`" "$DOC" >/dev/null
grep -F "CT202 service active state: \`inactive\`" "$DOC" >/dev/null
grep -F "CT202 checked listener count on \`7070\` is \`0\`" "$DOC" >/dev/null
grep -F "CT202 checked listener count on \`8787\` is \`0\`" "$DOC" >/dev/null
grep -F "CT202 checked listener count on \`8765\` is \`0\`" "$DOC" >/dev/null
grep -F "HM/HN backup hashes are still verified." "$DOC" >/dev/null
grep -F "Annotated tag verification uses tag dereference with \`^{}\`" "$DOC" >/dev/null
grep -F "A separate explicit approval boundary is requested and granted before any real mutation command is provided." "$DOC" >/dev/null
grep -F "This phase does not define an approval phrase and does not approve mutation." "$DOC" >/dev/null

if grep -E '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|token=|secret=|password=|api[_-]?key=|Authorization:' "$DOC" >/dev/null; then
  echo "FAIL: doc appears to contain raw network address or secret-like material"
  exit 1
fi

echo "PASS: ${PHASE} doc smoke passed"
