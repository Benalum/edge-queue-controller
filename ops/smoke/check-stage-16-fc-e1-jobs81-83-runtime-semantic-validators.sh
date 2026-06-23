#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-e1-jobs81-83-runtime-semantic-validators.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-E1 jobs81-83 runtime semantic validators" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_E_SERIAL_RUNTIME_JOBS_81_87_WITH_SEMANTIC_VALIDATORS" "$DOC"
grep -Fq "Base HEAD/origin/main: \`f734c49\`" "$DOC"

grep -Fq "job81_status_after_fc_e1=completed" "$DOC"
grep -Fq "job82_status_after_fc_e1=completed" "$DOC"
grep -Fq "job83_status_after_fc_e1=completed" "$DOC"
grep -Fq "job81_result_rows_after_fc_e1=1" "$DOC"
grep -Fq "job82_result_rows_after_fc_e1=1" "$DOC"
grep -Fq "job83_result_rows_after_fc_e1=1" "$DOC"
grep -Fq "ct203_fc_e1_mechanical_acceptance_pass=true" "$DOC"

grep -Fq "jobs81_83_semantic_pass_count_fc_e1=" "$DOC"
grep -Fq "jobs81_83_semantic_fail_count_fc_e1=" "$DOC"
grep -Fq "fc_e1_semantic_all_pass=" "$DOC"
grep -Fq "Semantic failures are not treated as runtime failure" "$DOC"

grep -Fq "jobs84_87_queued_after_fc_e1=4" "$DOC"
grep -Fq "jobs84_87_result_rows_after_fc_e1=0" "$DOC"
grep -Fq "job81_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job82_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job83_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "ct101_final_default_off_after_fc_e1_acceptance_pass=true" "$DOC"
grep -Fq "Stage 16 FC-E2" "$DOC"

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

echo "stage-16-fc-e1 jobs81-83 runtime semantic validators smoke passed"
