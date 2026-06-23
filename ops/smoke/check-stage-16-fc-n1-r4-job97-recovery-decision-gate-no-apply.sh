#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-n1-r4-job97-recovery-decision-gate-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-N1-R4 job97 recovery decision gate no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`35cf312\`" "$DOC"
grep -Fq "This stage is no-apply and read-only." "$DOC"

grep -Fq "fc_n1_r3_evidence_verified_for_r4=true" "$DOC"
grep -Fq "quick_check_fc_n1_r4=ok" "$DOC"
grep -Fq "ct203_fc_n1_r4_read_only_acceptance_pass=true" "$DOC"
grep -Fq "ct101_fc_n1_r4_failed_unit_evidence_acceptance_pass=true" "$DOC"

grep -Fq "| 95 | router_label | qwen2.5:0.5b | completed | 1 | 1 |" "$DOC"
grep -Fq "| 96 | summary | qwen2.5:0.5b | completed | 1 | 1 |" "$DOC"
grep -Fq "| 97 | summary | qwen3:1.7b | running/stale | 1 | 0 | no | preserve as stale failed evidence |" "$DOC"

grep -Fq "job97_status_fc_n1_r4=running" "$DOC"
grep -Fq "job97_result_rows_fc_n1_r4=0" "$DOC"
grep -Fq "failed_general_units_fc_n1_r4=1" "$DOC"
grep -Fq "job97_service_state_fc_n1_r4=failed" "$DOC"
grep -Fq "job97_service_result_fc_n1_r4=exit-code" "$DOC"

grep -Fq "Preserve job97 as stale failed evidence." "$DOC"
grep -Fq "Do not retry job97 now." "$DOC"
grep -Fq "Do not reset job97 now." "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-N2\`." "$DOC"
grep -Fq "continue only queued jobs98 through 104" "$DOC"
grep -Fq "FC-N2 requires explicit approval" "$DOC"

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
  echo "approval token found in no-apply FC-N1-R4 doc"
  exit 1
fi

echo "stage-16-fc-n1-r4 job97 recovery decision gate smoke passed"
