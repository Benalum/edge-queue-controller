#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-n2a-r2-timeout-recovery-unknown-state-no-new-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-N2A-R2 timeout recovery unknown state no-new-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_N2_CONTINUE_QUEUED_JOBS_98_104_SKIP_JOB97_PRESERVE_FAILED_EVIDENCE" "$DOC"
grep -Fq "Base HEAD/origin/main: \`e8d69ec\`" "$DOC"

grep -Fq "does not start new runtime" "$DOC"
grep -Fq "stops only possible lingering jobs98 and 99" "$DOC"
grep -Fq "quick_check_after_cleanup_fc_n2a_r2=ok" "$DOC"
grep -Fq "job97_status_after_cleanup_fc_n2a_r2=" "$DOC"
grep -Fq "job98_status_after_cleanup_fc_n2a_r2=" "$DOC"
grep -Fq "job99_status_after_cleanup_fc_n2a_r2=" "$DOC"
grep -Fq "jobs100_104_result_rows_after_cleanup_fc_n2a_r2=0" "$DOC"
grep -Fq "ct203_after_fc_n2a_r2_read_only_acceptance_pass=true" "$DOC"

grep -Fq "active_general_services_after_cleanup_fc_n2a_r2=0" "$DOC"
grep -Fq "active_general_timers_after_cleanup_fc_n2a_r2=0" "$DOC"
grep -Fq "ct101_fc_n2a_r2_cleanup_no_active_runtime_acceptance_pass=true" "$DOC"

grep -Fq "Do not continue FC-N runtime yet." "$DOC"
grep -Fq "Stage 16 FC-N2A-R3" "$DOC"

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

echo "stage-16-fc-n2a-r2 timeout recovery unknown-state smoke passed"
