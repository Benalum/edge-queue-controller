#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o25-gemma-llama-profile-gate-diagnosis-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O25 gemma/llama profile gate diagnosis no-apply" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O25_GEMMA_LLAMA_PROFILE_GATE_DIAGNOSIS_NO_APPLY" "$DOC"
grep -Fq "Base HEAD/origin/main: \`e0dcd0b\`" "$DOC"

grep -Fq "This stage was read-only CT203/CT101 diagnosis plus repo documentation and smoke." "$DOC"
grep -Fq "write CT203 DB" "$DOC"
grep -Fq "mutate CT101 profile" "$DOC"
grep -Fq "run jobs" "$DOC"

grep -Fq "| 107 | stage16_fc_companion_chat_semantic_probe | gemma4:e4b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 108 | stage16_fc_companion_chat_semantic_probe | gemma3:4b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 109 | stage16_fc_study_tutor_semantic_probe | gemma4:e4b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 110 | stage16_fc_flashcards_semantic_probe | gemma4:e4b | queued | 0 | 0 |" "$DOC"
grep -Fq "| 111 | stage16_fc_safe_refusal_semantic_probe | llama3.2:3b | queued | 0 | 0 |" "$DOC"

grep -Fq "profile_sha_fc_o25=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"
grep -Fq "worker_sha_fc_o25=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_fc_o25=2" "$DOC"
grep -Fq "active_general_services_fc_o25=0" "$DOC"
grep -Fq "failed_general_units_fc_o25=6" "$DOC"

grep -Fq "REFUSE_NO_PROFILE_FOR_MODEL=" "$DOC"
grep -Fq "REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE=" "$DOC"
grep -Fq "REFUSE_PROFILE_NOT_PROVEN=" "$DOC"

grep -Fq "The remaining product jobs are blocked by model/profile proof gates" "$DOC"
grep -Fq "FC-O26 should be no-apply" "$DOC"
grep -Fq "Back up \`/etc/edge-ct101-worker/model-profiles.yaml\`." "$DOC"
grep -Fq "Keep each gemma/llama profile at max_concurrent_model_calls=1." "$DOC"
grep -Fq "Do not enable concurrency above one for gemma/llama" "$DOC"
grep -Fq "Next recommended stage: FC-O26 gemma/llama profile remediation contract no-apply." "$DOC"

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

echo "stage-16-fc-o25 gemma llama profile gate diagnosis smoke passed"
