#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-n2b1-r3-job100-timeout-recovery-no-new-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-N2B1-R3 job100 timeout recovery no-new-runtime" "$DOC"
grep -Fq "Base HEAD/origin/main: \`770fcf6\`" "$DOC"
grep -Fq "job100 had actually started" "$DOC"
grep -Fq "stop \`edge-ct101-general-queue-job-worker@100.timer\`" "$DOC"
grep -Fq "quick_check_after_cleanup_fc_n2b1_r3=ok" "$DOC"
grep -Fq "ct203_after_cleanup_fc_n2b1_r3_acceptance_pass=true" "$DOC"
grep -Fq "job100_status_after_cleanup_fc_n2b1_r3=" "$DOC"
grep -Fq "job100_attempts_after_cleanup_fc_n2b1_r3=1" "$DOC"
grep -Fq "jobs100_104_result_rows_after_cleanup_fc_n2b1_r3=" "$DOC"
grep -Fq "ct101_fc_n2b1_r3_cleanup_no_active_runtime_acceptance_pass=true" "$DOC"
grep -Fq "active_general_services_after_cleanup_fc_n2b1_r3=0" "$DOC"
grep -Fq "active_general_timers_after_cleanup_fc_n2b1_r3=0" "$DOC"
grep -Fq "failed_general_units_after_cleanup_fc_n2b1_r3=" "$DOC"
grep -Fq "Do not continue FC-N runtime yet." "$DOC"
grep -Fq "Job100 is now evidence and must be handled by a decision gate" "$DOC"

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

echo "stage-16-fc-n2b1-r3 job100 timeout recovery smoke passed"
