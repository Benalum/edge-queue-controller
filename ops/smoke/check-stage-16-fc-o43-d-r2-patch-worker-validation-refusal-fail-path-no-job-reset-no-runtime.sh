#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o43-d-r2-patch-worker-validation-refusal-fail-path-no-job-reset-no-runtime.md"
WORKER="ops/workers/ct101_minimal_ollama_worker.py"
CONTRACT_SMOKE="ops/smoke/check-stage-16-fc-o43-d-r2-validation-refusal-fail-path.py"

test -f "$DOC"
test -f "$WORKER"
test -x "$CONTRACT_SMOKE"

grep -Fq "Stage 16 FC-O43-D-R2 patch worker validation-refusal fail path no job reset no runtime" "$DOC"
grep -Fq "Base HEAD/origin/main: \`9961ad3\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O43_D_PATCH_WORKER_VALIDATION_REFUSAL_FAIL_PATH_NO_JOB_RESET_NO_RUNTIME_NO_RESET_FAILED" "$DOC"

grep -Fq "REFUSE_PRODUCT_VISIBLE_THINKING" "$DOC"
grep -Fq "def fail_job" "$DOC"
grep -Fq "fail_job(config, token, job_id, str(exc))" "$DOC"
grep -Fq "/internal/edge-worker/jobs/117/fail" "$DOC"
grep -Fq "job117_state_before_fc_o43_d_r2=running,2,0" "$DOC"
grep -Fq "job117_state_after_fc_o43_d_r2=running,2,0" "$DOC"
grep -Fq "job118_state_after_fc_o43_d_r2=queued,0,0" "$DOC"
grep -Fq "job121_state_after_fc_o43_d_r2=queued,0,0" "$DOC"
grep -Fq "No failed-unit evidence was cleared." "$DOC"
grep -Fq "ct203_after_fc_o43_d_r2_acceptance_pass=true" "$DOC"
grep -Fq "Next recommended stage: FC-O43-E reset/requeue only job117" "$DOC"

grep -Fq "def fail_job(" "$WORKER"
grep -Fq "except WorkerRefusal as exc:" "$WORKER"
grep -Fq "fail_job(config, token, job_id, str(exc))" "$WORKER"
grep -Fq "complete_job(config, token, job_id, profile, claimed, response)" "$WORKER"

python3 -m py_compile "$WORKER"
"$CONTRACT_SMOKE"

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw Tailscale IPv4 leaked into doc"
  exit 1
fi
if grep -Eq '10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw private IPv4 leaked into doc"
  exit 1
fi
if grep -Eq '192\.168\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "raw private IPv4 leaked into doc"
  exit 1
fi
if grep -Eq 'fd7a:[0-9a-f:]+' "$DOC"; then
  echo "raw Tailscale IPv6 leaked into doc"
  exit 1
fi

echo "stage-16-fc-o43-d-r2 validation-refusal fail-path smoke passed"
