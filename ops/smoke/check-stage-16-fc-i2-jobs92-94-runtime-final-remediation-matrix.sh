#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-i2-jobs92-94-runtime-final-remediation-matrix.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-I2 jobs92-94 runtime final remediation matrix" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_I_SERIAL_RUNTIME_JOBS_88_94_WITH_REVISED_SEMANTIC_VALIDATORS" "$DOC"
grep -Fq "Base HEAD/origin/main: \`1fa856a\`" "$DOC"

grep -Fq "job92_status_after_fc_i2=completed" "$DOC"
grep -Fq "job93_status_after_fc_i2=completed" "$DOC"
grep -Fq "job94_status_after_fc_i2=completed" "$DOC"
grep -Fq "job92_result_rows_after_fc_i2=1" "$DOC"
grep -Fq "job93_result_rows_after_fc_i2=1" "$DOC"
grep -Fq "job94_result_rows_after_fc_i2=1" "$DOC"
grep -Fq "jobs88_94_completed_after_fc_i2=7" "$DOC"
grep -Fq "jobs88_94_result_rows_after_fc_i2=7" "$DOC"
grep -Fq "ct203_fc_i2_mechanical_acceptance_pass=true" "$DOC"

grep -Fq "job92_semantic_pass_fc_i2=" "$DOC"
grep -Fq "job93_semantic_pass_fc_i2=" "$DOC"
grep -Fq "job94_semantic_pass_fc_i2=" "$DOC"
grep -Fq "jobs88_94_semantic_pass_count_final_fc_i2=" "$DOC"
grep -Fq "jobs88_94_semantic_fail_count_final_fc_i2=" "$DOC"
grep -Fq "fc_i2_semantic_all_pass=" "$DOC"

grep -Fq "jobs81_87_completed_after_fc_i2=7" "$DOC"
grep -Fq "jobs73_80_completed_after_fc_i2=8" "$DOC"
grep -Fq "jobs65_72_running_after_fc_i2=1" "$DOC"
grep -Fq "jobs57_64_existing_after_fc_i2=8" "$DOC"

grep -Fq "job92_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job93_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job94_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "ct101_final_default_off_after_fc_i2_acceptance_pass=true" "$DOC"

grep -Fq "FC-I proves" "$DOC"
grep -Fq "no production activation is allowed from this stage" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-J\`" "$DOC"

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

echo "stage-16-fc-i2 jobs92-94 final remediation matrix smoke passed"
