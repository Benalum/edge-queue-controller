#!/usr/bin/env bash
set -u

echo "=== Stage 8R smoke: live backend router dry-run go/no-go decision ==="

fail=0

DOC="docs/stage-8r-live-backend-router-dry-run-go-no-go-decision.md"
REPORT="docs/generated/stage-8r-live-backend-router-dry-run-go-no-go-decision.json"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
LIVE="http://127.0.0.1:7070"

for f in "$DOC" "$APP_JS" "$STUB" "$INDEX_HTML"; do
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
  "Live Backend Router Dry-Run Go/No-Go Decision" \
  "No-go for live backend router dry-run enablement right now" \
  "Stage 8Q" \
  "Stage 8S"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== verify Stage 8Q tag exists ==="
if git rev-parse -q --verify refs/tags/controller-stage-8q-temporary-controller-router-dry-run-validation-2026-06-12 >/dev/null; then
  echo "OK: Stage 8Q tag exists"
else
  echo "FAIL: Stage 8Q tag missing"
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
  echo "OK: frontend enabled flag remains false"
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
  code="$(curl -sS --max-time 10 -o "/tmp/stage8r-${path//\//_}.out" -w "%{http_code}" \
    -X POST "$LIVE${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8r-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== /tick remains fast compatibility shim ==="
tick_code="$(curl -sS --max-time 10 -o /tmp/stage8r-tick.out -w "%{http_code}" -X POST "$LIVE/tick" || true)"
echo "tick_code=$tick_code"
sed -n '1,16p' /tmp/stage8r-tick.out || true

if [ "$tick_code" != "200" ]; then
  echo "FAIL: /tick shim should return 200"
  fail=1
else
  if grep -q "legacy_tick_compatibility_shim" /tmp/stage8r-tick.out; then
    echo "OK: /tick remains legacy compatibility shim"
  else
    echo "FAIL: /tick did not report compatibility shim"
    fail=1
  fi
fi

echo
echo "=== live frontend asset still loads disabled stub ==="
index_code="$(curl -sS --max-time 10 -o /tmp/stage8r-live-index.html -w "%{http_code}" http://127.0.0.1:8787/ || true)"
echo "index_code=$index_code"

if [ "$index_code" = "200" ]; then
  grep -q "router_shadow_read_stub.js" /tmp/stage8r-live-index.html && echo "OK: live index includes stub" || { echo "FAIL: live index missing stub"; fail=1; }
  grep -q "app.js?v=2026061208l" /tmp/stage8r-live-index.html && echo "OK: live index includes Stage 8L app asset" || { echo "FAIL: live index missing Stage 8L app asset"; fail=1; }
else
  echo "FAIL: live wrapper index should return 200"
  fail=1
fi

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 "$LIVE/health" | jq .

curl -sS --max-time 20 "$LIVE/system/status" > /tmp/stage8r-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker")),
  power: (.services[]? | select(.id=="power-automation"))
}' /tmp/stage8r-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8r-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8r-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8r-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8r-system-status.json)"

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
echo "=== write generated Stage 8R report ==="
python3 - <<'PY'
from pathlib import Path
import json
import subprocess

def read(path):
    p = Path(path)
    return p.read_text(errors="ignore") if p.exists() else ""

def cmd(args):
    return subprocess.run(args, capture_output=True, text=True).stdout

app = read("frontend/wrapper-ui/app.js")
stub = read("frontend/wrapper-ui/router_shadow_read_stub.js")
env_text = cmd(["systemctl", "show", "edge-queue-controller", "-p", "Environment", "--value"])

report = {
    "stage": "8R",
    "stage_type": "live_backend_router_dry_run_go_no_go_decision",
    "decision": "no_go_for_live_backend_router_dry_run_enablement",
    "reason": "temporary_controller_validation_passed_but_live_enablement_requires_separate_manual_activation_stage",
    "frontend": {
        "contains_router_endpoint": "/api/router/dry-run" in (app + stub),
        "stub_enabled_flag_false": "const ROUTER_SHADOW_READ_ENABLED = false" in stub,
        "feature_flag_default_false": "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false" in stub,
    },
    "live_controller": {
        "router_env_enabled": "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1" in env_text,
    },
    "safety": {
        "live_controller_restarted": False,
        "wrapper_restarted": False,
        "router_live_enabled": False,
        "browser_router_traffic_enabled": False,
        "dispatch_enabled": False,
        "model_calls_enabled": False,
    },
    "next_recommended_stage": "8S_live_backend_activation_and_rollback_plan_only",
}

Path("docs/generated").mkdir(parents=True, exist_ok=True)
Path("docs/generated/stage-8r-live-backend-router-dry-run-go-no-go-decision.json").write_text(
    json.dumps(report, indent=2, sort_keys=True) + "\n"
)

print("wrote_report=docs/generated/stage-8r-live-backend-router-dry-run-go-no-go-decision.json")
print("PASS: Stage 8R generated go/no-go decision report")
PY

if [ -f "$REPORT" ]; then
  python3 -m json.tool "$REPORT" >/dev/null || fail=1
  grep -q '"stage": "8R"' "$REPORT" || fail=1
  grep -q '"decision": "no_go_for_live_backend_router_dry_run_enablement"' "$REPORT" || fail=1
  grep -q '"contains_router_endpoint": false' "$REPORT" || fail=1
  grep -q '"router_env_enabled": false' "$REPORT" || fail=1
  echo "OK: generated Stage 8R report valid"
else
  echo "FAIL: missing generated Stage 8R report"
  fail=1
fi

echo
echo "=== final repo status ==="
git status --short

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8R live backend router dry-run go/no-go decision verified"
else
  echo "FAIL: Stage 8R smoke found an issue"
fi
