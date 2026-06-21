#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-16-e3p-e-controlled-dispatch-checkpoint-handoff.md"
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

must_contain "Stage 16 E3P-E"
must_contain "Controlled Dispatch Checkpoint Handoff"
must_contain "The controlled operator dispatch path successfully completed one queued job"
must_contain "Target job ID: \`27\`"
must_contain "Job status: \`completed\`"
must_contain "Job attempts: \`1\`"
must_contain "Result rows for job 27: \`1\`"
must_contain "Total jobs: \`26\`"
must_contain "Total job_results: \`9\`"
must_contain "Worker count: \`2\`"
must_contain "Response text: \`APC_E3P_OK\\nAPC_STAGE16_E3P_OPERATOR_DISPATCH_RESULT\`"
must_contain "Pipefail-safe PVESO runner counting."
must_contain "Nested \`APC_MANUAL_COMPLETION_APPROVAL\` passed into the helper."
must_contain "\`JOB_ID\` passed into the helper."
must_contain "PVESO runner count after completion: \`0\`"
must_contain "CT101 status: \`stopped\`"
must_contain "CT101 onboot: \`0\`"
must_contain "Do not rerun E3P-D for job 27."
must_contain "No scheduler activation."
must_contain "No persistent worker activation."
must_contain "No public PVESO/Ollama exposure."
must_contain "Do not activate scheduler or persistent workers yet."

grep -F -- 'APC_MANUAL_COMPLETION_APPROVAL="$HELPER_REQUIRED_APPROVAL"' "$SCRIPT" >/dev/null || fail "missing helper approval bridge"
grep -F -- 'JOB_ID="$JOB_ID"' "$SCRIPT" >/dev/null || fail "missing JOB_ID helper bridge"

test -f "$ROOT/docs/stage-16-e3p-d-r7-completion-recovery-docs-no-rerun.md" || fail "missing R7 completion doc"
test -f "$ROOT/ops/smoke/check-stage-16-e3p-d-r7-completion-recovery-docs-no-rerun.sh" || fail "missing R7 completion smoke"

echo "PASS stage-16-e3p-e-controlled-dispatch-checkpoint-handoff smoke"
