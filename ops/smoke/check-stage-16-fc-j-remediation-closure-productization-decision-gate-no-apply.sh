#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-j-remediation-closure-productization-decision-gate-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-J remediation closure productization decision gate no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`452ba77\`" "$DOC"
grep -Fq "quick_check_fc_j=ok" "$DOC"
grep -Fq "max_job_id_fc_j=94" "$DOC"
grep -Fq "jobs88_94_completed_fc_j=7" "$DOC"
grep -Fq "jobs88_94_result_rows_fc_j=7" "$DOC"
grep -Fq "ct203_fc_j_read_only_baseline_acceptance_pass=true" "$DOC"

grep -Fq "| 88 | study_tutor | remediation retry | pass | fail | blocked |" "$DOC"
grep -Fq "| 89 | flashcards | remediation retry | pass | fail | blocked |" "$DOC"
grep -Fq "| 90 | summary | remediation retry | pass | pass | recovered once; repeatability needed |" "$DOC"
grep -Fq "| 91 | json_response | remediation retry | pass | pass | recovered once; repeatability needed |" "$DOC"
grep -Fq "| 92 | safe_refusal | remediation retry | pass | fail | blocked |" "$DOC"
grep -Fq "| 93 | companion_chat | repeatability control | pass | fail | demoted; repeatability failed |" "$DOC"
grep -Fq "| 94 | router_label | repeatability control | pass | pass | repeatably passed |" "$DOC"

grep -Fq "Repeatably passed" "$DOC"
grep -Fq "\`router_label\`" "$DOC"
grep -Fq "Recovered once, needs repeatability" "$DOC"
grep -Fq "\`summary\`" "$DOC"
grep -Fq "\`json_response\`" "$DOC"
grep -Fq "Demoted due repeatability failure" "$DOC"
grep -Fq "\`companion_chat\`" "$DOC"
grep -Fq "Still blocked" "$DOC"
grep -Fq "\`study_tutor\`" "$DOC"
grep -Fq "\`flashcards\`" "$DOC"
grep -Fq "\`safe_refusal\`" "$DOC"

grep -Fq "Do not proceed to production activation." "$DOC"
grep -Fq "Do not activate scheduler." "$DOC"
grep -Fq "Do not enable persistent workers." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-K\`" "$DOC"

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
  echo "approval token found in no-apply FC-J doc"
  exit 1
fi

echo "stage-16-fc-j remediation closure decision gate smoke passed"
