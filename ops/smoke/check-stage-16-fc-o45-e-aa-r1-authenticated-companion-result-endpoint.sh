#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
BACKEND="$REPO/edge_controller.py"
APP="$REPO/frontend/wrapper-ui/app.js"
DOC="$REPO/docs/stage-16-fc-o45-e-aa-r1-authenticated-companion-result-endpoint.md"

echo "=== stage-16-fc-o45-e-aa-r3 static smoke ==="

test -s "$BACKEND"
test -s "$APP"
test -s "$DOC"

grep -F -q 'APC_COMPANION_RESULT_READ_API_FC_O45_E_AA' "$BACKEND"
grep -F -q '@app.get("/api/companion/jobs/{job_id}/result")' "$BACKEND"
grep -F -q '_auth_current_user_from_request(request)' "$BACKEND"
grep -F -q "job_type = 'companion.chat'" "$BACKEND"
grep -F -q 'response_text' "$BACKEND"

grep -F -q '/api/companion/jobs/124/result' "$APP"
grep -F -q 'method: "GET"' "$APP"
grep -F -q 'credentials: "same-origin"' "$APP"
grep -F -q 'Check Companion result for job 124' "$APP"

grep -F -q 'GET /api/companion/jobs/{job_id}/result' "$DOC"
grep -F -q 'did not create jobs' "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-aa-r3 static smoke"
