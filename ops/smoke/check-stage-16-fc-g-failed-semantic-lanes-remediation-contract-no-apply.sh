#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-g-failed-semantic-lanes-remediation-contract-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-G failed semantic lanes remediation contract no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`78aff10\`" "$DOC"
grep -Fq "max_job_id_fc_g=87" "$DOC"
grep -Fq "jobs88_94_existing_fc_g=0" "$DOC"
grep -Fq "jobs81_87_completed_fc_g=7" "$DOC"
grep -Fq "jobs81_87_result_rows_fc_g=7" "$DOC"
grep -Fq "ct203_fc_g_read_only_baseline_acceptance_pass=true" "$DOC"

grep -Fq "Do not reset, retry, delete, or manually complete jobs81 through 87." "$DOC"
grep -Fq "fresh jobs88 through 94" "$DOC"

grep -Fq "job88 study_tutor" "$DOC"
grep -Fq "job89 flashcards" "$DOC"
grep -Fq "job90 summary" "$DOC"
grep -Fq "job91 JSON response" "$DOC"
grep -Fq "job92 safe_refusal" "$DOC"
grep -Fq "job93 companion_chat repeatability control" "$DOC"
grep -Fq "job94 router_label repeatability control" "$DOC"

grep -Fq "FC-H insert-only" "$DOC"
grep -Fq "FC-I runtime" "$DOC"
grep -Fq "Requires explicit approval." "$DOC"
grep -Fq "activation remains blocked until a separate approved product route stage" "$DOC"

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
  echo "approval token found in no-apply FC-G doc"
  exit 1
fi

echo "stage-16-fc-g remediation contract smoke passed"
