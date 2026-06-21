#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-j-start-timer-one-tick-exact-fresh-job-34-restricted-pveso-helper.md"
SMOKE="ops/smoke/check-stage-16-e3z-j-start-timer-one-tick-exact-fresh-job-34-restricted-pveso-helper.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
require_file() { [ -f "$1" ] || fail "missing file: $1"; }
require_text() { local pattern="$1"; local file="$2"; grep -Fq "$pattern" "$file" || fail "missing required text in $file: $pattern"; }

require_file "$DOC"
require_file "$SMOKE"
bash -n "$SMOKE"

require_text 'MUTATION_SCOPE: one bounded timer start, exact job 34, restricted PVESO helper model call, DB completion, finalization, then repo docs/smoke/commit/tag/push.' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_J_START_TIMER_ONE_TICK_EXACT_FRESH_JOB_34_RESTRICTED_PVESO_HELPER' "$DOC"
require_text 'E3Z-J completed the first bounded timer proof after the direct service proof.' "$DOC"
require_text 'APC_E3Z_J_MODEL_CALL_OK=1' "$DOC"
require_text 'APC_E3Z_J_HELPER_RUN_OK=1' "$DOC"
require_text 'E3Z_J_TIMER_EXACT_JOB_34_COMPLETION_OK=1' "$DOC"
require_text 'E3Z_J_JOB_RESULTS_TOTAL_AFTER=14' "$DOC"
require_text 'job_results_total=14' "$DOC"
require_text 'job_34_status=completed' "$DOC"
require_text 'job_34_attempts=1' "$DOC"
require_text 'job_34_result_rows=1' "$DOC"
require_text 'service_active=inactive' "$DOC"
require_text 'timer_enabled=disabled' "$DOC"
require_text 'env_delegation=0' "$DOC"
require_text 'e3z_j_dropin_present=0' "$DOC"
require_text 'E3Z_J_HELPER_PREFLIGHT_ONLY_POSTURE=1' "$DOC"
require_text 'Job 34 is now completed and must not be reused.' "$DOC"
require_text 'Stage 16 E3Z-K — Timer Rollback/Idle Guard and Source Refresh Decision' "$DOC"
require_text 'Persistent workers remain blocked.' "$DOC"

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
[ -z "$BAD_PATHS" ] || { echo "$BAD_PATHS" >&2; fail "unexpected changed paths outside E3Z-J doc/smoke"; }

echo "E3Z-J timer one-tick exact job 34 proof smoke passed"
