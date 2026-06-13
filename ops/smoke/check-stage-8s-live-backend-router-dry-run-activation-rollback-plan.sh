#!/usr/bin/env bash
set -u

fail=0

pass() {
  echo "PASS: $1"
}

check_fail() {
  echo "CHECK: $1"
  fail=1
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
if [ -z "${ROOT:-}" ] || [ ! -d "$ROOT" ]; then
  check_fail "could not resolve repo root"
  ROOT="."
fi

cd "$ROOT" || check_fail "could not cd into repo root"

REPORT="docs/generated/stage-8s-live-backend-router-dry-run-activation-rollback-plan.md"
SMOKE="ops/smoke/check-stage-8s-live-backend-router-dry-run-activation-rollback-plan.sh"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

echo "=== Stage 8S smoke: live backend dry-run activation/rollback plan only ==="

echo
echo "=== report/script checks ==="
if [ -f "$REPORT" ]; then
  pass "Stage 8S report exists"
else
  check_fail "Stage 8S report missing: $REPORT"
fi

if [ -x "$SMOKE" ]; then
  pass "Stage 8S smoke script is executable"
else
  check_fail "Stage 8S smoke script missing or not executable: $SMOKE"
fi

for needle in \
  "Stage 8S is a planning and safety verification stage only." \
  "No live backend router dry-run was enabled." \
  "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1" \
  "Rollback plan for a future activation stage" \
  "Browser/frontend code still has no /api/router/dry-run endpoint string." \
  "ROUTER_SHADOW_READ_ENABLED = false" \
  "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false" \
  "GET /api/router/dry-run may return HTTP 405 because the route is POST-only."
do
  if grep -Fq "$needle" "$REPORT" 2>/dev/null; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

echo
echo "=== frontend/browser safety checks ==="
if [ -f "$APP_JS" ]; then
  pass "app.js exists"
else
  check_fail "missing $APP_JS"
fi

if [ -f "$STUB" ]; then
  pass "router shadow-read stub exists"
else
  check_fail "missing $STUB"
fi

if grep -q "/api/router/dry-run" "$APP_JS" "$STUB" 2>/dev/null; then
  check_fail "frontend app/stub contains /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" "$STUB" 2>/dev/null | sed -n '1,80p'
else
  pass "frontend app/stub contains no /api/router/dry-run string"
fi

if grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" 2>/dev/null; then
  pass "ROUTER_SHADOW_READ_ENABLED remains false"
else
  check_fail "ROUTER_SHADOW_READ_ENABLED=false marker not found in $STUB"
fi

if grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" 2>/dev/null; then
  pass "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false"
else
  check_fail "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker not found in $STUB"
fi

echo
echo "=== live controller health and dry-run disabled checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage8s-health.out -w "%{http_code}" http://127.0.0.1:7070/health 2>/tmp/stage8s-health.err || printf 'curl_failed')"
echo "health_code=$health_code"
if [ "$health_code" = "200" ]; then
  pass "live controller /health returned HTTP 200"
else
  check_fail "live controller /health did not return HTTP 200"
  sed -n '1,80p' /tmp/stage8s-health.err 2>/dev/null || true
  sed -n '1,80p' /tmp/stage8s-health.out 2>/dev/null || true
fi

dry_get_code="$(curl -sS --max-time 5 -o /tmp/stage8s-router-get.out -w "%{http_code}" http://127.0.0.1:7070/api/router/dry-run 2>/tmp/stage8s-router-get.err || printf 'curl_failed')"
echo "dry_get_code=$dry_get_code"
if [ "$dry_get_code" = "404" ] || [ "$dry_get_code" = "405" ]; then
  pass "live GET /api/router/dry-run is not enabled for GET; HTTP $dry_get_code"
else
  check_fail "live GET /api/router/dry-run returned unexpected HTTP $dry_get_code"
  sed -n '1,120p' /tmp/stage8s-router-get.out 2>/dev/null || true
fi

dry_post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage8s safety smoke","source":"stage8s","surface":"backend-only"}' \
  -o /tmp/stage8s-router-post.out \
  -w "%{http_code}" \
  http://127.0.0.1:7070/api/router/dry-run 2>/tmp/stage8s-router-post.err || printf 'curl_failed')"
echo "dry_post_code=$dry_post_code"
if [ "$dry_post_code" = "404" ]; then
  pass "live POST /api/router/dry-run remains HTTP 404 while disabled"
else
  check_fail "live POST /api/router/dry-run did not remain HTTP 404"
  sed -n '1,120p' /tmp/stage8s-router-post.out 2>/dev/null || true
fi

echo
echo "=== live controller environment safety check ==="
controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -E 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED|ROUTER|INTENT|DRY_RUN|SHADOW' || true

if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  check_fail "live controller has EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 enabled"
else
  pass "live controller does not have EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 enabled"
fi

echo
echo "=== queue clean check ==="
queue_url="http://127.0.0.1:8787/api/system/status"
queue_code="$(curl -sS --max-time 5 -o /tmp/stage8s-system-status.json -w "%{http_code}" "$queue_url" 2>/tmp/stage8s-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage8s-system-status.json <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

matches = []

def walk(value, label="$"):
    if isinstance(value, dict):
        if all(k in value for k in ("queued", "running", "failed")):
            matches.append((label, value.get("queued"), value.get("running"), value.get("failed")))
        for k, v in value.items():
            walk(v, f"{label}.{k}")
    elif isinstance(value, list):
        for i, v in enumerate(value):
            walk(v, f"{label}[{i}]")

walk(data)

if not matches:
    print("MISSING_QUEUE_TRIPLE")
    sys.exit(3)

for label, queued, running, failed in matches:
    print(f"{label}: queued={queued} running={running} failed={failed}")

clean = any(str(q) == "0" and str(r) == "0" and str(f) == "0" for _, q, r, f in matches)
sys.exit(0 if clean else 2)
PY
  queue_check=$?
  if [ "$queue_check" = "0" ]; then
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    check_fail "queue clean state was not confirmed"
    sed -n '1,160p' /tmp/stage8s-system-status.json 2>/dev/null || true
  fi
else
  check_fail "could not read queue/system status from $queue_url"
  sed -n '1,80p' /tmp/stage8s-system-status.err 2>/dev/null || true
fi

echo
echo "=== timer safety checks ==="
power_timer="$(systemctl is-active edge-queue-power-auto-tick.timer 2>/dev/null || true)"
remediation_timer="$(systemctl is-active edge-queue-remediation-tick.timer 2>/dev/null || true)"
legacy_active="$(systemctl is-active edge-queue-scheduler-tick.timer 2>/dev/null || true)"
legacy_enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer 2>/dev/null || true)"

echo "edge-queue-power-auto-tick.timer active=$power_timer"
echo "edge-queue-remediation-tick.timer active=$remediation_timer"
echo "edge-queue-scheduler-tick.timer active=$legacy_active enabled=$legacy_enabled"

if [ "$power_timer" = "active" ]; then
  pass "modern power auto timer is active"
else
  check_fail "modern power auto timer is not active"
fi

if [ "$remediation_timer" = "active" ]; then
  pass "modern remediation timer is active"
else
  check_fail "modern remediation timer is not active"
fi

if [ "$legacy_active" = "inactive" ] || [ "$legacy_active" = "unknown" ]; then
  pass "legacy scheduler timer is not active"
else
  check_fail "legacy scheduler timer is unexpectedly active/state=$legacy_active"
fi

if [ "$legacy_enabled" = "disabled" ] || [ "$legacy_enabled" = "masked" ]; then
  pass "legacy scheduler timer is disabled/masked"
else
  check_fail "legacy scheduler timer is not disabled/masked; enabled_state=$legacy_enabled"
fi

echo
echo "=== Stage 8S smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8S activation/rollback plan verified without enablement"
else
  echo "FAIL: Stage 8S activation/rollback plan smoke found issues"
fi

exit "$fail"
