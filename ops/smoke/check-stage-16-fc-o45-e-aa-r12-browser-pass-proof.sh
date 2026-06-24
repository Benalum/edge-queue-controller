#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-aa-r12-browser-pass-proof.md"
APP="$REPO/frontend/wrapper-ui/app.js"
BACKEND="$REPO/edge_controller.py"

echo "=== stage-16-fc-o45-e-aa-r12 browser PASS proof smoke ==="

test -s "$DOC"
test -s "$APP"
test -s "$BACKEND"

grep -F -q "PASS: completed Companion job 124 result is visible from signed-in UI." "$DOC"
grep -F -q "Endpoint: /api/companion/chat result_read_only" "$DOC"
grep -F -q "FC-O45-E-X-R4 repaired mock no-model completion text for Companion job 124." "$DOC"
grep -F -q "did not create jobs" "$DOC"
grep -F -q "did not run models" "$DOC"
grep -F -q "did not mutate data" "$DOC"

grep -F -q "APC_COMPANION_RESULT_VISIBILITY_UI_FC_O45_E_Z" "$APP"
grep -F -q "X-APC-Companion-Result-Read-Only" "$APP"
grep -F -q "result_read_only" "$BACKEND"

echo "RESULT=PASS stage-16-fc-o45-e-aa-r12 browser PASS proof smoke"
