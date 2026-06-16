#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BV smoke: no historical static inventory output ==="
echo "MUTATION_SCOPE=read_only_static_output_guard"
echo "NO runtime activation"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO DB mutation"
echo "NO job mutation"

smokes=(
  "ops/smoke/check-phase-14j-br-public-product-surface-static-inventory.sh"
  "ops/smoke/check-phase-14j-bs-product-ui-static-contract.sh"
  "ops/smoke/check-phase-14j-bs-public-route-ownership-static-contract.sh"
  "ops/smoke/check-phase-14j-bv-active-public-product-surface-static-inventory.sh"
)

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

for smoke in "${smokes[@]}"; do
  test -x "$smoke"
  name="$(basename "$smoke")"
  echo
  echo "=== guard output for $name ==="
  bash "$smoke" > "$tmpdir/$name.out"

  if grep -E '(^|[[:space:]])(\.cleanup-archive|\.cleanup-backups|\.cgpt-bridge|docs/cleanup)/' "$tmpdir/$name.out" >/dev/null; then
    echo "FAIL: historical/noisy path found in output for $name"
    grep -E '(\.cleanup-archive|\.cleanup-backups|\.cgpt-bridge|docs/cleanup)' "$tmpdir/$name.out" | head -40
    exit 1
  fi

  lines="$(wc -l < "$tmpdir/$name.out" | tr -d ' ')"
  printf 'guarded_output_lines_%s=%s\n' "$name" "$lines"
  echo "PASS: no historical/noisy paths in $name output"
done

echo
echo "PASS: no historical static inventory output guard passed"
