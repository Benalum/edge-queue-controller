#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o23-run-only-jobs115-116-qwen3-parallel-two-service-proof.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O23 run only jobs115-116 qwen3 parallel two-service proof" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O23_RUN_ONLY_JOBS115_116_QWEN3_PARALLEL_TWO_SERVICE_PROOF_NO_BULK_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "Base HEAD/origin/main: \`f443134\`" "$DOC"

grep -Fq "edge-ct101-general-queue-job-worker@115.service" "$DOC"
grep -Fq "edge-ct101-general-queue-job-worker@116.service" "$DOC"

grep -Fq "profile_sha_fc_o23=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"
grep -Fq "worker_sha_fc_o23=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_before_fc_o23=2" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_after_fc_o23=2" "$DOC"
grep -Fq "dual_active_observed_fc_o23=" "$DOC"
grep -Fq "failed_general_units_after_fc_o23=6" "$DOC"
grep -Fq "ct101_jobs115_116_two_service_fc_o23_acceptance_pass=true" "$DOC"

grep -Fq "quick_check_after_fc_o23=ok" "$DOC"
grep -Fq "job115_status_after_fc_o23=completed" "$DOC"
grep -Fq "job116_status_after_fc_o23=completed" "$DOC"
grep -Fq "job115_result_rows_after_fc_o23=1" "$DOC"
grep -Fq "job116_result_rows_after_fc_o23=1" "$DOC"
grep -Fq "job115_strict_json_pass_fc_o23=true" "$DOC"
grep -Fq "job116_strict_json_pass_fc_o23=true" "$DOC"
grep -Fq "job115_json_profile_id_fc_o23=qwen3_1_7b_candidate" "$DOC"
grep -Fq "job116_json_profile_id_fc_o23=qwen3_1_7b_candidate" "$DOC"
grep -Fq "preserved_jobs_105_114_fc_o23=true" "$DOC"
grep -Fq "ct203_post_fc_o23_parallel_acceptance_pass=true" "$DOC"

grep -Fq "Job105 remained running with attempts=1 and result_rows=0." "$DOC"
grep -Fq "Jobs107-111 remained queued with attempts=0 and result_rows=0." "$DOC"
grep -Fq "Job114 remained completed with attempts=1 and result_rows=1." "$DOC"

grep -Fq "Both qwen3 JSON parallel proof jobs completed with strict JSON pass." "$DOC"
grep -Fq "CT203 remained the durable queue and claim authority." "$DOC"
grep -Fq "Do not enable persistent workers or bulk queue draining yet." "$DOC"

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

echo "stage-16-fc-o23 qwen3 two-job parallel proof smoke passed"
