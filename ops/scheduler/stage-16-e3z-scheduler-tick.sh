#!/usr/bin/env bash
set -euo pipefail
set +H

fail() {
  echo "E3Z_SCHEDULER_TICK_REFUSAL: $*" >&2
  exit 2
}

usage() {
  cat <<'EOF_USAGE'
stage-16-e3z-scheduler-tick.sh

Static fail-closed scheduler tick harness for Stage 16 E3Z.

Modes:
  --describe    Print the static contract and exit.
  --run         Future activation entrypoint. Refuses unless explicit gates pass.

E3Z-C does not execute scheduler dispatch. The harness is committed only as a repo-static artifact.
EOF_USAGE
}

MODE="${1:-}"

if [ "$MODE" = "--describe" ]; then
  usage
  exit 0
fi

if [ "$MODE" != "--run" ]; then
  usage
  fail "missing required mode; E3Z-C artifact defaults to refusal"
fi

EXPECTED_APPROVAL="APPROVE_STAGE_16_E3Z_TIMER_ONE_JOB_PER_TICK_FRESH_PROOF_ONLY"

if [ "${APC_STAGE16_E3Z_SCHEDULER_TIMER_APPROVAL:-}" != "$EXPECTED_APPROVAL" ]; then
  fail "missing exact future activation approval token"
fi

if [ "${EDGE_QUEUE_CONTROLLER_DB_PATH:-}" != "/var/lib/edge-queue-controller/edge_queue.sqlite3" ]; then
  fail "unexpected or missing EDGE_QUEUE_CONTROLLER_DB_PATH"
fi

if [ "${EDGE_SCHEDULER_MODE:-}" != "one-shot-timer" ]; then
  fail "unexpected or missing EDGE_SCHEDULER_MODE"
fi

if [ "${EDGE_SCHEDULER_ONE_JOB_PER_TICK:-}" != "1" ]; then
  fail "EDGE_SCHEDULER_ONE_JOB_PER_TICK must be 1"
fi

if [ "${EDGE_SCHEDULER_MAX_JOBS_PER_TICK:-}" != "1" ]; then
  fail "EDGE_SCHEDULER_MAX_JOBS_PER_TICK must be 1"
fi

if [ "${EDGE_SCHEDULER_MAX_RUNTIME_SECONDS:-}" != "120" ]; then
  fail "EDGE_SCHEDULER_MAX_RUNTIME_SECONDS must be 120 for first proof"
fi

case "${EDGE_PERSISTENT_LANE_WORKERS_ENABLED:-0}" in
  ""|0|false|FALSE|False|no|NO|No)
    ;;
  *)
    fail "persistent workers must remain disabled"
    ;;
esac

JOB_ID="${EDGE_SCHEDULER_EXACT_JOB_ID:-}"

case "$JOB_ID" in
  ''|*[!0-9]*)
    fail "EDGE_SCHEDULER_EXACT_JOB_ID must be a numeric fresh job id"
    ;;
  29|30|31|32)
    fail "historical proof job $JOB_ID is forbidden"
    ;;
esac

if [ "${EDGE_SCHEDULER_ALLOWED_JOB_TYPE:-}" != "stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke" ]; then
  fail "unexpected or missing EDGE_SCHEDULER_ALLOWED_JOB_TYPE"
fi

if [ "${EDGE_SCHEDULER_ALLOWED_MODEL:-}" != "qwen2.5:0.5b" ]; then
  fail "unexpected or missing EDGE_SCHEDULER_ALLOWED_MODEL"
fi

if [ "${EDGE_SCHEDULER_DELEGATION_COMMAND_ENABLED:-0}" != "1" ]; then
  fail "delegation intentionally disabled in E3Z-C static artifact; a later explicit activation phase must wire and approve it"
fi

fail "E3Z-C static artifact reached dispatch edge without an approved implementation phase"
