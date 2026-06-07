#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

MISSING=0

check_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "FAIL: $file not found"
    MISSING=1
  fi
}

check_marker() {
  local file="$1"
  local marker="$2"
  local description="$3"

  if ! grep -Fq "$marker" "$file"; then
    echo "FAIL: missing marker in $file: $description"
    MISSING=1
  else
    echo "PASS: found marker in $file: $description"
  fi
}

check_file "docs/public-route-map.md"
check_file "docs/deploy.md"

echo "=== Stage 2B-1: Normalized system status contract documentation markers ==="
echo "This check is read-only and does not require CT101."

check_marker "docs/public-route-map.md" "Stage 2B: Normalized system status contract preparation" "Stage 2B route-map section"
check_marker "docs/public-route-map.md" "Stage 2B is additive only" "additive-only contract note"
check_marker "docs/public-route-map.md" "Route names must not change" "route names remain stable"
check_marker "docs/public-route-map.md" "UI consumption is postponed to Stage 2C" "UI consumption postponed"
check_marker "docs/public-route-map.md" "Runtime implementation is postponed to Stage 2B-2" "runtime implementation postponed"
check_marker "docs/public-route-map.md" "Existing system status response fields must remain backward-compatible" "backward-compatible existing fields"

for marker in ok checked_at overall_state nodes services apis; do
  check_marker "docs/public-route-map.md" "\`$marker\`" "existing field $marker"
done

for marker in master-laptop pveso ct-101; do
  check_marker "docs/public-route-map.md" "\`$marker\`" "real node/container ID $marker"
done

for marker in controller-node server-nodes cpu-nodes gpu-nodes storage-nodes; do
  check_marker "docs/public-route-map.md" "\`$marker\`" "grouped infrastructure ID $marker"
done

for marker in backend-api frontend-wrapper queue workers power-automation; do
  check_marker "docs/public-route-map.md" "\`$marker\`" "platform service ID $marker"
done

for marker in gpu-worker image-generation video-generation; do
  check_marker "docs/public-route-map.md" "\`$marker\`" "future optional service ID $marker"
done

for marker in online offline booting degraded error unknown maintenance planned; do
  check_marker "docs/public-route-map.md" "\`$marker\`" "allowed normalized state $marker"
done

check_marker "docs/public-route-map.md" "| \`master-laptop\` | \`controller-node\` |" "master-laptop to controller-node mapping"
check_marker "docs/public-route-map.md" "| \`pveso\` | \`server-nodes\` |" "pveso to server-nodes mapping"
check_marker "docs/public-route-map.md" "| \`ct-101\` | \`cpu-nodes\` |" "ct-101 to cpu-nodes mapping"
check_marker "docs/public-route-map.md" "| none yet | \`gpu-nodes\` | May remain \`planned\` until active |" "gpu-nodes planned mapping"
check_marker "docs/public-route-map.md" "| none yet | \`storage-nodes\` | May remain \`planned\` until active |" "storage-nodes planned mapping"

check_marker "docs/deploy.md" "Stage 2B: Normalized grouped status contract preparation" "Stage 2B deploy section"
check_marker "docs/deploy.md" "Runtime implementation is postponed until Stage 2B-2" "runtime postponed in deploy notes"
check_marker "docs/deploy.md" "UI consumption is postponed until Stage 2C" "UI postponed in deploy notes"
check_marker "docs/deploy.md" "No route names should change during Stage 2B" "route names stable in deploy notes"
check_marker "docs/deploy.md" "Existing payload fields remain backward-compatible" "existing payload compatibility in deploy notes"

if [ "$MISSING" -eq 0 ]; then
  echo "PASS: normalized system status contract documentation markers verified"
  exit 0
fi

echo "FAIL: one or more normalized system status contract documentation markers are missing"
exit 1
