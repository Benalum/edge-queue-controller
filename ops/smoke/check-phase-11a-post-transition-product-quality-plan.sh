#!/usr/bin/env bash

echo "=== Phase 11A smoke: post-transition product quality checkpoint ==="

fail=0

code_for() {
  local url="$1"
  curl -sS --max-time 5 -o /tmp/phase11a-curl.out -w "%{http_code}" "$url" 2>/tmp/phase11a-curl.err || true
}

echo
echo "=== verify docs exist ==="
for path in \
  docs/phase-11a-post-transition-product-quality-plan.md \
  ops/smoke/check-phase-11a-post-transition-product-quality-plan.sh
do
  if [ -f "$path" ]; then
    echo "PASS: found $path"
  else
    echo "FAIL: missing $path"
    fail=1
  fi
done

echo
echo "=== verify Stage 10O tag remains present ==="
if git rev-parse --verify controller-stage-10o-transition-complete-operational-baseline-2026-06-12 >/dev/null 2>&1; then
  echo "PASS: Stage 10O tag exists"
else
  echo "FAIL: Stage 10O tag missing"
  fail=1
fi

echo
echo "=== verify controller health on known controller port ==="
health_code="$(code_for http://127.0.0.1:7070/health)"
if [ "$health_code" = "200" ]; then
  echo "PASS: controller /health returned HTTP 200 on 127.0.0.1:7070"
else
  echo "CHECK: controller /health returned HTTP $health_code on 127.0.0.1:7070"
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
  styles_code="$(code_for "$base/styles.css")"
  status_code="$(code_for "$base/api/system/status")"

  echo "CHECK: $base root=$root_code styles=$styles_code system_status=$status_code"

  if [ -z "$FRONTEND_BASE" ] && [ "$root_code" = "200" ] && [ "$styles_code" = "200" ]; then
    FRONTEND_BASE="$base"
  fi

  if [ -z "$STATUS_BASE" ] && [ "$status_code" = "200" ]; then
    STATUS_BASE="$base"
  fi
done

if [ -n "$FRONTEND_BASE" ]; then
  echo "PASS: selected frontend gateway: $FRONTEND_BASE"
else
  echo "FAIL: no frontend gateway returned HTTP 200 for / and /styles.css"
  fail=1
fi

if [ -n "$STATUS_BASE" ]; then
  echo "PASS: selected system status gateway: $STATUS_BASE"
else
  echo "FAIL: no gateway returned HTTP 200 for /api/system/status"
  fail=1
fi

echo
echo "=== verify important frontend routes with GET only ==="
if [ -n "$FRONTEND_BASE" ]; then
  for route in / /study /companion /calendar /profile /admin /system; do
    code="$(code_for "${FRONTEND_BASE}${route}")"
    if [ "$code" = "200" ]; then
      echo "PASS: ${FRONTEND_BASE}${route} returned HTTP 200"
    else
      echo "FAIL: ${FRONTEND_BASE}${route} returned HTTP ${code}"
      fail=1
    fi
  done
else
  echo "SKIP: frontend route checks because no frontend gateway was found"
fi

echo
echo "=== verify static assets with GET only ==="
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
echo "=== verify system status remains reachable and reasonably fast ==="
if [ -n "$STATUS_BASE" ]; then
  PHASE11A_STATUS_BASE="$STATUS_BASE" python3 - <<'PY'
import json
import os
import statistics
import sys
import time
import urllib.request

base = os.environ["PHASE11A_STATUS_BASE"].rstrip("/")
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
    print("FAIL: /api/system/status mean latency exceeded 0.500s Phase 11A checkpoint threshold")
    sys.exit(1)

print("PASS: /api/system/status returned HTTP 200 JSON and remained reasonably fast")
PY
  if [ "$?" != "0" ]; then
    fail=1
  fi
else
  echo "SKIP: system status timing because no status gateway was found"
fi

echo
echo "=== inspect frontend asset size baseline ==="
if [ -f frontend/wrapper-ui/app.js ]; then
  wc -c frontend/wrapper-ui/app.js
elif [ -f public/app.js ]; then
  wc -c public/app.js
elif [ -f app.js ]; then
  wc -c app.js
else
  echo "CHECK: app.js source file not found in expected locations"
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
echo "=== check for router dry-run source references without failing Phase 11A ==="
if printf '%s\n' "$runtime_files" | xargs grep -nE 'router/dry-run|/api/router/dry-run' 2>/dev/null; then
  echo "CHECK: router dry-run source references exist; Phase 11A does not mutate or POST to them"
else
  echo "PASS: no router dry-run source references found"
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
echo "=== verify queue is clean when status JSON exposes queue counts ==="
if [ -n "$STATUS_BASE" ]; then
  PHASE11A_STATUS_BASE="$STATUS_BASE" python3 - <<'PY'
import json
import os
import sys
import urllib.request

base = os.environ["PHASE11A_STATUS_BASE"].rstrip("/")
url = f"{base}/api/system/status"

try:
    with urllib.request.urlopen(url, timeout=5) as response:
        data = json.loads(response.read().decode("utf-8"))
except Exception as exc:
    print(f"CHECK: could not parse queue counts from {url}: {exc}")
    sys.exit(0)

interesting_keys = {"queued", "running", "failed"}
found = []

def walk(value, path="root"):
    if isinstance(value, dict):
        for key, child in value.items():
            child_path = f"{path}.{key}"
            if str(key).lower() in interesting_keys and isinstance(child, int):
                found.append((child_path, child))
            walk(child, child_path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            walk(child, f"{path}[{index}]")

walk(data)

bad = [(path, value) for path, value in found if value != 0]

if bad:
    print("FAIL: nonzero queue-like counts found:")
    for path, value in bad:
        print(f"  {path}={value}")
    sys.exit(1)

if found:
    print("PASS: queue-like counts found and all are zero")
else:
    print("CHECK: no queue-like count fields found in status JSON")
PY
  if [ "$?" != "0" ]; then
    fail=1
  fi
else
  echo "SKIP: queue clean check because no status gateway was found"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11A smoke passed"
else
  echo "FAIL: Phase 11A smoke failed"
fi

[ "$fail" = "0" ]
