#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-n1-r3-failed-unit-evidence-checkpoint-no-new-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-N1-R3 failed unit evidence checkpoint no-new-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_N_SERIAL_RUNTIME_JOBS_95_104_WITH_MODEL_TIER_VALIDATORS" "$DOC"
grep -Fq "Base HEAD/origin/main: \`7d06e6d\`" "$DOC"

grep -Fq "This stage is read-only." "$DOC"
grep -Fq "reset-failed services" "$DOC"
grep -Fq "quick_check_fc_n1_r3=ok" "$DOC"
grep -Fq "job95_status_fc_n1_r3=completed" "$DOC"
grep -Fq "job96_status_fc_n1_r3=completed" "$DOC"
grep -Fq "job97_status_fc_n1_r3=" "$DOC"
grep -Fq "job97_result_rows_fc_n1_r3=0" "$DOC"
grep -Fq "jobs100_104_queued_fc_n1_r3=5" "$DOC"
grep -Fq "ct203_fc_n1_r3_read_only_acceptance_pass=true" "$DOC"

grep -Fq "active_general_services_fc_n1_r3=0" "$DOC"
grep -Fq "active_general_timers_fc_n1_r3=0" "$DOC"
grep -Fq "failed_general_units_fc_n1_r3=" "$DOC"
grep -Fq "job97_service_state_fc_n1_r3=" "$DOC"
grep -Fq "ct101_fc_n1_r3_no_active_runtime_acceptance_pass=true" "$DOC"

grep -Fq "Do not continue FC-N runtime yet." "$DOC"
grep -Fq "Stage 16 FC-N1-R4" "$DOC"

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

echo "stage-16-fc-n1-r3 failed unit evidence checkpoint smoke passed"
