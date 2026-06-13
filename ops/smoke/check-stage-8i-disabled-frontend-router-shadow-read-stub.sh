#!/usr/bin/env bash
set -u

echo "=== Stage 8I smoke: disabled frontend router shadow-read stub ==="

fail=0
DOC="docs/stage-8i-disabled-frontend-router-shadow-read-stub.md"
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
  "Disabled Frontend Router Shadow-Read Stub" \
  "ROUTER_SHADOW_READ_ENABLED = false" \
  "Not Wired Yet" \
  "Stage 8J"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== stub markers ==="
for marker in \
  "STAGE_8I_ROUTER_SHADOW_READ_STUB_V1" \
  "const ROUTER_SHADOW_READ_ENABLED = false" \
  "buildRouterShadowReadPayload" \
  "extractRouterDecisionContract" \
  "isRouterDecisionShadowSafe" \
  "routerShadowRead"; do
  if grep -q "$marker" "$STUB"; then
    echo "OK: stub marker found: $marker"
  else
    echo "FAIL: stub marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== prove stub is not wired into live frontend files ==="
if grep -q "router_shadow_read_stub" "$APP_JS" "$INDEX_HTML"; then
  echo "FAIL: stub should not be imported or loaded yet"
  grep -n "router_shadow_read_stub" "$APP_JS" "$INDEX_HTML" || true
  fail=1
else
  echo "OK: stub is not referenced by app.js or index.html"
fi

if grep -q "/api/router/dry-run" "$APP_JS"; then
  echo "FAIL: app.js should not call router dry-run yet"
  grep -n "/api/router/dry-run" "$APP_JS" || true
  fail=1
else
  echo "OK: app.js does not call router dry-run"
fi

echo
echo "=== JS syntax and helper behavior checks ==="
node - <<'NODE' | tee /tmp/stage8i-node-check.txt
const {
  ROUTER_SHADOW_READ_ENABLED,
  buildRouterShadowReadPayload,
  extractRouterDecisionContract,
  isRouterDecisionShadowSafe,
  routerShadowRead,
} = require("./frontend/wrapper-ui/router_shadow_read_stub.js");

async function main() {
  if (ROUTER_SHADOW_READ_ENABLED !== false) {
    throw new Error("shadow read must be disabled by default");
  }

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
      intent_key: "study.card.next",
      legacy_intent_name: "study.next",
      confidence: 0.98,
      needs_confirmation: false,
      dispatch_performed: false,
      allowed_to_dispatch: false,
      eligible_for_dispatch: false,
      model_call_required: false,
      dispatch_plan: {
        would_dispatch: false,
      },
    },
  });

  if (decision.selected_path !== "study_command") throw new Error("bad selected_path");
  if (decision.intent_key !== "study.card.next") throw new Error("bad intent_key");
  if (decision.dispatch_performed !== false) throw new Error("dispatch_performed must be false");
  if (decision.allowed_to_dispatch !== false) throw new Error("allowed_to_dispatch must be false");
  if (decision.would_dispatch !== false) throw new Error("would_dispatch must be false");
  if (isRouterDecisionShadowSafe(decision) !== true) throw new Error("safe decision should pass");

  const skipped = await routerShadowRead(async () => {
    throw new Error("api function should not be called while disabled");
  }, payload);

  if (skipped.skipped !== true) throw new Error("shadow read should skip while disabled");
  if (skipped.reason !== "router_shadow_read_disabled") throw new Error("wrong disabled reason");
  if (skipped.dispatch_performed !== false) throw new Error("disabled result dispatch_performed must be false");
  if (skipped.allowed_to_dispatch !== false) throw new Error("disabled result allowed_to_dispatch must be false");
  if (skipped.would_dispatch !== false) throw new Error("disabled result would_dispatch must be false");

  console.log("PASS: Stage 8I node helper checks passed");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
NODE

if ! grep -q "PASS: Stage 8I node helper checks passed" /tmp/stage8i-node-check.txt; then
  echo "FAIL: node helper checks failed"
  fail=1
fi

echo
echo "=== live router endpoint must remain disabled ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8i-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8i-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8i-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8i-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8i-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8i-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8i-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8i-system-status.json)"

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
  echo "PASS: Stage 8I disabled frontend router shadow-read stub verified"
else
  echo "FAIL: Stage 8I smoke found an issue"
fi
