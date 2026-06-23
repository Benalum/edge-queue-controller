#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o27-apply-gemma-llama-minimal-profile-gates-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O27 apply gemma/llama minimal profile gates no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O27_APPLY_GEMMA_LLAMA_MINIMAL_PROFILE_GATES_NO_RUNTIME_NO_JOB_PROCESSING" "$DOC"
grep -Fq "Base HEAD/origin/main: \`4c5ab30\`" "$DOC"

grep -Fq "This stage mutated only the CT101 profile file" "$DOC"
grep -Fq "/etc/edge-ct101-worker/model-profiles.yaml" "$DOC"
grep -Fq "profile_backup_path_fc_o27=" "$DOC"
grep -Fq "profile_backup_sha_fc_o27=" "$DOC"

grep -Fq "profile_sha_before_fc_o27=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"
grep -Fq "profile_sha_after_fc_o27=" "$DOC"
grep -Fq "worker_sha_after_fc_o27=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"

grep -Fq "gemma4_profile_strategy_fc_o27=merged_gemma4_product_candidate" "$DOC"
grep -Fq "gemma4_product_candidate" "$DOC"
grep -Fq "gemma3_companion_candidate" "$DOC"
grep -Fq "llama32_safe_refusal_candidate" "$DOC"

grep -Fq "model: gemma4:e4b" "$DOC"
grep -Fq "model: gemma3:4b" "$DOC"
grep -Fq "model: llama3.2:3b" "$DOC"
grep -Fq "max_concurrent_model_calls: 1" "$DOC"
grep -Fq "completion_validation_policy: exact_marker_only" "$DOC"
grep -Fq "enabled_by_default: false" "$DOC"
grep -Fq "stage16_fc_companion_chat_semantic_probe" "$DOC"
grep -Fq "stage16_fc_study_tutor_semantic_probe" "$DOC"
grep -Fq "stage16_fc_flashcards_semantic_probe" "$DOC"
grep -Fq "stage16_fc_safe_refusal_semantic_probe" "$DOC"

grep -Fq "profile_validation_after_fc_o27_pass=true" "$DOC"
grep -Fq "profile_model_count_after_fc_o27 gemma4:e4b=1" "$DOC"
grep -Fq "profile_model_count_after_fc_o27 gemma3:4b=1" "$DOC"
grep -Fq "profile_model_count_after_fc_o27 llama3.2:3b=1" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_after_fc_o27=2" "$DOC"
grep -Fq "active_general_services_after_fc_o27=0" "$DOC"
grep -Fq "failed_general_units_after_fc_o27=6" "$DOC"
grep -Fq "ct101_profile_apply_fc_o27_acceptance_pass=true" "$DOC"

grep -Fq "quick_check_after_fc_o27=ok" "$DOC"
grep -Fq "job107_status_after_fc_o27=queued" "$DOC"
grep -Fq "job108_status_after_fc_o27=queued" "$DOC"
grep -Fq "job109_status_after_fc_o27=queued" "$DOC"
grep -Fq "job110_status_after_fc_o27=queued" "$DOC"
grep -Fq "job111_status_after_fc_o27=queued" "$DOC"
grep -Fq "jobs107_111_remain_queued_after_fc_o27=true" "$DOC"
grep -Fq "No runtime occurred." "$DOC"
grep -Fq "Next recommended stage: FC-O28 run only job107 gemma4:e4b companion_chat proof." "$DOC"

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

echo "stage-16-fc-o27 apply gemma llama minimal profile gates smoke passed"
