#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o43-a-r3-recover-worker-complete-job-context-no-job-reset-no-runtime.md"
WORKER="ops/workers/ct101_minimal_ollama_worker.py"
CONTRACT_SMOKE="ops/smoke/check-stage-16-fc-o43-a-complete-job-context.py"

test -f "$DOC"
test -f "$WORKER"
test -x "$CONTRACT_SMOKE"

grep -Fq "Stage 16 FC-O43-A-R3 recover worker complete_job job context no job reset no runtime" "$DOC"
grep -Fq "Base HEAD/origin/main: \`a575841\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O43_A_PATCH_WORKER_COMPLETE_JOB_JOB_CONTEXT_NO_JOB_RESET_NO_RUNTIME_NO_RESET_FAILED" "$DOC"

grep -Fq "NameError: name 'job' is not defined" "$DOC"
grep -Fq "complete_job(config, token, job_id, profile, job, response)" "$DOC"
grep -Fq "job: Dict[str, Any]" "$DOC"
grep -Fq "REFUSE_WORKER_CLAIMED_JOB_ID_NOT_ALLOWED" "$DOC"
grep -Fq "CT101 deployed worker import tests also passed." "$DOC"

grep -Fq "job117_state_before_fc_o43_a_r3=running,1,0" "$DOC"
grep -Fq "job117_state_after_fc_o43_a_r3=running,1,0" "$DOC"
grep -Fq "job118_state_after_fc_o43_a_r3=queued,0,0" "$DOC"
grep -Fq "job121_state_after_fc_o43_a_r3=queued,0,0" "$DOC"

grep -Fq "No failed-unit evidence was cleared." "$DOC"
grep -Fq "ct203_after_fc_o43_a_r3_acceptance_pass=true" "$DOC"
grep -Fq "Next recommended stage: FC-O43-B reset/requeue job117 only" "$DOC"

grep -Fq "def complete_job(config: WorkerConfig, token: str, job_id: int, profile: ModelProfile, job: Dict[str, Any], response_text: str)" "$WORKER"
grep -Fq "complete_job(config, token, job_id, profile, job, response)" "$WORKER"
grep -Fq "build_completion_payload(profile, job, response_text)" "$WORKER"

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

echo "stage-16-fc-o43-a-r3 complete_job job context recovery smoke passed"
