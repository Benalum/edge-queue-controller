#!/usr/bin/env bash
set -u

echo "=== Stage 8P smoke: backend/live router dry-run flag boundary plan ==="

fail=0

DOC="docs/stage-8p-backend-live-router-dry-run-flag-boundary-plan.md"
REPORT="docs/generated/stage-8p-backend-live-router-dry-run-flag-boundary-plan.json"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
CONTROLLER="edge_controller.py"

for f in "$DOC" "$APP_JS" "$STUB" "$INDEX_HTML" "$CONTROLLER"; do
  if [ -f "$f" ]; then
    echo "OK: found $f"
  else
    echo "FAIL: missing $f"
    fail=1
  fi
done

echo
echo "=== doc markers ==="
for marker in \
  "Backend Live Router Dry-Run Flag Boundary Plan" \
  "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED" \
  "Do not enable live router dry-run traffic yet" \
  "Stage 8Q"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== verify Stage 8O is present ==="
if git rev-parse -q --verify refs/tags/controller-stage-8o-frontend-router-shadow-read-feature-flag-boundary-2026-06-12 >/dev/null; then
  echo "OK: Stage 8O tag exists"
else
  echo "FAIL: Stage 8O tag missing"
  fail=1
fi

echo
echo "=== frontend remains unable to call router dry-run ==="
if grep -q "/api/router/dry-run" "$APP_JS" "$STUB"; then
  echo "FAIL: frontend files must not contain /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" "$STUB" || true
  fail=1
else
  echo "OK: frontend files contain no /api/router/dry-run"
fi

if grep -q "const ROUTER_SHADOW_READ_ENABLED = false" "$STUB"; then
  echo "OK: frontend router shadow read enabled flag remains false"
else
  echo "FAIL: frontend enabled flag missing/changed"
  fail=1
fi

if grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false" "$STUB"; then
  echo "OK: frontend feature flag default remains false"
else
  echo "FAIL: frontend feature flag default missing/changed"
  fail=1
fi

if grep -q "function isRouterShadowReadFeatureEnabled" "$STUB"; then
  echo "OK: frontend feature flag function exists"
else
  echo "FAIL: frontend feature flag function missing"
  fail=1
fi

stub_line="$(grep -n "router_shadow_read_stub.js" "$INDEX_HTML" | head -n 1 | cut -d: -f1 || true)"
app_line="$(grep -n "<script.*app.js" "$INDEX_HTML" | head -n 1 | cut -d: -f1 || true)"
echo "stub_line=$stub_line"
echo "app_line=$app_line"

if [ -z "$stub_line" ] || [ -z "$app_line" ] || [ "$stub_line" -ge "$app_line" ]; then
  echo "FAIL: stub should load before app.js"
  fail=1
else
  echo "OK: stub loads before app.js"
fi

echo
echo "=== backend source contains live dry-run boundary ==="
if grep -RIn "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED" edge_controller.py edge_intent_router.py 2>/dev/null | sed -n '1,20p'; then
  echo "OK: backend dry-run env boundary found"
else
  echo "FAIL: backend dry-run env boundary not found"
  fail=1
fi

if grep -RIn "Universal Intent Router dry-run endpoint is disabled" edge_controller.py edge_intent_router.py 2>/dev/null | sed -n '1,20p'; then
  echo "OK: disabled detail found in backend source"
else
  echo "FAIL: disabled detail not found in backend source"
  fail=1
fi

echo
echo "=== live router env flag must remain off ==="
if systemctl show edge-queue-controller -p Environment --value | tr ' ' '\n' | grep -q '^EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1$'; then
  echo "FAIL: live router dry-run env is enabled"
  fail=1
else
  echo "OK: live router dry-run env is not enabled"
fi

echo
echo "=== live router endpoints must remain disabled/not found ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8p-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8p-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== current legacy tick remains fast compatibility shim ==="
tick_code="$(curl -sS --max-time 10 -o /tmp/stage8p-tick.out -w "%{http_code}" -X POST http://127.0.0.1:7070/tick || true)"
echo "tick_code=$tick_code"
sed -n '1,16p' /tmp/stage8p-tick.out || true

if [ "$tick_code" != "200" ]; then
  echo "FAIL: /tick shim should return 200"
  fail=1
