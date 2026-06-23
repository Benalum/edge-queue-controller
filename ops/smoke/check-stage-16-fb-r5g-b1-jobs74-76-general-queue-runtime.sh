#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r5g-b1-jobs74-76-general-queue-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R5G-B1 jobs74-76 general_queue runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FB_R5G_SERIAL_RUNTIME_JOBS_73_80_ONLY" "$DOC"
grep -Fq "Base HEAD/origin/main: \`ab193c6\`" "$DOC"
grep -Fq "job74_status_after_fb_r5g_b1=completed" "$DOC"
grep -Fq "job75_status_after_fb_r5g_b1=completed" "$DOC"
grep -Fq "job76_status_after_fb_r5g_b1=completed" "$DOC"
grep -Fq "job74_result_rows_after_fb_r5g_b1=1" "$DOC"
grep -Fq "job75_result_rows_after_fb_r5g_b1=1" "$DOC"
grep -Fq "job76_result_rows_after_fb_r5g_b1=1" "$DOC"
grep -Fq "ct203_fb_r5g_b1_final_acceptance_pass=true" "$DOC"
grep -Fq "jobs77_80_queued_after_fb_r5g_b1=4" "$DOC"
grep -Fq "jobs77_80_result_rows_after_fb_r5g_b1=0" "$DOC"
grep -Fq "job74_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job75_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "job76_unit_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "ct101_final_default_off_after_fb_r5g_b1_acceptance_pass=true" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R5G-B2\`" "$DOC"

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

echo "stage-16-fb-r5g-b1 jobs74-76 general_queue runtime smoke passed"
