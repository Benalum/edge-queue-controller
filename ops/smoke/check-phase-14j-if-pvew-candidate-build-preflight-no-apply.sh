#!/usr/bin/env bash
set -euo pipefail
PHASE="phase-14j-if-pvew-candidate-build-preflight-no-apply"
DOC="docs/${PHASE}.md"

echo "=== ${PHASE} smoke ==="
test -f "$DOC"
grep -F "Phase 14J-IF - PVEW candidate build preflight, no apply" "$DOC" >/dev/null
grep -F "Base checkpoint: Phase 14J-IE, commit 0e664e0." "$DOC" >/dev/null
grep -F 'CT203 `edge-controller-pvew`' "$DOC" >/dev/null
grep -F 'CT204 `edge-data-pvew`' "$DOC" >/dev/null
grep -F "CT203 and CT204 IDs are unused" "$DOC" >/dev/null
grep -F "explicit real-mutation approval is granted" "$DOC" >/dev/null
grep -F "Do not create CTs, create storage, generate keys, copy data" "$DOC" >/dev/null
echo "PASS: ${PHASE} doc smoke passed"
