#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-h-r13-start-service-once-exact-job-33-restricted-pveso-helper.md"
SMOKE="ops/smoke/check-stage-16-e3z-h-r13-start-service-once-exact-job-33-restricted-pveso-helper.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }
require_file() { [ -f "$1" ] || fail "missing file: $1"; }
require_text() { local pattern="$1"; local file="$2"; grep -Fq "$pattern" "$file" || fail "missing required text in $file: $pattern"; }

require_file "$DOC"
require_file "$SMOKE"
bash -n "$SMOKE"

require_text 'MUTATION_SCOPE: one service start, exact job 33, restricted PVESO helper model call, DB completion recovery, finalization, then repo docs/smoke/commit/tag/push.' "$DOC"
require_text 'APPROVE_STAGE_16_E3Z_H_R13_START_SERVICE_ONCE_EXACT_JOB_33_RESTRICTED_PVESO_HELPER' "$DOC"
require_text 'R13 completed the direct service proof for exact job 33 through the restricted PVESO helper path.' "$DOC"
require_text 'R13B performed DB-only recovery using the already captured R13 service log output.' "$DOC"
require_text 'APC_E3Z_H_R13_MODEL_CALL_OK=1' "$DOC"
require_text 'APC_E3Z_H_R13_HELPER_RUN_OK=1' "$DOC"
require_text 'R13_MODEL_RESPONSE_DECODED=E3Z-H-R13-' "$DOC"
require_text 'service_active=inactive' "$DOC"
require_text 'timer_enabled=disabled' "$DOC"
require_text 'env_delegation=0' "$DOC"
require_text 'r13_dropin_present=0' "$DOC"
require_text 'E3Z_H_R13B_HELPER_PREFLIGHT_ONLY_POSTURE=1' "$DOC"
require_text 'job_results_total=13' "$DOC"
require_text 'job_33_status=completed' "$DOC"
require_text 'job_33_attempts=1' "$DOC"
require_text 'job_33_result_rows=1' "$DOC"
require_text 'job 33 is now completed and must not be reused' "$DOC"
require_text 'Stage 16 E3Z-I — Insert Fresh Timer Proof Job After Direct Service Proof' "$DOC"
require_text 'Persistent workers remain blocked.' "$DOC"

require_text "R13D repo closure verified after R13B DB-only recovery." "$DOC"

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
[ -z "$BAD_PATHS" ] || { echo "$BAD_PATHS" >&2; fail "unexpected changed paths outside R13 doc/smoke"; }

echo "E3Z-H R13 DB-only recovery closure smoke passed"
