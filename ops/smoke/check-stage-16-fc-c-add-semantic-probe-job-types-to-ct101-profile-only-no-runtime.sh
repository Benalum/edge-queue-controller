#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-c-add-semantic-probe-job-types-to-ct101-profile-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-C add semantic probe job_types to CT101 profile only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_C_ADD_SEMANTIC_PROBE_JOB_TYPES_TO_CT101_PROFILE_ONLY_NO_RUNTIME" "$DOC"
grep -Fq "Base HEAD/origin/main: \`166a213\`" "$DOC"

grep -Fq "profile_sha_before_fc_c=329118c8916917e538200ee5c0e6d2b4c2a214adf00cf075b810ee23d0baed1d" "$DOC"
grep -Fq "profile_backup_path_fc_c=" "$DOC"
grep -Fq "profile_backup_sha256_fc_c=" "$DOC"
grep -Fq "profile_sha_after_fc_c=" "$DOC"

grep -Fq "stage16_fc_companion_chat_semantic_probe" "$DOC"
grep -Fq "stage16_fc_study_tutor_semantic_probe" "$DOC"
grep -Fq "stage16_fc_flashcards_semantic_probe" "$DOC"
grep -Fq "stage16_fc_summary_semantic_probe" "$DOC"
grep -Fq "stage16_fc_json_semantic_probe" "$DOC"
grep -Fq "stage16_fc_router_label_semantic_probe" "$DOC"
grep -Fq "stage16_fc_safe_refusal_semantic_probe" "$DOC"

grep -Fq "profile_fc_job_type_memberships_fc_c=7" "$DOC"
grep -Fq "profile_fc_all_job_types_present_fc_c=true" "$DOC"
grep -Fq "ct101_fc_c_profile_mutation_acceptance_pass=true" "$DOC"

grep -Fq "jobs81_87_existing_before_fc_c=0" "$DOC"
grep -Fq "active_exact_services_after_fc_c=0" "$DOC"
grep -Fq "active_general_services_after_fc_c=0" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-D\`" "$DOC"

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

echo "stage-16-fc-c ct101 profile semantic probe types smoke passed"
