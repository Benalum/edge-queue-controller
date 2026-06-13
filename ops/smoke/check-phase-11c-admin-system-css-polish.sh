#!/usr/bin/env bash

echo "=== Phase 11C smoke: CSS-only Admin/System polish ==="

fail=0

code_for() {
  local url="$1"
  curl -sS --max-time 5 -o /tmp/phase11c-curl.out -w "%{http_code}" "$url" 2>/tmp/phase11c-curl.err || true
}

echo
echo "=== verify stage files exist ==="
for path in \
  docs/phase-11c-admin-system-css-polish.md \
  ops/smoke/check-phase-11c-admin-system-css-polish.sh \
  frontend/wrapper-ui/styles.css
do
  if [ -f "$path" ]; then
    echo "PASS: found $path"
  else
    echo "FAIL: missing $path"
    fail=1
  fi
done

echo
echo "=== verify Phase 11B tag remains present ==="
if git rev-parse --verify controller-phase-11b-admin-system-dashboard-polish-inspection-2026-06-13 >/dev/null 2>&1; then
  echo "PASS: Phase 11B tag exists"
else
  echo "FAIL: Phase 11B tag missing"
  fail=1
fi

echo
echo "=== verify CSS marker exists exactly once ==="
marker_count="$(grep -c 'PHASE_11C_ADMIN_SYSTEM_CSS_POLISH_BEGIN' frontend/wrapper-ui/styles.css || true)"
if [ "$marker_count" = "1" ]; then
  echo "PASS: Phase 11C CSS marker exists exactly once"
else
  echo "FAIL: Phase 11C CSS marker count is $marker_count"
  fail=1
fi

echo
echo "=== verify this is CSS-only for runtime source ==="
if git diff --name-only | grep -E '(^edge_controller\.py$|^frontend/wrapper-ui/app\.js$|\.py$|\.js$|\.html$)' ; then
  echo "FAIL: runtime source outside CSS/doc/smoke changed"
  fail=1
else
  echo "PASS: no Python, JavaScript, or HTML runtime source changed"
fi

echo
echo "=== verify expected changed files only ==="
changed_files="$(git diff --name-only | sort)"
echo "$changed_files"

unexpected="$(printf '%s\n' "$changed_files" | grep -vE '^(docs/phase-11c-admin-system-css-polish\.md|ops/smoke/check-phase-11c-admin-system-css-polish\.sh|frontend/wrapper-ui/styles\.css)$' || true)"
if [ -n "$unexpected" ]; then
  echo "FAIL: unexpected changed files:"
  printf '%s\n' "$unexpected"
  fail=1
else
  echo "PASS: only expected Phase 11C files changed"
fi

echo
echo "=== verify CSS block has balanced braces ==="
python3 - <<'PY'
from pathlib import Path
import re
import sys

path = Path("frontend/wrapper-ui/styles.css")
text = path.read_text()

start = "/* PHASE_11C_ADMIN_SYSTEM_CSS_POLISH_BEGIN */"
end = "/* PHASE_11C_ADMIN_SYSTEM_CSS_POLISH_END */"

match = re.search(re.escape(start) + r"(.*?)" + re.escape(end), text, re.DOTALL)
if not match:
    print("FAIL: CSS block not found")
    sys.exit(1)

block = match.group(1)
open_count = block.count("{")
close_count = block.count("}")

print(f"css_block_open_braces={open_count}")
print(f"css_block_close_braces={close_count}")

if open_count != close_count:
    print("FAIL: CSS block brace count mismatch")
    sys.exit(1)

print("PASS: CSS block brace count is balanced")
PY
if [ "$?" != "0" ]; then
  fail=1
fi

echo
echo "=== discover frontend/API gateway with GET only ==="
CANDIDATES="
http://127.0.0.1:8787
http://127.0.0.1:7070
http://127.0.0.1:8088
https://alexhartel.com
"

FRONTEND_BASE=""
STATUS_BASE=""

for base in $CANDIDATES; do
  root_code="$(code_for "$base/")"
  admin_code="$(code_for "$base/admin")"
  system_code="$(code_for "$base/system")"
  styles_code="$(code_for "$base/styles.css")"
  status_code="$(code_for "$base/api/system/status")"

  echo "CHECK: $base root=$root_code admin=$admin_code system=$system_code styles=$styles_code system_status=$status_code"

  if [ -z "$FRONTEND_BASE" ] && [ "$root_code" = "200" ] && [ "$admin_code" = "200" ] && [ "$system_code" = "200" ] && [ "$styles_code" = "200" ]; then
    FRONTEND_BASE="$base"
  fi

  if [ -z "$STATUS_BASE" ] && [ "$status_code" = "200" ]; then
    STATUS_BASE="$base"
  fi
done

