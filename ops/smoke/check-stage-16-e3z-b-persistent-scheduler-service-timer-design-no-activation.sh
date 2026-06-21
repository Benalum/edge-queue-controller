#!/usr/bin/env bash
set -euo pipefail

PHASE="stage-16-e3z-b-persistent-scheduler-service-timer-design-no-activation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

require_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

require_text() {
  local pattern="$1"
  local file="$2"
  grep -Fq "$pattern" "$file" || fail "missing required text in $file: $pattern"
}

require_file "$DOC"
require_file "$SMOKE"

bash -n "$SMOKE"

require_text "MUTATION_SCOPE: repo docs/smoke/commit/tag/push only" "$DOC"
require_text "No service/timer install occurs in this phase." "$DOC"
require_text "No loop may continue selecting additional jobs in the same service invocation." "$DOC"
require_text "edge-queue-scheduler-one-shot.service" "$DOC"
require_text "edge-queue-scheduler-one-shot.timer" "$DOC"
require_text "ops/scheduler/stage-16-e3z-scheduler-tick.sh" "$DOC"
require_text "EDGE_QUEUE_CONTROLLER_DB_PATH=/var/lib/edge-queue-controller/edge_queue.sqlite3" "$DOC"
require_text "EDGE_SCHEDULER_ONE_JOB_PER_TICK=1" "$DOC"
require_text "EDGE_SCHEDULER_MAX_JOBS_PER_TICK=1" "$DOC"
require_text "EDGE_SCHEDULER_EXACT_JOB_ID=<fresh_job_id_only>" "$DOC"
require_text "EDGE_SCHEDULER_ALLOWED_JOB_TYPE=stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke" "$DOC"
require_text "EDGE_SCHEDULER_ALLOWED_MODEL=qwen2.5:0.5b" "$DOC"
require_text "EDGE_PERSISTENT_LANE_WORKERS_ENABLED=0" "$DOC"
require_text "Persistent workers: disabled" "$DOC"
require_text "CT101: stopped and onboot=0" "$DOC"
require_text "job 29" "$DOC"
require_text "job 30" "$DOC"
require_text "job 31" "$DOC"
require_text "job 32" "$DOC"
require_text "Activation refusal gates" "$DOC"
require_text "Rollback plan for future activation phase" "$DOC"
require_text "Postflight checks for future activation phase" "$DOC"
require_text "E3Z-C must not install, enable, start, restart, reload, or activate service/timer units." "$DOC"

STATUS_PATHS="$(git status --short | sed 's/^...//')"
BAD_PATHS="$(printf '%s\n' "$STATUS_PATHS" | awk -v d="$DOC" -v s="$SMOKE" 'NF && $0 != d && $0 != s {print}')"
if [ -n "$BAD_PATHS" ]; then
  echo "$BAD_PATHS" >&2
  fail "unexpected changed paths outside E3Z-B doc/smoke"
fi

if printf '%s\n' "$STATUS_PATHS" | grep -E '(^|/)([^/]+\.(service|timer)|etc/systemd|systemd/)'; then
  fail "E3Z-B must not create service/timer/systemd artifacts"
fi

echo "E3Z-B design smoke passed"
