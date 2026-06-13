#!/usr/bin/env bash
set -u

echo "=== Stage 8O smoke: frontend router shadow-read feature flag boundary ==="

fail=0

DOC="docs/stage-8o-frontend-router-shadow-read-feature-flag-boundary.md"
REPORT="docs/generated/stage-8o-frontend-router-shadow-read-feature-flag-boundary.json"
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
  "Frontend Router Shadow-Read Feature Flag Boundary" \
  "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false" \
  "isRouterShadowReadFeatureEnabled() = false" \
  "Stage 8P"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== stub feature flag markers ==="
for marker in \
  "STAGE_8O_FEATURE_FLAG_BOUNDARY_V1" \
  "const ROUTER_SHADOW_READ_ENABLED = false" \
  "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false" \
  "function isRouterShadowReadFeatureEnabled" \
  "router_shadow_read_disabled"; do
  if grep -q "$marker" "$STUB"; then
    echo "OK: stub marker found: $marker"
  else
    echo "FAIL: stub marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== no frontend router endpoint string yet ==="
if grep -q "/api/router/dry-run" "$APP_JS" "$STUB"; then
  echo "FAIL: frontend files must not contain /api/router/dry-run at Stage 8O"
  grep -n "/api/router/dry-run" "$APP_JS" "$STUB" || true
  fail=1
else
  echo "OK: frontend files contain no /api/router/dry-run"
fi

echo
echo "=== app.js still has disabled observer and Study command path ==="
grep -q "STAGE_8L_DISABLED_ROUTER_SHADOW_READ_OBSERVER_V1" "$APP_JS" || fail=1
grep -q "STAGE_8L_DISABLED_STUDY_SHADOW_READ_OBSERVATION_CALL_V1" "$APP_JS" || fail=1

study_count="$(grep -c "/api/study/session/command" "$APP_JS" || true)"
echo "study_command_api_count=$study_count"
if [ "$study_count" = "0" ]; then
  echo "FAIL: Study command path missing"
  fail=1
else
  echo "OK: Study command path still present"
fi

echo
echo "=== index still loads stub before app.js ==="
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
echo "=== JavaScript syntax checks ==="
node --check "$STUB" >/tmp/stage8o-stub-syntax.txt 2>&1
if [ "$?" = "0" ]; then
  echo "OK: stub syntax passed"
else
  echo "FAIL: stub syntax failed"
  cat /tmp/stage8o-stub-syntax.txt
  fail=1
fi

node --check "$APP_JS" >/tmp/stage8o-app-syntax.txt 2>&1
if [ "$?" = "0" ]; then
  echo "OK: app.js syntax passed"
else
  echo "FAIL: app.js syntax failed"
  cat /tmp/stage8o-app-syntax.txt
  fail=1
fi

echo
echo "=== CommonJS feature flag behavior check ==="
node - <<'NODE' | tee /tmp/stage8o-commonjs-check.txt
const {
  ROUTER_SHADOW_READ_ENABLED,
  ROUTER_SHADOW_READ_FEATURE_FLAG_NAME,
  ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT,
  isRouterShadowReadFeatureEnabled,
  buildRouterShadowReadPayload,
  routerShadowRead,
} = require("./frontend/wrapper-ui/router_shadow_read_stub.js");

