#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r4d-reset-failed-job58-service-only-no-runtime.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R4D reset-failed job58 service only no-runtime" "$DOC"
grep -Fq "APPROVE_STAGE_16_FB_R4D_RESET_FAILED_JOB58_SERVICE_ONLY_NO_RUNTIME" "$DOC"
grep -Fq "Base HEAD/origin/main: \`8344124\`" "$DOC"
grep -Fq "systemctl reset-failed edge-ct101-exact-job-worker@58.service" "$DOC"
grep -Fq "job58_service_active_before_reset_failed=failed" "$DOC"
grep -Fq "job58_service_result_before_reset_failed=exit-code" "$DOC"
grep -Fq "job58_service_active_after_reset_failed=inactive" "$DOC"
grep -Fq "job58_service_enabled_after_reset_failed=static" "$DOC"
grep -Fq "active_exact_job_services_after_reset_failed=0" "$DOC"
grep -Fq "active_exact_job_timers_after_reset_failed=0" "$DOC"
grep -Fq "ct101_reset_failed_job58_only_acceptance_pass=true" "$DOC"
grep -Fq "25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "ct203_preservation_after_fb_r4d_reset_failed_acceptance_pass=true" "$DOC"
grep -Fq "job 58 remains running, attempts 1, result rows 0" "$DOC"
grep -Fq "The preserved systemd failed state for job58 has been cleared." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R4E\`" "$DOC"

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

echo "stage-16-fb-r4d reset-failed job58 service only smoke passed"
