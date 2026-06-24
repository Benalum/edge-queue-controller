#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-ad-g-r2-end-to-end-submit-result-reader-proof-job-126.md"
APP="$REPO/frontend/wrapper-ui/app.js"
BACKEND="$REPO/edge_controller.py"

echo "=== stage-16-fc-o45-e-ad-g-r2 end-to-end proof smoke ==="
test -s "$DOC"
test -s "$APP"
test -s "$BACKEND"

grep -F -q "End-to-end Companion submit/result-reader proof for job 126" "$DOC"
grep -F -q "say hello in 1 sentence" "$DOC"
grep -F -q "queued job \`126\`" "$DOC"
grep -F -q "The job was found, but no result is available yet. HTTP 200." "$DOC"
grep -F -q "PASS: Companion result read path returned a result." "$DOC"
grep -F -q "job_id: 126" "$DOC"
grep -F -q "status: completed" "$DOC"
grep -F -q "job_type: companion.chat" "$DOC"
grep -F -q "requested_model: mock/no-model" "$DOC"
grep -F -q "queue_write: false" "$DOC"
grep -F -q "Hello! I am here and ready to help." "$DOC"
grep -F -q "no real model call" "$DOC"
grep -F -q "no worker call" "$DOC"
grep -F -q "no scheduler activation" "$DOC"

grep -F -q "APC_COMPANION_SUBMIT_RESULT_READER_BRIDGE_FC_O45_E_AD_E_R2" "$APP"
grep -F -q "apcCompanionResultReaderSetJobId" "$APP"
grep -F -q "X-APC-Companion-Result-Read-Only" "$APP"
grep -F -q "result_read_only" "$BACKEND"

echo "RESULT=PASS stage-16-fc-o45-e-ad-g-r2 end-to-end proof smoke"
