#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o38-product-result-contract-design-no-runtime-no-job-mutation.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O38 product result contract design no-runtime/no-job-mutation" "$DOC"
grep -Fq "Base HEAD/origin/main: \`ed13f13\`" "$DOC"
grep -Fq "This stage is repo documentation and smoke only." "$DOC"

grep -Fq "job107_prompt_sha_fc_o37=4ae77146c7bd18db6227150ccfcadb2a4504669eb876a56111df2dd24024bafb" "$DOC"
grep -Fq "job107_response_json_sha_fc_o37=b306e13d87708c5ccd08e0f8d43da92d402c516cf76085795a3fae25206ebd79" "$DOC"
grep -Fq "job107_response_text_sha_fc_o37=5402081494ce7ac5559b84066ad7bb019addc9a9aa127a95e50f1bd06c361180" "$DOC"
grep -Fq "job107_prompt_has_guard_marker_fc_o37=false" "$DOC"
grep -Fq "job107_result_is_guard_json_fc_o37=true" "$DOC"
grep -Fq "job107_response_text_contains_thinking_fc_o37=true" "$DOC"

grep -Fq "The blocker has moved from profile/runtime wiring to product result handling." "$DOC"
grep -Fq "Lane A: guard proof contract" "$DOC"
grep -Fq "Lane B: product visible output contract" "$DOC"
grep -Fq "completion_validation_policy=product_visible_output_v1" "$DOC"
grep -Fq "result_contract=product_visible_output_v1" "$DOC"

grep -Fq "response_text = final user-visible answer only" "$DOC"
grep -Fq "response_json = metadata envelope" "$DOC"
grep -Fq "REFUSE_PRODUCT_VISIBLE_THINKING" "$DOC"
grep -Fq "REFUSE_PRODUCT_GUARD_JSON" "$DOC"
grep -Fq "REFUSE_PRODUCT_EMPTY_VISIBLE_OUTPUT" "$DOC"
grep -Fq "REFUSE_PRODUCT_SHAPE_MISMATCH" "$DOC"

grep -Fq "Profiles intended for product surfaces must not keep:" "$DOC"
grep -Fq "gemma4_product_candidate:" "$DOC"
grep -Fq "gemma3_companion_candidate:" "$DOC"
grep -Fq "llama32_safe_refusal_candidate:" "$DOC"
grep -Fq "This is a future mutation and is not performed in FC-O38." "$DOC"

grep -Fq "FC-O39" "$DOC"
grep -Fq "FC-O40" "$DOC"
grep -Fq "FC-O41" "$DOC"
grep -Fq "FC-O42" "$DOC"
grep -Fq "FC-O43" "$DOC"

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

echo "stage-16-fc-o38 product result contract design smoke passed"
