#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o26-gemma-llama-profile-remediation-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O26 gemma/llama profile remediation contract no-apply" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O26_GEMMA_LLAMA_PROFILE_REMEDIATION_CONTRACT_NO_APPLY" "$DOC"
grep -Fq "Base HEAD/origin/main: \`15c5af9\`" "$DOC"
grep -Fq "This stage is repo documentation and smoke only." "$DOC"

grep -Fq "FC-O25 observed target profile presence as:" "$DOC"
grep -Fq "gemma4:e4b profile=missing" "$DOC"
grep -Fq "gemma3:4b profile=missing" "$DOC"
grep -Fq "llama3.2:3b profile=missing" "$DOC"

grep -Fq "stage-16-fc-o27-apply-gemma-llama-minimal-profile-gates-no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O27_APPLY_GEMMA_LLAMA_MINIMAL_PROFILE_GATES_NO_RUNTIME_NO_JOB_PROCESSING" "$DOC"
grep -Fq "write \`/etc/edge-ct101-worker/model-profiles.yaml\` only" "$DOC"
grep -Fq "No runtime may occur in FC-O27." "$DOC"

grep -Fq "profile_sha_fc_o25=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"
grep -Fq "worker_sha_fc_o25=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"

grep -Fq "gemma4_companion_candidate" "$DOC"
grep -Fq "gemma3_companion_candidate" "$DOC"
grep -Fq "gemma4_study_flashcards_candidate" "$DOC"
grep -Fq "llama32_safe_refusal_candidate" "$DOC"
grep -Fq "gemma4_product_candidate" "$DOC"

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

grep -Fq "FC-O27 must inspect the actual worker profile lookup behavior before choosing split or merged gemma4 entries." "$DOC"
grep -Fq "jobs107-111 remain queued attempts=0 rows=0" "$DOC"
grep -Fq "FC-O28: run only job107" "$DOC"
grep -Fq "FC-O32: run only job111" "$DOC"
grep -Fq "mechanical_pass" "$DOC"
grep -Fq "semantic_pass" "$DOC"
grep -Fq "product_surface_candidate" "$DOC"
grep -Fq "Next recommended stage: FC-O27 apply gemma/llama minimal profile gates, no runtime, no job processing." "$DOC"

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

echo "stage-16-fc-o26 gemma llama profile remediation contract smoke passed"
