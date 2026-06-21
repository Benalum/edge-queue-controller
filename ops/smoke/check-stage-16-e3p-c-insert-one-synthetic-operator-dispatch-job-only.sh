#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-16-e3p-c-insert-one-synthetic-operator-dispatch-job-only.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

must_contain() {
  local needle="$1"
  grep -F "$needle" "$DOC" >/dev/null || fail "missing required text: $needle"
}

test -f "$DOC" || fail "missing doc: $DOC"

must_contain 'Stage 16 E3P-C'
must_contain 'Insert One Synthetic Operator Dispatch Job Only'
must_contain 'APPROVE_STAGE_16_E3P_C_INSERT_ONE_SYNTHETIC_OPERATOR_DISPATCH_JOB_ONLY'
must_contain 'Job ID: `27`'
must_contain 'Job type: `stage16_e3p_operator_dispatch_synthetic_model_smoke`'
must_contain 'Requested model: `qwen2.5:32b-instruct-q4_K_M`'
must_contain 'Status: `queued`'
must_contain 'Attempts: `0`'
must_contain 'Expected response token for later E3P-D: `APC_E3P_OK`'
must_contain 'Expected result marker for later E3P-D: `APC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT`'
must_contain 'Result rows for inserted job after E3P-C: `0`'
must_contain 'Jobs before: `25`'
must_contain 'Jobs after: `26`'
must_contain 'Job results before: `8`'
must_contain 'Job results after: `8`'
must_contain 'No helper execution'
must_contain 'No adapter execution'
must_contain 'No operator dispatch execution'
must_contain 'No PVESO contact'
must_contain 'No Ollama contact'
must_contain 'No model endpoint call'
must_contain 'No scheduler activation'
must_contain 'No persistent worker activation'
must_contain 'APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION'
must_contain 'E3P-D must not run against jobs 25 or 26'

test -f "$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh" || fail "missing operator dispatch artifact"
test -x "$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh" || fail "operator dispatch artifact not executable"
test -f "$ROOT/docs/stage-16-e3p-b-controlled-dispatch-implementation-no-run.md" || fail "missing E3P-B doc"
test -f "$ROOT/ops/smoke/check-stage-16-e3p-b-controlled-dispatch-implementation-no-run.sh" || fail "missing E3P-B smoke"

echo "PASS stage-16-e3p-c-insert-one-synthetic-operator-dispatch-job-only smoke"
