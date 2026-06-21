#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-f-insert-one-fresh-timer-proof-job-only.md"
SMOKE="ops/smoke/check-stage-16-e3z-f-insert-one-fresh-timer-proof-job-only.sh"
INSERTED_JOB_ID="33"

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

case "$INSERTED_JOB_ID" in
  ''|*[!0-9]*) fail "inserted job id is not numeric: $INSERTED_JOB_ID" ;;
  29|30|31|32) fail "inserted job id must not be historical forbidden job id" ;;
esac

require_text 'MUTATION_SCOPE: approved CT203 DB insert of exactly one fresh queued proof job plus repo docs/smoke/commit/tag/push.' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_F_INSERT_ONE_FRESH_TIMER_PROOF_JOB_ONLY' "$DOC"
require_text 'inserted_job_id: `33`' "$DOC"
require_text 'status: `queued`' "$DOC"
require_text 'job_type: `stage16_e3z_scheduler_timer_fresh_small_model_completion_smoke`' "$DOC"
require_text 'model: `qwen2.5:0.5b`' "$DOC"
require_text 'attempts: `0`' "$DOC"
require_text 'result_rows: `0`' "$DOC"
require_text 'DB integrity after insert: `ok`' "$DOC"
require_text 'duplicate job_results after insert: `0`' "$DOC"
require_text 'queued/running Stage 16 proof jobs after insert: `1`' "$DOC"
require_text 'Do not run the E3Z-F inserted job except through an approved E3Z-H bounded scheduler-only timer activation phase.' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_G_INSTALL_SCHEDULER_TIMER_FILES_DISABLED_NO_START' "$DOC"

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
  fail "unexpected changed paths outside E3Z-F doc/smoke"
fi

echo "E3Z-F fresh proof job insertion smoke passed"
