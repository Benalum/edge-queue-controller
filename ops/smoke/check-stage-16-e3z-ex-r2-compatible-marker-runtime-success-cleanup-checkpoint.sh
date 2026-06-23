#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-e3z-ex-r2-compatible-marker-runtime-success-cleanup-checkpoint.md"

test -f "$DOC"

grep -Fq "Stage 16 E3Z-EX-R2 compatible-marker runtime success cleanup checkpoint" "$DOC"
grep -Fq "Base HEAD/origin/main: \`86526b7\`" "$DOC"
grep -Fq "fresh job 55 exists" "$DOC"
grep -Fq "job 55 is completed" "$DOC"
grep -Fq "job55_status_after_ex_reconcile=completed" "$DOC"
grep -Fq "job55_attempts_after_ex_reconcile=1" "$DOC"
grep -Fq "job55_result_rows_after_ex_reconcile=1" "$DOC"
grep -Fq "job55_result_response_after_ex_reconcile=E3Z-EW-OK" "$DOC"
grep -Fq "job53_status_after_ex_reconcile=running" "$DOC"
grep -Fq "job53_attempts_after_ex_reconcile=1" "$DOC"
grep -Fq "job53_result_rows_after_ex_reconcile=0" "$DOC"
grep -Fq "job54_status_after_ex_reconcile=running" "$DOC"
grep -Fq "job54_attempts_after_ex_reconcile=1" "$DOC"
grep -Fq "job54_result_rows_after_ex_reconcile=0" "$DOC"
grep -Fq "timer55_active_before_cleanup=active" "$DOC"
grep -Fq "timer55_active_after_cleanup=inactive" "$DOC"
grep -Fq "active_exact_job_timers_after_cleanup=0" "$DOC"
grep -Fq "ct101_cleanup_acceptance_pass=true" "$DOC"
grep -Fq "E3Z-EX-R2 passed as a recovered runtime success checkpoint." "$DOC"
grep -Fq "Return exactly this text and nothing else: E3Z-EW-OK" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 E3Z-EY\`" "$DOC"

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

echo "stage-16-e3z-ex-r2 recovered runtime success smoke passed"
