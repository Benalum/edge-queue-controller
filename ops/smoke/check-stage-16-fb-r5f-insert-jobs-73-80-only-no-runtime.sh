#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r5f-insert-jobs-73-80-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R5F insert jobs 73-80 only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FB_R5F_INSERT_JOBS_73_80_ONLY_NO_RUNTIME" "$DOC"
grep -Fq "Base HEAD/origin/main: \`069268d\`" "$DOC"
grep -Fq "inserted exactly jobs 73 through 80" "$DOC"
grep -Fq "backup_path_fb_r5f=" "$DOC"
grep -Fq "backup_sha256_fb_r5f=" "$DOC"
grep -Fq "quick_check_before_fb_r5f_insert=ok" "$DOC"
grep -Fq "max_job_id_before_fb_r5f_insert=72" "$DOC"
grep -Fq "jobs73_80_existing_before_fb_r5f_insert=0" "$DOC"
grep -Fq "inserted_jobs_count_fb_r5f=8" "$DOC"
grep -Fq "max_job_id_after_fb_r5f_insert=80" "$DOC"
grep -Fq "jobs73_80_existing_after_fb_r5f_insert=8" "$DOC"
grep -Fq "jobs73_80_queued_after_fb_r5f_insert=8" "$DOC"
grep -Fq "jobs73_80_attempts_zero_after_fb_r5f_insert=8" "$DOC"
grep -Fq "jobs73_80_recovery_job_type_count_after_fb_r5f_insert=8" "$DOC"
grep -Fq "jobs73_80_recovery_model_count_after_fb_r5f_insert=8" "$DOC"
grep -Fq "jobs73_80_result_rows_after_fb_r5f_insert=0" "$DOC"
grep -Fq "ct203_fb_r5f_insert_acceptance_pass=true" "$DOC"
grep -Fq "job_type=stage16_e3z_limited_persistent_worker_repeat_proof" "$DOC"
grep -Fq "requested_model=qwen2.5:0.5b" "$DOC"
grep -Fq "jobs65_72_running_after_fb_r5f_insert=1" "$DOC"
grep -Fq "ct101_default_off_after_fb_r5f_insert_acceptance_pass=true" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R5G\`" "$DOC"

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

echo "stage-16-fb-r5f insert jobs 73-80 only smoke passed"
