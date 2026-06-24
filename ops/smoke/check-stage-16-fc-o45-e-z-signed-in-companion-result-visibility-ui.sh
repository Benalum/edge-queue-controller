#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
APP="$REPO/frontend/wrapper-ui/app.js"
DOC="$REPO/docs/stage-16-fc-o45-e-z-signed-in-companion-result-visibility-ui.md"

echo "=== stage-16-fc-o45-e-z static smoke ==="

test -s "$APP"
test -s "$DOC"
grep -F -q 'APC_COMPANION_RESULT_VISIBILITY_UI_FC_O45_E_Z' "$APP"
grep -F -q 'Check Companion result for job 124' "$APP"
grep -F -q 'credentials: "same-origin"' "$APP"
grep -F -q 'method: "GET"' "$APP"
! grep -F 'method: "POST"' "$APP" | grep -F 'APC_COMPANION_RESULT_VISIBILITY_UI_FC_O45_E_Z'
grep -F -q 'Check Companion result for job 124' "$DOC"
grep -F -q '/app.js?v=20260624fc045ez' "$DOC"
grep -F -q 'does not create jobs' "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-z static smoke"
