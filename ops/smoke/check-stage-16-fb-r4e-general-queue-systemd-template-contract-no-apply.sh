#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r4e-general-queue-systemd-template-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R4E general_queue systemd template contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`7e3a155\`" "$DOC"
grep -Fq "read-only CT101 unit inventory and repo doc/smoke only" "$DOC"
grep -Fq "ct101_worker_sha_fb_r4e_read_only=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "exact_service=edge-ct101-exact-job-worker@.service" "$DOC"
grep -Fq "exact_timer=edge-ct101-exact-job-worker@.timer" "$DOC"
grep -Fq "exact_timer_enabled_fb_r4e=disabled" "$DOC"
grep -Fq "general_service_exists_before_fb_r4e=false" "$DOC"
grep -Fq "general_timer_exists_before_fb_r4e=false" "$DOC"
grep -Fq "active_general_services_fb_r4e=0" "$DOC"
grep -Fq "active_general_timers_fb_r4e=0" "$DOC"
grep -Fq "ct101_fb_r4e_read_only_inventory_acceptance_pass=true" "$DOC"
grep -Fq "EDGE_WORKER_MODE=general_queue" "$DOC"
grep -Fq "EDGE_ALLOWED_JOB_IDS=%i" "$DOC"
grep -Fq "Stage 16 FB-R4F" "$DOC"
grep -Fq "FB-R4F requires explicit approval" "$DOC"
grep -Fq "job 58: running failed evidence in DB but systemd failed marker cleared" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R4F\`" "$DOC"

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

echo "stage-16-fb-r4e general queue systemd template contract smoke passed"
