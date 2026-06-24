#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-ad-f-r2-fresh-submit-bridge-proof-job-126.md"
APP="$REPO/frontend/wrapper-ui/app.js"

echo "=== stage-16-fc-o45-e-ad-f-r2 static proof smoke ==="
test -s "$DOC"
test -s "$APP"

grep -F -q "Fresh Companion submit bridge proof for job 126" "$DOC"
grep -F -q "User message: \`say hello in 1 sentence\`" "$DOC"
grep -F -q "Returned job id displayed: \`126\`" "$DOC"
grep -F -q "The job was found, but no result is available yet. HTTP 200." "$DOC"
grep -F -q "user_id=16" "$DOC"
grep -F -q "job_type=companion.chat" "$DOC"
grep -F -q "requested_model=mock/no-model" "$DOC"
grep -F -q "attempts=0" "$DOC"
grep -F -q "result_rows=0" "$DOC"
grep -F -q "remains uncompleted" "$DOC"

grep -F -q "APC_COMPANION_SUBMIT_RESULT_READER_BRIDGE_FC_O45_E_AD_E_R2" "$APP"
grep -F -q "apcCompanionResultReaderSetJobId" "$APP"
grep -F -q "apc_companion_latest_submitted_job_id" "$APP"

echo "RESULT=PASS stage-16-fc-o45-e-ad-f-r2 static proof smoke"
