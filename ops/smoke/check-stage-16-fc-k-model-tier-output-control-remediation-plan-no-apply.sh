#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-k-model-tier-output-control-remediation-plan-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-K model-tier output-control remediation plan no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`464e311\`" "$DOC"
grep -Fq "fc_j_doc_decision_matrix_verified=true" "$DOC"
grep -Fq "quick_check_fc_k=ok" "$DOC"
grep -Fq "max_job_id_fc_k=94" "$DOC"
grep -Fq "jobs95_104_existing_fc_k=0" "$DOC"
grep -Fq "ct203_fc_k_read_only_baseline_acceptance_pass=true" "$DOC"

grep -Fq "\`qwen2.5:0.5b\` remains approved only for mechanical smoke" "$DOC"
grep -Fq "Use backend-enforced structured output." "$DOC"
grep -Fq "Use backend-enforced card schema." "$DOC"
grep -Fq "Use a policy-aware model tier and backend safety template." "$DOC"
grep -Fq "Use stronger companion model and repeatability probes." "$DOC"

grep -Fq "Jobs95 through 104 are future jobs" "$DOC"
grep -Fq "| 95 | router_label | repeatability control" "$DOC"
grep -Fq "| 96 | summary | repeatability control A" "$DOC"
grep -Fq "| 97 | summary | repeatability control B" "$DOC"
grep -Fq "| 98 | json_response | backend-shape control A" "$DOC"
grep -Fq "| 99 | json_response | backend-shape control B" "$DOC"
grep -Fq "| 100 | companion_chat | improved prompt repeatability A" "$DOC"
grep -Fq "| 101 | companion_chat | improved prompt repeatability B" "$DOC"
grep -Fq "| 102 | study_tutor | stronger prompt/model probe" "$DOC"
grep -Fq "| 103 | flashcards | structured card schema probe" "$DOC"
grep -Fq "| 104 | safe_refusal | policy-template probe" "$DOC"

grep -Fq "FC-L no-apply model inventory/readiness plan" "$DOC"
grep -Fq "FC-M insert-only jobs95-104" "$DOC"
grep -Fq "FC-N runtime jobs95-104" "$DOC"
grep -Fq "FC-K does not allow production activation." "$DOC"

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
  echo "approval token found in no-apply FC-K doc"
  exit 1
fi

echo "stage-16-fc-k model-tier output-control remediation plan smoke passed"
