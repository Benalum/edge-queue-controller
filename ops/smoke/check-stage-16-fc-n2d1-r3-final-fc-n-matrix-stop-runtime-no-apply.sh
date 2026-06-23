#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-n2d1-r3-final-fc-n-matrix-stop-runtime-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-N2D1-R3 final FC-N matrix stop runtime no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`9404727\`" "$DOC"
grep -Fq "This stage is no-apply and read-only." "$DOC"

grep -Fq "fc_n2d1_r2_evidence_verified_for_r3=true" "$DOC"
grep -Fq "quick_check_fc_n2d1_r3=ok" "$DOC"
grep -Fq "ct203_fc_n2d1_r3_read_only_acceptance_pass=true" "$DOC"
grep -Fq "ct101_fc_n2d1_r3_failed_units_evidence_acceptance_pass=true" "$DOC"

grep -Fq "| 95 | router_label | qwen2.5:0.5b | completed | 1 | 1 | true | passed and keep as qwen2.5 evidence |" "$DOC"
grep -Fq "| 98 | json_response | qwen2.5:0.5b | completed | 1 | 1 | true | passed and keep as qwen2.5 evidence |" "$DOC"
grep -Fq "| 104 | safe_refusal | llama3.2:3b | running/stale | 1 | 0 | no | preserve as stale failed evidence |" "$DOC"

grep -Fq "failed_general_units_fc_n2d1_r3=5" "$DOC"
grep -Fq "Stop FC-N runtime." "$DOC"
grep -Fq "Do not run jobs102 or 103." "$DOC"
grep -Fq "Do not retry jobs97, 99, 100, 101, or 104." "$DOC"
grep -Fq "The failure now looks like a worker/model-runtime path issue for non-qwen2.5 runs" "$DOC"
grep -Fq "Recommended next stage: \`Stage 16 FC-O\`." "$DOC"
grep -Fq "FC-O can begin with read-only journal/log diagnosis" "$DOC"

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
  echo "approval token found in final no-apply matrix doc"
  exit 1
fi

echo "stage-16-fc-n2d1-r3 final matrix smoke passed"
