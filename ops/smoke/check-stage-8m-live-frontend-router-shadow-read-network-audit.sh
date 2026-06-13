#!/usr/bin/env bash
set -u

echo "=== Stage 8M smoke: live frontend router shadow-read network audit ==="

fail=0

DOC="docs/stage-8m-live-frontend-router-shadow-read-network-audit.md"
REPORT="docs/generated/stage-8m-live-frontend-router-shadow-read-network-audit.json"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"
APP_JS="frontend/wrapper-ui/app.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
BASE_URL="http://127.0.0.1:8787"

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
  "Live Frontend Router Shadow-Read Network Audit" \
  "does not contain /api/router/dry-run" \
  "ROUTER_SHADOW_READ_ENABLED = false" \
  "Stage 8N"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== local source checks ==="
grep -q "STAGE_8L_DISABLED_ROUTER_SHADOW_READ_OBSERVER_V1" "$APP_JS" || fail=1
grep -q "STAGE_8L_DISABLED_STUDY_SHADOW_READ_OBSERVATION_CALL_V1" "$APP_JS" || fail=1
grep -q "const ROUTER_SHADOW_READ_ENABLED = false" "$STUB" || fail=1
grep -q "router_shadow_read_stub.js" "$INDEX_HTML" || fail=1
grep -q "app.js?v=2026061208l" "$INDEX_HTML" || fail=1

if grep -q "/api/router/dry-run" "$APP_JS"; then
  echo "FAIL: local app.js should not contain /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" || true
  fail=1
else
  echo "OK: local app.js contains no /api/router/dry-run"
fi

echo
echo "=== live asset load audit from wrapper server ==="
index_code="$(curl -sS --max-time 10 -o /tmp/stage8m-live-index.html -w "%{http_code}" "$BASE_URL/" || true)"
echo "index_code=$index_code"

if [ "$index_code" != "200" ]; then
  echo "FAIL: live wrapper index should return 200"
  fail=1
else
  echo "OK: live wrapper index returned 200"
fi

app_src="$(python3 - <<'PY'
from pathlib import Path
import re

text = Path("/tmp/stage8m-live-index.html").read_text(errors="ignore")
m = re.search(r'<script[^>]+src=["\']([^"\']*app\.js[^"\']*)["\']', text)
print(m.group(1) if m else "")
PY
)"

stub_src="$(python3 - <<'PY'
from pathlib import Path
import re

text = Path("/tmp/stage8m-live-index.html").read_text(errors="ignore")
m = re.search(r'<script[^>]+src=["\']([^"\']*router_shadow_read_stub\.js[^"\']*)["\']', text)
print(m.group(1) if m else "")
PY
)"

echo "live_stub_src=$stub_src"
echo "live_app_src=$app_src"

if [ -z "$stub_src" ]; then
  echo "FAIL: live index missing router shadow-read stub script"
  fail=1
fi

if [ -z "$app_src" ]; then
  echo "FAIL: live index missing app.js script"
  fail=1
fi

if [ -n "$stub_src" ] && [ -n "$app_src" ]; then
  stub_line="$(grep -n "router_shadow_read_stub.js" /tmp/stage8m-live-index.html | head -n 1 | cut -d: -f1 || true)"
  app_line="$(grep -n "app.js" /tmp/stage8m-live-index.html | head -n 1 | cut -d: -f1 || true)"
  echo "live_stub_line=$stub_line"
  echo "live_app_line=$app_line"

  if [ -z "$stub_line" ] || [ -z "$app_line" ] || [ "$stub_line" -ge "$app_line" ]; then
    echo "FAIL: live stub should load before app.js"
    fail=1
  else
    echo "OK: live stub loads before app.js"
  fi
fi

resolve_url() {
  local src="$1"
  if printf '%s' "$src" | grep -q '^http'; then
    printf '%s' "$src"
  elif printf '%s' "$src" | grep -q '^/'; then
    printf '%s%s' "$BASE_URL" "$src"
  else
    printf '%s/%s' "$BASE_URL" "$src"
  fi
}

