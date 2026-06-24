#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-ac-r2-browser-proof-result-reader-job-125.md"
APP="$REPO/frontend/wrapper-ui/app.js"

echo "=== stage-16-fc-o45-e-ac-r2 browser proof smoke ==="
test -s "$DOC"
test -s "$APP"

grep -F -q "Browser proof for user-facing Companion result reader" "$DOC"
grep -F -q "PASS: Companion result read path returned a result." "$DOC"
grep -F -q "job_id: 125" "$DOC"
grep -F -q "status: completed" "$DOC"
grep -F -q "job_type: companion.chat" "$DOC"
grep -F -q "requested_model: mock/no-model" "$DOC"
grep -F -q "queue_write: false" "$DOC"
grep -F -q "FC-O45-E-AB completed mock no-model result for Companion job 125." "$DOC"

grep -F -q "APC_COMPANION_RESULT_READER_UI_FC_O45_E_AC" "$APP"
grep -F -q "Companion result reader" "$APP"
grep -F -q "apc-companion-result-reader-job-id" "$APP"

echo "RESULT=PASS stage-16-fc-o45-e-ac-r2 browser proof smoke"
