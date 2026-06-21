#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh"
DOC="$ROOT/docs/stage-16-e3p-d-r1-pveso-runner-count-preflight-fix-no-rerun.md"

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

must_contain_file "$SCRIPT" "awk '/[o]llama serve/ {n++} END {print n+0}'"
must_contain_file "$SCRIPT" "awk '/[o]llama_llama_server|[o]llama runner|[r]unners\\// {n++} END {print n+0}'"
must_contain_file "$SCRIPT" "APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION"
must_contain_file "$SCRIPT" "run_execute_approved"
must_contain_file "$SCRIPT" "pveso_preflight_script"
must_contain_file "$SCRIPT" "ct203_preflight_python"
must_contain_file "$SCRIPT" "ct203_postflight_python"

must_contain_file "$DOC" "Stage 16 E3P-D-R1"
must_contain_file "$DOC" "PVESO Runner Count Preflight Fix No-Rerun"
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

test "$refused_rc" = "64" || fail "execute-approved without approval should refuse with rc=64, got $refused_rc"
printf '%s\n' "$refused_output" | grep -F "E3P_EXECUTION_REFUSED" >/dev/null || fail "refusal output missing marker"

echo "PASS stage-16-e3p-d-r1-pveso-runner-count-preflight-fix-no-rerun smoke"
