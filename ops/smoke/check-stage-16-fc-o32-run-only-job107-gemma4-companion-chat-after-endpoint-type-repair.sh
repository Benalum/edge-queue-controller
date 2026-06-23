#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o32-run-only-job107-gemma4-companion-chat-after-endpoint-type-repair.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O32 run only job107 gemma4 companion chat after endpoint_type repair" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O32_RUN_ONLY_JOB107_GEMMA4_COMPANION_CHAT_AFTER_ENDPOINT_TYPE_REPAIR_NO_BULK_NO_OLD_JOB_MUTATION_NO_RESET_FAILED" "$DOC"
grep -Fq "Base HEAD/origin/main: \`9f5e232\`" "$DOC"

grep -Fq "edge-ct101-general-queue-job-worker@107.service" "$DOC"
grep -Fq "reset-failed" "$DOC"
grep -Fq "profile_sha_fc_o32=bbd8e5b94d6897f05c91f2680e92bb99cf77e9c7b0515a7f9642a2819dd072f7" "$DOC"
grep -Fq "worker_sha_fc_o32=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_after_fc_o32=2" "$DOC"
grep -Fq "ct101_job107_one_service_fc_o32_observed=true" "$DOC"

grep -Fq "quick_check_after_fc_o32=ok" "$DOC"
grep -Fq "job107_job_type_after_fc_o32=stage16_fc_companion_chat_semantic_probe" "$DOC"
grep -Fq "job107_requested_model_after_fc_o32=gemma4:e4b" "$DOC"
grep -Fq "job107_status_after_fc_o32=" "$DOC"
grep -Fq "job107_attempts_after_fc_o32=" "$DOC"
grep -Fq "job107_result_rows_after_fc_o32=" "$DOC"
grep -Fq "job107_mechanical_pass_fc_o32=" "$DOC"
grep -Fq "job107_output_hygiene_pass_fc_o32=" "$DOC"
grep -Fq "job107_semantic_pass_fc_o32=" "$DOC"
grep -Fq "job107_product_surface_candidate_fc_o32=" "$DOC"
grep -Fq "preserved_unrelated_jobs_fc_o32=true" "$DOC"
grep -Fq "ct203_post_fc_o32_safety_acceptance_pass=true" "$DOC"

grep -Fq "Job105 remained running attempts=1 rows=0." "$DOC"
grep -Fq "Jobs108-111 remained queued attempts=0 rows=0." "$DOC"
grep -Fq "Jobs112-116 remained completed attempts=1 rows=1." "$DOC"

grep -Fq "Product surface candidate means the result is good enough to continue toward the Companion surface with this model." "$DOC"
grep -Fq "Next recommended stage depends on classification:" "$DOC"

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

echo "stage-16-fc-o32 job107 gemma4 after endpoint_type repair smoke passed"
