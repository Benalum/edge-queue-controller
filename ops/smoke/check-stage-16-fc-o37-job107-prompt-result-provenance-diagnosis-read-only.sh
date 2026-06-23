#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o37-job107-prompt-result-provenance-diagnosis-read-only.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O37 job107 prompt/result provenance diagnosis read-only" "$DOC"
grep -Fq "FC-O36-R3 proved job107 completed mechanically" "$DOC"
grep -Fq "FC-O37-R2 preserves that evidence in a corrected checkpoint." "$DOC"
grep -Fq "read-only CT203 job/result provenance inspection" "$DOC"
grep -Fq "read-only CT101 profile/worker inspection" "$DOC"

grep -Fq "job107_prompt_sha_fc_o37=4ae77146c7bd18db6227150ccfcadb2a4504669eb876a56111df2dd24024bafb" "$DOC"
grep -Fq "job107_response_json_sha_fc_o37=b306e13d87708c5ccd08e0f8d43da92d402c516cf76085795a3fae25206ebd79" "$DOC"
grep -Fq "job107_response_text_sha_fc_o37=5402081494ce7ac5559b84066ad7bb019addc9a9aa127a95e50f1bd06c361180" "$DOC"

grep -Fq "job107_prompt_has_guard_marker_fc_o37=false" "$DOC"
grep -Fq "job107_prompt_has_companion_terms_fc_o37=true" "$DOC"
grep -Fq "job107_result_is_guard_json_fc_o37=true" "$DOC"
grep -Fq "job107_prompt_result_mismatch_fc_o37=true" "$DOC"
grep -Fq "job107_response_text_contains_thinking_fc_o37=true" "$DOC"
grep -Fq "job107_response_text_is_product_like_fc_o37=true" "$DOC"

grep -Fq '"exact_match": true' "$DOC"
grep -Fq '"profile_id": "gemma4_product_candidate"' "$DOC"
grep -Fq '"stage": "stage-16-e3z-ec-worker-guards"' "$DOC"
grep -Fq "visible thinking trace" "$DOC"

grep -Fq "profile_sha_fc_o37=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740" "$DOC"
grep -Fq "worker_sha_fc_o37=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "profile_gemma4_product_candidate_completion_validation_policy_fc_o37=exact_marker_only" "$DOC"

grep -Fq "preserved_job_states_fc_o37=true" "$DOC"
grep -Fq "job108_status_fc_o37=queued" "$DOC"
grep -Fq "job111_status_fc_o37=queued" "$DOC"

grep -Fq "OLLAMA_NUM_PARALLEL_fc_o37=2" "$DOC"
grep -Fq "active_general_services_fc_o37=0" "$DOC"
grep -Fq "ct101_fc_o37_read_only_acceptance_pass=true" "$DOC"
grep -Fq "ct203_fc_o37_read_only_acceptance_pass=true" "$DOC"
grep -Fq "No failed-unit evidence was cleared." "$DOC"

grep -Fq "Do not rerun job107. It already completed." "$DOC"
grep -Fq "The blocker is result contract/product extraction" "$DOC"
grep -Fq "separates guard proof metadata from user-visible model output" "$DOC"

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

echo "stage-16-fc-o37 provenance diagnosis smoke passed"
