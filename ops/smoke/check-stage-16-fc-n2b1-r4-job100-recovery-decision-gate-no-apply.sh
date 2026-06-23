#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-n2b1-r4-job100-recovery-decision-gate-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-N2B1-R4 job100 recovery decision gate no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`1b6ef39\`" "$DOC"
grep -Fq "This stage is no-apply and read-only." "$DOC"

grep -Fq "fc_n2b1_r3_evidence_verified_for_r4=true" "$DOC"
grep -Fq "quick_check_fc_n2b1_r4=ok" "$DOC"
grep -Fq "ct203_fc_n2b1_r4_read_only_acceptance_pass=true" "$DOC"
grep -Fq "ct101_fc_n2b1_r4_failed_units_evidence_acceptance_pass=true" "$DOC"

grep -Fq "| 100 | companion_chat | gemma4:e4b | running/stale | 1 | 0 | no | preserve as stale failed evidence |" "$DOC"
grep -Fq "| 102 | study_tutor | gemma4:e4b | queued | 0 | 0 | no | block until gemma4 diagnosis |" "$DOC"
grep -Fq "| 103 | flashcards | gemma4:e4b | queued | 0 | 0 | no | block until gemma4 diagnosis |" "$DOC"

grep -Fq "failed_general_units_fc_n2b1_r4=3" "$DOC"
grep -Fq "job97_service_state_fc_n2b1_r4=failed" "$DOC"
grep -Fq "job99_service_state_fc_n2b1_r4=failed" "$DOC"
grep -Fq "job100_service_state_fc_n2b1_r4=failed" "$DOC"

grep -Fq "Preserve job97, job99, and job100 as stale failed evidence." "$DOC"
grep -Fq "Do not continue to gemma4 jobs102 or 103" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-N2C\`." "$DOC"
grep -Fq "continue only job101 \`gemma3:4b\` and job104 \`llama3.2:3b\`" "$DOC"
grep -Fq "FC-N2C requires explicit approval" "$DOC"

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
  echo "approval token found in no-apply FC-N2B1-R4 doc"
  exit 1
fi

echo "stage-16-fc-n2b1-r4 job100 recovery decision gate smoke passed"
