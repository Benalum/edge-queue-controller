#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o11-qwen3-response-hygiene-diagnosis-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O11 qwen3 response hygiene diagnosis no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`8546444\`" "$DOC"
grep -Fq "This stage is read-only against CT203 and CT101." "$DOC"

grep -Fq "Job112 proved qwen3:1.7b can now execute through the CT203 queue after FC-O8." "$DOC"
grep -Fq "job112_status_fc_o11=completed" "$DOC"
grep -Fq "job112_attempts_fc_o11=1" "$DOC"
grep -Fq "job112_result_rows_fc_o11=1" "$DOC"
grep -Fq "job112_starts_with_thinking_fc_o11=true" "$DOC"
grep -Fq "job112_contains_thinking_fc_o11=true" "$DOC"
grep -Fq "job112_strict_response_hygiene_pass_fc_o11=false" "$DOC"

grep -Fq "qwen3_1_7b_policy_fc_o11=exact_marker_only" "$DOC"
grep -Fq "visible thinking text is stored in response_text" "$DOC"
grep -Fq "Running job106 now would likely produce JSON contaminated by thinking text." "$DOC"
grep -Fq "This is an output-control/hygiene issue, not a model reachability issue." "$DOC"

grep -Fq "job105_status_fc_o11=running" "$DOC"
grep -Fq "jobs106_111_remain_queued_attempts0_rows0=true" "$DOC"
grep -Fq "active_exact_services_fc_o11=0" "$DOC"
grep -Fq "active_general_services_fc_o11=0" "$DOC"
grep -Fq "failed_general_units_fc_o11=6" "$DOC"

grep -Fq "Do not run job106 yet." "$DOC"
grep -Fq "The next apply stage should add qwen3 response hygiene controls before JSON/runtime work." "$DOC"

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
if grep -Fq "APPROVE_" "$DOC"; then
  echo "approval token found in no-apply FC-O11 doc"
  exit 1
fi

echo "stage-16-fc-o11 qwen3 response hygiene smoke passed"
