#!/usr/bin/env bash

echo "=== Phase 11G smoke: System render readiness variable repair ==="

fail=0

code_for() {
  local url="$1"
  curl -sS --max-time 5 -o /tmp/phase11g-curl.out -w "%{http_code}" "$url" 2>/tmp/phase11g-curl.err || true
}

echo
echo "=== verify stage files exist ==="
for path in \
  docs/phase-11g-system-render-readiness-variable-repair.md \
  ops/smoke/check-phase-11g-system-render-readiness-variable-repair.sh \
  frontend/wrapper-ui/app.js
do
  if [ -f "$path" ]; then
    echo "PASS: found $path"
  else
    echo "FAIL: missing $path"
    fail=1
  fi
done

echo
echo "=== verify Phase 11F tag remains present ==="
if git rev-parse --verify controller-phase-11f-system-loading-completion-repair-2026-06-13 >/dev/null 2>&1; then
  echo "PASS: Phase 11F tag exists"
else
  echo "FAIL: Phase 11F tag missing"
  fail=1
fi

echo
echo "=== verify Phase 11G source repair ==="
if grep -q 'PHASE_11G_SYSTEM_READINESS_VARIABLE_REPAIR' frontend/wrapper-ui/app.js; then
  echo "PASS: Phase 11G marker exists"
else
  echo "FAIL: Phase 11G marker missing"
  fail=1
fi

if grep -q 'const phase11eStatus = lastStatus || {}' frontend/wrapper-ui/app.js; then
  echo "PASS: renderSystemPage now reads lastStatus"
else
  echo "FAIL: renderSystemPage does not read lastStatus"
  fail=1
fi

if grep -q 'lastStatus &&' frontend/wrapper-ui/app.js; then
  echo "PASS: readiness check uses lastStatus"
else
  echo "FAIL: readiness check does not use lastStatus"
  fail=1
fi

if grep -q 'if (!lastStatus) return;' frontend/wrapper-ui/app.js; then
  echo "PASS: Phase 11F refresh helper now checks lastStatus"
else
  echo "FAIL: Phase 11F refresh helper does not check lastStatus"
  fail=1
fi

if grep -q 'const phase11eStatus = adminStatus || {}' frontend/wrapper-ui/app.js; then
  echo "FAIL: old adminStatus readiness source remains"
  fail=1
else
  echo "PASS: old adminStatus readiness source removed"
fi

echo
echo "=== verify only expected file types changed ==="
git status --short

unexpected_runtime="$(git status --short | awk '{print $2}' | grep -E '(^edge_controller\.py$|\.py$|\.html$|frontend/wrapper-ui/styles\.css$)' || true)"
if [ -n "$unexpected_runtime" ]; then
  echo "FAIL: unexpected backend/CSS/HTML runtime file changed:"
  printf '%s\n' "$unexpected_runtime"
  fail=1
else
  echo "PASS: no backend, CSS, or HTML runtime files changed"
fi

unexpected_files="$(git status --short | awk '{print $2}' | grep -vE '^(docs/phase-11g-system-render-readiness-variable-repair\.md|ops/smoke/check-phase-11g-system-render-readiness-variable-repair\.sh|frontend/wrapper-ui/app\.js)$' || true)"
if [ -n "$unexpected_files" ]; then
  echo "FAIL: unexpected changed files:"
  printf '%s\n' "$unexpected_files"
  fail=1
else
  echo "PASS: only expected Phase 11G files changed"
fi

echo
echo "=== run JavaScript syntax check if node is available ==="
if command -v node >/dev/null 2>&1; then
  node --check frontend/wrapper-ui/app.js
  if [ "$?" = "0" ]; then
    echo "PASS: node syntax check passed"
  else
    echo "FAIL: node syntax check failed"
    fail=1
  fi
else
  echo "CHECK: node not available; skipping node syntax check"
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
  system_code="$(code_for "$base/system")"
  styles_code="$(code_for "$base/styles.css")"
  app_code="$(code_for "$base/app.js")"
  status_code="$(code_for "$base/api/system/status")"

  echo "CHECK: $base system=$system_code styles=$styles_code app=$app_code system_status=$status_code"

  if [ -z "$FRONTEND_BASE" ] && [ "$system_code" = "200" ] && [ "$styles_code" = "200" ] && [ "$app_code" = "200" ]; then
    FRONTEND_BASE="$base"
  fi

  if [ -z "$STATUS_BASE" ] && [ "$status_code" = "200" ]; then
    STATUS_BASE="$base"
  fi
done

if [ -n "$FRONTEND_BASE" ]; then
  echo "PASS: selected frontend gateway: $FRONTEND_BASE"
else
  echo "FAIL: no frontend gateway returned HTTP 200 for /system, /styles.css, and /app.js"
  fail=1
fi

if [ -n "$STATUS_BASE" ]; then
  echo "PASS: selected system status gateway: $STATUS_BASE"
else
  echo "FAIL: no gateway returned HTTP 200 for /api/system/status"
  fail=1
fi

echo
echo "=== verify served app.js marker when possible ==="
if [ -n "$FRONTEND_BASE" ]; then
  curl -sS --max-time 5 "${FRONTEND_BASE}/app.js" -o /tmp/phase11g-served-app.js || true

  if grep -q 'PHASE_11G_SYSTEM_READINESS_VARIABLE_REPAIR' /tmp/phase11g-served-app.js 2>/dev/null; then
    echo "PASS: served app.js contains Phase 11G marker"
  else
    echo "CHECK: served app.js does not contain Phase 11G marker yet; local file may be served after commit/cache refresh"
  fi
else
  echo "SKIP: served app.js marker check because no frontend gateway was found"
fi

echo
echo "=== verify /system and core static assets with GET only ==="
if [ -n "$FRONTEND_BASE" ]; then
  for route in /system /styles.css /app.js /queued_chat_config.js /queued_chat_status.js; do
    code="$(code_for "${FRONTEND_BASE}${route}")"
    if [ "$code" = "200" ]; then
      echo "PASS: ${FRONTEND_BASE}${route} returned HTTP 200"
    else
      echo "FAIL: ${FRONTEND_BASE}${route} returned HTTP ${code}"
      fail=1
    fi
  done
else
  echo "SKIP: route/static checks because no frontend gateway was found"
fi

echo
echo "=== verify /api/system/status remains reachable and fast ==="
if [ -n "$STATUS_BASE" ]; then
  PHASE11G_STATUS_BASE="$STATUS_BASE" python3 - <<'PY'
import json
import os
import statistics
import sys
import time
import urllib.request

base = os.environ["PHASE11G_STATUS_BASE"].rstrip("/")
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

        data = json.loads(body.decode("utf-8"))

        if not isinstance(data, dict):
            print("FAIL: status payload is not an object")
            sys.exit(1)

        if "services" not in data and "nodes" not in data and "normalized" not in data:
            print("FAIL: status payload lacks services/nodes/normalized")
            sys.exit(1)

    except Exception as exc:
        print(f"FAIL: {url} request failed: {exc}")
        sys.exit(1)

mean = statistics.mean(times)
print(f"system_status_mean_seconds={mean:.6f}")

if mean > 0.500:
    print("FAIL: /api/system/status mean latency exceeded 0.500s Phase 11G threshold")
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
  echo "PASS: Phase 11G smoke passed"
else
  echo "FAIL: Phase 11G smoke failed"
fi

[ "$fail" = "0" ]
