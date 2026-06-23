#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r5a-fresh-corrected-breadth-batch-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R5A fresh corrected breadth batch contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`7202e53\`" "$DOC"
grep -Fq "read-only CT101/CT203 verification and repo docs/smoke only" "$DOC"
grep -Fq "ct101_worker_sha_fb_r5a=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "general_service_sha_fb_r5a=b1b4c6422e7188c7190eae2e27ae34cb520a7efc107631f560611e7f7242d68d" "$DOC"
grep -Fq "general_timer_sha_fb_r5a=c70c5495365b771d32ed787e35154c4bcb7c51bd8629d229ce87bdea937c766b" "$DOC"
grep -Fq "ct101_fb_r5a_read_only_unit_default_off_acceptance_pass=true" "$DOC"
grep -Fq "max_job_id_fb_r5a=64" "$DOC"
grep -Fq "jobs65_72_existing_fb_r5a=0" "$DOC"
grep -Fq "ct203_fb_r5a_job_id_availability_acceptance_pass=true" "$DOC"
grep -Fq "job 58: running, attempts 1, result rows 0" "$DOC"
grep -Fq "jobs 59 through 64: queued, attempts 0, result rows 0" "$DOC"
grep -Fq "STAGE16-FB-R5-J65-OK" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "FB-R5B must" "$DOC"
grep -Fq "FB-R5C must" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R5B\`" "$DOC"

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
  echo "approval token found in no-apply doc"
  exit 1
fi
if grep -Eq '^```bash' "$DOC"; then
  echo "bash executable block found in no-apply doc"
  exit 1
fi

echo "stage-16-fb-r5a fresh corrected breadth batch contract smoke passed"
