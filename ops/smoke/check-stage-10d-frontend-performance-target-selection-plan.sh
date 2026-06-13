#!/usr/bin/env bash
set -u

fail=0

pass() { echo "PASS: $1"; }
check_fail() { echo "CHECK: $1"; fail=1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
cd "$ROOT" || {
  echo "CHECK: could not cd into repo root"
  exit 1
}

REPORT="docs/generated/stage-10d-frontend-performance-target-selection-plan.md"
SMOKE="ops/smoke/check-stage-10d-frontend-performance-target-selection-plan.sh"
STAGE10C_EVIDENCE="docs/generated/stage-10c-frontend-load-route-boundary-baseline-inspection-evidence.json"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"
STATUS_URL="$FRONTEND_BASE/api/system/status"

echo "=== Stage 10D smoke: frontend performance target selection plan ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10D report exists" || check_fail "Stage 10D report missing"
[ -x "$SMOKE" ] && pass "Stage 10D smoke script is executable" || check_fail "Stage 10D smoke script missing or not executable"

for needle in \
  "Stage 10D selects the first frontend performance optimization target from the Stage 10C baseline." \
  "Stage 10D is plan-only." \
  "Stage 10D does not modify frontend/wrapper-ui/app.js." \
  "Stage 10D does not modify edge_controller.py." \
  "Stage 10D does not restart live services." \
  "Stage 10D does not add a mutation endpoint." \
  "Stage 10D does not enable browser router traffic." \
  "Stage 10D does not enable backend router dry-run." \
  "Stage 10D does not send frontend router POST traffic." \
  "The first optimization target should be startup/status load pressure." \
  "/api/system/status is the slowest measured route" \
  "Stage 10E should inspect frontend startup fetch behavior" \
  "Keep logged-in/logged-out route boundaries unchanged." \
  "Keep router rollout parked."
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10C evidence validation ==="
[ -f "$STAGE10C_EVIDENCE" ] && pass "Stage 10C evidence exists" || check_fail "Stage 10C evidence missing"

python3 - "$STAGE10C_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))

checks = {
    "final_result": {"pass"},
    "health_code": {"200"},
    "status_code": {"200"},
    "post_code": {"404"},
    "env_absent": {"true", "True"},
    "queue_clean": {"true", "True"},
}

bad = []
for key, allowed in checks.items():
    actual = str(data.get(key))
    print(f"{key}={actual}")
    if actual not in allowed:
        bad.append((key, sorted(allowed), actual))

app_js_bytes = data.get("app_js_bytes")
print(f"app_js_bytes={app_js_bytes}")
if str(app_js_bytes) != "323331":
    bad.append(("app_js_bytes", "323331", app_js_bytes))

routes = data.get("route_metrics", [])
route_by_name = {r.get("name"): r for r in routes}

for name in ["root", "chat", "study", "companion", "profile", "admin", "system", "styles_css", "app_js", "router_shadow_read_stub", "api_system_status"]:
    route = route_by_name.get(name)
    if not route:
        bad.append((name, "route present", "missing"))
        continue
    print(f"{name}: code={route.get('code')} time={route.get('time_total_seconds')} size={route.get('size_download_bytes')}")
    if str(route.get("code")) != "200":
        bad.append((f"{name}.code", "200", route.get("code")))

api_status = route_by_name.get("api_system_status", {})
try:
    api_time = float(api_status.get("time_total_seconds", 0))
except Exception:
    api_time = 0
if api_time <= 1.0:
    bad.append(("api_system_status.time_total_seconds", ">1.0 baseline expected", api_status.get("time_total_seconds")))

if bad:
    print("CHECK: Stage 10C evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10C baseline evidence supports startup/status load pressure target")
PY
[ "$?" = "0" ] && pass "Stage 10C evidence values confirmed" || check_fail "Stage 10C evidence validation failed"

echo
echo "=== source safety checks ==="
python3 -m py_compile "$CONTROLLER" \
  && pass "edge_controller.py compiles" \
  || check_fail "edge_controller.py failed py_compile"

if grep -RInE '@app\.(post|put|patch|delete)\("/api/router/persistent-rollout/status"|@app\.(post|put|patch|delete)\(PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH|/api/router/persistent-rollout/request' "$CONTROLLER" 2>/dev/null; then
  check_fail "persistent rollout mutation route unexpectedly exists"
else
  pass "persistent rollout mutation route does not exist"
fi

if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js directly contains /api/router/dry-run"
else
  pass "app.js contains no /api/router/dry-run"
fi

grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$STUB" \
  && pass "stub contains backend dry-run endpoint boundary" \
  || check_fail "stub missing backend dry-run endpoint boundary"

grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" \
  && pass "ROUTER_SHADOW_READ_ENABLED remains false" \
  || check_fail "ROUTER_SHADOW_READ_ENABLED=false marker missing"

grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" \
  && pass "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
  || check_fail "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"

echo
echo "=== live router parked posture checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage10d-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10d-health.err || printf 'curl_failed')"
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

rollout_code="$(curl -sS --max-time 5 -o /tmp/stage10d-rollout-status.json -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10d-rollout-status.err || printf 'curl_failed')"
echo "rollout_status_code=$rollout_code"
[ "$rollout_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10d target selection","source":"stage10d","surface":"backend-only"}' \
  -o /tmp/stage10d-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10d-router-post.err || printf 'curl_failed')"
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  check_fail "backend dry-run env is enabled"
else
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage10d-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10d-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10d-system-status.json <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
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
for label, q, r, f in matches:
    print(f"{label}: queued={q} running={r} failed={f}")

sys.exit(0 if any(str(q) == "0" and str(r) == "0" and str(f) == "0" for _, q, r, f in matches) else 2)
PY
  [ "$?" = "0" ] && pass "queue clean state confirmed with queued=0 running=0 failed=0" || check_fail "queue clean state was not confirmed"
else
  check_fail "could not read queue/system status"
fi

echo
echo "=== timer and temporary port checks ==="
power_timer="$(systemctl is-active edge-queue-power-auto-tick.timer 2>/dev/null || true)"
remediation_timer="$(systemctl is-active edge-queue-remediation-tick.timer 2>/dev/null || true)"
legacy_active="$(systemctl is-active edge-queue-scheduler-tick.timer 2>/dev/null || true)"
legacy_enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer 2>/dev/null || true)"

echo "edge-queue-power-auto-tick.timer active=$power_timer"
echo "edge-queue-remediation-tick.timer active=$remediation_timer"
echo "edge-queue-scheduler-tick.timer active=$legacy_active enabled=$legacy_enabled"

[ "$power_timer" = "active" ] && pass "modern power auto timer is active" || check_fail "modern power auto timer is not active"
[ "$remediation_timer" = "active" ] && pass "modern remediation timer is active" || check_fail "modern remediation timer is not active"

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

if ss -ltnp 2>/dev/null | grep -q ':7076'; then
  check_fail "port 7076 appears to be listening"
else
  pass "port 7076 is not listening"
fi

echo
echo "=== Stage 10D smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10D frontend performance target selection verified"
else
  echo "FAIL: Stage 10D frontend performance target selection found issues"
fi

exit "$fail"
