#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o6-run-only-job105-qwen3-summary-one-shot.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O6 run only job105 qwen3 summary one-shot" "$DOC"
grep -Fq "APPROVE_STAGE_16_FC_O6_RUN_ONLY_JOB105_QWEN3_SUMMARY_ONE_SHOT_NO_BULK_NO_OLD_JOB_MUTATION" "$DOC"
grep -Fq "Base HEAD/origin/main: \`dc1d025\`" "$DOC"

grep -Fq "This stage ran only job105" "$DOC"
grep -Fq "unit=edge-ct101-general-queue-job-worker@105.service" "$DOC"
grep -Fq "active_exact_services_after_fc_o6=0" "$DOC"
grep -Fq "active_general_services_after_fc_o6=0" "$DOC"
grep -Fq "active_exact_timers_after_fc_o6=0" "$DOC"
grep -Fq "active_general_timers_after_fc_o6=0" "$DOC"

grep -Fq "quick_check_after_fc_o6=ok" "$DOC"
grep -Fq "job105_status_after_fc_o6=" "$DOC"
grep -Fq "job105_attempts_after_fc_o6=" "$DOC"
grep -Fq "job105_result_rows_after_fc_o6=" "$DOC"
grep -Fq "job105_semantic_summary_pass_fc_o6=" "$DOC"
grep -Fq "ct203_post_fc_o6_read_only_acceptance_pass=true" "$DOC"
grep -Fq "Jobs106-111 remained queued with attempts=0 and result_rows=0." "$DOC"
grep -Fq "Do not run bulk replacement jobs." "$DOC"

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

echo "stage-16-fc-o6 job105 one-shot smoke passed"
