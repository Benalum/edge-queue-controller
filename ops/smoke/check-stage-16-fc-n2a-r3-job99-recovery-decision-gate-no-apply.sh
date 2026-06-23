#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-n2a-r3-job99-recovery-decision-gate-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-N2A-R3 job99 recovery decision gate no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`fc21d87\`" "$DOC"
grep -Fq "This stage is no-apply and read-only." "$DOC"

grep -Fq "fc_n2a_r2_evidence_verified_for_r3=true" "$DOC"
grep -Fq "quick_check_fc_n2a_r3=ok" "$DOC"
grep -Fq "ct203_fc_n2a_r3_read_only_acceptance_pass=true" "$DOC"
grep -Fq "ct101_fc_n2a_r3_failed_units_evidence_acceptance_pass=true" "$DOC"

grep -Fq "| 98 | json_response | qwen2.5:0.5b | completed | 1 | 1 | true | keep evidence |" "$DOC"
grep -Fq "| 99 | json_response | qwen3:1.7b | running/stale | 1 | 0 | false | preserve as stale failed evidence |" "$DOC"

grep -Fq "job97_status_fc_n2a_r3=running" "$DOC"
grep -Fq "job99_status_fc_n2a_r3=running" "$DOC"
grep -Fq "job99_result_rows_fc_n2a_r3=0" "$DOC"
grep -Fq "failed_general_units_fc_n2a_r3=2" "$DOC"
grep -Fq "job97_service_state_fc_n2a_r3=failed" "$DOC"
grep -Fq "job99_service_state_fc_n2a_r3=failed" "$DOC"

grep -Fq "Preserve job97 and job99 as stale failed evidence." "$DOC"
grep -Fq "qwen3:1.7b now has two stale/failed one-shot outcomes" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-N2B\`." "$DOC"
grep -Fq "continue only queued jobs100 through 104" "$DOC"
grep -Fq "FC-N2B requires explicit approval" "$DOC"

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
  echo "approval token found in no-apply FC-N2A-R3 doc"
  exit 1
fi

echo "stage-16-fc-n2a-r3 job99 recovery decision gate smoke passed"
