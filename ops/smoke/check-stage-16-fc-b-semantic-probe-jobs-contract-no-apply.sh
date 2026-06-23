#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-b-semantic-probe-jobs-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-B semantic probe jobs contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`30b60d6\`" "$DOC"
grep -Fq "jobs81_87_existing_fc_b=0" "$DOC"
grep -Fq "jobs73_80_completed_fc_b=8" "$DOC"
grep -Fq "ct203_fc_b_read_only_baseline_acceptance_pass=true" "$DOC"

grep -Fq "stage16_fc_companion_chat_semantic_probe" "$DOC"
grep -Fq "stage16_fc_study_tutor_semantic_probe" "$DOC"
grep -Fq "stage16_fc_flashcards_semantic_probe" "$DOC"
grep -Fq "stage16_fc_summary_semantic_probe" "$DOC"
grep -Fq "stage16_fc_json_semantic_probe" "$DOC"
grep -Fq "stage16_fc_router_label_semantic_probe" "$DOC"
grep -Fq "stage16_fc_safe_refusal_semantic_probe" "$DOC"

grep -Fq "job81 companion_chat validator" "$DOC"
grep -Fq "job82 study_tutor validator" "$DOC"
grep -Fq "job83 flashcards validator" "$DOC"
grep -Fq "job84 summary validator" "$DOC"
grep -Fq "job85 JSON validator" "$DOC"
grep -Fq "job86 router_label validator" "$DOC"
grep -Fq "job87 safe_refusal validator" "$DOC"

grep -Fq "mechanically passed" "$DOC"
grep -Fq "semantically passed" "$DOC"
grep -Fq "productization blocked" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-C\`" "$DOC"
grep -Fq "Do not insert jobs81 through 87 until FC-C profile mutation is complete" "$DOC"

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
  echo "approval token found in no-apply FC-B doc"
  exit 1
fi

echo "stage-16-fc-b semantic probe jobs contract smoke passed"