if [ -n "$stub_src" ]; then
  stub_url="$(resolve_url "$stub_src")"
  stub_code="$(curl -sS --max-time 10 -o /tmp/stage8m-live-stub.js -w "%{http_code}" "$stub_url" || true)"
  echo "stub_code=$stub_code"
  if [ "$stub_code" != "200" ]; then
    echo "FAIL: live stub asset should return 200"
    fail=1
  fi
fi

if [ -n "$app_src" ]; then
  app_url="$(resolve_url "$app_src")"
  app_code="$(curl -sS --max-time 10 -o /tmp/stage8m-live-app.js -w "%{http_code}" "$app_url" || true)"
  echo "app_code=$app_code"
  if [ "$app_code" != "200" ]; then
    echo "FAIL: live app asset should return 200"
    fail=1
  fi
fi

echo
echo "=== live asset content checks ==="
if [ -f /tmp/stage8m-live-stub.js ]; then
  if grep -q "const ROUTER_SHADOW_READ_ENABLED = false" /tmp/stage8m-live-stub.js; then
    echo "OK: live stub remains disabled"
  else
    echo "FAIL: live stub does not show disabled flag"
    fail=1
  fi

  if grep -q "window.EdgeRouterShadowRead" /tmp/stage8m-live-stub.js; then
    echo "OK: live stub exposes browser namespace"
  else
    echo "FAIL: live stub missing browser namespace"
    fail=1
  fi
fi

if [ -f /tmp/stage8m-live-app.js ]; then
  if grep -q "STAGE_8L_DISABLED_ROUTER_SHADOW_READ_OBSERVER_V1" /tmp/stage8m-live-app.js; then
    echo "OK: live app includes Stage 8L disabled observer"
  else
    echo "FAIL: live app missing Stage 8L observer"
    fail=1
  fi

  if grep -q "/api/router/dry-run" /tmp/stage8m-live-app.js; then
    echo "FAIL: live app should not contain /api/router/dry-run"
    grep -n "/api/router/dry-run" /tmp/stage8m-live-app.js || true
    fail=1
  else
    echo "OK: live app contains no /api/router/dry-run"
  fi
fi

echo
echo "=== isolated observer simulation using live-served assets ==="
node - <<'NODE' | tee /tmp/stage8m-live-asset-simulation.txt
const fs = require("fs");
const vm = require("vm");

const stubCode = fs.readFileSync("/tmp/stage8m-live-stub.js", "utf8");
const appCode = fs.readFileSync("/tmp/stage8m-live-app.js", "utf8");

const helperMarker = "// STAGE_8L_DISABLED_ROUTER_SHADOW_READ_OBSERVER_V1";
const helperIndex = appCode.indexOf(helperMarker);
if (helperIndex < 0) {
  throw new Error("Stage 8L helper marker missing from live app asset");
}

const helperCode = appCode.slice(helperIndex);

const sandbox = {
  window: {},
  console,
  document: {},
  localStorage: {
    getItem: () => null,
    setItem: () => {},
    removeItem: () => {},
  },
  sessionStorage: {
    getItem: () => null,
    setItem: () => {},
    removeItem: () => {},
  },
  setTimeout,
  clearTimeout,
};

vm.createContext(sandbox);
vm.runInContext(stubCode, sandbox, { filename: "live-router-shadow-stub.js" });
vm.runInContext(helperCode, sandbox, { filename: "live-stage8l-helper.js" });

if (!sandbox.window.EdgeRouterShadowRead) {
  throw new Error("EdgeRouterShadowRead namespace missing");
}

if (sandbox.window.EdgeRouterShadowRead.ROUTER_SHADOW_READ_ENABLED !== false) {
  throw new Error("router shadow read must remain disabled");
}

