#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r5c-r2-job65-exact-runtime-failure-evidence-no-retry.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R5C-R2 job65 exact runtime failure evidence no-retry" "$DOC"
grep -Fq "Base HEAD/origin/main: \`526aab4\`" "$DOC"
grep -Fq "job65 had started through the exact-marker unit family and failed" "$DOC"
grep -Fq "job65_status_fb_r5c_r2=running" "$DOC"
grep -Fq "job65_attempts_fb_r5c_r2=1" "$DOC"
grep -Fq "job65_result_rows_fb_r5c_r2=0" "$DOC"
grep -Fq "jobs65_72_queued_fb_r5c_r2=7" "$DOC"
grep -Fq "jobs65_72_running_fb_r5c_r2=1" "$DOC"
grep -Fq "jobs65_72_result_rows_fb_r5c_r2=0" "$DOC"
grep -Fq "jobs 66 through 72: queued, attempts 0, result rows 0" "$DOC"
grep -Fq "job65_exact_service_result_fb_r5c_r2=exit-code" "$DOC"
grep -Fq "ct101_fb_r5c_r2_evidence_acceptance_pass=true" "$DOC"
grep -Fq "The new general_queue units were not exercised" "$DOC"
grep -Fq "Do not retry job65 blindly." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R5D\`" "$DOC"

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

if grep -Fq "APPROVE_" "$DOC"; then
  echo "approval token found in evidence doc"
  exit 1
fi

echo "stage-16-fb-r5c-r2 job65 failure evidence smoke passed"
