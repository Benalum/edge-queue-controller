#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-n2d1-r2-job104-timeout-recovery-unknown-state-no-new-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-N2D1-R2 job104 timeout recovery unknown state no-new-runtime" "$DOC"
grep -Fq "Base HEAD/origin/main: \`e0abc87\`" "$DOC"
grep -Fq "job104 had to be treated as unknown until inspected" "$DOC"
grep -Fq "quick_check_after_cleanup_fc_n2d1_r2=ok" "$DOC"
grep -Fq "ct203_after_cleanup_fc_n2d1_r2_acceptance_pass=true" "$DOC"
grep -Fq "job104_status_after_cleanup_fc_n2d1_r2=" "$DOC"
grep -Fq "job104_attempts_after_cleanup_fc_n2d1_r2=" "$DOC"
grep -Fq "job104_result_rows_after_cleanup_fc_n2d1_r2=" "$DOC"
grep -Fq "ct101_fc_n2d1_r2_cleanup_no_active_runtime_acceptance_pass=true" "$DOC"
grep -Fq "active_general_services_after_cleanup_fc_n2d1_r2=0" "$DOC"
grep -Fq "active_general_timers_after_cleanup_fc_n2d1_r2=0" "$DOC"
grep -Fq "Do not run more FC-N runtime." "$DOC"
grep -Fq "Job104 now needs a final no-apply decision gate." "$DOC"

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

echo "stage-16-fc-n2d1-r2 job104 timeout recovery smoke passed"
