#!/usr/bin/env bash
set -euo pipefail

# check-public-route-map-consistency.sh
#
# Stage 1: Non-destructive route map consistency check
#
# Validates that expected route ownership markers exist in:
# - docs/public-route-map.md (documentation)
# - cloudflare/edge-public-proxy/src/index.js (gateway mapping)
# - public_gateway.py (controller gateway)
#
# This script is validation-only and does not:
# - modify files
# - require CT101 to be online
# - make network calls
# - deploy anything
# - restart services
#
# Exit code: 0 if all markers found, 1 if any are missing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

MISSING=0

echo "=== Stage 1: Route Map Consistency Check ==="
echo

# Check docs/public-route-map.md
echo "Checking docs/public-route-map.md..."
ROUTE_MAP_FILE="$REPO_ROOT/docs/public-route-map.md"

if [ ! -f "$ROUTE_MAP_FILE" ]; then
  echo "  FAIL: $ROUTE_MAP_FILE not found"
  MISSING=1
else
  MARKERS=(
    "Controller-owned API routes"
    "CT101-owned API routes"
    "/system/\*"
    "/public/\*"
    "/api/auth/\*"
    "/api/jobs\*"
    "/api/study/\*"
    "/api/companion/\*"
    "/api/calendar/\*"
    "CT101 is not modified in Stage 1"
  )

  for marker in "${MARKERS[@]}"; do
    if grep -q "$marker" "$ROUTE_MAP_FILE"; then
      echo "  ✓ Found: $marker"
    else
      echo "  ✗ Missing: $marker"
      MISSING=1
    fi
  done
fi

echo

# Check cloudflare/edge-public-proxy/src/index.js
echo "Checking cloudflare/edge-public-proxy/src/index.js..."
GATEWAY_FILE="$REPO_ROOT/cloudflare/edge-public-proxy/src/index.js"

if [ ! -f "$GATEWAY_FILE" ]; then
  echo "  FAIL: $GATEWAY_FILE not found"
  MISSING=1
else
  MARKERS=(
    "mapApiPathToBackend"
    "/api/auth"
    "/api/jobs"
    "/api/study"
    "/api/companion"
    "/api/system"
  )

  for marker in "${MARKERS[@]}"; do
    if grep -q "$marker" "$GATEWAY_FILE"; then
      echo "  ✓ Found: $marker"
    else
      echo "  ✗ Missing: $marker"
      MISSING=1
    fi
  done
fi

echo

# Check public_gateway.py
echo "Checking public_gateway.py..."
CONTROLLER_GATEWAY_FILE="$REPO_ROOT/public_gateway.py"

if [ ! -f "$CONTROLLER_GATEWAY_FILE" ]; then
  echo "  FAIL: $CONTROLLER_GATEWAY_FILE not found"
  MISSING=1
else
  MARKERS=(
    "/public"
    "/system"
    "study"
    "companion"
  )

  for marker in "${MARKERS[@]}"; do
    if grep -q "$marker" "$CONTROLLER_GATEWAY_FILE"; then
      echo "  ✓ Found: $marker"
    else
      echo "  ✗ Missing: $marker"
      MISSING=1
    fi
  done
fi

echo
echo "=== Result ==="

if [ $MISSING -eq 0 ]; then
  echo "PASS: Route map consistency markers verified"
  exit 0
else
  echo "FAIL: One or more route map markers are missing"
  exit 1
fi
