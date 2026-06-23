#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-et-r2-installed-unit-proof-failure-cleanup-diagnostic-no-retry.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-ET-R2 installed-unit proof failure cleanup diagnostic no-retry" "$DOC"
grep -Fq "Base HEAD/origin/main: \`a309b8d\`" "$DOC"
grep -Fq "REFUSE_WORKER_EXACT_MARKER_MISMATCH" "$DOC"
grep -Fq "Because a model attempt occurred, job 53 must not be reset, deleted, or retried silently." "$DOC"
grep -Fq "job53_status_after_et_failure=running" "$DOC"
grep -Fq "job53_attempts_after_et_failure=1" "$DOC"
grep -Fq "job53_result_rows_after_et_failure=0" "$DOC"
grep -Fq "jobs_37_52_completed_with_one_result_after_et_failure=16" "$DOC"
grep -Fq "cleanup_acceptance_pass=true" "$DOC"
grep -Fq "timer_instance_active_after_cleanup=inactive" "$DOC"
grep -Fq "timer_instance_enabled_after_cleanup=disabled" "$DOC"
grep -Fq "edge_service_after_cleanup_active=inactive" "$DOC"
grep -Fq "edge_service_after_cleanup_enabled=disabled" "$DOC"
grep -Fq "active_exact_job_units_after_cleanup=0" "$DOC"
grep -Fq "active_exact_job_timers_after_cleanup=0" "$DOC"
grep -Fq "model output did not exactly match the marker" "$DOC"
grep -Fq "Job 53 must not be reset, deleted, or retried silently." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EU\`" "$DOC"

# The doc must not contain raw private or Tailscale IP addresses.
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

echo "stage-16-e3z-et-r2 failure cleanup diagnostic smoke passed"
