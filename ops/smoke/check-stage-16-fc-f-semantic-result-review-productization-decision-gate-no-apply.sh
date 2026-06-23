#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-f-semantic-result-review-productization-decision-gate-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-F semantic result review productization decision gate no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`836dd5b\`" "$DOC"

grep -Fq "jobs81_87_completed_fc_f=7" "$DOC"
grep -Fq "jobs81_87_result_rows_fc_f=7" "$DOC"
grep -Fq "jobs81_87_mechanical_pass_count_fc_f=7" "$DOC"
grep -Fq "jobs81_87_semantic_pass_count_fc_f=2" "$DOC"
grep -Fq "jobs81_87_semantic_fail_count_fc_f=5" "$DOC"
grep -Fq "fc_f_productization_allowed_lane_count=2" "$DOC"
grep -Fq "fc_f_productization_blocked_lane_count=5" "$DOC"

grep -Fq "companion_chat | pass | pass" "$DOC"
grep -Fq "router_label | pass | pass" "$DOC"
grep -Fq "study_tutor | pass | fail" "$DOC"
grep -Fq "flashcards | pass | fail" "$DOC"
grep -Fq "summary | pass | fail" "$DOC"
grep -Fq "json_response | pass | fail" "$DOC"
grep -Fq "safe_refusal | pass | fail" "$DOC"

grep -Fq "Do not proceed to production activation." "$DOC"
grep -Fq "Do not activate scheduler." "$DOC"
grep -Fq "Do not enable persistent workers." "$DOC"
grep -Fq "Do not wire companion/study/flashcards public product routes yet." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-G\`" "$DOC"

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
  echo "approval token found in no-apply FC-F doc"
  exit 1
fi

echo "stage-16-fc-f semantic decision gate smoke passed"