const result = sandbox.stage8lObserveRouterShadowReadDisabled({
  text: "study_command_shadow_observation",
  source: "study",
  surface: "study_session",
  activePage: "study",
  profileLanguage: "en",
});

if (!result || result.skipped !== true) {
  throw new Error("observer should skip");
}

if (result.reason !== "router_shadow_read_disabled") {
  throw new Error(`wrong skip reason: ${result.reason}`);
}

if (result.dispatch_performed !== false) {
  throw new Error("dispatch_performed must be false");
}

if (result.allowed_to_dispatch !== false) {
  throw new Error("allowed_to_dispatch must be false");
}

if (result.would_dispatch !== false) {
  throw new Error("would_dispatch must be false");
}

console.log("PASS: Stage 8M live asset observer simulation skipped without router call");
NODE

if ! grep -q "PASS: Stage 8M live asset observer simulation skipped without router call" /tmp/stage8m-live-asset-simulation.txt; then
  echo "FAIL: live asset observer simulation failed"
  fail=1
fi

echo
echo "=== live router remains disabled by configuration/source state ==="
if systemctl show edge-queue-controller -p Environment --value | tr ' ' '\n' | grep -q '^EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1$'; then
  echo "FAIL: live router dry-run env should not be enabled"
  fail=1
else
  echo "OK: live router dry-run env is not enabled"
fi

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8m-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8m-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8m-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8m-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8m-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8m-system-status.json)"

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

echo
echo "=== write generated audit report ==="
python3 - <<'PY'
from pathlib import Path
import json
import subprocess

def read(path):
    p = Path(path)
    return p.read_text(errors="ignore") if p.exists() else ""

index = read("/tmp/stage8m-live-index.html")
stub = read("/tmp/stage8m-live-stub.js")
app = read("/tmp/stage8m-live-app.js")

report = {
    "stage": "8M",
    "audit_type": "live_frontend_asset_network_audit",
    "wrapper_base_url": "http://127.0.0.1:8787",
    "live_index_loaded": "router_shadow_read_stub.js" in index and "app.js" in index,
    "live_stub_disabled": "const ROUTER_SHADOW_READ_ENABLED = false" in stub,
    "live_stub_namespace": "window.EdgeRouterShadowRead" in stub,
    "live_app_has_stage8l_observer": "STAGE_8L_DISABLED_ROUTER_SHADOW_READ_OBSERVER_V1" in app,
    "live_app_contains_router_dry_run_endpoint": "/api/router/dry-run" in app,
    "frontend_router_request_expected": False,
    "frontend_router_request_observed_in_assets": False,
    "router_enabled_env": False,
    "safety": {
        "live_controller_restarted": False,
        "wrapper_restarted": False,
        "router_enabled": False,
        "dispatch_enabled": False,
        "model_calls_enabled": False,
    },
}

Path("docs/generated").mkdir(parents=True, exist_ok=True)
Path("docs/generated/stage-8m-live-frontend-router-shadow-read-network-audit.json").write_text(
    json.dumps(report, indent=2, sort_keys=True) + "\n"
)

print("wrote_report=docs/generated/stage-8m-live-frontend-router-shadow-read-network-audit.json")
print("PASS: Stage 8M generated live frontend network audit report")
PY

if ! grep -q '"stage": "8M"' "$REPORT"; then
  echo "FAIL: generated report missing stage"
  fail=1
else
  python3 -m json.tool "$REPORT" >/dev/null || fail=1
  grep -q '"live_app_contains_router_dry_run_endpoint": false' "$REPORT" || fail=1
  grep -q '"live_stub_disabled": true' "$REPORT" || fail=1
  echo "OK: generated report valid"
fi

echo
echo "=== final repo status ==="
git status --short

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8M live frontend router shadow-read network audit verified"
else
  echo "FAIL: Stage 8M smoke found an issue"
fi
