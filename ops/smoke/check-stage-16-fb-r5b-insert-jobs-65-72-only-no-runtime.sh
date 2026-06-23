#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r5b-insert-jobs-65-72-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R5B insert jobs 65-72 only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FB_R5B_INSERT_JOBS_65_72_ONLY_NO_RUNTIME" "$DOC"
grep -Fq "Base HEAD/origin/main: \`829d416\`" "$DOC"
grep -Fq "inserted exactly jobs 65 through 72" "$DOC"
grep -Fq "backup_path_fb_r5b=" "$DOC"
grep -Fq "backup_sha256_fb_r5b=" "$DOC"
grep -Fq "quick_check_before_fb_r5b_insert=ok" "$DOC"
grep -Fq "max_job_id_before_fb_r5b_insert=64" "$DOC"
grep -Fq "jobs65_72_existing_before_fb_r5b_insert=0" "$DOC"
grep -Fq "inserted_jobs_count_fb_r5b=8" "$DOC"
grep -Fq "max_job_id_after_fb_r5b_insert=72" "$DOC"
grep -Fq "jobs65_72_existing_after_fb_r5b_insert=8" "$DOC"
grep -Fq "jobs65_72_queued_after_fb_r5b_insert=8" "$DOC"
grep -Fq "jobs65_72_attempts_zero_after_fb_r5b_insert=8" "$DOC"
grep -Fq "jobs65_72_result_rows_after_fb_r5b_insert=0" "$DOC"
grep -Fq "ct203_fb_r5b_insert_acceptance_pass=true" "$DOC"
grep -Fq "job 65: exact-marker sanity, queued, attempts 0, result rows 0" "$DOC"
grep -Fq "job 72: safe refusal boundary, queued, attempts 0, result rows 0" "$DOC"
grep -Fq "job 58: running, attempts 1, result rows 0" "$DOC"
grep -Fq "jobs 59 through 64: queued, attempts 0, result rows 0" "$DOC"
grep -Fq "ct101_default_off_after_fb_r5b_insert_acceptance_pass=true" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R5C\`" "$DOC"

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

echo "stage-16-fb-r5b insert jobs 65-72 only smoke passed"
