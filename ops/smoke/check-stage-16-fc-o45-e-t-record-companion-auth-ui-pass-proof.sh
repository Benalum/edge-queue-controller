#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-t-record-companion-auth-ui-pass-proof.md"
APP_JS="$REPO/frontend/wrapper-ui/app.js"
INDEX_HTML="$REPO/frontend/wrapper-ui/index.html"

UI_MARKER="APC_COMPANION_AUTH_VALIDATE_UI_FC_O45_E_S"
CACHE_VERSION="20260624fc045esr20"
EXPECTED_UI_RESULT="PASS: signed-in Companion auth validated; queue_write=false."

echo "=== stage-16-fc-o45-e-t static smoke ==="

test -s "$DOC"
test -s "$APP_JS"
test -s "$INDEX_HTML"

grep -q "$UI_MARKER" "$APP_JS"
grep -q "Run Companion auth test" "$APP_JS"
grep -q "queue_write=false" "$DOC"
grep -q "$EXPECTED_UI_RESULT" "$DOC"
grep -q "app.js?v=${CACHE_VERSION}" "$INDEX_HTML"
grep -q "job \`123\`" "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-t static smoke"
