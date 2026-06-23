#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o29-repair-gemma-llama-profile-model-name-schema-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O29 repair gemma/llama profile model_name schema no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O29_REPAIR_GEMMA_LLAMA_PROFILE_MODEL_NAME_SCHEMA_NO_RUNTIME_NO_JOB_PROCESSING_NO_RESET_FAILED" "$DOC"
grep -Fq "Base HEAD/origin/main: \`d850d50\`" "$DOC"

grep -Fq "R2 recovery note" "$DOC"
grep -Fq "REFUSE_PROFILE_EMPTY_MODEL_NAME" "$DOC"
grep -Fq "requires non-empty \`model_name\`" "$DOC"
grep -Fq "This R2 mutated only repo docs/smoke." "$DOC"

grep -Fq "profile_backup_path_fc_o29=/etc/edge-ct101-worker/model-profiles.yaml.stage16-fc-o29-pre-model-name-schema-repair.20260623T181640Z.bak" "$DOC"
grep -Fq "profile_backup_sha_fc_o29=7464d59fc66fd63e6676980e7f8253b1de0b4046c447dc23e68ed024520d2127" "$DOC"

grep -Fq "profile_sha_before_fc_o29=7464d59fc66fd63e6676980e7f8253b1de0b4046c447dc23e68ed024520d2127" "$DOC"
grep -Fq "profile_sha_after_fc_o29=0e68ab762c920d4514587ef94f4c6d816b6b2e9f3879ae034aa8559e414ef34b" "$DOC"
grep -Fq "worker_sha_after_fc_o29=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"

grep -Fq "profile_schema_repaired_ids_fc_o29=gemma4_product_candidate,gemma3_companion_candidate,llama32_safe_refusal_candidate" "$DOC"
grep -Fq "profile_validation_after_fc_o29_pass=true" "$DOC"
grep -Fq "profile_model_name_count_after_fc_o29 gemma4:e4b=1" "$DOC"
grep -Fq "profile_model_name_count_after_fc_o29 gemma3:4b=1" "$DOC"
grep -Fq "profile_model_name_count_after_fc_o29 llama3.2:3b=1" "$DOC"
grep -Fq "profile_model_key_removed_for_targets_fc_o29=true" "$DOC"
grep -Fq "profile_model_name_key_present_for_targets_fc_o29=true" "$DOC"
grep -Fq "ct101_profile_repair_fc_o29_r2_read_only_acceptance_pass=true" "$DOC"

grep -Fq "OLLAMA_NUM_PARALLEL_after_fc_o29=2" "$DOC"
grep -Fq "active_general_services_after_fc_o29=0" "$DOC"
grep -Fq "failed_general_units_after_fc_o29=7" "$DOC"
grep -Fq "FC-O29 did not reset-failed." "$DOC"

grep -Fq "quick_check_after_fc_o29=ok" "$DOC"
grep -Fq "job107_status_after_fc_o29=queued" "$DOC"
grep -Fq "job107_attempts_after_fc_o29=0" "$DOC"
grep -Fq "job107_result_rows_after_fc_o29=0" "$DOC"
grep -Fq "job108_status_after_fc_o29=queued" "$DOC"
grep -Fq "job111_status_after_fc_o29=queued" "$DOC"
grep -Fq "jobs107_111_remain_queued_after_fc_o29=true" "$DOC"
grep -Fq "No runtime occurred." "$DOC"
grep -Fq "Next recommended stage: rerun job107 only as FC-O30 gemma4 companion_chat one-shot after model_name repair." "$DOC"

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

echo "stage-16-fc-o29 r2 profile model_name schema repair recovery smoke passed"
