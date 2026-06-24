#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
APP="$REPO/frontend/wrapper-ui/app.js"
INDEX="$REPO/frontend/wrapper-ui/index.html"
DOC="$REPO/docs/stage-16-fc-o45-e-aa-r11-ui-result-panel-exact-auth-helper.md"

echo "=== stage-16-fc-o45-e-aa-r11 static smoke ==="
grep -F -q 'function findBearerToken()' "$APP"
grep -F -q 'parsed[inner]' "$APP"
grep -F -q 'headers.Authorization = `Bearer ${token}`' "$APP"
grep -F -q 'credentials: "include"' "$APP"
grep -F -q 'FC-O45-E-AA-R11 read completed Companion result only' "$APP"
grep -F -q '20260624fc045eaar11' "$INDEX"
grep -F -q 'Result panel exact auth helper' "$DOC"
echo "RESULT=PASS stage-16-fc-o45-e-aa-r11 static smoke"
