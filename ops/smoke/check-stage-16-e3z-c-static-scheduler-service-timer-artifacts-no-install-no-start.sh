#!/usr/bin/env bash
set -euo pipefail

PHASE="stage-16-e3z-c-static-scheduler-service-timer-artifacts-no-install-no-start"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
HARNESS="ops/scheduler/stage-16-e3z-scheduler-tick.sh"
SERVICE="ops/systemd/edge-queue-scheduler-one-shot.service"
TIMER="ops/systemd/edge-queue-scheduler-one-shot.timer"

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
  pattern="$1"
  file="$2"
  grep -Fq "$pattern" "$file" || fail "missing required text in $file: $pattern"
}

for path in "$DOC" "$SMOKE" "$HARNESS" "$SERVICE" "$TIMER"; do
  require_file "$path"
done

require_executable "$SMOKE"
require_executable "$HARNESS"

bash -n "$SMOKE"
bash -n "$HARNESS"

"$HARNESS" --describe >/dev/null

require_text 'MUTATION_SCOPE: repo static artifacts, docs, smoke, commit, tag, and push only.' "$DOC"
require_text 'This phase creates repo-static templates and a fail-closed scheduler tick harness.' "$DOC"
require_text 'E3Z-C does not activate the scheduler.' "$DOC"
require_text 'E3Z-C does not enable/start the timer.' "$DOC"
require_text 'E3Z-C does not install the service.' "$DOC"
require_text 'E3Z-C does not enable/start persistent workers.' "$DOC"
require_text 'E3Z-C does not start CT101.' "$DOC"
require_text 'job 29' "$DOC"
require_text 'job 30' "$DOC"
require_text 'job 31' "$DOC"
require_text 'job 32' "$DOC"
require_text 'stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke' "$DOC"
require_text 'qwen2.5:0.5b' "$DOC"

require_text 'E3Z_SCHEDULER_TICK_REFUSAL' "$HARNESS"
require_text 'missing exact future activation approval token' "$HARNESS"
require_text 'historical proof job $JOB_ID is forbidden' "$HARNESS"
require_text 'persistent workers must remain disabled' "$HARNESS"
require_text 'delegation intentionally disabled in E3Z-C static artifact' "$HARNESS"
require_text 'APPROVE_STAGE_16_E3Z_TIMER_ONE_JOB_PER_TICK_FRESH_PROOF_ONLY' "$HARNESS"

require_text 'Type=oneshot' "$SERVICE"
require_text 'EnvironmentFile=-/etc/edge-queue-controller/scheduler-one-shot.env' "$SERVICE"
require_text 'EDGE_SCHEDULER_ONE_JOB_PER_TICK=1' "$SERVICE"
require_text 'EDGE_SCHEDULER_MAX_JOBS_PER_TICK=1' "$SERVICE"
require_text 'EDGE_PERSISTENT_LANE_WORKERS_ENABLED=0' "$SERVICE"
require_text 'EDGE_SCHEDULER_DELEGATION_COMMAND_ENABLED=0' "$SERVICE"
require_text 'stage-16-e3z-scheduler-tick.sh --run' "$SERVICE"

require_text 'Unit=edge-queue-scheduler-one-shot.service' "$TIMER"
require_text 'OnBootSec=5min' "$TIMER"
require_text 'OnUnitActiveSec=2min' "$TIMER"
require_text 'Persistent=false' "$TIMER"

if grep -Eq '(^|[[:space:]])(curl|wget|ollama|sqlite3|systemctl)([[:space:]]|$)' "$HARNESS"; then
  fail "harness must not directly call curl/wget/ollama/sqlite3/systemctl in E3Z-C"
fi

if [ -e "/etc/systemd/system/edge-queue-scheduler-one-shot.service" ]; then
  fail "live service unit path already exists; E3Z-C must not install service units"
fi

if [ -e "/etc/systemd/system/edge-queue-scheduler-one-shot.timer" ]; then
  fail "live timer unit path already exists; E3Z-C must not install timer units"
fi

STATUS_PATHS="$(git status --short --untracked-files=all | sed 's/^...//')"
ALLOWED_PATHS="$(cat <<EOF_ALLOWED
$DOC
$SMOKE
$HARNESS
$SERVICE
$TIMER
EOF_ALLOWED
)"

BAD_PATHS="$(printf '%s\n' "$STATUS_PATHS" | while IFS= read -r path; do
  [ -z "$path" ] && continue
  printf '%s\n' "$ALLOWED_PATHS" | grep -Fxq "$path" || printf '%s\n' "$path"
done)"

if [ -n "$BAD_PATHS" ]; then
  echo "$BAD_PATHS" >&2
  fail "unexpected changed paths outside E3Z-C artifacts"
fi

echo "E3Z-C static artifact smoke passed"
