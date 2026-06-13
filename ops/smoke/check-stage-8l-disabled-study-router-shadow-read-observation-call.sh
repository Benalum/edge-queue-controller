#!/usr/bin/env bash
set -u

echo "=== Stage 8L smoke: disabled Study router shadow-read observation call ==="

fail=0

DOC="docs/stage-8l-disabled-study-router-shadow-read-observation-call.md"
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
  "Disabled Study Router Shadow-Read Observation Call" \
  "ROUTER_SHADOW_READ_ENABLED = false" \
  "does not call the router" \
  "Stage 8M"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== source markers ==="
for marker in \
  "STAGE_8L_DISABLED_ROUTER_SHADOW_READ_OBSERVER_V1" \
  "STAGE_8L_DISABLED_STUDY_SHADOW_READ_OBSERVATION_CALL_V1" \
  "stage8lObserveRouterShadowReadDisabled" \
  "router_shadow_read_disabled"; do
  if grep -q "$marker" "$APP_JS"; then
    echo "OK: app.js marker found: $marker"
  else
    echo "FAIL: app.js marker missing: $marker"
    fail=1
  fi
done

if grep -q "const ROUTER_SHADOW_READ_ENABLED = false" "$STUB"; then
  echo "OK: stub remains disabled"
else
  echo "FAIL: stub must remain disabled"
  fail=1
fi

echo
echo "=== prove app.js still does not call router dry-run directly ==="
if grep -q "/api/router/dry-run" "$APP_JS"; then
  echo "FAIL: app.js should not contain /api/router/dry-run yet"
  grep -n "/api/router/dry-run" "$APP_JS" || true
  fail=1
else
  echo "OK: app.js has no /api/router/dry-run string"
fi

echo
echo "=== prove Study command path still exists ==="
study_count="$(grep -c "/api/study/session/command" "$APP_JS" || true)"
echo "study_command_api_count=$study_count"
if [ "$study_count" = "0" ]; then
  echo "FAIL: Study command API path missing"
  fail=1
else
  echo "OK: Study command API path still present"
fi

echo
echo "=== verify index.html loads stub before app.js and app.js version bumped ==="
stub_count="$(grep -c "router_shadow_read_stub.js" "$INDEX_HTML" || true)"
stub_line="$(grep -n "router_shadow_read_stub.js" "$INDEX_HTML" | head -n 1 | cut -d: -f1 || true)"
app_line="$(grep -n "<script.*app.js" "$INDEX_HTML" | head -n 1 | cut -d: -f1 || true)"

echo "stub_count=$stub_count"
echo "stub_line=$stub_line"
echo "app_line=$app_line"

if [ "$stub_count" != "1" ]; then
  echo "FAIL: expected one stub script"
  fail=1
fi

if [ -z "$stub_line" ] || [ -z "$app_line" ] || [ "$stub_line" -ge "$app_line" ]; then
  echo "FAIL: stub should load before app.js"
  fail=1
else
  echo "OK: stub loads before app.js"
fi

if grep -q "app.js?v=2026061208l" "$INDEX_HTML"; then
  echo "OK: app.js version bumped for Stage 8L"
else
  echo "FAIL: app.js version was not bumped for Stage 8L"
  fail=1
fi

echo
echo "=== JavaScript syntax checks ==="
node --check "$STUB" | tee /tmp/stage8l-stub-syntax.txt
if [ "${PIPESTATUS[0]}" != "0" ]; then
  echo "FAIL: stub syntax failed"
  fail=1
else
  echo "OK: stub syntax passed"
fi

node --check "$APP_JS" | tee /tmp/stage8l-app-syntax.txt
if [ "${PIPESTATUS[0]}" != "0" ]; then
  echo "FAIL: app.js syntax failed"
  fail=1
else
  echo "OK: app.js syntax passed"
fi

echo
echo "=== isolated Stage 8L observer simulation: disabled means no API call ==="
node - <<'NODE' | tee /tmp/stage8l-observer-simulation.txt
const fs = require("fs");
const vm = require("vm");

const stubCode = fs.readFileSync("frontend/wrapper-ui/router_shadow_read_stub.js", "utf8");
const appCode = fs.readFileSync("frontend/wrapper-ui/app.js", "utf8");

const helperMarker = "// STAGE_8L_DISABLED_ROUTER_SHADOW_READ_OBSERVER_V1";
const helperIndex = appCode.indexOf(helperMarker);
if (helperIndex < 0) {
  throw new Error("Stage 8L helper marker missing");
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
vm.runInContext(stubCode, sandbox, { filename: "router_shadow_read_stub.js" });
vm.runInContext(helperCode, sandbox, { filename: "stage8l-helper.js" });

const result = sandbox.stage8lObserveRouterShadowReadDisabled({
  text: "study_command_shadow_observation",
  source: "study",
  surface: "study_session",
  activePage: "study",
  profileLanguage: "en",
});

if (!result || result.skipped !== true) {
  throw new Error("disabled observer should return skipped=true");
}

if (result.reason !== "router_shadow_read_disabled") {
  throw new Error(`wrong reason: ${result.reason}`);
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

console.log("PASS: Stage 8L observer simulation skipped without router call");
NODE

if ! grep -q "PASS: Stage 8L observer simulation skipped without router call" /tmp/stage8l-observer-simulation.txt; then
  echo "FAIL: observer simulation failed"
  fail=1
fi

echo
echo "=== live index should serve Stage 8L assets without restart ==="
code="$(curl -sS --max-time 10 -o /tmp/stage8l-index.html -w "%{http_code}" http://127.0.0.1:8787/ || true)"
echo "wrapper_index_code=$code"
if [ "$code" = "200" ]; then
  grep -q "router_shadow_read_stub.js" /tmp/stage8l-index.html && echo "OK: live index includes stub script" || { echo "FAIL: live index missing stub script"; fail=1; }
  grep -q "app.js?v=2026061208l" /tmp/stage8l-index.html && echo "OK: live index includes Stage 8L app.js version" || { echo "CHECK: live index may not reflect Stage 8L app version yet"; }
else
  echo "CHECK: local wrapper index did not return 200; continuing with file proof"
fi

echo
echo "=== live router endpoint must remain disabled ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8l-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8l-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8l-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8l-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8l-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8l-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8l-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8l-system-status.json)"

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
echo "legacy_enabled=$(systemctl is-enabled edge-queue-scheduler-tick.timer || true)"
echo "legacy_active=$(systemctl is-active edge-queue-scheduler-tick.timer || true)"
echo "power_auto_active=$(systemctl is-active edge-queue-power-auto-tick.timer || true)"
echo "remediation_active=$(systemctl is-active edge-queue-remediation-tick.timer || true)"

echo
echo "=== final repo status ==="
git status --short

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8L disabled Study router shadow-read observation call verified"
else
  echo "FAIL: Stage 8L smoke found an issue"
fi
