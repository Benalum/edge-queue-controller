#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BU smoke: no cleanup archive static inventory output ==="
echo "MUTATION_SCOPE=read_only_static_output_guard"
echo "NO runtime activation"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO DB mutation"
echo "NO job mutation"

PUBLIC_SMOKE="ops/smoke/check-phase-14j-br-public-product-surface-static-inventory.sh"
BS_UI_SMOKE="ops/smoke/check-phase-14j-bs-product-ui-static-contract.sh"
BS_ROUTE_SMOKE="ops/smoke/check-phase-14j-bs-public-route-ownership-static-contract.sh"

for smoke in "$PUBLIC_SMOKE" "$BS_UI_SMOKE" "$BS_ROUTE_SMOKE"; do
  test -x "$smoke"
done

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo
echo "=== run public/product inventory with archive-noise guard ==="
bash "$PUBLIC_SMOKE" > "$tmpdir/public.out"
if grep -F ".cleanup-archive" "$tmpdir/public.out" >/dev/null; then
  echo "FAIL: public/product inventory output includes cleanup archive paths"
  sed -n '1,120p' "$tmpdir/public.out"
  exit 1
fi
echo "PASS: public/product inventory excludes cleanup archive paths"

echo
echo "=== run product UI inventory with archive-noise guard ==="
bash "$BS_UI_SMOKE" > "$tmpdir/ui.out"
if grep -F ".cleanup-archive" "$tmpdir/ui.out" >/dev/null; then
  echo "FAIL: product UI inventory output includes cleanup archive paths"
  sed -n '1,120p' "$tmpdir/ui.out"
  exit 1
fi
echo "PASS: product UI inventory excludes cleanup archive paths"

echo
echo "=== run route inventory with archive-noise guard ==="
bash "$BS_ROUTE_SMOKE" > "$tmpdir/route.out"
if grep -F ".cleanup-archive" "$tmpdir/route.out" >/dev/null; then
  echo "FAIL: route inventory output includes cleanup archive paths"
  sed -n '1,120p' "$tmpdir/route.out"
  exit 1
fi
echo "PASS: route inventory excludes cleanup archive paths"

echo
echo "PASS: no cleanup archive static inventory output guard passed"
