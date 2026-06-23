#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o14-run-only-job113-qwen3-summary-hygiene-one-shot.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O14 run only job113 qwen3 summary hygiene one-shot" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O14_RUN_ONLY_JOB113_QWEN3_SUMMARY_HYGIENE_ONE_SHOT_NO_BULK_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "Base HEAD/origin/main: \`7ee60bd\`" "$DOC"

grep -Fq "This stage ran only job113" "$DOC"
grep -Fq "unit=edge-ct101-general-queue-job-worker@113.service" "$DOC"
grep -Fq "profile_sha_fc_o14=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"

grep -Fq "active_exact_services_after_fc_o14=0" "$DOC"
grep -Fq "active_general_services_after_fc_o14=0" "$DOC"
grep -Fq "active_exact_timers_after_fc_o14=0" "$DOC"
grep -Fq "active_general_timers_after_fc_o14=0" "$DOC"

grep -Fq "quick_check_after_fc_o14=ok" "$DOC"
grep -Fq "job113_status_after_fc_o14=" "$DOC"
grep -Fq "job113_attempts_after_fc_o14=" "$DOC"
grep -Fq "job113_result_rows_after_fc_o14=" "$DOC"
grep -Fq "job113_starts_with_thinking_fc_o14=" "$DOC"
grep -Fq "job113_contains_thinking_fc_o14=" "$DOC"
grep -Fq "job113_strict_response_hygiene_pass_fc_o14=" "$DOC"
grep -Fq "ct203_post_fc_o14_read_only_acceptance_pass=true" "$DOC"

grep -Fq "Job105 remained running with attempts=1 and result_rows=0." "$DOC"
grep -Fq "Jobs106-111 remained queued with attempts=0 and result_rows=0." "$DOC"
grep -Fq "Job112 remained completed with attempts=1 and result_rows=1." "$DOC"

grep -Fq "If job113_strict_response_hygiene_pass_fc_o14=true" "$DOC"
grep -Fq "If job113_strict_response_hygiene_pass_fc_o14=false" "$DOC"
grep -Fq "Do not change Ollama concurrency in this runtime stage." "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL" "$DOC"
grep -Fq "CT203 remains the durable queue authority" "$DOC"

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

echo "stage-16-fc-o14 job113 one-shot smoke passed"
