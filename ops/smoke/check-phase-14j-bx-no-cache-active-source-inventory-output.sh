#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BX smoke: no cache active source inventory output ==="
echo "MUTATION_SCOPE=read_only_static_output_guard"
echo "NO runtime activation"
echo "NO CT101 call"
echo "NO model/Ollama endpoint call"
echo "NO DB mutation"
echo "NO job mutation"

smokes=(
  "ops/smoke/check-phase-14j-bw-active-source-only-ui-route-inventory.sh"
  "ops/smoke/check-phase-14j-bx-active-source-ui-map-inventory.sh"
)

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

for smoke in "${smokes[@]}"; do
  test -x "$smoke"
  name="$(basename "$smoke")"
  out="$tmpdir/$name.out"
  echo
  echo "=== guard output for $name ==="
  bash "$smoke" > "$out"

  if grep -E '(^|[[:space:]])(\.wrangler|\.cache|\.parcel-cache|\.next|coverage|docs/cleanup|\.cgpt-bridge)/' "$out" >/dev/null; then
    echo "FAIL: cache/history/noisy path found in output for $name"
    grep -E '(\.wrangler|\.cache|\.parcel-cache|\.next|coverage|docs/cleanup|\.cgpt-bridge)' "$out" | head -40
    exit 1
  fi

  lines="$(wc -l < "$out" | tr -d ' ')"
  printf 'guarded_output_lines_%s=%s\n' "$name" "$lines"
  echo "PASS: no cache/history/noisy paths in $name output"
done

echo
echo "PASS: no cache active source inventory output guard passed"
