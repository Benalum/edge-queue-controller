#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r5h-r5-recovery-batch-closure-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R5H R5 recovery batch closure no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`1cd3afe\`" "$DOC"
grep -Fq "jobs73_80_completed_fb_r5h=8" "$DOC"
grep -Fq "jobs73_80_attempts_one_fb_r5h=8" "$DOC"
grep -Fq "jobs73_80_result_rows_fb_r5h=8" "$DOC"
grep -Fq "jobs74_80_completed_fb_r5h=7" "$DOC"
grep -Fq "jobs74_80_result_rows_fb_r5h=7" "$DOC"
grep -Fq "job73_exact_marker_match_fb_r5h=true" "$DOC"
grep -Fq "STAGE16-FB-R5-J73-OK" "$DOC"
grep -Fq "Important quality caveat" "$DOC"
grep -Fq "does not prove production semantic quality" "$DOC"
grep -Fq "jobs65_72_running_fb_r5h=1" "$DOC"
grep -Fq "jobs65_72_result_rows_fb_r5h=0" "$DOC"
grep -Fq "jobs57_64_existing_fb_r5h=8" "$DOC"
grep -Fq "active_exact_services_fb_r5h=0" "$DOC"
grep -Fq "active_general_services_fb_r5h=0" "$DOC"
grep -Fq "ct101_fb_r5h_default_off_acceptance_pass=true" "$DOC"
grep -Fq "Stage 16 FB-R5 proves" "$DOC"
grep -Fq "Stage 16 FB-R5 does not prove" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-A\`" "$DOC"

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
  echo "approval token found in no-apply closure doc"
  exit 1
fi

echo "stage-16-fb-r5h closure smoke passed"
