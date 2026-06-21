#!/usr/bin/env bash
set -euo pipefail

PHASE="stage-16-e3z-d-activation-and-rollback-plan-no-live-mutation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
E3Z_C_DOC="docs/stage-16-e3z-c-static-scheduler-service-timer-artifacts-no-install-no-start.md"
E3Z_C_HARNESS="ops/scheduler/stage-16-e3z-scheduler-tick.sh"
E3Z_C_SERVICE="ops/systemd/edge-queue-scheduler-one-shot.service"
E3Z_C_TIMER="ops/systemd/edge-queue-scheduler-one-shot.timer"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

require_executable() {
  [ -x "$1" ] || fail "missing executable file: $1"
}

require_text() {
  local pattern="$1"
  local file="$2"
  grep -Fq "$pattern" "$file" || fail "missing required text in $file: $pattern"
}

require_file "$DOC"
require_file "$SMOKE"
require_file "$E3Z_C_DOC"
require_file "$E3Z_C_HARNESS"
require_file "$E3Z_C_SERVICE"
require_file "$E3Z_C_TIMER"
require_executable "$SMOKE"
require_executable "$E3Z_C_HARNESS"

bash -n "$SMOKE"
bash -n "$E3Z_C_HARNESS"

require_text 'E3Z-C does not activate the scheduler.' "$E3Z_C_DOC"
require_text 'EDGE_SCHEDULER_DELEGATION_COMMAND_ENABLED=0' "$E3Z_C_SERVICE"
require_text 'Persistent=false' "$E3Z_C_TIMER"

require_text 'MUTATION_SCOPE: repo docs/smoke/commit/tag/push only.' "$DOC"
require_text 'E3Z-D is a planning phase only.' "$DOC"
require_text 'E3Z-D does not authorize live activation.' "$DOC"
require_text 'Previous HEAD/origin/main: `5f8104d`' "$DOC"
require_text 'controller-stage-16-e3z-c-static-scheduler-service-timer-artifacts-no-install-no-start-2026-06-21' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_F_INSERT_ONE_FRESH_TIMER_PROOF_JOB_ONLY' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_G_INSTALL_SCHEDULER_TIMER_FILES_DISABLED_NO_START' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_H_START_TIMER_ONE_TICK_ONE_FRESH_JOB_SCHEDULER_ONLY' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_TIMER_ONE_JOB_PER_TICK_FRESH_PROOF_ONLY' "$DOC"
require_text 'EDGE_QUEUE_CONTROLLER_DB_PATH=/var/lib/edge-queue-controller/edge_queue.sqlite3' "$DOC"
require_text 'EDGE_SCHEDULER_EXACT_JOB_ID=<fresh_job_id_only>' "$DOC"
require_text 'EDGE_SCHEDULER_ALLOWED_JOB_TYPE=stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke' "$DOC"
require_text 'EDGE_SCHEDULER_ALLOWED_MODEL=qwen2.5:0.5b' "$DOC"
require_text 'EDGE_PERSISTENT_LANE_WORKERS_ENABLED=0' "$DOC"
require_text 'EDGE_SCHEDULER_DELEGATION_COMMAND_ENABLED=1' "$DOC"
require_text 'job 29' "$DOC"
require_text 'job 30' "$DOC"
require_text 'job 31' "$DOC"
require_text 'job 32' "$DOC"
require_text 'No daemon loop is allowed.' "$DOC"
require_text 'No broad queue drain is allowed.' "$DOC"
require_text 'Future rollback commands' "$DOC"
require_text 'Future rollback verification' "$DOC"
require_text 'Future postflight after bounded activation' "$DOC"
require_text 'Persistent workers remain blocked until scheduler-only service/timer activation is proven safe.' "$DOC"

if [ -e "/etc/systemd/system/edge-queue-scheduler-one-shot.service" ]; then
  fail "live service unit path exists; E3Z-D must not install service units"
fi

if [ -e "/etc/systemd/system/edge-queue-scheduler-one-shot.timer" ]; then
  fail "live timer unit path exists; E3Z-D must not install timer units"
fi

STATUS_PATHS="$(git status --short --untracked-files=all | sed 's/^...//')"
ALLOWED_PATHS="$(cat <<EOF_ALLOWED
$DOC
$SMOKE
EOF_ALLOWED
)"

BAD_PATHS="$(printf '%s\n' "$STATUS_PATHS" | while IFS= read -r path; do
  [ -z "$path" ] && continue
  printf '%s\n' "$ALLOWED_PATHS" | grep -Fxq "$path" || printf '%s\n' "$path"
done)"

if [ -n "$BAD_PATHS" ]; then
  echo "$BAD_PATHS" >&2
  fail "unexpected changed paths outside E3Z-D doc/smoke"
fi

echo "E3Z-D activation and rollback plan smoke passed"
