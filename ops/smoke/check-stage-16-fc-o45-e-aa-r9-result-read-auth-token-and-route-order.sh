#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
BACKEND="$REPO/edge_controller.py"
APP="$REPO/frontend/wrapper-ui/app.js"
INDEX="$REPO/frontend/wrapper-ui/index.html"
DOC="$REPO/docs/stage-16-fc-o45-e-aa-r9-result-read-auth-token-and-route-order.md"

echo "=== stage-16-fc-o45-e-aa-r9 static smoke ==="
grep -F -q 'APC_COMPANION_RESULT_READ_AUTH_PATH_FC_O45_E_AA_R9' "$BACKEND"
grep -F -q 'X-APC-Companion-Result-Read-Only' "$BACKEND"
grep -F -q 'mode": "result_read_only"' "$BACKEND"
grep -F -q 'findBearerToken' "$APP"
grep -F -q 'headers.Authorization = "Bearer " + token' "$APP"
grep -F -q 'FC-O45-E-AA-R9 read completed Companion result only' "$APP"
grep -F -q '20260624fc045eaar9' "$INDEX"
grep -F -q 'Result read auth token and route order fix' "$DOC"

python3 - <<PY
from pathlib import Path
t = Path("$BACKEND").read_text()
a = t.index("APC_COMPANION_RESULT_READ_AUTH_PATH_FC_O45_E_AA_R9 START")
b = t.index('X-APC-Companion-Auth-Validate-Only") == "FC-O45-E-Q"')
assert a < b
PY

echo "RESULT=PASS stage-16-fc-o45-e-aa-r9 static smoke"
