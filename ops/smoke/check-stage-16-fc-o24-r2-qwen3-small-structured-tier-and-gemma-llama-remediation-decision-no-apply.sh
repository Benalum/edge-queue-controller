#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o24-r2-qwen3-small-structured-tier-and-gemma-llama-remediation-decision-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O24-R2 qwen3 small structured tier and gemma/llama remediation decision no-apply" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O24_QWEN3_SMALL_STRUCTURED_TIER_AND_GEMMA_LLAMA_REMEDIATION_DECISION_NO_APPLY" "$DOC"
grep -Fq "The first FC-O24 attempt failed before mutation" "$DOC"
grep -Fq "Base HEAD/origin/main: \`f3ca576\`" "$DOC"
grep -Fq "This stage is repo documentation and smoke only." "$DOC"

grep -Fq "qwen3:1.7b is now the first reliable small structured-output tier candidate." "$DOC"
grep -Fq "FC-O14 | 113 | Summary hygiene passed" "$DOC"
grep -Fq "FC-O16 | 106 | JSON strict pass before Ollama concurrency change" "$DOC"
grep -Fq "FC-O20 | 114 | JSON strict pass after \`OLLAMA_NUM_PARALLEL=2\`" "$DOC"
grep -Fq "FC-O23 | 115 and 116 | Two explicitly targeted parallel JSON jobs both passed" "$DOC"

grep -Fq "job114_strict_json_pass_fc_o20=true" "$DOC"
grep -Fq "dual_active_observed_fc_o23=true" "$DOC"
grep -Fq "job115_strict_json_pass_fc_o23=true" "$DOC"
grep -Fq "job116_strict_json_pass_fc_o23=true" "$DOC"
grep -Fq "61067975d9dc6d70f9eb50d376f0de45996f343d8f8daffbb17bf43b76d33817" "$DOC"

grep -Fq "qwen3_small_structured_tier" "$DOC"
grep -Fq "router labels" "$DOC"
grep -Fq "strict JSON outputs" "$DOC"
grep -Fq "light study structured responses" "$DOC"

grep -Fq "Do not enable persistent workers yet." "$DOC"
grep -Fq "Do not bulk drain the queue yet." "$DOC"
grep -Fq "Do not increase above 2 yet." "$DOC"

grep -Fq "| 107 | companion_chat | gemma4:e4b | queued attempts=0 rows=0 | model/profile proof gate |" "$DOC"
grep -Fq "| 108 | companion_chat | gemma3:4b | queued attempts=0 rows=0 | model/profile proof gate |" "$DOC"
grep -Fq "| 109 | study_tutor | gemma4:e4b | queued attempts=0 rows=0 | model/profile proof gate |" "$DOC"
grep -Fq "| 110 | flashcards | gemma4:e4b | queued attempts=0 rows=0 | model/profile proof gate |" "$DOC"
grep -Fq "| 111 | safe_refusal | llama3.2:3b | queued attempts=0 rows=0 | model/profile proof gate |" "$DOC"

grep -Fq "FC-O25: gemma/llama profile gate diagnosis no-apply" "$DOC"
grep -Fq "No runtime and no profile mutation in FC-O25." "$DOC"
grep -Fq "FC-O26: profile remediation contract no-apply" "$DOC"
grep -Fq "one-model, one-job proof sequence" "$DOC"

grep -Fq "Speaking and listening should remain downstream surfaces until companion/study model behavior is proven." "$DOC"
grep -Fq "Next recommended stage: FC-O25 gemma/llama profile gate diagnosis no-apply." "$DOC"

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

echo "stage-16-fc-o24-r2 qwen3 tier and gemma llama remediation decision smoke passed"
