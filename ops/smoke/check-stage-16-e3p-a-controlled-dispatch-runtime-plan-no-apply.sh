#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-16-e3p-a-controlled-dispatch-runtime-plan-no-apply.md"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

must_contain() {
  local needle="$1"
  grep -F "$needle" "$DOC" >/dev/null || fail "missing required text: $needle"
}

test -f "$DOC" || fail "missing doc: $DOC"

must_contain "Stage 16 E3P-A"
must_contain "Controlled Dispatch Runtime Plan No-Apply"
must_contain "No DB write"
must_contain "No synthetic job insertion"
must_contain "No helper execution"
must_contain "No adapter execution"
must_contain "No operator dispatch execution"
must_contain "No model endpoint call"
must_contain "No scheduler activation"
must_contain "No persistent worker activation"
must_contain "E3P-B — Add execution-capable operator dispatch implementation no-run"
must_contain "E3P-C — Insert one fresh synthetic queued job only"
must_contain "APPROVE_STAGE_16_E3P_C_INSERT_ONE_SYNTHETIC_OPERATOR_DISPATCH_JOB_ONLY"
must_contain "E3P-D — Execute controlled operator dispatch for one queued job"
must_contain "APPROVE_STAGE_16_E3P_D_RUN_OPERATOR_DISPATCH_ONE_JOB_MODEL_DB_COMPLETION"
must_contain "APC_E3P_OK"
must_contain "APC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT"
must_contain "Timeout recovery policy for E3P-D"
must_contain "Never rerun E3P runtime against jobs 25 or 26"
must_contain "The browser must never call PVESO or Ollama directly"
must_contain "Proceed next with E3P-B"

test -f "$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh" || fail "missing E3O operator dispatch artifact"
test -x "$ROOT/ops/model/operator-dispatch-one-queued-job-via-pveso.sh" || fail "E3O operator dispatch artifact is not executable"
test -f "$ROOT/ops/model/pveso-one-shot-generate.sh" || fail "missing one-shot adapter"
test -f "$ROOT/ops/model/manual-complete-queued-job-via-pveso-adapter.sh" || fail "missing manual completion helper"
test -f "$ROOT/docs/stage-16-e3o-controlled-operator-dispatch-artifact-no-run.md" || fail "missing E3O doc"
test -f "$ROOT/ops/smoke/check-stage-16-e3o-controlled-operator-dispatch-artifact-no-run.sh" || fail "missing E3O smoke"

echo "PASS stage-16-e3p-a-controlled-dispatch-runtime-plan-no-apply smoke"
