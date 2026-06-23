#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-n2c1-r3-job101-recovery-decision-gate-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-N2C1-R3 job101 recovery decision gate no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`5555212\`" "$DOC"
grep -Fq "This stage is no-apply and read-only." "$DOC"

grep -Fq "fc_n2c1_r2_evidence_verified_for_r3=true" "$DOC"
grep -Fq "quick_check_fc_n2c1_r3=ok" "$DOC"
grep -Fq "ct203_fc_n2c1_r3_read_only_acceptance_pass=true" "$DOC"
grep -Fq "ct101_fc_n2c1_r3_failed_units_evidence_acceptance_pass=true" "$DOC"

grep -Fq "| 101 | companion_chat | gemma3:4b | running/stale | 1 | 0 | no | preserve as stale failed evidence |" "$DOC"
grep -Fq "| 104 | safe_refusal | llama3.2:3b | queued | 0 | 0 | no | only remaining queued non-gemma/non-qwen3 probe |" "$DOC"

grep -Fq "failed_general_units_fc_n2c1_r3=4" "$DOC"
grep -Fq "job97_service_state_fc_n2c1_r3=failed" "$DOC"
grep -Fq "job99_service_state_fc_n2c1_r3=failed" "$DOC"
grep -Fq "job100_service_state_fc_n2c1_r3=failed" "$DOC"
grep -Fq "job101_service_state_fc_n2c1_r3=failed" "$DOC"

grep -Fq "Preserve jobs97, 99, 100, and 101 as stale failed evidence." "$DOC"
grep -Fq "Job104 remains the only queued, non-gemma/non-qwen3 FC-N probe." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-N2D\`." "$DOC"
grep -Fq "FC-N2D runtime requires explicit approval if job104 is run." "$DOC"

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
  echo "approval token found in no-apply FC-N2C1-R3 doc"
  exit 1
fi

echo "stage-16-fc-n2c1-r3 job101 recovery decision gate smoke passed"
