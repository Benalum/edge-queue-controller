#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ie-pvew-target-candidate-layout-no-apply"
DOC="docs/${PHASE}.md"

echo "=== ${PHASE} smoke ==="
test -f "$DOC"

grep -F "Phase 14J-IE - PVEW target candidate layout, no apply" "$DOC" >/dev/null
grep -F "Base checkpoint: Phase 14J-ID, commit e712093." "$DOC" >/dev/null
grep -F 'CT203 `edge-controller-pvew`' "$DOC" >/dev/null
grep -F 'CT204 `edge-data-pvew`' "$DOC" >/dev/null
grep -F "must not contain user DB files" "$DOC" >/dev/null
grep -F "dedicated encrypted data volume with manual unlock" "$DOC" >/dev/null
grep -F "laptop controller is still live controller/queue authority" "$DOC" >/dev/null
grep -F "Do not create CTs, create storage, generate keys, copy data, stop PVESO, or alter public routes." "$DOC" >/dev/null

echo "PASS: ${PHASE} doc smoke passed"
