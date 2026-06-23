#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ev-r2-installed-unit-marker-extraction-failure-diagnostic-no-retry.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EV-R2 installed-unit marker extraction failure diagnostic no-retry" "$DOC"
grep -Fq "Base HEAD/origin/main: \`5ffb140\`" "$DOC"
grep -Fq "REFUSE_EXPECTED_MARKER_NOT_FOUND" "$DOC"
grep -Fq "REFUSE_WORKER_EXACT_MARKER_MISMATCH" "$DOC"
grep -Fq "repo HEAD/origin/main remained \`5ffb140\`" "$DOC"
grep -Fq "job53_status_after_timeout=running" "$DOC"
grep -Fq "job53_attempts_after_timeout=1" "$DOC"
grep -Fq "job53_result_rows_after_timeout=0" "$DOC"
grep -Fq "job54_status_after_timeout=running" "$DOC"
grep -Fq "job54_attempts_after_timeout=1" "$DOC"
grep -Fq "job54_result_rows_after_timeout=0" "$DOC"
grep -Fq "jobs_37_52_completed_with_one_result_after_timeout=16" "$DOC"
grep -Fq "max_job_id_after_timeout=54" "$DOC"
grep -Fq "timer54_active=inactive" "$DOC"
grep -Fq "timer54_enabled=disabled" "$DOC"
grep -Fq "service54_active=failed" "$DOC"
grep -Fq "service54_result=exit-code" "$DOC"
grep -Fq "active_exact_job_units=0" "$DOC"
grep -Fq "active_exact_job_timers=0" "$DOC"
grep -Fq "ct101_default_off_after_timeout=true" "$DOC"
grep -Fq "Return exactly E3Z-EV-OK" "$DOC"
grep -Fq "Return exactly this text and nothing else: <MARKER>" "$DOC"
grep -Fq "Neither job may be reset, deleted, reused, manually completed, or retried silently." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EW\`" "$DOC"
grep -Fq "Return exactly this text and nothing else: E3Z-EW-OK" "$DOC"

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

echo "stage-16-e3z-ev-r2 marker extraction diagnostic smoke passed"
