#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-16-e3p-d-r7-completion-recovery-docs-no-rerun.md"
SCRIPT="$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

must_contain() {
  local needle="$1"
  grep -F -- "$needle" "$DOC" >/dev/null || fail "missing required text: $needle"
}

test -f "$DOC" || fail "missing doc"
test -f "$SCRIPT" || fail "missing operator dispatch artifact"
test -x "$SCRIPT" || fail "operator dispatch artifact not executable"
bash -n "$SCRIPT"

must_contain 'Stage 16 E3P-D-R7'
must_contain 'Completion Recovery Docs No-Rerun'
must_contain 'Do not rerun E3P-D for job 27.'
must_contain 'Job 27 status: `completed`'
must_contain 'Job 27 attempts: `1`'
must_contain 'Result rows for job 27: `1`'
must_contain 'Total jobs: `26`'
must_contain 'Total job_results: `9`'
must_contain 'Worker count: `2`'
must_contain 'Result contains `APC_E3P_OK`: yes'
must_contain 'Result contains `APC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT`: yes'
must_contain 'ONE_SHOT_MODEL_ADAPTER_RESULT=PASS'
must_contain 'MANUAL_COMPLETION_HELPER_DB_RESULT=PASS'
must_contain 'MANUAL_COMPLETION_HELPER_RESULT=PASS'
must_contain 'Ollama runner process count: `0`'
must_contain 'Non-localhost Ollama listener count: `0`'
must_contain 'CT101 status: `stopped`'
must_contain 'No scheduler activation'
must_contain 'No persistent worker activation'
must_contain 'No CT101 start'
must_contain 'No public PVESO/Ollama exposure'
must_contain 'No jobs 25/26 mutation'
must_contain 'No duplicate result row for job 27'
must_contain 'Do not activate scheduler or persistent workers yet.'

test -f "$ROOT/docs/stage-16-e3p-d-r6-helper-job-id-env-fix-no-rerun.md" || fail "missing R6 doc"
test -f "$ROOT/ops/smoke/check-stage-16-e3p-d-r6-helper-job-id-env-fix-no-rerun.sh" || fail "missing R6 smoke"

echo "PASS stage-16-e3p-d-r7-completion-recovery-docs-no-rerun smoke"
