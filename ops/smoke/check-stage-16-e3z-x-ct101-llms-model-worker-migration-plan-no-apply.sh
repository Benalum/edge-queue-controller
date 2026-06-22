#!/usr/bin/env bash
set -euo pipefail
DOC="docs/stage-16-e3z-x-ct101-llms-model-worker-migration-plan-no-apply.md"

[ -f "$DOC" ] || { echo "missing_doc=$DOC"; exit 1; }

require_literal() {
  local pattern="$1"
  if ! grep -Fq -- "$pattern" "$DOC"; then
    echo "missing_required_pattern=$pattern"
    exit 1
  fi
}

require_literal "E3Z_X_NO_APPLY_PLAN=1"
require_literal "E3Z_X_NO_LIVE_INFRA_MUTATION=1"
require_literal "E3Z_X_NO_CT_START_STOP_RESTART=1"
require_literal "E3Z_X_NO_SERVICE_OR_TIMER_ACTIVATION=1"
require_literal "E3Z_X_NO_SYSTEMCTL_DAEMON_RELOAD=1"
require_literal "E3Z_X_NO_DB_WRITE_OR_JOB_MUTATION=1"
require_literal "E3Z_X_NO_MODEL_OR_OLLAMA_ENDPOINT_CALL=1"
require_literal "E3Z_X_CT101_LLMS_REPLICABLE_MODEL_WORKER_TARGET=1"
require_literal "E3Z_X_PVESO_HOST_OLLAMA_LEGACY_TEMPORARY_PATH=1"
require_literal "E3Z_X_THIN_COMPANION_VERTICAL_SLICE_AFTER_CT101_PROOF=1"
require_literal "CT203 remains the controller, scheduler, queue, and database authority."
require_literal "CT101 llms becomes the model runtime container on PVESO."
require_literal "Only after CT101 worker path is proven, build the thin companion vertical slice."
require_literal "running systemctl daemon-reload;"
require_literal "any DB write, job claim, job retry, status update, result insert, or model call."

echo "E3Z_X_R3_SMOKE_OK=1"
