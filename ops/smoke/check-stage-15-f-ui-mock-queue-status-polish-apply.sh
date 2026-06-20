#!/usr/bin/env bash
set -euo pipefail
set +H

echo "=== Stage 15-F smoke ==="

APP_JS="frontend/wrapper-ui/app.js"
DOC="docs/stage-15-f-ui-mock-queue-status-polish-apply.md"

test -f "$APP_JS"
test -f "$DOC"

require_text() {
  file="$1"
  needle="$2"
  if grep -F -- "$needle" "$file" >/dev/null 2>&1; then
    echo "PASS: found text in $file: $needle"
  else
    echo "FAIL: missing text in $file: $needle"
    exit 1
  fi
}

require_text "$APP_JS" "STAGE_15_F_MOCK_QUEUE_STATUS_POLISH_BEGIN"
require_text "$APP_JS" "STAGE_15_F_MOCK_QUEUE_SUMMARY_QUEUED_STATE_BEGIN"
require_text "$APP_JS" "Your message is queued safely. The model worker is not active yet"
require_text "$APP_JS" "mock/no-model"
require_text "$APP_JS" "model_call"
require_text "$APP_JS" "not_started"
require_text "$APP_JS" 'stage5p10fSetText("queuedChatQueueSummary", "Queued")'
require_text "$APP_JS" 'const job = data && data.job ? data.job : (data && data.job_id ? data : null);'

require_text "$DOC" "No backend mutation."
require_text "$DOC" "No database write."
require_text "$DOC" "No worker activation."
require_text "$DOC" "No scheduler activation."
require_text "$DOC" "No live model endpoint call."

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
  echo "PASS: node syntax check"
else
  echo "node_not_available=skipped"
fi

echo "PASS_STAGE_15_F_SMOKE"
