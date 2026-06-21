#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh"
DOC="$ROOT/docs/stage-16-e3o-controlled-operator-dispatch-artifact-no-run.md"

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

must_contain_file "$SCRIPT" "E3O_NO_RUN_ARTIFACT"
must_contain_file "$SCRIPT" "E3O_NO_RUN_ARTIFACT_EXECUTION_DISABLED"
must_contain_file "$SCRIPT" "APC_OPERATOR_DISPATCH_APPROVAL"
must_contain_file "$SCRIPT" "APPROVE_STAGE_16_E3P_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION"
must_contain_file "$SCRIPT" "duplicate job_results"
must_contain_file "$SCRIPT" "PVESO Ollama is active and localhost-only"
must_contain_file "$SCRIPT" "browser never calls PVESO or Ollama directly"
must_contain_file "$SCRIPT" "DB completed with one result row: do not rerun"

must_contain_file "$DOC" "Stage 16 E3O"
must_contain_file "$DOC" "Controlled Operator Dispatch Artifact No-Run"
must_contain_file "$DOC" "This stage is no-run"
must_contain_file "$DOC" "No DB write"
must_contain_file "$DOC" "No helper execution"
must_contain_file "$DOC" "No adapter execution"
must_contain_file "$DOC" "No model endpoint call"
must_contain_file "$DOC" "No scheduler activation"
must_contain_file "$DOC" "No persistent worker activation"
must_contain_file "$DOC" "E3O_NO_RUN_ARTIFACT_EXECUTION_DISABLED"
must_contain_file "$DOC" "APPROVE_STAGE_16_E3P_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION"
must_contain_file "$DOC" "Duplicate result guard"
must_contain_file "$DOC" "Timeout recovery contract"

help_output="$(bash "$SCRIPT" --help)"
must_contain_text "$help_output" "Stage 16 E3O no-run artifact"
must_contain_text "$help_output" "Execution mode:"
must_contain_text "$help_output" "Hard boundaries:"

contract_output="$(bash "$SCRIPT" --contract)"
must_contain_text "$contract_output" "mode=E3O_NO_RUN_ARTIFACT"
must_contain_text "$contract_output" "controlled_dispatch_contract:"
must_contain_text "$contract_output" "duplicate_result_guard:"
must_contain_text "$contract_output" "public_boundary:"

plan_output="$(bash "$SCRIPT" --plan-only --job-id 27 --expected-model qwen2.5:32b-instruct-q4_K_M --run-root /tmp/apc-test-runs --max-runtime-seconds 7200)"
must_contain_text "$plan_output" "mode=plan-only"
must_contain_text "$plan_output" "dispatch_would_target_job_id=27"
must_contain_text "$plan_output" "E3O_NO_RUN_ARTIFACT: no CT203, PVESO, Ollama, model, helper, adapter, or DB action was performed."

set +e
disabled_output="$(APC_OPERATOR_DISPATCH_APPROVAL=APPROVE_STAGE_16_E3P_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION bash "$SCRIPT" --execute-approved --job-id 27 2>&1)"
disabled_rc="$?"
set -e

test "$disabled_rc" = "64" || fail "execute-approved should be disabled with rc=64, got rc=$disabled_rc"
must_contain_text "$disabled_output" "E3O_NO_RUN_ARTIFACT_EXECUTION_DISABLED"
must_contain_text "$disabled_output" "execution_is_intentionally_disabled_until_E3P=true"

test -f "$ROOT/ops/model/pveso-one-shot-generate.sh" || fail "missing one-shot adapter"
test -f "$ROOT/ops/model/manual-complete-queued-job-via-pveso-adapter.sh" || fail "missing manual completion helper"
test -f "$ROOT/docs/stage-16-e3n-controlled-operator-dispatch-design-no-apply.md" || fail "missing E3N design doc"
test -f "$ROOT/ops/smoke/check-stage-16-e3n-controlled-operator-dispatch-design-no-apply.sh" || fail "missing E3N smoke"

echo "PASS stage-16-e3o-controlled-operator-dispatch-artifact-no-run smoke"
