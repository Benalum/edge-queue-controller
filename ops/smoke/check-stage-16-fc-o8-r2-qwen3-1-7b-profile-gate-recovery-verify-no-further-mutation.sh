#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o8-r2-qwen3-1-7b-profile-gate-recovery-verify-no-further-mutation.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O8-R2 qwen3:1.7b profile gate recovery verify no further mutation" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O8_QWEN3_1_7B_PROFILE_PROVEN_GATE_ONLY_NO_RUNTIME_NO_JOB_RESET" "$DOC"
grep -Fq "Base HEAD/origin/main: \`7641d58\`" "$DOC"
grep -Fq "FC-O8 successfully mutated the CT101 profile" "$DOC"
grep -Fq "FC-O8-R2 performs verification only." "$DOC"

grep -Fq "profile_sha_before_fc_o8=005bb2990ee2244591777c37ff164b26bdab8cd3c9adc7685f78e4c8f624e5ec" "$DOC"
grep -Fq "profile_sha_current_fc_o8_r2=56512391b1df4b444d8f72ff2213ee9faeeb2d2db8a55eb1a642d9d4a1202ebf" "$DOC"
grep -Fq "profile_backup_sha_fc_o8_r2=005bb2990ee2244591777c37ff164b26bdab8cd3c9adc7685f78e4c8f624e5ec" "$DOC"
grep -Fq "worker_load_profiles_after_fc_o8_r2=true" "$DOC"

grep -Fq "qwen3_1_7b_policy_before_fc_o8_r2=no_default_until_proven" "$DOC"
grep -Fq "qwen3_1_7b_policy_after_fc_o8_r2=exact_marker_only" "$DOC"
grep -Fq "Gemma4, gemma3, and llama3.2 profile entries were verified unchanged" "$DOC"

grep -Fq "active_exact_services_fc_o8_r2=0" "$DOC"
grep -Fq "active_general_services_fc_o8_r2=0" "$DOC"
grep -Fq "failed_general_units_fc_o8_r2=6" "$DOC"

grep -Fq "job105_status_fc_o8_r2=running" "$DOC"
grep -Fq "job105_attempts_fc_o8_r2=1" "$DOC"
grep -Fq "job105_result_rows_fc_o8_r2=0" "$DOC"
grep -Fq "jobs106_111_remain_queued_attempts0_rows0=true" "$DOC"
grep -Fq "ct203_fc_o8_r2_read_only_acceptance_pass=true" "$DOC"

grep -Fq "This still does not prove qwen3:1.7b model generation." "$DOC"
grep -Fq "Do not run jobs106-111 yet." "$DOC"
grep -Fq "Do not retry job105 blindly." "$DOC"

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

echo "stage-16-fc-o8-r2 qwen3 profile gate recovery smoke passed"
