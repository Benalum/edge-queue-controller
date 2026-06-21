#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh"
DOC="$ROOT/docs/stage-16-e3p-d-r6-helper-job-id-env-fix-no-rerun.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

must_contain_file() {
  local file="$1"
  local needle="$2"
  grep -F -- "$needle" "$file" >/dev/null || fail "missing required text in $file: $needle"
}

test -f "$SCRIPT" || fail "missing script"
test -x "$SCRIPT" || fail "script not executable"
test -f "$DOC" || fail "missing doc"

bash -n "$SCRIPT"

must_contain_file "$SCRIPT" 'APC_MANUAL_COMPLETION_APPROVAL="$HELPER_REQUIRED_APPROVAL"'
must_contain_file "$SCRIPT" 'JOB_ID="$JOB_ID"'
must_contain_file "$SCRIPT" 'timeout "$MAX_RUNTIME_SECONDS" bash "$HELPER_PATH"'
must_contain_file "$SCRIPT" '--job-id "$JOB_ID"'
must_contain_file "$SCRIPT" 'HELPER_REQUIRED_APPROVAL='
must_contain_file "$SCRIPT" 'REQUIRED_EXEC_APPROVAL="APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION"'

must_contain_file "$DOC" "Stage 16 E3P-D-R6"
must_contain_file "$DOC" "Helper JOB_ID Env Fix No-Rerun"
must_contain_file "$DOC" "job_id_guard=FAIL missing JOB_ID"
must_contain_file "$DOC" 'JOB_ID="$JOB_ID"'
must_contain_file "$DOC" "Job 27 status: \`queued\`"
must_contain_file "$DOC" "Job 27 result rows: \`0\`"
must_contain_file "$DOC" "PVESO runner count: \`0\`"
must_contain_file "$DOC" "No DB write"
must_contain_file "$DOC" "No helper execution"
must_contain_file "$DOC" "No adapter execution"
must_contain_file "$DOC" "No operator dispatch execution"
must_contain_file "$DOC" "No model endpoint call"
must_contain_file "$DOC" "Do not rerun against jobs 25 or 26"

plan_output="$(bash "$SCRIPT" --plan-only --job-id 27 --expected-model qwen2.5:32b-instruct-q4_K_M --run-root /tmp/apc-test-runs --max-runtime-seconds 7200)"
printf '%s\n' "$plan_output" | grep -F "E3P_B_NO_RUN_PLAN" >/dev/null || fail "plan-only output missing no-run marker"

set +e
refused_output="$(bash "$SCRIPT" --execute-approved --job-id 27 2>&1)"
refused_rc="$?"
set -e

test "$refused_rc" = "64" || fail "execute-approved without operator approval should refuse with rc=64, got $refused_rc"
printf '%s\n' "$refused_output" | grep -F "E3P_EXECUTION_REFUSED" >/dev/null || fail "refusal output missing marker"

echo "PASS stage-16-e3p-d-r6-helper-job-id-env-fix-no-rerun smoke"