else
  if grep -q "legacy_tick_compatibility_shim" /tmp/stage8p-tick.out; then
    echo "OK: /tick remains legacy compatibility shim"
  else
    echo "FAIL: /tick did not report compatibility shim"
    fail=1
  fi
fi

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8p-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker")),
  power: (.services[]? | select(.id=="power-automation"))
}' /tmp/stage8p-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8p-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8p-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8p-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8p-system-status.json)"

echo "overall_state=$overall_state"
echo "queue_failed=$queue_failed"
echo "queue_queued=$queue_queued"
echo "queue_running=$queue_running"

if [ "$overall_state" != "online" ]; then
  echo "FAIL: platform should remain online"
  fail=1
fi

if [ "$queue_failed" != "0" ] || [ "$queue_queued" != "0" ] || [ "$queue_running" != "0" ]; then
  echo "FAIL: queue should remain clean"
  fail=1
fi

echo
echo "=== timer safety unchanged ==="
legacy_enabled="$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
legacy_active="$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
power_auto_active="$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
remediation_active="$(systemctl is-active edge-queue-remediation-tick.timer || true)"

echo "legacy_enabled=$legacy_enabled"
echo "legacy_active=$legacy_active"
echo "power_auto_active=$power_auto_active"
echo "remediation_active=$remediation_active"

if [ "$legacy_enabled" != "disabled" ] || [ "$legacy_active" != "inactive" ]; then
  echo "FAIL: legacy scheduler timer should remain disabled/inactive"
  fail=1
fi

if [ "$power_auto_active" != "active" ] || [ "$remediation_active" != "active" ]; then
  echo "FAIL: modern timers should remain active"
  fail=1
fi

echo
echo "=== write generated Stage 8P report ==="
python3 - <<'PY'
from pathlib import Path
import json
import subprocess

def cmd(args):
    return subprocess.run(args, capture_output=True, text=True).stdout

def read(path):
    p = Path(path)
    return p.read_text(errors="ignore") if p.exists() else ""

app = read("frontend/wrapper-ui/app.js")
stub = read("frontend/wrapper-ui/router_shadow_read_stub.js")
controller = read("edge_controller.py")

env_text = cmd(["systemctl", "show", "edge-queue-controller", "-p", "Environment", "--value"])

report = {
    "stage": "8P",
    "stage_type": "backend_live_router_dry_run_flag_boundary_plan",
    "decision": "do_not_enable_live_router_dry_run_traffic_yet",
    "next_recommended_stage": "8Q_temporary_controller_validation_only",
    "frontend": {
        "contains_router_endpoint": "/api/router/dry-run" in (app + stub),
        "stub_enabled_flag_false": "const ROUTER_SHADOW_READ_ENABLED = false" in stub,
        "feature_flag_default_false": "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false" in stub,
    },
    "backend": {
        "env_boundary_present_in_source": "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED" in controller,
        "live_env_enabled": "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1" in env_text,
    },
    "safety": {
        "live_controller_restarted": False,
        "wrapper_restarted": False,
        "router_live_enabled": False,
        "dispatch_enabled": False,
        "model_calls_enabled": False,
        "browser_router_traffic_enabled": False,
    },
}

Path("docs/generated").mkdir(parents=True, exist_ok=True)
Path("docs/generated/stage-8p-backend-live-router-dry-run-flag-boundary-plan.json").write_text(
    json.dumps(report, indent=2, sort_keys=True) + "\n"
)

print("wrote_report=docs/generated/stage-8p-backend-live-router-dry-run-flag-boundary-plan.json")
print("PASS: Stage 8P generated backend/live flag boundary plan report")
PY

if [ -f "$REPORT" ]; then
  python3 -m json.tool "$REPORT" >/dev/null || fail=1
  grep -q '"stage": "8P"' "$REPORT" || fail=1
  grep -q '"decision": "do_not_enable_live_router_dry_run_traffic_yet"' "$REPORT" || fail=1
  grep -q '"contains_router_endpoint": false' "$REPORT" || fail=1
  grep -q '"live_env_enabled": false' "$REPORT" || fail=1
  echo "OK: generated Stage 8P report valid"
else
  echo "FAIL: missing generated Stage 8P report"
  fail=1
fi

echo
echo "=== final repo status ==="
git status --short

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8P backend/live router dry-run flag boundary plan verified"
else
  echo "FAIL: Stage 8P smoke found an issue"
fi
