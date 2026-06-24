#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-ab-e-complete-job-125-no-model-result.md"
BACKEND="$REPO/edge_controller.py"

echo "=== stage-16-fc-o45-e-ab-e static proof smoke ==="
test -s "$DOC"
test -s "$BACKEND"

grep -F -q "Complete fresh Companion job 125 with no-model result" "$DOC"
grep -F -q "id: \`125\`" "$DOC"
grep -F -q "user_id: \`16\`" "$DOC"
grep -F -q "job_type: \`companion.chat\`" "$DOC"
grep -F -q "requested_model: \`mock/no-model\`" "$DOC"
grep -F -q "FC-O45-E-AB completed mock no-model result for Companion job 125." "$DOC"
grep -F -q "updated only job \`125\`" "$DOC"
grep -F -q "X-APC-Companion-Result-Read-Only" "$BACKEND"
grep -F -q "result_read_only" "$BACKEND"

echo "RESULT=PASS stage-16-fc-o45-e-ab-e static proof smoke"
