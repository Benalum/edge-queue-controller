#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-ab-f-browser-read-proof-job-125.md"
APP="$REPO/frontend/wrapper-ui/app.js"
BACKEND="$REPO/edge_controller.py"

echo "=== stage-16-fc-o45-e-ab-f browser read proof smoke ==="

test -s "$DOC"
test -s "$APP"
test -s "$BACKEND"

grep -F -q "Browser read proof for fresh Companion job 125" "$DOC"
grep -F -q "http_status: 200" "$DOC"
grep -F -q "pass: true" "$DOC"
grep -F -q "mode: result_read_only" "$DOC"
grep -F -q "queue_write: false" "$DOC"
grep -F -q "job.id: 125" "$DOC"
grep -F -q "job.job_type: companion.chat" "$DOC"
grep -F -q "job.status: completed" "$DOC"
grep -F -q "job.attempts: 0" "$DOC"
grep -F -q "result.response_text: FC-O45-E-AB completed mock no-model result for Companion job 125." "$DOC"
grep -F -q "no_real_model_call: 1" "$DOC"
grep -F -q "no_worker_call: 1" "$DOC"
grep -F -q "no_scheduler_activation: 1" "$DOC"

grep -F -q "APC_COMPANION_RESULT_VISIBILITY_UI_FC_O45_E_Z" "$APP"
grep -F -q "X-APC-Companion-Result-Read-Only" "$BACKEND"
grep -F -q "result_read_only" "$BACKEND"

echo "RESULT=PASS stage-16-fc-o45-e-ab-f browser read proof smoke"