if [ -n "$FRONTEND_BASE" ]; then
  echo "PASS: selected frontend gateway: $FRONTEND_BASE"
else
  echo "FAIL: no frontend gateway returned HTTP 200 for /, /admin, /system, and /styles.css"
  fail=1
fi

if [ -n "$STATUS_BASE" ]; then
  echo "PASS: selected system status gateway: $STATUS_BASE"
else
  echo "FAIL: no gateway returned HTTP 200 for /api/system/status"
  fail=1
fi

echo
echo "=== verify Admin/System routes with GET only ==="
if [ -n "$FRONTEND_BASE" ]; then
  for route in /admin /system; do
    code="$(code_for "${FRONTEND_BASE}${route}")"
    if [ "$code" = "200" ]; then
      echo "PASS: ${FRONTEND_BASE}${route} returned HTTP 200"
    else
      echo "FAIL: ${FRONTEND_BASE}${route} returned HTTP ${code}"
      fail=1
    fi
  done
else
  echo "SKIP: Admin/System route checks because no frontend gateway was found"
fi

echo
echo "=== verify core static assets with GET only ==="
if [ -n "$FRONTEND_BASE" ]; then
  for route in /styles.css /app.js /queued_chat_config.js /queued_chat_status.js; do
    code="$(code_for "${FRONTEND_BASE}${route}")"
    if [ "$code" = "200" ]; then
      echo "PASS: ${FRONTEND_BASE}${route} returned HTTP 200"
    else
      echo "FAIL: ${FRONTEND_BASE}${route} returned HTTP ${code}"
      fail=1
    fi
  done
else
  echo "SKIP: static asset checks because no frontend gateway was found"
fi

echo
echo "=== verify /api/system/status remains reachable and fast ==="
if [ -n "$STATUS_BASE" ]; then
  PHASE11C_STATUS_BASE="$STATUS_BASE" python3 - <<'PY'
import json
import os
import statistics
import sys
import time
import urllib.request

base = os.environ["PHASE11C_STATUS_BASE"].rstrip("/")
url = f"{base}/api/system/status"

times = []

for _ in range(5):
    start = time.perf_counter()
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            body = response.read()
            code = response.getcode()
        elapsed = time.perf_counter() - start
        times.append(elapsed)

        if code != 200:
            print(f"FAIL: {url} returned HTTP {code}")
            sys.exit(1)

        try:
            json.loads(body.decode("utf-8"))
        except Exception as exc:
            print(f"FAIL: {url} did not return valid JSON: {exc}")
            sys.exit(1)

    except Exception as exc:
        print(f"FAIL: {url} request failed: {exc}")
        sys.exit(1)

mean = statistics.mean(times)
print(f"system_status_mean_seconds={mean:.6f}")

if mean > 0.500:
    print("FAIL: /api/system/status mean latency exceeded 0.500s Phase 11C threshold")
    sys.exit(1)

print("PASS: /api/system/status returned HTTP 200 JSON and remained fast")
PY
  if [ "$?" != "0" ]; then
    fail=1
  fi
else
  echo "SKIP: system status timing because no status gateway was found"
fi

echo
echo "=== verify router rollout remains parked ==="
if systemctl show edge-queue-controller -p Environment --value 2>/dev/null | tr ' ' '\n' | grep -E 'ROUTER.*DRY.*RUN|DRY.*RUN.*ROUTER' ; then
  echo "FAIL: router dry-run environment appears present"
  fail=1
else
  echo "PASS: router dry-run environment remains absent"
fi

runtime_files="$(find . \
  -type f \( -name '*.py' -o -name '*.js' -o -name '*.html' \) \
  -not -path './.git/*' \
  -not -path './.venv/*' \
  -not -path './node_modules/*' \
  -not -path './docs/*' \
  -not -path './ops/smoke/*' \
  -not -path './ops/stage/*' \
  -print)"

echo
echo "=== check for frontend router network traffic references ==="
if printf '%s\n' "$runtime_files" | xargs grep -nE 'fetch\([^)]*/api/router|XMLHttpRequest.*api/router' 2>/dev/null; then
  echo "FAIL: frontend router network call reference found"
  fail=1
else
  echo "PASS: no frontend router network call reference found"
fi

echo
echo "=== check for obvious persistent rollout mutation routes ==="
if printf '%s\n' "$runtime_files" | xargs grep -nE '@app\.(post|put|patch|delete).*rollout|router\.(post|put|patch|delete).*rollout' 2>/dev/null; then
  echo "FAIL: possible persistent rollout mutation route found"
  fail=1
else
  echo "PASS: no obvious persistent rollout mutation route found"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11C smoke passed"
else
  echo "FAIL: Phase 11C smoke failed"
fi

[ "$fail" = "0" ]