async function main() {
  if (ROUTER_SHADOW_READ_ENABLED !== false) throw new Error("ROUTER_SHADOW_READ_ENABLED must be false");
  if (ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT !== false) throw new Error("feature flag default must be false");
  if (ROUTER_SHADOW_READ_FEATURE_FLAG_NAME !== "edge_router_shadow_read") throw new Error("wrong feature flag name");
  if (isRouterShadowReadFeatureEnabled() !== false) throw new Error("feature flag boundary must resolve false");

  const payload = buildRouterShadowReadPayload({
    text: "next",
    source: "study",
    surface: "study_session",
    activePage: "study",
    profileLanguage: "en",
  });

  let apiCalled = false;
  const result = await routerShadowRead(async () => {
    apiCalled = true;
    throw new Error("api must not be called while feature flag is off");
  }, payload);

  if (apiCalled) throw new Error("api was called while feature flag is off");
  if (result.skipped !== true) throw new Error("result should be skipped");
  if (result.reason !== "router_shadow_read_disabled") throw new Error("wrong skipped reason");
  if (result.dispatch_performed !== false) throw new Error("dispatch_performed must be false");
  if (result.allowed_to_dispatch !== false) throw new Error("allowed_to_dispatch must be false");
  if (result.would_dispatch !== false) throw new Error("would_dispatch must be false");

  console.log("PASS: Stage 8O CommonJS feature flag checks passed");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
NODE

if ! grep -q "PASS: Stage 8O CommonJS feature flag checks passed" /tmp/stage8o-commonjs-check.txt; then
  echo "FAIL: CommonJS feature flag checks failed"
  fail=1
fi

echo
echo "=== browser namespace feature flag simulation ==="
node - <<'NODE' | tee /tmp/stage8o-browser-check.txt
const fs = require("fs");
const vm = require("vm");

const code = fs.readFileSync("frontend/wrapper-ui/router_shadow_read_stub.js", "utf8");
const sandbox = { window: {}, console };

vm.createContext(sandbox);
vm.runInContext(code, sandbox, { filename: "router_shadow_read_stub.js" });

async function main() {
  const ns = sandbox.window.EdgeRouterShadowRead;
  if (!ns) throw new Error("window.EdgeRouterShadowRead missing");
  if (ns.ROUTER_SHADOW_READ_ENABLED !== false) throw new Error("browser enabled flag must be false");
  if (ns.ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT !== false) throw new Error("browser feature flag default must be false");
  if (ns.isRouterShadowReadFeatureEnabled() !== false) throw new Error("browser feature boundary must resolve false");

  let apiCalled = false;
  const result = await ns.routerShadowRead(async () => {
    apiCalled = true;
  }, ns.buildRouterShadowReadPayload({ text: "skip", source: "study", surface: "study_session" }));

  if (apiCalled) throw new Error("browser helper called API while disabled");
  if (result.skipped !== true) throw new Error("browser helper should skip");
  if (result.reason !== "router_shadow_read_disabled") throw new Error("wrong browser reason");

  console.log("PASS: Stage 8O browser feature flag simulation passed");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
NODE

if ! grep -q "PASS: Stage 8O browser feature flag simulation passed" /tmp/stage8o-browser-check.txt; then
  echo "FAIL: browser feature flag simulation failed"
  fail=1
fi

echo
echo "=== live router endpoint remains disabled ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8o-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8o-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== live router env flag remains off ==="
if systemctl show edge-queue-controller -p Environment --value | tr ' ' '\n' | grep -q '^EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1$'; then
  echo "FAIL: live router dry-run env is enabled"
  fail=1
else
  echo "OK: live router dry-run env is not enabled"
fi

echo
echo "=== live frontend asset still serves disabled stub ==="
index_code="$(curl -sS --max-time 10 -o /tmp/stage8o-live-index.html -w "%{http_code}" http://127.0.0.1:8787/ || true)"
echo "index_code=$index_code"

if [ "$index_code" = "200" ]; then
  grep -q "router_shadow_read_stub.js" /tmp/stage8o-live-index.html && echo "OK: live index includes stub" || { echo "FAIL: live index missing stub"; fail=1; }
else
  echo "FAIL: live wrapper index should return 200"
  fail=1
fi

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8o-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8o-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8o-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8o-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8o-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8o-system-status.json)"

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
echo "=== write generated Stage 8O report ==="
python3 - <<'PY'
from pathlib import Path
import json

stub = Path("frontend/wrapper-ui/router_shadow_read_stub.js").read_text(errors="ignore")
app = Path("frontend/wrapper-ui/app.js").read_text(errors="ignore")

report = {
    "stage": "8O",
    "feature_flag_boundary": "frontend_router_shadow_read",
    "enabled_by_default": False,
    "router_endpoint_in_frontend": "/api/router/dry-run" in (stub + app),
    "stub_disabled": "const ROUTER_SHADOW_READ_ENABLED = false" in stub,
    "feature_flag_default_disabled": "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false" in stub,
    "feature_flag_function_present": "function isRouterShadowReadFeatureEnabled" in stub,
    "next_recommended_stage": "8P_backend_or_frontend_flag_plan_without_enabling_traffic",
    "safety": {
        "dispatch_enabled": False,
        "model_calls_enabled": False,
        "router_traffic_enabled": False,
    },
}

Path("docs/generated").mkdir(parents=True, exist_ok=True)
Path("docs/generated/stage-8o-frontend-router-shadow-read-feature-flag-boundary.json").write_text(
    json.dumps(report, indent=2, sort_keys=True) + "\n"
)

print("wrote_report=docs/generated/stage-8o-frontend-router-shadow-read-feature-flag-boundary.json")
print("PASS: Stage 8O generated feature flag boundary report")
PY

if [ -f "$REPORT" ]; then
  python3 -m json.tool "$REPORT" >/dev/null || fail=1
  grep -q '"stage": "8O"' "$REPORT" || fail=1
  grep -q '"enabled_by_default": false' "$REPORT" || fail=1
  grep -q '"router_endpoint_in_frontend": false' "$REPORT" || fail=1
  grep -q '"feature_flag_default_disabled": true' "$REPORT" || fail=1
  echo "OK: generated Stage 8O report valid"
else
  echo "FAIL: missing generated Stage 8O report"
  fail=1
fi

echo
echo "=== final repo status ==="
git status --short

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8O frontend router shadow-read feature flag boundary verified"
else
  echo "FAIL: Stage 8O smoke found an issue"
fi
