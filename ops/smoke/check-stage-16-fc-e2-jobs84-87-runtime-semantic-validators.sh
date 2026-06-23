#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-e2-jobs84-87-runtime-semantic-validators.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-E2 jobs84-87 runtime semantic validators" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_E_SERIAL_RUNTIME_JOBS_81_87_WITH_SEMANTIC_VALIDATORS" "$DOC"
grep -Fq "Base HEAD/origin/main: \`6d77c57\`" "$DOC"

grep -Fq "job84_status_after_fc_e2=completed" "$DOC"
grep -Fq "job85_status_after_fc_e2=completed" "$DOC"
grep -Fq "job86_status_after_fc_e2=completed" "$DOC"
grep -Fq "job87_status_after_fc_e2=completed" "$DOC"
grep -Fq "job84_result_rows_after_fc_e2=1" "$DOC"
grep -Fq "job85_result_rows_after_fc_e2=1" "$DOC"
grep -Fq "job86_result_rows_after_fc_e2=1" "$DOC"
grep -Fq "job87_result_rows_after_fc_e2=1" "$DOC"
grep -Fq "jobs81_87_completed_after_fc_e2=7" "$DOC"
grep -Fq "jobs81_87_result_rows_after_fc_e2=7" "$DOC"
grep -Fq "ct203_fc_e2_mechanical_acceptance_pass=true" "$DOC"

grep -Fq "job84_semantic_pass_fc_e2=" "$DOC"
grep -Fq "job85_semantic_pass_fc_e2=" "$DOC"
grep -Fq "job86_semantic_pass_fc_e2=" "$DOC"
grep -Fq "job87_semantic_pass_fc_e2=" "$DOC"
grep -Fq "jobs81_87_semantic_pass_count_final_fc_e2=" "$DOC"
grep -Fq "jobs81_87_semantic_fail_count_final_fc_e2=" "$DOC"
grep -Fq "fc_e2_semantic_all_pass=" "$DOC"
grep -Fq "Semantic failures are not runtime failures" "$DOC"

grep -Fq "jobs73_80_completed_after_fc_e2=8" "$DOC"
grep -Fq "jobs65_72_running_after_fc_e2=1" "$DOC"
grep -Fq "jobs57_64_existing_after_fc_e2=8" "$DOC"

grep -Fq "job84_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job85_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job86_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job87_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "ct101_final_default_off_after_fc_e2_acceptance_pass=true" "$DOC"

grep -Fq "FC-E proves" "$DOC"
grep -Fq "semantic gates are necessary" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-F\`" "$DOC"

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

echo "stage-16-fc-e2 jobs84-87 runtime semantic validators smoke passed"
