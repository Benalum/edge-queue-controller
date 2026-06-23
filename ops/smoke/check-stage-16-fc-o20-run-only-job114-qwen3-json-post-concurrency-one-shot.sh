#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o20-run-only-job114-qwen3-json-post-concurrency-one-shot.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O20 run only job114 qwen3 JSON post-concurrency one-shot" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O20_RUN_ONLY_JOB114_QWEN3_JSON_POST_CONCURRENCY_ONE_SHOT_NO_BULK_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "Base HEAD/origin/main: \`a27b5e4\`" "$DOC"

grep -Fq "This stage ran only job114" "$DOC"
grep -Fq "unit=edge-ct101-general-queue-job-worker@114.service" "$DOC"
grep -Fq "profile_sha_fc_o20=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899" "$DOC"
grep -Fq "worker_sha_fc_o20=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_before_fc_o20=2" "$DOC"
grep -Fq "OLLAMA_NUM_PARALLEL_after_fc_o20=2" "$DOC"

grep -Fq "active_exact_services_after_fc_o20=0" "$DOC"
grep -Fq "active_general_services_after_fc_o20=0" "$DOC"
grep -Fq "active_exact_timers_after_fc_o20=0" "$DOC"
grep -Fq "active_general_timers_after_fc_o20=0" "$DOC"

grep -Fq "quick_check_after_fc_o20=ok" "$DOC"
grep -Fq "job114_status_after_fc_o20=" "$DOC"
grep -Fq "job114_attempts_after_fc_o20=" "$DOC"
grep -Fq "job114_result_rows_after_fc_o20=" "$DOC"
grep -Fq "job114_json_like_fc_o20=" "$DOC"
grep -Fq "job114_json_parse_pass_fc_o20=" "$DOC"
grep -Fq "job114_strict_json_pass_fc_o20=" "$DOC"
grep -Fq "ct203_post_fc_o20_read_only_acceptance_pass=true" "$DOC"

grep -Fq "Job105 remained running with attempts=1 and result_rows=0." "$DOC"
grep -Fq "Job106 remained completed with attempts=1 and result_rows=1." "$DOC"
grep -Fq "Jobs107-111 remained queued with attempts=0 and result_rows=0." "$DOC"
grep -Fq "Job112 remained completed with attempts=1 and result_rows=1." "$DOC"
grep -Fq "Job113 remained completed with attempts=1 and result_rows=1." "$DOC"

grep -Fq "If job114_strict_json_pass_fc_o20=true" "$DOC"
grep -Fq "If job114_strict_json_pass_fc_o20=false" "$DOC"
grep -Fq "Do not enable persistent workers or bulk queue draining yet." "$DOC"
grep -Fq "two-job qwen3 parallel proof design" "$DOC"

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

echo "stage-16-fc-o20 job114 qwen3 json post-concurrency one-shot smoke passed"
