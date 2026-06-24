#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
BACKEND="$REPO/edge_controller.py"
APP="$REPO/frontend/wrapper-ui/app.js"
DOC="$REPO/docs/stage-16-fc-o45-e-aa-r4-result-read-via-companion-auth-path.md"

echo "=== stage-16-fc-o45-e-aa-r4 static smoke ==="

test -s "$BACKEND"
test -s "$APP"
test -s "$DOC"

grep -F -q 'APC_COMPANION_RESULT_READ_AUTH_PATH_FC_O45_E_AA_R4' "$BACKEND"
grep -F -q 'X-APC-Companion-Result-Read-Only' "$BACKEND"
grep -F -q 'mode": "result_read_only"' "$BACKEND"
grep -F -q "job_type = 'companion.chat'" "$BACKEND"
grep -F -q 'response_text' "$BACKEND"

grep -F -q 'X-APC-Companion-Result-Read-Only' "$APP"
grep -F -q 'method: "POST"' "$APP"
grep -F -q 'credentials: "same-origin"' "$APP"
grep -F -q 'Check Companion result for job 124' "$APP"

grep -F -q 'Companion result read through proven auth path' "$DOC"
grep -F -q 'did not create jobs' "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-aa-r4 static smoke"
