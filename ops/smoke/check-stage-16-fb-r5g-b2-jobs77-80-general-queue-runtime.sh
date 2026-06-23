#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r5g-b2-jobs77-80-general-queue-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R5G-B2 jobs77-80 general_queue runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FB_R5G_SERIAL_RUNTIME_JOBS_73_80_ONLY" "$DOC"
grep -Fq "Base HEAD/origin/main: \`c6f268f\`" "$DOC"
grep -Fq "job77_status_after_fb_r5g_b2=completed" "$DOC"
grep -Fq "job78_status_after_fb_r5g_b2=completed" "$DOC"
grep -Fq "job79_status_after_fb_r5g_b2=completed" "$DOC"
grep -Fq "job80_status_after_fb_r5g_b2=completed" "$DOC"
grep -Fq "job77_result_rows_after_fb_r5g_b2=1" "$DOC"
grep -Fq "job78_result_rows_after_fb_r5g_b2=1" "$DOC"
grep -Fq "job79_result_rows_after_fb_r5g_b2=1" "$DOC"
grep -Fq "job80_result_rows_after_fb_r5g_b2=1" "$DOC"
grep -Fq "ct203_fb_r5g_b2_final_acceptance_pass=true" "$DOC"
grep -Fq "jobs74_80_completed_after_fb_r5g_b2=7" "$DOC"
grep -Fq "jobs74_80_result_rows_after_fb_r5g_b2=7" "$DOC"
grep -Fq "jobs65_72_running_after_fb_r5g_b2=1" "$DOC"
grep -Fq "job77_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job78_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job79_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job80_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "ct101_final_default_off_after_fb_r5g_b2_acceptance_pass=true" "$DOC"
grep -Fq "The fresh recovery batch succeeded" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R5H\`" "$DOC"

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

echo "stage-16-fb-r5g-b2 jobs77-80 general_queue runtime smoke passed"
