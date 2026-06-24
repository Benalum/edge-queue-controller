#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o41-product-profile-policy-update-only-no-job-processing.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O41 product profile policy update only no job processing" "$DOC"
grep -Fq "Base HEAD/origin/main: \`99606cc\`" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O41_PRODUCT_PROFILE_POLICY_UPDATE_ONLY_NO_JOB_PROCESSING_NO_RESET_FAILED" "$DOC"

grep -Fq "deployed_worker_sha_fc_o41=1809af3a97e5b357d47b4ce3728ca4e5e8f6692de89e920b881f7b3b58b820d3" "$DOC"
grep -Fq "old_profile_sha_fc_o41=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740" "$DOC"
grep -Fq "new_profile_sha_fc_o41=" "$DOC"
grep -Fq "profile_backup_path_fc_o41=" "$DOC"
grep -Fq "profile_backup_sha_fc_o41=bebfb1dcf8fad51681c87fa5b6a8ce5e03df9040cae4f2fa1959a24c88df5740" "$DOC"

grep -Fq "gemma4_product_candidate=product_visible_output_v1" "$DOC"
grep -Fq "gemma3_companion_candidate=product_visible_output_v1" "$DOC"
grep -Fq "llama32_safe_refusal_candidate=product_visible_output_v1" "$DOC"
grep -Fq "profile_load_validation_fc_o41=true" "$DOC"
grep -Fq "ct101_fc_o41_profile_policy_acceptance_pass=true" "$DOC"

grep -Fq "job108=queued,0,0" "$DOC"
grep -Fq "job111=queued,0,0" "$DOC"
grep -Fq "No failed-unit evidence was cleared." "$DOC"
grep -Fq "Next recommended stage: FC-O42 insert fresh product-style probes" "$DOC"

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

echo "stage-16-fc-o41 product profile policy update smoke passed"
