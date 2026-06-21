#!/usr/bin/env bash
set -euo pipefail
set +H

echo "=== Stage 16-E2R smoke: local-only doc assertions ==="
echo "MUTATION_SCOPE=local_repo_read_only_smoke"
echo "NO SSH"
echo "NO live infra mutation"
echo "NO DB write"
echo "NO worker/model/scheduler activation"
echo

cd "$(git rev-parse --show-toplevel)"

doc="docs/stage-16-e2r-e2p-e2q-inventory-recovery-results-and-runtime-state.md"
test -f "$doc"

grep -F "Stage 16-E2P-R3 succeeded" "$doc" >/dev/null
grep -F "Stage 16-E2Q succeeded" "$doc" >/dev/null
grep -F "inventory \`ok=true\`" "$doc" >/dev/null
grep -F "runtime-only network/firewall state" "$doc" >/dev/null
grep -F "temporary CT203 secondary IP" "$doc" >/dev/null
grep -F "temporary PVESO firewall allow" "$doc" >/dev/null
grep -F "Do not start CT101 yet" "$doc" >/dev/null
grep -F "Stage 16-E2S" "$doc" >/dev/null

echo "doc_assertions_ok=true"
echo "PASS_STAGE_16_E2R_LOCAL_ONLY_DOC_SMOKE"
