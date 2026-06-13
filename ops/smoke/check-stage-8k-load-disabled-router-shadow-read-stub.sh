#!/usr/bin/env bash
set -u

echo "=== Stage 8K smoke: load disabled router shadow-read stub ==="

fail=0

DOC="docs/stage-8k-load-disabled-router-shadow-read-stub.md"
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
  "Load Disabled Router Shadow-Read Stub" \
  "window.EdgeRouterShadowRead" \
  "ROUTER_SHADOW_READ_ENABLED = false" \
  "Stage 8L"; do
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
  "STAGE_8I_ROUTER_SHADOW_READ_STUB_V1" \
  "STAGE_8K_BROWSER_NAMESPACE_EXPORT_V1" \
  "window.EdgeRouterShadowRead" \
  "const ROUTER_SHADOW_READ_ENABLED = false"; do
  if grep -q "$marker" "$STUB"; then
    echo "OK: stub marker found: $marker"
  else
    echo "FAIL: stub marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== index.html loads stub exactly once before app.js ==="
stub_count="$(grep -c "router_shadow_read_stub.js" "$INDEX_HTML" || true)"
app_line="$(grep -n "<script.*app.js" "$INDEX_HTML" | head -n 1 | cut -d: -f1 || true)"
stub_line="$(grep -n "router_shadow_read_stub.js" "$INDEX_HTML" | head -n 1 | cut -d: -f1 || true)"

echo "stub_count=$stub_count"
echo "stub_line=$stub_line"
echo "app_line=$app_line"

if [ "$stub_count" != "1" ]; then
  echo "FAIL: expected exactly one stub script tag"
  fail=1
fi

if [ -z "$stub_line" ] || [ -z "$app_line" ]; then
  echo "FAIL: expected both stub and app.js script lines"
  fail=1
else
  if [ "$stub_line" -ge "$app_line" ]; then
    echo "FAIL: stub should load before app.js"
    fail=1
  else
    echo "OK: stub loads before app.js"
  fi
fi

echo
echo "=== prove app.js still has no router dry-run call and no stub dependency ==="
if grep -q "/api/router/dry-run" "$APP_JS"; then
  echo "FAIL: app.js should not call router dry-run yet"
  grep -n "/api/router/dry-run" "$APP_JS" || true
  fail=1
else
  echo "OK: app.js does not call router dry-run"
fi

if grep -q "EdgeRouterShadowRead\|routerShadowRead\|router_shadow_read_stub" "$APP_JS"; then
  echo "FAIL: app.js should not depend on the stub yet"
  grep -n "EdgeRouterShadowRead\|routerShadowRead\|router_shadow_read_stub" "$APP_JS" || true
  fail=1
else
  echo "OK: app.js does not depend on the stub"
fi

echo
echo "=== Node CommonJS helper checks still pass ==="
node - <<'NODE' | tee /tmp/stage8k-node-commonjs-check.txt
const {
  ROUTER_SHADOW_READ_ENABLED,
  buildRouterShadowReadPayload,
  extractRouterDecisionContract,
  isRouterDecisionShadowSafe,
  routerShadowRead,
} = require("./frontend/wrapper-ui/router_shadow_read_stub.js");

async function main() {
  if (ROUTER_SHADOW_READ_ENABLED !== false) throw new Error("must be disabled");

  const payload = buildRouterShadowReadPayload({
    text: "next",
    source: "study",
    surface: "study_session",
    activePage: "study",
    profileLanguage: "en",
  });

  if (payload.router_options.dry_run !== true) throw new Error("dry_run must be true");
  if (payload.router_options.allow_dispatch !== false) throw new Error("allow_dispatch must be false");
  if (payload.router_options.allow_model_call !== false) throw new Error("allow_model_call must be false");

  const decision = extractRouterDecisionContract({
    decision_contract: {
      selected_path: "study_command",
      dispatch_performed: false,
      allowed_to_dispatch: false,
      dispatch_plan: { would_dispatch: false },
    },
  });

  if (isRouterDecisionShadowSafe(decision) !== true) throw new Error("safe decision should pass");

  let apiCalled = false;
  const skipped = await routerShadowRead(async () => {
    apiCalled = true;
  }, payload);

  if (apiCalled) throw new Error("disabled helper must not call api");
  if (skipped.skipped !== true) throw new Error("disabled helper should skip");
  if (skipped.reason !== "router_shadow_read_disabled") throw new Error("wrong skip reason");

  console.log("PASS: Stage 8K CommonJS helper checks passed");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
NODE

if ! grep -q "PASS: Stage 8K CommonJS helper checks passed" /tmp/stage8k-node-commonjs-check.txt; then
  echo "FAIL: CommonJS helper checks failed"
  fail=1
fi

echo
echo "=== browser namespace simulation check ==="
node - <<'NODE' | tee /tmp/stage8k-node-browser-check.txt
const fs = require("fs");
const vm = require("vm");

const code = fs.readFileSync("frontend/wrapper-ui/router_shadow_read_stub.js", "utf8");

const sandbox = {
  window: {},
  console,
};

vm.createContext(sandbox);
vm.runInContext(code, sandbox, { filename: "router_shadow_read_stub.js" });

async function main() {
  const ns = sandbox.window.EdgeRouterShadowRead;
  if (!ns) throw new Error("window.EdgeRouterShadowRead missing");
  if (ns.ROUTER_SHADOW_READ_ENABLED !== false) throw new Error("browser namespace must be disabled");

  const payload = ns.buildRouterShadowReadPayload({
    text: "skip",
    source: "study",
    surface: "study_session",
    activePage: "study",
    profileLanguage: "en",
  });

  if (payload.router_options.dry_run !== true) throw new Error("dry_run must be true");
  if (payload.router_options.allow_dispatch !== false) throw new Error("allow_dispatch must be false");
  if (payload.router_options.allow_model_call !== false) throw new Error("allow_model_call must be false");

  let apiCalled = false;
  const skipped = await ns.routerShadowRead(async () => {
    apiCalled = true;
  }, payload);

  if (apiCalled) throw new Error("browser disabled helper must not call api");
  if (skipped.skipped !== true) throw new Error("browser disabled helper should skip");
  if (skipped.reason !== "router_shadow_read_disabled") throw new Error("wrong browser skip reason");

  console.log("PASS: Stage 8K browser namespace simulation passed");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
NODE

if ! grep -q "PASS: Stage 8K browser namespace simulation passed" /tmp/stage8k-node-browser-check.txt; then
  echo "FAIL: browser namespace simulation failed"
  fail=1
fi

echo
echo "=== live index should serve script tag without restart ==="
code="$(curl -sS --max-time 10 -o /tmp/stage8k-index.html -w "%{http_code}" http://127.0.0.1:8787/ || true)"
echo "wrapper_index_code=$code"
if [ "$code" != "200" ]; then
  echo "CHECK: local wrapper index did not return 200; continuing with file-based proof"
else
  if grep -q "router_shadow_read_stub.js" /tmp/stage8k-index.html; then
    echo "OK: live wrapper index includes stub script"
  else
    echo "CHECK: live wrapper index does not show stub yet; service may need reload later, but file proof passed"
  fi
fi

echo
echo "=== live router endpoint must remain disabled ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8k-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8k-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8k-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8k-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8k-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8k-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8k-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8k-system-status.json)"

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
  echo "PASS: Stage 8K disabled router shadow-read stub loaded safely"
else
  echo "FAIL: Stage 8K smoke found an issue"
fi
