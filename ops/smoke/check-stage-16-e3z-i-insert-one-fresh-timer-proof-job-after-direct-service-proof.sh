#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-i-insert-one-fresh-timer-proof-job-after-direct-service-proof.md"
SMOKE="ops/smoke/check-stage-16-e3z-i-insert-one-fresh-timer-proof-job-after-direct-service-proof.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
require_file() { [ -f "$1" ] || fail "missing file: $1"; }
require_text() { local pattern="$1"; local file="$2"; grep -Fq "$pattern" "$file" || fail "missing required text in $file: $pattern"; }

require_file "$DOC"
require_file "$SMOKE"
bash -n "$SMOKE"

require_text 'MUTATION_SCOPE: one CT203 DB job insert plus repo docs/smoke/commit/tag/push.' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_I_INSERT_ONE_FRESH_TIMER_PROOF_JOB_AFTER_DIRECT_SERVICE_PROOF' "$DOC"
require_text 'inserted_job_id=34' "$DOC"
require_text 'job_type=stage16_e3z_i_timer_proof_after_direct_service_small_model_completion_smoke' "$DOC"
require_text 'requested_model=qwen2.5:0.5b' "$DOC"
require_text 'status=queued' "$DOC"
require_text 'attempts=0' "$DOC"
require_text 'result_rows=0' "$DOC"
require_text 'jobs_total=33' "$DOC"
require_text 'job_results_total=13' "$DOC"
require_text 'fresh_job_id=34' "$DOC"
require_text 'fresh_job_status=queued' "$DOC"
require_text 'fresh_job_attempts=0' "$DOC"
require_text 'fresh_job_result_rows=0' "$DOC"
require_text 'job_33_status=completed' "$DOC"
require_text 'service_active=inactive' "$DOC"
require_text 'timer_enabled=disabled' "$DOC"
require_text 'env_delegation=0' "$DOC"
require_text 'Job 33 is completed and must not be reused.' "$DOC"
require_text 'Stage 16 E3Z-J — Start Timer One Tick, Exact Fresh Job 34' "$DOC"
require_text 'keep persistent workers blocked' "$DOC"

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
[ -z "$BAD_PATHS" ] || { echo "$BAD_PATHS" >&2; fail "unexpected changed paths outside E3Z-I doc/smoke"; }

echo "E3Z-I fresh timer proof job insert smoke passed"
