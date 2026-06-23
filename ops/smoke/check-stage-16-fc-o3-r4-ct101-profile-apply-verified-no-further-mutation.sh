#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o3-r4-ct101-profile-apply-verified-no-further-mutation.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O3-R4 CT101 profile apply verified no further mutation" "$DOC"
grep -Fq "Base HEAD/origin/main: \`0104e84\`" "$DOC"
grep -Fq "FC-O3-R2 successfully wrote the CT101 profile file" "$DOC"
grep -Fq "FC-O3-R4 fixes the verification harness" "$DOC"
grep -Fq "This stage is read-only against CT101 and CT203." "$DOC"

grep -Fq "profile_sha_expected_before_fc_o3_r4=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c" "$DOC"
grep -Fq "profile_sha_current_fc_o3_r4=005bb2990ee2244591777c37ff164b26bdab8cd3c9adc7685f78e4c8f624e5ec" "$DOC"
grep -Fq "profile_backup_sha_fc_o3_r4=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c" "$DOC"
grep -Fq "worker_load_profiles_after_fc_o3_r4=true" "$DOC"

grep -Fq "qwen3_1_7b_allows=stage16_fc_summary_semantic_probe,stage16_fc_json_semantic_probe" "$DOC"
grep -Fq "gemma4_e4b_allows=stage16_fc_companion_chat_semantic_probe,stage16_fc_study_tutor_semantic_probe,stage16_fc_flashcards_semantic_probe" "$DOC"
grep -Fq "gemma3_4b_allows=stage16_fc_companion_chat_semantic_probe" "$DOC"
grep -Fq "llama3_2_3b_allows=stage16_fc_safe_refusal_semantic_probe" "$DOC"

grep -Fq "ct203_fc_o3_r4_read_only_acceptance_pass=true" "$DOC"
grep -Fq "failed_general_units_fc_o3_r4=5" "$DOC"
grep -Fq "The FC-O3 profile gate remediation is applied and verified." "$DOC"
grep -Fq "Preferred next stage is a no-apply replacement-job contract" "$DOC"

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
if grep -Fq "APPROVE_" "$DOC"; then
  echo "approval token found in read-only verification doc"
  exit 1
fi

echo "stage-16-fc-o3-r4 profile apply verification smoke passed"
