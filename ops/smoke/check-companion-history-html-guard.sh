#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

APP="frontend/study-ui/app.js"

if [ ! -f "$APP" ]; then
  echo "FAIL: missing $APP"
  exit 1
fi

# These markers prove the frontend recognizes transient companion gateway errors
# and replaces raw gateway/error HTML with a safe user-facing message.
required_markers=(
  "COMPANION_TRANSIENT_GATEWAY_V1"
  "I did not save the raw Cloudflare error page"
)

for marker in "${required_markers[@]}"; do
  if ! grep -Fq "$marker" "$APP"; then
    echo "FAIL: missing companion HTML/gateway guard marker in $APP: $marker"
    exit 1
  fi
done

# Guard against accidentally adding a path that stores obvious raw HTML error pages
# as assistant messages.
if grep -RIn "assistant.*<!DOCTYPE html\\|content.*<!DOCTYPE html\\|message.*<!DOCTYPE html" frontend/study-ui frontend/wrapper-ui 2>/dev/null; then
  echo "FAIL: possible raw HTML assistant message persistence path found"
  exit 1
fi

echo "PASS: companion history HTML guard markers are present"
