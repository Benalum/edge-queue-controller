#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
APP="$REPO/frontend/wrapper-ui/app.js"
INDEX="$REPO/frontend/wrapper-ui/index.html"
DOC="$REPO/docs/stage-16-fc-o45-e-ad-e-r2-submit-returned-job-id-result-reader-bridge.md"

echo "=== stage-16-fc-o45-e-ad-e-r2 static smoke ==="
test -s "$APP"
test -s "$INDEX"
test -s "$DOC"

grep -F -q "APC_COMPANION_SUBMIT_RESULT_READER_BRIDGE_FC_O45_E_AD_E_R2" "$APP"
grep -F -q "apcCompanionResultReaderSetJobId" "$APP"
grep -F -q "apc_companion_latest_submitted_job_id" "$APP"
grep -F -q "Latest submitted Companion job id" "$APP"
grep -F -q "Click Read result to check this job without creating another job" "$APP"
grep -F -q "queuedChatUiState.lastJobId = jobId;" "$APP"
grep -F -q "20260624fc045eader2" "$INDEX"
grep -F -q "Companion submit returned job id result-reader bridge" "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-ad-e-r2 static smoke"
