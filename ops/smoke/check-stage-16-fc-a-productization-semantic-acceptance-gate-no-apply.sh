#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-a-productization-semantic-acceptance-gate-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-A productization semantic acceptance gate no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`a67648c\`" "$DOC"
grep -Fq "jobs73_80_completed_fc_a=8" "$DOC"
grep -Fq "jobs73_80_result_rows_fc_a=8" "$DOC"
grep -Fq "ct203_fc_a_read_only_baseline_acceptance_pass=true" "$DOC"
grep -Fq "Stage 16 FB-R5 proved queue/runtime mechanics" "$DOC"
grep -Fq "did not prove productization readiness" "$DOC"
grep -Fq "Do not productize companion, study, flashcards" "$DOC"
grep -Fq "Proposed production lanes" "$DOC"
grep -Fq "stage16_fc_companion_chat_semantic_probe" "$DOC"
grep -Fq "Semantic acceptance validators" "$DOC"
grep -Fq "companion_chat" "$DOC"
grep -Fq "study_tutor" "$DOC"
grep -Fq "flashcards" "$DOC"
grep -Fq "summary" "$DOC"
grep -Fq "json_response" "$DOC"
grep -Fq "router_label" "$DOC"
grep -Fq "safe_refusal" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-B\`" "$DOC"
grep -Fq "Do not mutate profile yet." "$DOC"
grep -Fq "Do not insert jobs81 through 87 yet." "$DOC"

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
  echo "approval token found in no-apply FC-A doc"
  exit 1
fi

echo "stage-16-fc-a productization semantic acceptance gate smoke passed"
