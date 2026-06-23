#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-i1-jobs88-91-runtime-revised-semantic-validators.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-I1 jobs88-91 runtime revised semantic validators" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_I_SERIAL_RUNTIME_JOBS_88_94_WITH_REVISED_SEMANTIC_VALIDATORS" "$DOC"
grep -Fq "Base HEAD/origin/main: \`2ad0cde\`" "$DOC"

grep -Fq "job88_status_after_fc_i1=completed" "$DOC"
grep -Fq "job89_status_after_fc_i1=completed" "$DOC"
grep -Fq "job90_status_after_fc_i1=completed" "$DOC"
grep -Fq "job91_status_after_fc_i1=completed" "$DOC"
grep -Fq "job88_result_rows_after_fc_i1=1" "$DOC"
grep -Fq "job89_result_rows_after_fc_i1=1" "$DOC"
grep -Fq "job90_result_rows_after_fc_i1=1" "$DOC"
grep -Fq "job91_result_rows_after_fc_i1=1" "$DOC"
grep -Fq "ct203_fc_i1_mechanical_acceptance_pass=true" "$DOC"

grep -Fq "job88_semantic_pass_fc_i1=" "$DOC"
grep -Fq "job89_semantic_pass_fc_i1=" "$DOC"
grep -Fq "job90_semantic_pass_fc_i1=" "$DOC"
grep -Fq "job91_semantic_pass_fc_i1=" "$DOC"
grep -Fq "jobs88_91_semantic_pass_count_fc_i1=" "$DOC"
grep -Fq "jobs88_91_semantic_fail_count_fc_i1=" "$DOC"
grep -Fq "fc_i1_semantic_all_pass=" "$DOC"

grep -Fq "jobs92_94_queued_after_fc_i1=3" "$DOC"
grep -Fq "jobs92_94_result_rows_after_fc_i1=0" "$DOC"
grep -Fq "job88_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job89_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job90_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job91_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "ct101_final_default_off_after_fc_i1_acceptance_pass=true" "$DOC"
grep -Fq "Stage 16 FC-I2" "$DOC"

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

echo "stage-16-fc-i1 jobs88-91 runtime revised semantic validators smoke passed"
