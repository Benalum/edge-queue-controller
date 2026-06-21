#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh"
DOC="$ROOT/docs/stage-16-e3p-b-controlled-dispatch-implementation-no-run.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

must_contain_file() {
  local file="$1"
  local needle="$2"
  grep -F "$needle" "$file" >/dev/null || fail "missing required text in $file: $needle"
}

must_contain_text() {
  local text="$1"
  local needle="$2"
  printf '%s\n' "$text" | grep -F "$needle" >/dev/null || fail "missing required output text: $needle"
}

test -f "$SCRIPT" || fail "missing script: $SCRIPT"
test -x "$SCRIPT" || fail "script is not executable: $SCRIPT"
test -f "$DOC" || fail "missing doc: $DOC"

bash -n "$SCRIPT"

must_contain_file "$SCRIPT" "APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION"
must_contain_file "$SCRIPT" "run_execute_approved"
must_contain_file "$SCRIPT" "ct203_preflight_python"
must_contain_file "$SCRIPT" "ct203_postflight_python"
must_contain_file "$SCRIPT" "pveso_preflight_script"
must_contain_file "$SCRIPT" "target job has zero job_results rows"
must_contain_file "$SCRIPT" "duplicate_result_guard"
must_contain_file "$SCRIPT" "timeout_recovery"
must_contain_file "$SCRIPT" "manual-complete-queued-job-via-pveso-adapter.sh"
must_contain_file "$SCRIPT" "pveso-one-shot-generate.sh"
must_contain_file "$SCRIPT" "APC_E3P_OK"
must_contain_file "$SCRIPT" "APC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT"
must_contain_file "$SCRIPT" "E3P_EXECUTION_REFUSED"

must_contain_file "$DOC" "Stage 16 E3P-B"
must_contain_file "$DOC" "Controlled Dispatch Implementation No-Run"
must_contain_file "$DOC" "E3P-B itself is no-run"
must_contain_file "$DOC" "No DB write"
must_contain_file "$DOC" "No synthetic job insertion"
must_contain_file "$DOC" "No helper execution"
must_contain_file "$DOC" "No adapter execution"
must_contain_file "$DOC" "No operator dispatch execution"
must_contain_file "$DOC" "No CT203 contact"
must_contain_file "$DOC" "No PVESO contact"
must_contain_file "$DOC" "No Ollama contact"
must_contain_file "$DOC" "APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION"
must_contain_file "$DOC" "APPROVE_STAGE_16_E3P_C_INSERT_ONE_SYNTHETIC_OPERATOR_DISPATCH_JOB_ONLY"

help_output="$(bash "$SCRIPT" --help)"
must_contain_text "$help_output" "Stage 16 E3P-B execution-capable artifact"
must_contain_text "$help_output" "Safe local modes:"
must_contain_text "$help_output" "Execution mode for later approved E3P-D:"

contract_output="$(bash "$SCRIPT" --contract)"
must_contain_text "$contract_output" "mode=E3P_B_EXECUTION_CAPABLE_NO_RUN"
must_contain_text "$contract_output" "controlled_dispatch_contract:"
must_contain_text "$contract_output" "duplicate_result_guard:"
must_contain_text "$contract_output" "public_boundary:"

plan_output="$(bash "$SCRIPT" --plan-only --job-id 27 --expected-model qwen2.5:32b-instruct-q4_K_M --run-root /tmp/apc-test-runs --max-runtime-seconds 7200)"
must_contain_text "$plan_output" "mode=plan-only"
must_contain_text "$plan_output" "dispatch_would_target_job_id=27"
must_contain_text "$plan_output" "E3P_B_NO_RUN_PLAN: no CT203, PVESO, Ollama, model, helper, adapter, or DB action was performed."

set +e
refused_output="$(bash "$SCRIPT" --execute-approved --job-id 27 2>&1)"
refused_rc="$?"
set -e

test "$refused_rc" = "64" || fail "execute-approved without approval should refuse with rc=64, got rc=$refused_rc"
must_contain_text "$refused_output" "E3P_EXECUTION_REFUSED"
must_contain_text "$refused_output" "missing_or_wrong_approval_marker=true"

test -f "$ROOT/ops/model/pveso-one-shot-generate.sh" || fail "missing one-shot adapter"
test -f "$ROOT/ops/model/manual-complete-queued-job-via-pveso-adapter.sh" || fail "missing manual completion helper"
test -f "$ROOT/docs/stage-16-e3p-a-controlled-dispatch-runtime-plan-no-apply.md" || fail "missing E3P-A plan doc"
test -f "$ROOT/ops/smoke/check-stage-16-e3p-a-controlled-dispatch-runtime-plan-no-apply.sh" || fail "missing E3P-A smoke"

echo "PASS stage-16-e3p-b-controlled-dispatch-implementation-no-run smoke"
