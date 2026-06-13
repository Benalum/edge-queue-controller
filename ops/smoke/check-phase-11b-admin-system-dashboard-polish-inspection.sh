#!/usr/bin/env bash

echo "=== Phase 11B smoke: Admin/System dashboard polish inspection ==="

fail=0

code_for() {
  local url="$1"
  curl -sS --max-time 5 -o /tmp/phase11b-curl.out -w "%{http_code}" "$url" 2>/tmp/phase11b-curl.err || true
}

echo
echo "=== verify docs exist ==="
for path in \
  docs/phase-11b-admin-system-dashboard-polish-inspection.md \
  ops/smoke/check-phase-11b-admin-system-dashboard-polish-inspection.sh
do
  if [ -f "$path" ]; then
    echo "PASS: found $path"
  else
    echo "FAIL: missing $path"
    fail=1
  fi
done

echo
echo "=== verify Phase 11A tag remains present ==="
if git rev-parse --verify controller-phase-11a-post-transition-product-quality-plan-2026-06-13 >/dev/null 2>&1; then
  echo "PASS: Phase 11A tag exists"
else
  echo "FAIL: Phase 11A tag missing"
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
  PHASE11B_STATUS_BASE="$STATUS_BASE" python3 - <<'PY'
import json
import os
import statistics
import sys
import time
import urllib.request

base = os.environ["PHASE11B_STATUS_BASE"].rstrip("/")
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
    print("FAIL: /api/system/status mean latency exceeded 0.500s Phase 11B threshold")
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
echo "=== inspect frontend app size baseline ==="
if [ -f frontend/wrapper-ui/app.js ]; then
  echo "PASS: frontend/wrapper-ui/app.js exists"
  wc -c frontend/wrapper-ui/app.js
  wc -l frontend/wrapper-ui/app.js
else
  echo "FAIL: frontend/wrapper-ui/app.js missing"
  fail=1
fi

if [ -f frontend/wrapper-ui/styles.css ]; then
  echo "PASS: frontend/wrapper-ui/styles.css exists"
  wc -c frontend/wrapper-ui/styles.css
  wc -l frontend/wrapper-ui/styles.css
else
  echo "CHECK: frontend/wrapper-ui/styles.css missing; CSS may be elsewhere"
fi

echo
echo "=== inspect Admin/System source markers ==="
if [ -f frontend/wrapper-ui/app.js ]; then
  echo "--- Admin markers ---"
  grep -nEi 'admin|renderAdmin|adminView|admin page|admin-page|Admin' frontend/wrapper-ui/app.js | sed -n '1,120p' || true

  echo
  echo "--- System markers ---"
  grep -nEi 'system|renderSystem|systemView|system page|system-page|System' frontend/wrapper-ui/app.js | sed -n '1,160p' || true

  echo
  echo "--- Status/queue/power markers ---"
  grep -nEi 'queue|worker|server|power|health|system status|api/system/status' frontend/wrapper-ui/app.js | sed -n '1,180p' || true
fi

echo
echo "=== verify router rollout remains parked by configuration/source inspection ==="
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
echo "=== generate Phase 11B evidence appendix ==="
{
  echo
  echo "## Phase 11B Smoke Evidence"
  echo
  echo "Generated: $(date -Is)"
  echo
  echo "### Git"
  echo
  echo '```text'
  git log --oneline -6
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
  echo "### Frontend asset size"
  echo
  echo '```text'
  if [ -f frontend/wrapper-ui/app.js ]; then
    wc -c frontend/wrapper-ui/app.js
    wc -l frontend/wrapper-ui/app.js
  fi
  if [ -f frontend/wrapper-ui/styles.css ]; then
    wc -c frontend/wrapper-ui/styles.css
    wc -l frontend/wrapper-ui/styles.css
  fi
  echo '```'
  echo
  echo "### Recommended Phase 11C target"
  echo
  echo "Phase 11C should make a small presentation-only Admin/System dashboard polish patch, then run GET-only route and asset smokes before commit."
} >> docs/phase-11b-admin-system-dashboard-polish-inspection.md

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11B smoke passed"
else
  echo "FAIL: Phase 11B smoke failed"
fi

[ "$fail" = "0" ]
