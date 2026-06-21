#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh"
DOC="$ROOT/docs/stage-16-e3p-d-r3-helper-approval-env-fix-no-rerun.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

must_contain_file() {
  local file="$1"
  local needle="$2"
  grep -F "$needle" "$file" >/dev/null || fail "missing required text in $file: $needle"
}

test -f "$SCRIPT" || fail "missing script"
test -x "$SCRIPT" || fail "script not executable"
test -f "$DOC" || fail "missing doc"

bash -n "$SCRIPT"

must_contain_file "$SCRIPT" "REQUIRED_EXEC_APPROVAL=\"APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION\""
must_contain_file "$SCRIPT" "HELPER_REQUIRED_APPROVAL=\"APPROVE_STAGE_16_E3M_B_RUN_MANUAL_COMPLETION_HELPER_FOR_ONE_QUEUED_JOB_ONE_MODEL_CALL_ONE_JOB_UPDATE_ONE_JOB_RESULT_INSERT_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_MODEL_PULL_NO_PUBLIC_EXPOSURE_KEEP_CT101_STOPPED\""
must_contain_file "$SCRIPT" "helper_required_approval=\$HELPER_REQUIRED_APPROVAL"
must_contain_file "$SCRIPT" "APC_MANUAL_COMPLETION_APPROVAL=\"\$HELPER_REQUIRED_APPROVAL\""
must_contain_file "$SCRIPT" "timeout \"\$MAX_RUNTIME_SECONDS\" bash \"\$HELPER_PATH\""
must_contain_file "$SCRIPT" "run_execute_approved"

must_contain_file "$DOC" "Stage 16 E3P-D-R3"
must_contain_file "$DOC" "Helper Approval Env Fix No-Rerun"
must_contain_file "$DOC" "manual helper refused with exit code \`64\`"
must_contain_file "$DOC" "APC_MANUAL_COMPLETION_APPROVAL"
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

echo "PASS stage-16-e3p-d-r3-helper-approval-env-fix-no-rerun smoke"
