#!/usr/bin/env bash
set -euo pipefail
set +H

echo "=== Stage 16-E2O smoke: local-only no-apply doc assertions ==="
echo "MUTATION_SCOPE=local_repo_read_only_smoke"
echo "NO SSH"
echo "NO live infra mutation"
echo "NO network config mutation"
echo "NO DB write"
echo "NO worker/model/scheduler activation"
echo

cd "$(git rev-parse --show-toplevel)"

doc="docs/stage-16-e2o-ct203-temporary-secondary-lan-ip-candidate-plan-no-apply.md"
test -f "$doc"
grep -F "temporary secondary IP" "$doc" >/dev/null
grep -F "APPROVE_STAGE_16_E2P_ADD_TEMP_CT203_SECONDARY_LAN_IP_FOR_PVESO_INVENTORY_TEST_NO_PUBLIC_ROUTE_CUTOVER_NO_DB_WRITE" "$doc" >/dev/null
grep -F "E2P must not" "$doc" >/dev/null
grep -F "Rollback Shape" "$doc" >/dev/null
grep -F "CT101 remains stopped" "$doc" >/dev/null
grep -F "No route to host" "$doc" >/dev/null
grep -F "Proceed to E2P only with explicit approval" "$doc" >/dev/null

echo "doc_assertions_ok=true"
echo "PASS_STAGE_16_E2O_LOCAL_ONLY_PLAN_SMOKE"
