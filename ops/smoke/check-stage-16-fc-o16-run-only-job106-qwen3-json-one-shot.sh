#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o16-run-only-job106-qwen3-json-one-shot.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O16 run only job106 qwen3 JSON one-shot" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O16_RUN_ONLY_JOB106_QWEN3_JSON_ONE_SHOT_NO_BULK_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "Base HEAD/origin/main: \`89a1d98\`" "$DOC"

grep -Fq "This stage ran only job106" "$DOC"
grep -Fq "unit=edge-ct101-general-queue-job-worker@106.service" "$DOC"
grep -Fq "profile_sha_fc_o16=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"

grep -Fq "active_exact_services_after_fc_o16=0" "$DOC"
grep -Fq "active_general_services_after_fc_o16=0" "$DOC"
grep -Fq "active_exact_timers_after_fc_o16=0" "$DOC"
grep -Fq "active_general_timers_after_fc_o16=0" "$DOC"

grep -Fq "quick_check_after_fc_o16=ok" "$DOC"
grep -Fq "job106_status_after_fc_o16=" "$DOC"
grep -Fq "job106_attempts_after_fc_o16=" "$DOC"
grep -Fq "job106_result_rows_after_fc_o16=" "$DOC"
grep -Fq "job106_json_like_fc_o16=" "$DOC"
grep -Fq "job106_json_parse_pass_fc_o16=" "$DOC"
grep -Fq "job106_strict_json_pass_fc_o16=" "$DOC"
grep -Fq "ct203_post_fc_o16_read_only_acceptance_pass=true" "$DOC"

grep -Fq "Job105 remained running with attempts=1 and result_rows=0." "$DOC"
grep -Fq "Jobs107-111 remained queued with attempts=0 and result_rows=0." "$DOC"
grep -Fq "Job112 remained completed with attempts=1 and result_rows=1." "$DOC"
grep -Fq "Job113 remained completed with attempts=1 and result_rows=1." "$DOC"

grep -Fq "If job106_strict_json_pass_fc_o16=true" "$DOC"
grep -Fq "If job106_strict_json_pass_fc_o16=false" "$DOC"
grep -Fq "Do not change Ollama concurrency in this runtime stage." "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL=2" "$DOC"
grep -Fq "CT203 still as durable queue authority" "$DOC"

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

echo "stage-16-fc-o16 job106 qwen3 json one-shot smoke passed"
