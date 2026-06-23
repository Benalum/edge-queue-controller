#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r5d-job-type-profile-eligibility-diagnosis-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R5D job_type/profile eligibility diagnosis no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`b4a415e\`" "$DOC"
grep -Fq "read-only CT203/CT101 profile, source, unit, and journal diagnosis" "$DOC"
grep -Fq "Job65 did not fail because of marker mismatch." "$DOC"
grep -Fq "REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE" "$DOC"
grep -Fq "job65_status_fb_r5d=running" "$DOC"
grep -Fq "job65_attempts_fb_r5d=1" "$DOC"
grep -Fq "job65_result_rows_fb_r5d=0" "$DOC"
grep -Fq "jobs65_72_queued_fb_r5d=7" "$DOC"
grep -Fq "jobs65_72_running_fb_r5d=1" "$DOC"
grep -Fq "ct203_fb_r5d_read_only_acceptance_pass=true" "$DOC"
grep -Fq "ct101_fb_r5d_profile_diagnosis_acceptance_pass=true" "$DOC"
grep -Fq "The CT101 profile eligibility gate is working as designed" "$DOC"
grep -Fq "Option A, preferred" "$DOC"
grep -Fq "Option B" "$DOC"
grep -Fq "Option C" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R5E\`" "$DOC"
grep -Fq "Do not retry job65 or process jobs66 through 72" "$DOC"

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
  echo "approval token found in no-apply diagnosis doc"
  exit 1
fi

echo "stage-16-fb-r5d profile eligibility diagnosis smoke passed"
