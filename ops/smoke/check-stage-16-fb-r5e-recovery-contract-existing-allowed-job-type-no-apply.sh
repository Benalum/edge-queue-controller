#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r5e-recovery-contract-existing-allowed-job-type-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R5E recovery contract existing allowed job_type no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`bd92095\`" "$DOC"
grep -Fq "REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE" "$DOC"
grep -Fq "Use **fresh jobs 73 through 80**" "$DOC"
grep -Fq "Do not mutate the profile yet." "$DOC"
grep -Fq "stage16_e3z_limited_persistent_worker_repeat_proof" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "max_job_id_fb_r5e=72" "$DOC"
grep -Fq "jobs73_80_existing_fb_r5e=0" "$DOC"
grep -Fq "jobs65_72_queued_fb_r5e=7" "$DOC"
grep -Fq "jobs65_72_running_fb_r5e=1" "$DOC"
grep -Fq "ct203_fb_r5e_recovery_preflight_acceptance_pass=true" "$DOC"
grep -Fq "FB-R5F requires explicit approval" "$DOC"
grep -Fq "FB-R5G requires explicit approval" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R5F\`" "$DOC"

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
  echo "approval token found in no-apply contract doc"
  exit 1
fi

echo "stage-16-fb-r5e recovery contract smoke passed"
