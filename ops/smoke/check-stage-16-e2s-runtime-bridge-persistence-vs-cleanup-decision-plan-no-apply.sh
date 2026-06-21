#!/usr/bin/env bash
set -euo pipefail
set +H

echo "=== Stage 16-E2S smoke: local-only decision doc assertions ==="
echo "MUTATION_SCOPE=local_repo_read_only_smoke"
echo "NO SSH"
echo "NO live infra mutation"
echo "NO DB write"
echo "NO worker/model/scheduler activation"
echo

cd "$(git rev-parse --show-toplevel)"

doc="docs/stage-16-e2s-runtime-bridge-persistence-vs-cleanup-decision-plan-no-apply.md"
test -f "$doc"

grep -F "Runtime Bridge Persistence vs Cleanup" "$doc" >/dev/null
grep -F "Option A" "$doc" >/dev/null
grep -F "recommended next apply path" "$doc" >/dev/null
grep -F "APPROVE_STAGE_16_E2T_PERSIST_CT203_SECONDARY_LAN_IP_AND_PVESO_FIREWALL_ALLOW_FOR_INVENTORY_ONLY_NO_PUBLIC_ROUTE_CUTOVER_NO_DB_WRITE" "$doc" >/dev/null
grep -F "Do not start CT101 again" "$doc" >/dev/null
grep -F "CT203 primary IP/gateway change" "$doc" >/dev/null
grep -F "Ollama/model endpoint calls" "$doc" >/dev/null

echo "doc_assertions_ok=true"
echo "PASS_STAGE_16_E2S_LOCAL_ONLY_DOC_SMOKE"
