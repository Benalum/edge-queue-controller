#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-16-e3p-c-r2-smoke-quote-recovery-no-runtime.md"
PATCHED="$ROOT/ops/smoke/check-stage-16-e3p-c-insert-one-synthetic-operator-dispatch-job-only.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

must_contain_file() {
  local file="$1"
  local needle="$2"
  grep -F "$needle" "$file" >/dev/null || fail "missing required text in $file: $needle"
}

test -f "$DOC" || fail "missing doc: $DOC"
test -f "$PATCHED" || fail "missing patched smoke: $PATCHED"
test -x "$PATCHED" || fail "patched smoke not executable: $PATCHED"

bash -n "$PATCHED"

must_contain_file "$PATCHED" "must_contain 'Job ID: \`27\`'"
must_contain_file "$PATCHED" "must_contain 'Job type: \`stage16_e3p_operator_dispatch_synthetic_model_smoke\`'"
must_contain_file "$PATCHED" "must_contain 'Expected response token for later E3P-D: \`APC_E3P_OK\`'"
must_contain_file "$PATCHED" "must_contain 'Expected result marker for later E3P-D: \`APC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT\`'"

must_contain_file "$DOC" "Stage 16 E3P-C-R2"
must_contain_file "$DOC" "Smoke Quote Recovery No-Runtime"
must_contain_file "$DOC" "No DB write"
must_contain_file "$DOC" "No helper execution"
must_contain_file "$DOC" "No adapter execution"
must_contain_file "$DOC" "No operator dispatch execution"
must_contain_file "$DOC" "No PVESO contact"
must_contain_file "$DOC" "No Ollama contact"
must_contain_file "$DOC" "Job ID: \`27\`"
must_contain_file "$DOC" "Result rows for job 27: \`0\`"
must_contain_file "$DOC" "APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION"

smoke_output="$("$PATCHED" 2>&1)"
printf '%s\n' "$smoke_output"

if printf '%s\n' "$smoke_output" | grep -F "command not found" >/dev/null; then
  fail "patched E3P-C smoke still emitted command-not-found output"
fi

printf '%s\n' "$smoke_output" | grep -F "PASS stage-16-e3p-c-insert-one-synthetic-operator-dispatch-job-only smoke" >/dev/null \
  || fail "patched E3P-C smoke did not pass"

echo "PASS stage-16-e3p-c-r2-smoke-quote-recovery-no-runtime smoke"
