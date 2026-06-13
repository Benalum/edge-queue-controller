#!/usr/bin/env bash

echo "=== Phase 11D smoke: System page double-render inspection ==="

fail=0

code_for() {
  local url="$1"
  curl -sS --max-time 5 -o /tmp/phase11d-curl.out -w "%{http_code}" "$url" 2>/tmp/phase11d-curl.err || true
}

echo
echo "=== verify stage files exist ==="
for path in \
  docs/phase-11d-system-page-double-render-inspection.md \
  ops/smoke/check-phase-11d-system-page-double-render-inspection.sh \
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
echo "=== verify Phase 11C tag remains present ==="
if git rev-parse --verify controller-phase-11c-admin-system-css-polish-2026-06-13 >/dev/null 2>&1; then
  echo "PASS: Phase 11C tag exists"
else
  echo "FAIL: Phase 11C tag missing"
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
echo "=== verify /api/system/status remains reachable and fast ==="
if [ -n "$STATUS_BASE" ]; then
  PHASE11D_STATUS_BASE="$STATUS_BASE" python3 - <<'PY'
import json
import os
import statistics
import sys
import time
import urllib.request

base = os.environ["PHASE11D_STATUS_BASE"].rstrip("/")
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

        json.loads(body.decode("utf-8"))

    except Exception as exc:
        print(f"FAIL: {url} request failed: {exc}")
        sys.exit(1)

mean = statistics.mean(times)
print(f"system_status_mean_seconds={mean:.6f}")

if mean > 0.500:
    print("FAIL: /api/system/status mean latency exceeded 0.500s Phase 11D threshold")
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
echo "=== inspect System render source markers ==="
{
  echo
  echo "## Phase 11D Smoke Evidence"
  echo
  echo "Generated: $(date -Is)"
  echo
  echo "### Git"
  echo
  echo '```text'
  git log --oneline -8
  git tag --points-at HEAD
  echo '```'
  echo
  echo "### Selected gateways"
  echo
  echo '```text'
  echo "FRONTEND_BASE=${FRONTEND_BASE:-none}"
  echo "STATUS_BASE=${STATUS_BASE:-none}"
  echo '```'
  echo
  echo "### System render markers"
  echo
  echo '```text'
  grep -nEi 'function renderSystemPage|renderSystemPage|loadSystemStatus|systemStatus|cleanRemoveAdminInfrastructureFromSystemPage|Backend API|Study API|Companion API|Profile API|Calendar Integrations|Images API|Power Automation|CT101|Frontend Wrapper' frontend/wrapper-ui/app.js | sed -n '1,240p' || true
  echo '```'
  echo
  echo "### Recommendation"
  echo
  echo "Phase 11E should remove the visible static-to-live System page swap by giving /system one stable render path: loading state first, then live status once loaded."
} >> docs/phase-11d-system-page-double-render-inspection.md

echo "--- System render markers, first 240 matches ---"
grep -nEi 'function renderSystemPage|renderSystemPage|loadSystemStatus|systemStatus|cleanRemoveAdminInfrastructureFromSystemPage|Backend API|Study API|Companion API|Profile API|Calendar Integrations|Images API|Power Automation|CT101|Frontend Wrapper' frontend/wrapper-ui/app.js | sed -n '1,240p' || true

echo
echo "=== verify this stage is read-only for runtime source ==="
if git diff --name-only | grep -E '(^edge_controller\.py$|^frontend/wrapper-ui/app\.js$|^frontend/wrapper-ui/styles\.css$|\.py$|\.js$|\.html$)' ; then
  echo "FAIL: runtime source changed during Phase 11D inspection"
  fail=1
else
  echo "PASS: no runtime source changed"
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
  echo "PASS: Phase 11D smoke passed"
else
  echo "FAIL: Phase 11D smoke failed"
fi

[ "$fail" = "0" ]
