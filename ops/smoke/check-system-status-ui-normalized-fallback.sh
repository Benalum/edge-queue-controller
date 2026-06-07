#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

MISSING=0
APP_JS="frontend/wrapper-ui/app.js"

check_marker() {
  local marker="$1"
  local description="$2"

  if ! grep -Fq "$marker" "$APP_JS"; then
    echo "FAIL: missing marker in $APP_JS: $description"
    MISSING=1
  else
    echo "PASS: found marker in $APP_JS: $description"
  fi
}

echo "=== Stage 2C: UI normalized status fallback markers ==="
echo "This check is read-only and does not require CT101."

if [ ! -f "$APP_JS" ]; then
  echo "FAIL: $APP_JS not found"
  exit 1
fi

check_marker "function getNormalizedStatus" "normalized status helper"
check_marker "function normalizedInfrastructureGroups" "normalized infrastructure helper"
check_marker "function normalizedPlatformGroups" "normalized platform helper"
check_marker "normalized?.[key]" "normalized payload lookup"
check_marker "normalized.infrastructure" "normalized.infrastructure usage"
check_marker "normalized.platform" "normalized.platform usage"
check_marker "Fallback to apiGroups()" "fallback to apiGroups"
check_marker "Fallback to infrastructureGroups()" "fallback to infrastructureGroups"
check_marker "lastStatus?.overall_state" "header still follows overall_state"
check_marker "renderApiCards(platformGroups)" "public system page uses platform groups"
check_marker "renderDrawerItems(\"drawerServices\", platformGroups, \"api\")" "drawer service status uses platform groups"
check_marker "renderInfraCards(infraGroups)" "admin system page uses infrastructure groups"
check_marker "normalizedInfrastructureGroups(cleanAdminSystem)" "admin page uses normalized infrastructure when available"

if command -v node >/dev/null 2>&1; then
  node --check "$APP_JS"
  echo "PASS: node syntax check passed for $APP_JS"
else
  echo "SKIP: node not available; skipped frontend syntax check"
fi

if [ "$MISSING" -eq 0 ]; then
  echo "PASS: UI normalized status fallback markers verified"
  exit 0
fi

echo "FAIL: one or more UI normalized status fallback markers are missing"
exit 1
