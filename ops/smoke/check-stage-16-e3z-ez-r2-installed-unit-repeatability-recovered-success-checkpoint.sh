#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ez-r2-installed-unit-repeatability-recovered-success-checkpoint.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EZ-R2 installed-unit repeatability recovered success checkpoint" "$DOC"
grep -Fq "Base HEAD/origin/main: \`8a847ba\`" "$DOC"
grep -Fq "fresh job 56 was inserted" "$DOC"
grep -Fq "timer_start_rc=0" "$DOC"
grep -Fq "timer56_active_before_cleanup=active" "$DOC"
grep -Fq "timer56_active_after_cleanup=inactive" "$DOC"
grep -Fq "service56_result_after_cleanup=success" "$DOC"
grep -Fq "active_exact_job_services_after_cleanup=0" "$DOC"
grep -Fq "active_exact_job_timers_after_cleanup=0" "$DOC"
grep -Fq "ct101_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "quick_check_after_ez_timeout_cleanup=ok" "$DOC"
grep -Fq "job53_status_after_ez_timeout_cleanup=running" "$DOC"
grep -Fq "job53_attempts_after_ez_timeout_cleanup=1" "$DOC"
grep -Fq "job53_result_rows_after_ez_timeout_cleanup=0" "$DOC"
grep -Fq "job54_status_after_ez_timeout_cleanup=running" "$DOC"
grep -Fq "job54_attempts_after_ez_timeout_cleanup=1" "$DOC"
grep -Fq "job54_result_rows_after_ez_timeout_cleanup=0" "$DOC"
grep -Fq "job55_status_after_ez_timeout_cleanup=completed" "$DOC"
grep -Fq "job55_result_rows_after_ez_timeout_cleanup=1" "$DOC"
grep -Fq "job55_response_after_ez_timeout_cleanup=E3Z-EW-OK" "$DOC"
grep -Fq "job56_status_after_ez_timeout_cleanup=completed" "$DOC"
grep -Fq "job56_attempts_after_ez_timeout_cleanup=1" "$DOC"
grep -Fq "job56_result_rows_after_ez_timeout_cleanup=1" "$DOC"
grep -Fq "job56_response_after_ez_timeout_cleanup=E3Z-EY-OK" "$DOC"
grep -Fq "job56_exact_marker_after_ez_timeout_cleanup=true" "$DOC"
grep -Fq "ez_recovered_success_candidate=true" "$DOC"
grep -Fq "E3Z-EZ-R2 passed as a recovered repeatability success checkpoint." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FA\`" "$DOC"

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

echo "stage-16-e3z-ez-r2 recovered repeatability success smoke passed"
