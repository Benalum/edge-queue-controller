#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fb-r2-partial-runtime-failure-evidence-checkpoint-no-retry.md"

test -f "$DOC"

grep -Fq "Stage 16 FB-R2 partial runtime failure evidence checkpoint no-retry" "$DOC"
grep -Fq "Base HEAD/origin/main: \`4278066\`" "$DOC"
grep -Fq "job 57 completed successfully" "$DOC"
grep -Fq "REFUSE_EXPECTED_MARKER_NOT_FOUND" "$DOC"
grep -Fq "job 58 remained running with attempts 1 and no result rows" "$DOC"
grep -Fq "jobs 59 through 64 remained queued" "$DOC"
grep -Fq "timer58_active_evidence=inactive" "$DOC"
grep -Fq "service58_active_evidence=failed" "$DOC"
grep -Fq "service58_result_evidence=exit-code" "$DOC"
grep -Fq "active_exact_job_services_evidence=0" "$DOC"
grep -Fq "active_exact_job_timers_evidence=0" "$DOC"
grep -Fq "ct101_failed_state_preserved_acceptance_pass=true" "$DOC"
grep -Fq "quick_check_fb_r2_evidence=ok" "$DOC"
grep -Fq "job57_status_fb_r2_evidence=completed" "$DOC"
grep -Fq "job57_response_fb_r2_evidence=STAGE16-FB-J57-OK" "$DOC"
grep -Fq "job58_status_fb_r2_evidence=running" "$DOC"
grep -Fq "job58_attempts_fb_r2_evidence=1" "$DOC"
grep -Fq "job58_result_rows_fb_r2_evidence=0" "$DOC"
grep -Fq "jobs57_64_completed_fb_r2_evidence=1" "$DOC"
grep -Fq "jobs57_64_running_fb_r2_evidence=1" "$DOC"
grep -Fq "jobs57_64_queued_fb_r2_evidence=6" "$DOC"
grep -Fq "fb_r2_evidence_acceptance_pass=true" "$DOC"
grep -Fq "not a general queue breadth worker" "$DOC"
grep -Fq "Jobs 57 through 64 are now FB evidence." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FB-R3\`" "$DOC"

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

echo "stage-16-fb-r2 evidence checkpoint smoke passed"
