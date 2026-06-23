#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-l-model-inventory-readiness-no-apply.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-L model inventory readiness no-apply" "$DOC"
grep -Fq "Base HEAD/origin/main: \`e8f57b5\`" "$DOC"
grep -Fq "fc_k_plan_verified_for_fc_l=true" "$DOC"
grep -Fq "quick_check_fc_l=ok" "$DOC"
grep -Fq "max_job_id_fc_l=94" "$DOC"
grep -Fq "jobs95_104_existing_fc_l=0" "$DOC"
grep -Fq "ct203_fc_l_read_only_baseline_acceptance_pass=true" "$DOC"

grep -Fq "profile_sha_fc_l=432cd0130f61472b94215ffbf279f516bbc64d2d8ea0e8ba161878186816279c" "$DOC"
grep -Fq "active_exact_services_fc_l=0" "$DOC"
grep -Fq "active_general_services_fc_l=0" "$DOC"
grep -Fq "ct101_fc_l_read_only_inventory_acceptance_pass=true" "$DOC"

grep -Fq "ollama_manifest_count_fc_l=" "$DOC"
grep -Fq "ollama_blob_count_fc_l=" "$DOC"
grep -Fq "Ollama filesystem inventory" "$DOC"
grep -Fq "not from Ollama model endpoints" "$DOC"

grep -Fq "FC-M insert-only jobs95-104" "$DOC"
grep -Fq "FC-N runtime jobs95-104" "$DOC"
grep -Fq "Requires explicit approval." "$DOC"
grep -Fq "FC-L does not allow production activation." "$DOC"

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
  echo "approval token found in no-apply FC-L doc"
  exit 1
fi

echo "stage-16-fc-l model inventory readiness smoke passed"
