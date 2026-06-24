#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
APP="$REPO/frontend/wrapper-ui/app.js"
INDEX="$REPO/frontend/wrapper-ui/index.html"
DOC="$REPO/docs/stage-16-fc-o45-e-ac-user-facing-companion-result-reader.md"

echo "=== stage-16-fc-o45-e-ac static smoke ==="
test -s "$APP"
test -s "$INDEX"
test -s "$DOC"

grep -F -q "APC_COMPANION_RESULT_READER_UI_FC_O45_E_AC" "$APP"
grep -F -q "Companion result reader" "$APP"
grep -F -q "apc-companion-result-reader-job-id" "$APP"
grep -F -q "X-APC-Companion-Result-Read-Only" "$APP"
grep -F -q "FC-O45-E-AC read Companion job result by job id." "$APP"
grep -F -q "20260624fc045eac" "$INDEX"
grep -F -q "User-facing Companion result reader" "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-ac static smoke"
