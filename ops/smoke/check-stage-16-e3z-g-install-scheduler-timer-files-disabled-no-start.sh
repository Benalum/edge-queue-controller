#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-g-install-scheduler-timer-files-disabled-no-start.md"
SMOKE="ops/smoke/check-stage-16-e3z-g-install-scheduler-timer-files-disabled-no-start.sh"

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

require_text 'MUTATION_SCOPE: approved CT203 disabled systemd file installation plus repo docs/smoke/commit/tag/push.' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_G_INSTALL_SCHEDULER_TIMER_FILES_DISABLED_NO_START' "$DOC"
require_text 'E3Z-G installed disabled scheduler service/timer artifacts inside CT203' "$DOC"
require_text 'service: `/etc/systemd/system/edge-queue-scheduler-one-shot.service`' "$DOC"
require_text 'timer: `/etc/systemd/system/edge-queue-scheduler-one-shot.timer`' "$DOC"
require_text 'env file: `/etc/edge-queue-controller/scheduler-one-shot.env`' "$DOC"
require_text 'harness: `/opt/edge-queue-controller/ops/scheduler/stage-16-e3z-scheduler-tick.sh`' "$DOC"
require_text 'timer enabled after install: `disabled`' "$DOC"
require_text 'EDGE_SCHEDULER_DELEGATION_COMMAND_ENABLED=0' "$DOC"
require_text 'Fresh proof job: `33`' "$DOC"
require_text 'status: `queued`' "$DOC"
require_text 'attempts: `0`' "$DOC"
require_text 'result_rows: `0`' "$DOC"
require_text 'jobs total: 32' "$DOC"
require_text 'job_results total: 12' "$DOC"
require_text 'queued/running Stage 16 proof jobs: 1' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_H_START_TIMER_ONE_TICK_ONE_FRESH_JOB_SCHEDULER_ONLY' "$DOC"
require_text 'E3Z-H must keep persistent workers disabled and CT101 stopped.' "$DOC"

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
  fail "unexpected changed paths outside E3Z-G doc/smoke"
fi

echo "E3Z-G disabled service/timer install smoke passed"
