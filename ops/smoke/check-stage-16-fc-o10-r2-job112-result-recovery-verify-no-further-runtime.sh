#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o10-r2-job112-result-recovery-verify-no-further-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O10-R2 job112 result recovery verify no further runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O10_RUN_ONLY_JOB112_QWEN3_SUMMARY_ONE_SHOT_NO_BULK_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "Base HEAD/origin/main: \`0aba68f\`" "$DOC"

grep -Fq "FC-O10 successfully ran job112 and completed the job." "$DOC"
grep -Fq "FC-O10-R2 performs verification only. It does not run job112 again." "$DOC"

grep -Fq "quick_check_fc_o10_r2=ok" "$DOC"
grep -Fq "job112_status_fc_o10_r2=completed" "$DOC"
grep -Fq "job112_attempts_fc_o10_r2=1" "$DOC"
grep -Fq "job112_result_rows_fc_o10_r2=1" "$DOC"
grep -Fq "job_results_columns_fc_o10_r2=" "$DOC"
grep -Fq "job112_response_sha_fc_o10_r2=" "$DOC"
grep -Fq "job112_semantic_summary_pass_fc_o10_r2=" "$DOC"
grep -Fq "ct203_fc_o10_r2_read_only_acceptance_pass=true" "$DOC"

grep -Fq "job105_status_fc_o10_r2=running" "$DOC"
grep -Fq "job105_attempts_fc_o10_r2=1" "$DOC"
grep -Fq "job105_result_rows_fc_o10_r2=0" "$DOC"
grep -Fq "jobs106_111_remain_queued_attempts0_rows0=true" "$DOC"

grep -Fq "profile_sha_fc_o10_r2=56512391b1df4b444d8f72ff2213ee9faeeb2d2db8a55eb1a642d9d4a1202ebf" "$DOC"
grep -Fq "active_exact_services_fc_o10_r2=0" "$DOC"
grep -Fq "active_general_services_fc_o10_r2=0" "$DOC"
grep -Fq "failed_general_units_fc_o10_r2=6" "$DOC"

grep -Fq "the next separately approved step can run job106 only" "$DOC"

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

echo "stage-16-fc-o10-r2 job112 recovery smoke passed"
