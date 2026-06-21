#!/usr/bin/env bash
set -euo pipefail

PHASE="stage-16-e3z-e-source-refresh-and-activation-handoff-checkpoint"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
E3Z_D_DOC="docs/stage-16-e3z-d-activation-and-rollback-plan-no-live-mutation.md"
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
require_file "$E3Z_D_DOC"
require_file "$E3Z_C_HARNESS"
require_file "$E3Z_C_SERVICE"
require_file "$E3Z_C_TIMER"
require_executable "$SMOKE"
require_executable "$E3Z_C_HARNESS"

bash -n "$SMOKE"
bash -n "$E3Z_C_HARNESS"

require_text 'MUTATION_SCOPE: repo docs/smoke/commit/tag/push only.' "$DOC"
require_text 'E3Z-E is a source-refresh and new-chat handoff checkpoint before any live scheduler service/timer activation.' "$DOC"
require_text 'Previous HEAD/origin/main: `bee501f`' "$DOC"
require_text 'controller-stage-16-e3z-d-activation-and-rollback-plan-no-live-mutation-2026-06-21' "$DOC"
require_text 'Persistent scheduler: blocked' "$DOC"
require_text 'Persistent workers: disabled' "$DOC"
require_text 'CT101: stopped and onboot=0' "$DOC"
require_text 'E3Z-F fresh proof job insertion' "$DOC"
require_text 'E3Z-G install service/timer files disabled, no start' "$DOC"
require_text 'E3Z-H bounded scheduler-only timer activation' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_F_INSERT_ONE_FRESH_TIMER_PROOF_JOB_ONLY' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_G_INSTALL_SCHEDULER_TIMER_FILES_DISABLED_NO_START' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_H_START_TIMER_ONE_TICK_ONE_FRESH_JOB_SCHEDULER_ONLY' "$DOC"
require_text 'job 29' "$DOC"
require_text 'job 30' "$DOC"
require_text 'job 31' "$DOC"
require_text 'job 32' "$DOC"
require_text 'Future runtime proof must use a fresh job.' "$DOC"
require_text 'use file-based PPB scripts for larger phases to avoid heredoc paste corruption' "$DOC"

require_text 'E3Z-D does not authorize live activation.' "$E3Z_D_DOC"
require_text 'EDGE_SCHEDULER_DELEGATION_COMMAND_ENABLED=0' "$E3Z_C_SERVICE"
require_text 'Persistent=false' "$E3Z_C_TIMER"

if [ -e "/etc/systemd/system/edge-queue-scheduler-one-shot.service" ]; then
  fail "live service unit path exists; E3Z-E must not install service units"
fi

if [ -e "/etc/systemd/system/edge-queue-scheduler-one-shot.timer" ]; then
  fail "live timer unit path exists; E3Z-E must not install timer units"
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
  fail "unexpected changed paths outside E3Z-E doc/smoke"
fi

echo "E3Z-E source refresh and activation handoff checkpoint smoke passed"
