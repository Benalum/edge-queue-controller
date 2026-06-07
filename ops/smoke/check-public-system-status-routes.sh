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
    echo "✗ Missing marker in $file: $description"
    MISSING=1
  else
    echo "✓ Found marker in $file: $description"
  fi
}

check_file "public_gateway.py"
check_file "cloudflare/edge-public-proxy/src/index.js"
check_file "frontend/wrapper-ui/app.js"
check_file "docs/public-route-map.md"

echo "=== Stage 2A: Public system status route markers ==="

check_marker "public_gateway.py" "/system/status" "public_gateway.py contains /system/status"
check_marker "public_gateway.py" "/system/public-status" "public_gateway.py contains /system/public-status"
check_marker "public_gateway.py" "/system/admin-status" "public_gateway.py contains /system/admin-status"
check_marker "public_gateway.py" "SYSTEM_STATUS_HEAD_SUPPORT_V1" "public_gateway.py documents HEAD support for system status routes"
check_marker "public_gateway.py" 'method in {"GET", "HEAD"}' "public_gateway.py accepts HEAD for system status routes"

check_marker "cloudflare/edge-public-proxy/src/index.js" "/api/system" "edge-public-proxy/src/index.js contains /api/system"
check_marker "cloudflare/edge-public-proxy/src/index.js" "/system/" "edge-public-proxy/src/index.js contains /system/"

check_marker "frontend/wrapper-ui/app.js" "/system/public-status" "frontend wrapper app reads /system/public-status"
check_marker "frontend/wrapper-ui/app.js" "/system/admin-status" "frontend wrapper app reads /system/admin-status"

check_marker "docs/public-route-map.md" "/system/public-status" "docs/public-route-map.md documents /system/public-status"
check_marker "docs/public-route-map.md" "/system/admin-status" "docs/public-route-map.md documents /system/admin-status"
check_marker "docs/public-route-map.md" "/public/status" "docs/public-route-map.md documents /public/status"

if [ "$MISSING" -eq 0 ]; then
  echo "PASS: public system status route markers verified"
  exit 0
fi

echo "FAIL: one or more public system status route markers are missing"
exit 1
