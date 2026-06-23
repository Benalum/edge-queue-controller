#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o31-repair-gemma-llama-profile-endpoint-type-schema-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O31 repair gemma/llama profile endpoint_type schema no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O31_REPAIR_GEMMA_LLAMA_PROFILE_ENDPOINT_TYPE_SCHEMA_NO_RUNTIME_NO_JOB_PROCESSING_NO_RESET_FAILED" "$DOC"
grep -Fq "Base HEAD/origin/main: \`c4eda7e\`" "$DOC"

grep -Fq "KeyError: 'endpoint_type'" "$DOC"
grep -Fq "requires \`endpoint_type\`" "$DOC"
grep -Fq "This stage mutated only the CT101 profile file" "$DOC"
grep -Fq "/etc/edge-ct101-worker/model-profiles.yaml" "$DOC"

grep -Fq "profile_backup_path_fc_o31=" "$DOC"
grep -Fq "profile_backup_sha_fc_o31=0e68ab762c920d4514587ef94f4c6d816b6b2e9f3879ae034aa8559e414ef34b" "$DOC"

grep -Fq "profile_sha_before_fc_o31=0e68ab762c920d4514587ef94f4c6d816b6b2e9f3879ae034aa8559e414ef34b" "$DOC"
grep -Fq "profile_sha_after_fc_o31=" "$DOC"
grep -Fq "worker_sha_after_fc_o31=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"

grep -Fq "reference_endpoint_type_fc_o31=" "$DOC"
grep -Fq "profile_endpoint_type_schema_repaired_ids_fc_o31=gemma4_product_candidate,gemma3_companion_candidate,llama32_safe_refusal_candidate" "$DOC"
grep -Fq "profile_endpoint_type_key_present_for_targets_fc_o31=true" "$DOC"
grep -Fq "profile_model_name_key_still_present_for_targets_fc_o31=true" "$DOC"
grep -Fq "profile_model_key_absent_for_targets_fc_o31=true" "$DOC"
grep -Fq "profile_validation_after_fc_o31_pass=true" "$DOC"
grep -Fq "profile_endpoint_type_uniform_for_targets_fc_o31=true" "$DOC"
grep -Fq "profile_model_name_count_after_fc_o31 gemma4:e4b=1" "$DOC"
grep -Fq "profile_model_name_count_after_fc_o31 gemma3:4b=1" "$DOC"
grep -Fq "profile_model_name_count_after_fc_o31 llama3.2:3b=1" "$DOC"

grep -Fq "OLLAMA_NUM_PARALLEL_after_fc_o31=2" "$DOC"
grep -Fq "active_general_services_after_fc_o31=0" "$DOC"
grep -Fq "failed_general_units_after_fc_o31=7" "$DOC"
grep -Fq "FC-O31 did not reset-failed." "$DOC"
grep -Fq "ct101_endpoint_type_repair_fc_o31_acceptance_pass=true" "$DOC"

grep -Fq "quick_check_after_fc_o31=ok" "$DOC"
grep -Fq "job107_status_after_fc_o31=queued" "$DOC"
grep -Fq "job107_attempts_after_fc_o31=0" "$DOC"
grep -Fq "job107_result_rows_after_fc_o31=0" "$DOC"
grep -Fq "job108_status_after_fc_o31=queued" "$DOC"
grep -Fq "job111_status_after_fc_o31=queued" "$DOC"
grep -Fq "jobs107_111_remain_queued_after_fc_o31=true" "$DOC"
grep -Fq "No runtime occurred." "$DOC"
grep -Fq "Next recommended stage: rerun job107 only as FC-O32 gemma4 companion_chat one-shot after endpoint_type repair." "$DOC"

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

echo "stage-16-fc-o31 endpoint_type schema repair smoke passed"
