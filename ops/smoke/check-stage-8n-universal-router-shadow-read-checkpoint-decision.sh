#!/usr/bin/env bash
set -u

echo "=== Stage 8N smoke: Universal Router shadow-read checkpoint decision ==="

fail=0

DOC="docs/stage-8n-universal-router-shadow-read-checkpoint-decision.md"
REPORT="docs/generated/stage-8n-universal-router-shadow-read-checkpoint-decision.json"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"
APP_JS="frontend/wrapper-ui/app.js"
INDEX_HTML="frontend/wrapper-ui/index.html"

for f in "$DOC" "$STUB" "$APP_JS" "$INDEX_HTML"; do
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
  "Universal Router Shadow-Read Checkpoint Decision" \
  "Do not enable real router traffic yet" \
  "Stage 8O" \
  "Stop Condition"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== verify Stage 8A through Stage 8M tags exist ==="
required_tags=(
  controller-stage-8a-universal-intent-router-reentry-audit-2026-06-12
  controller-stage-8b-universal-intent-router-decision-maker-contract-2026-06-12
  controller-stage-8c-router-response-schema-comparison-audit-2026-06-12
  controller-stage-8d-router-decision-contract-adapter-helper-2026-06-12
  controller-stage-8e-temporary-router-decision-contract-http-smoke-2026-06-12
  controller-stage-8f-router-response-nested-decision-contract-2026-06-12
  controller-stage-8g-router-decision-contract-consumer-readiness-2026-06-12
  controller-stage-8h-frontend-router-shadow-read-hook-audit-2026-06-12
  controller-stage-8i-disabled-frontend-router-shadow-read-stub-2026-06-12
  controller-stage-8j-frontend-router-shadow-read-stub-consumer-plan-2026-06-12
  controller-stage-8k-load-disabled-router-shadow-read-stub-2026-06-12
  controller-stage-8l-disabled-study-router-shadow-read-observation-2026-06-12
  controller-stage-8m-live-frontend-router-shadow-read-network-audit-2026-06-12
)

for tag in "${required_tags[@]}"; do
  if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
    echo "OK: tag exists: $tag"
  else
    echo "FAIL: missing tag: $tag"
    fail=1
  fi
done

echo
echo "=== frontend disabled-state checks ==="
if grep -q "const ROUTER_SHADOW_READ_ENABLED = false" "$STUB"; then
  echo "OK: stub remains disabled"
else
  echo "FAIL: stub is not disabled"
  fail=1
fi

if grep -q "window.EdgeRouterShadowRead" "$STUB"; then
  echo "OK: stub exposes browser namespace"
else
  echo "FAIL: stub namespace missing"
  fail=1
fi

if grep -q "STAGE_8L_DISABLED_ROUTER_SHADOW_READ_OBSERVER_V1" "$APP_JS"; then
  echo "OK: app.js has disabled Stage 8L observer"
else
  echo "FAIL: app.js missing Stage 8L observer"
  fail=1
fi

if grep -q "/api/router/dry-run" "$APP_JS"; then
  echo "FAIL: app.js must not contain /api/router/dry-run at Stage 8N"
  grep -n "/api/router/dry-run" "$APP_JS" || true
  fail=1
else
  echo "OK: app.js contains no /api/router/dry-run"
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
echo "=== syntax checks ==="
node --check "$STUB" >/tmp/stage8n-stub-syntax.txt 2>&1
if [ "$?" = "0" ]; then
  echo "OK: stub syntax passed"
else
  echo "FAIL: stub syntax failed"
  cat /tmp/stage8n-stub-syntax.txt
  fail=1
fi

node --check "$APP_JS" >/tmp/stage8n-app-syntax.txt 2>&1
if [ "$?" = "0" ]; then
  echo "OK: app.js syntax passed"
else
  echo "FAIL: app.js syntax failed"
  cat /tmp/stage8n-app-syntax.txt
  fail=1
fi

echo
echo "=== live router endpoint must remain disabled ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8n-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8n-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== live router env flag must remain off ==="
if systemctl show edge-queue-controller -p Environment --value | tr ' ' '\n' | grep -q '^EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1$'; then
  echo "FAIL: live router dry-run env is enabled"
  fail=1
else
  echo "OK: live router dry-run env is not enabled"
fi

echo
echo "=== live frontend asset audit ==="
index_code="$(curl -sS --max-time 10 -o /tmp/stage8n-live-index.html -w "%{http_code}" http://127.0.0.1:8787/ || true)"
echo "index_code=$index_code"

