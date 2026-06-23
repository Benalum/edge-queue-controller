#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o33-repair-gemma-llama-profile-container-name-schema-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O33 repair gemma/llama profile container_name schema no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O33_REPAIR_GEMMA_LLAMA_PROFILE_CONTAINER_NAME_SCHEMA_NO_RUNTIME_NO_JOB_PROCESSING_NO_RESET_FAILED" "$DOC"
grep -Fq "Base HEAD/origin/main: \`3b85d91\`" "$DOC"

grep -Fq "KeyError: 'container_name'" "$DOC"
grep -Fq "requires \`container_name\`" "$DOC"
grep -Fq "This stage mutated only the CT101 profile file" "$DOC"
grep -Fq "/etc/edge-ct101-worker/model-profiles.yaml" "$DOC"

grep -Fq "profile_backup_path_fc_o33=" "$DOC"
grep -Fq "profile_backup_sha_fc_o33=bbd8e5b94d6897f05c91f2680e92bb99cf77e9c7b0515a7f9642a2819dd072f7" "$DOC"

grep -Fq "profile_sha_before_fc_o33=bbd8e5b94d6897f05c91f2680e92bb99cf77e9c7b0515a7f9642a2819dd072f7" "$DOC"
grep -Fq "profile_sha_after_fc_o33=" "$DOC"
grep -Fq "worker_sha_after_fc_o33=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"

grep -Fq "reference_container_name_fc_o33=" "$DOC"
grep -Fq "profile_container_name_schema_repaired_ids_fc_o33=gemma4_product_candidate,gemma3_companion_candidate,llama32_safe_refusal_candidate" "$DOC"
grep -Fq "profile_container_name_key_present_for_targets_fc_o33=true" "$DOC"
grep -Fq "profile_endpoint_type_key_still_present_for_targets_fc_o33=true" "$DOC"
grep -Fq "profile_model_name_key_still_present_for_targets_fc_o33=true" "$DOC"
grep -Fq "profile_model_key_absent_for_targets_fc_o33=true" "$DOC"
grep -Fq "profile_validation_after_fc_o33_pass=true" "$DOC"
grep -Fq "profile_container_name_uniform_for_targets_fc_o33=true" "$DOC"
grep -Fq "profile_model_name_count_after_fc_o33 gemma4:e4b=1" "$DOC"
grep -Fq "profile_model_name_count_after_fc_o33 gemma3:4b=1" "$DOC"
grep -Fq "profile_model_name_count_after_fc_o33 llama3.2:3b=1" "$DOC"

grep -Fq "OLLAMA_NUM_PARALLEL_after_fc_o33=2" "$DOC"
grep -Fq "active_general_services_after_fc_o33=0" "$DOC"
grep -Fq "failed_general_units_after_fc_o33=7" "$DOC"
grep -Fq "FC-O33 did not reset-failed." "$DOC"
grep -Fq "ct101_container_name_repair_fc_o33_acceptance_pass=true" "$DOC"

grep -Fq "quick_check_after_fc_o33=ok" "$DOC"
grep -Fq "job107_status_after_fc_o33=queued" "$DOC"
grep -Fq "job107_attempts_after_fc_o33=0" "$DOC"
grep -Fq "job107_result_rows_after_fc_o33=0" "$DOC"
grep -Fq "job108_status_after_fc_o33=queued" "$DOC"
grep -Fq "job111_status_after_fc_o33=queued" "$DOC"
grep -Fq "jobs107_111_remain_queued_after_fc_o33=true" "$DOC"
grep -Fq "No runtime occurred." "$DOC"
grep -Fq "Next recommended stage: rerun job107 only as FC-O34 gemma4 companion_chat one-shot after container_name repair." "$DOC"

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

echo "stage-16-fc-o33 container_name schema repair smoke passed"
