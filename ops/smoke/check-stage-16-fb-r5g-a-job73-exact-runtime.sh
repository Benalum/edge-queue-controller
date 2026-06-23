#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r5g-a-job73-exact-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R5G-A job73 exact runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FB_R5G_SERIAL_RUNTIME_JOBS_73_80_ONLY" "$DOC"
grep -Fq "Base HEAD/origin/main: \`8a842e9\`" "$DOC"
grep -Fq "start \`edge-ct101-exact-job-worker@73.timer\`" "$DOC"
grep -Fq "job73_runtime_outcome=completed" "$DOC"
grep -Fq "job73_status_after_fb_r5g_a=completed" "$DOC"
grep -Fq "job73_attempts_after_fb_r5g_a=1" "$DOC"
grep -Fq "job73_result_rows_after_fb_r5g_a=1" "$DOC"
grep -Fq "job73_exact_marker_match_fb_r5g_a=true" "$DOC"
grep -Fq "STAGE16-FB-R5-J73-OK" "$DOC"
grep -Fq "jobs74_80_queued_after_fb_r5g_a=7" "$DOC"
grep -Fq "jobs74_80_result_rows_after_fb_r5g_a=0" "$DOC"
grep -Fq "job73_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "ct101_final_default_off_after_fb_r5g_a_acceptance_pass=true" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R5G-B\`" "$DOC"

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

echo "stage-16-fb-r5g-a job73 exact runtime smoke passed"
