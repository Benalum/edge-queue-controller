#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
BACKEND="$REPO/edge_controller.py"
APP="$REPO/frontend/wrapper-ui/app.js"
INDEX="$REPO/frontend/wrapper-ui/index.html"
DOC="$REPO/docs/stage-16-fc-o45-e-aa-r7-result-read-mirror-auth-header.md"

echo "=== stage-16-fc-o45-e-aa-r7 static smoke ==="
grep -F -q 'APC_COMPANION_RESULT_READ_AUTH_PATH_FC_O45_E_AA_R7' "$BACKEND"
grep -F -q 'X-APC-Companion-Auth-Validate-Only' "$APP"
grep -F -q 'X-APC-Companion-Result-Read-Only' "$APP"
grep -F -q 'FC-O45-E-AA-R7 read completed Companion result only' "$APP"
grep -F -q '20260624fc045eaar7' "$INDEX"
grep -F -q 'Result read mirrors proven Companion auth header' "$DOC"
echo "RESULT=PASS stage-16-fc-o45-e-aa-r7 static smoke"
