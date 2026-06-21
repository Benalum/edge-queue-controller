#!/usr/bin/env bash
set -euo pipefail
set +H

echo "=== Stage 16-E2V smoke: local-only durable bridge doc assertions ==="
echo "MUTATION_SCOPE=local_repo_read_only_smoke"
echo "NO SSH"
echo "NO live infra mutation"
echo "NO DB write"
echo "NO worker/model/scheduler activation"
echo

cd "$(git rev-parse --show-toplevel)"

doc="docs/stage-16-e2v-durable-pveso-inventory-bridge-results.md"
test -f "$doc"

grep -F "Durable PVESO Inventory Bridge Results" "$doc" >/dev/null
grep -F "CT203 persistent secondary LAN IP service" "$doc" >/dev/null
grep -F "PVESO persistent firewall config" "$doc" >/dev/null
grep -F "Stage 16-E2T-R2 completed host.fw persistence" "$doc" >/dev/null
grep -F "Stage 16-E2U performed controlled PVESO firewall reload validation" "$doc" >/dev/null
grep -F "runtime nft persistent marker: true" "$doc" >/dev/null
grep -F "CT203 bound tcp/22 to PVESO after reload: ok" "$doc" >/dev/null
grep -F "inventory \`ok=true\`" "$doc" >/dev/null
grep -F "DB counts unchanged" "$doc" >/dev/null
grep -F "Do not start CT101 again" "$doc" >/dev/null
grep -F "Stage 16-E2W" "$doc" >/dev/null

echo "doc_assertions_ok=true"
echo "PASS_STAGE_16_E2V_LOCAL_ONLY_DOC_SMOKE"
