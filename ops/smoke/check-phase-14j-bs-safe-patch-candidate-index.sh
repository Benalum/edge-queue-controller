#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BS reusable smoke: safe patch candidate index ==="
echo "MUTATION_SCOPE=read_only_candidate_index"
echo "NO runtime activation"

DOC="docs/phase-14j-bs-batched-static-smoke-coverage-and-safe-ui-contract-candidates.md"

test -f "$DOC"

for marker in \
  "SAFE_PATCH_CANDIDATE_INDEX=created" \
  "CANDIDATE_CLASS=public_route_ownership_static_contracts" \
  "CANDIDATE_CLASS=product_ui_static_contracts" \
  "CANDIDATE_CLASS=parked_runtime_no_touch_contracts" \
  "CANDIDATE_CLASS=controller_owned_safe_ui_polish" \
  "CANDIDATE_CLASS=next_milestone_consolidation" \
  "ACTIVATION_REQUIRES_EXPLICIT_USER_APPROVAL"
do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: candidate marker found: $marker"
done

echo
echo "PASS: safe patch candidate index smoke passed"
