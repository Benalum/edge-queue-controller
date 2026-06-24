#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
APP="$REPO/frontend/wrapper-ui/app.js"
INDEX="$REPO/frontend/wrapper-ui/index.html"
DOC="$REPO/docs/stage-16-fc-o45-e-aa-r5-chunked-vm200-static-realign.md"

echo "=== stage-16-fc-o45-e-aa-r5 static smoke ==="

test -s "$APP"
test -s "$INDEX"
test -s "$DOC"

grep -F -q 'APC_COMPANION_RESULT_VISIBILITY_UI_FC_O45_E_Z' "$APP"
grep -F -q 'X-APC-Companion-Result-Read-Only' "$APP"
grep -F -q 'fetch(probeConfig.url, probeConfig.options)' "$APP"
if grep -F -q 'probeConfig.options ||' "$APP"; then
  echo "FAIL: bad live-patch pattern remains in repo app"
  exit 1
fi
grep -F -q '20260624fc045eaar5' "$INDEX"
grep -F -q 'Chunked VM200 static realign' "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-aa-r5 static smoke"