if [ "$index_code" = "200" ]; then
  grep -q "router_shadow_read_stub.js" /tmp/stage8n-live-index.html && echo "OK: live index includes stub" || { echo "FAIL: live index missing stub"; fail=1; }
  grep -q "app.js?v=2026061208l" /tmp/stage8n-live-index.html && echo "OK: live index includes Stage 8L app asset" || { echo "FAIL: live index missing Stage 8L app asset"; fail=1; }
else
  echo "FAIL: live wrapper index should return 200"
  fail=1
fi

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8n-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8n-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8n-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8n-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8n-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8n-system-status.json)"

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
echo "=== write generated Stage 8N checkpoint report ==="
python3 - <<'PY'
from pathlib import Path
import json
import subprocess

required_tags = [
    "controller-stage-8a-universal-intent-router-reentry-audit-2026-06-12",
    "controller-stage-8b-universal-intent-router-decision-maker-contract-2026-06-12",
    "controller-stage-8c-router-response-schema-comparison-audit-2026-06-12",
    "controller-stage-8d-router-decision-contract-adapter-helper-2026-06-12",
    "controller-stage-8e-temporary-router-decision-contract-http-smoke-2026-06-12",
    "controller-stage-8f-router-response-nested-decision-contract-2026-06-12",
    "controller-stage-8g-router-decision-contract-consumer-readiness-2026-06-12",
    "controller-stage-8h-frontend-router-shadow-read-hook-audit-2026-06-12",
    "controller-stage-8i-disabled-frontend-router-shadow-read-stub-2026-06-12",
    "controller-stage-8j-frontend-router-shadow-read-stub-consumer-plan-2026-06-12",
    "controller-stage-8k-load-disabled-router-shadow-read-stub-2026-06-12",
    "controller-stage-8l-disabled-study-router-shadow-read-observation-2026-06-12",
    "controller-stage-8m-live-frontend-router-shadow-read-network-audit-2026-06-12",
]

def tag_exists(tag):
    return subprocess.run(
        ["git", "rev-parse", "-q", "--verify", f"refs/tags/{tag}"],
        capture_output=True,
        text=True,
    ).returncode == 0

def read(path):
    p = Path(path)
    return p.read_text(errors="ignore") if p.exists() else ""

stub = read("frontend/wrapper-ui/router_shadow_read_stub.js")
app = read("frontend/wrapper-ui/app.js")
index = read("frontend/wrapper-ui/index.html")

report = {
    "stage": "8N",
    "decision": "do_not_enable_real_router_traffic_yet",
    "next_recommended_stage": "8O_feature_flag_boundary_off_by_default",
    "tags": {tag: tag_exists(tag) for tag in required_tags},
    "frontend_state": {
        "stub_disabled": "const ROUTER_SHADOW_READ_ENABLED = false" in stub,
        "stub_loaded_in_index": "router_shadow_read_stub.js" in index,
        "app_has_stage8l_observer": "STAGE_8L_DISABLED_ROUTER_SHADOW_READ_OBSERVER_V1" in app,
        "app_contains_router_dry_run_endpoint": "/api/router/dry-run" in app,
    },
    "safety": {
        "router_live_enabled": False,
        "dispatch_enabled": False,
        "model_calls_enabled": False,
        "study_behavior_replaced": False,
        "companion_behavior_replaced": False,
    },
}

Path("docs/generated").mkdir(parents=True, exist_ok=True)
Path("docs/generated/stage-8n-universal-router-shadow-read-checkpoint-decision.json").write_text(
    json.dumps(report, indent=2, sort_keys=True) + "\n"
)

print("wrote_report=docs/generated/stage-8n-universal-router-shadow-read-checkpoint-decision.json")
print("PASS: Stage 8N generated checkpoint report")
PY

if [ -f "$REPORT" ]; then
  python3 -m json.tool "$REPORT" >/dev/null || fail=1
  grep -q '"stage": "8N"' "$REPORT" || fail=1
  grep -q '"decision": "do_not_enable_real_router_traffic_yet"' "$REPORT" || fail=1
  grep -q '"app_contains_router_dry_run_endpoint": false' "$REPORT" || fail=1
  grep -q '"stub_disabled": true' "$REPORT" || fail=1
  echo "OK: generated Stage 8N report valid"
else
  echo "FAIL: missing generated Stage 8N report"
  fail=1
fi

echo
echo "=== final repo status ==="
git status --short

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8N Universal Router shadow-read checkpoint decision verified"
else
  echo "FAIL: Stage 8N smoke found an issue"
fi
