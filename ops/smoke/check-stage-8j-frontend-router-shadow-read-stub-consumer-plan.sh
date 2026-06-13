#!/usr/bin/env bash
set -u

echo "=== Stage 8J smoke: frontend router shadow-read stub consumer plan ==="

fail=0

DOC="docs/stage-8j-frontend-router-shadow-read-stub-consumer-plan.md"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"
APP_JS="frontend/wrapper-ui/app.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
FIXTURE_8G="docs/generated/stage-8g-router-decision-contract-consumer-fixtures.json"
AUDIT_8H="docs/generated/stage-8h-frontend-router-shadow-read-hook-audit.json"
PLAN="docs/generated/stage-8j-frontend-router-shadow-read-stub-consumer-plan.json"

for f in "$DOC" "$STUB" "$APP_JS" "$INDEX_HTML" "$FIXTURE_8G" "$AUDIT_8H"; do
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
  "Frontend Router Shadow-Read Stub Consumer Plan" \
  "Stage 8G" \
  "Stage 8H" \
  "First Safe Wiring Plan" \
  "Stage 8K"; do
  if grep -q "$marker" "$DOC"; then
    echo "OK: doc marker found: $marker"
  else
    echo "FAIL: doc marker missing: $marker"
    fail=1
  fi
done

echo
echo "=== prove stub remains not wired ==="
if grep -q "router_shadow_read_stub" "$APP_JS" "$INDEX_HTML"; then
  echo "FAIL: stub should not be referenced by app.js or index.html yet"
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
echo "=== validate source fixtures ==="
python3 -m json.tool "$FIXTURE_8G" >/dev/null || fail=1
python3 -m json.tool "$AUDIT_8H" >/dev/null || fail=1

echo
echo "=== node consumer-plan checks ==="
node - <<'NODE' | tee /tmp/stage8j-node-check.txt
const fs = require("fs");

const {
  ROUTER_SHADOW_READ_ENABLED,
  buildRouterShadowReadPayload,
  extractRouterDecisionContract,
  isRouterDecisionShadowSafe,
  routerShadowRead,
} = require("./frontend/wrapper-ui/router_shadow_read_stub.js");

async function main() {
  if (ROUTER_SHADOW_READ_ENABLED !== false) {
    throw new Error("stub must remain disabled by default");
  }

  const fixture8g = JSON.parse(
    fs.readFileSync("docs/generated/stage-8g-router-decision-contract-consumer-fixtures.json", "utf8")
  );

  const audit8h = JSON.parse(
    fs.readFileSync("docs/generated/stage-8h-frontend-router-shadow-read-hook-audit.json", "utf8")
  );

  if (fixture8g.stage !== "8G") throw new Error("bad Stage 8G fixture");
  if (audit8h.stage !== "8H") throw new Error("bad Stage 8H audit");

  const requiredPaths = new Set(["study_command", "companion_chat", "unsupported"]);
  const seenPaths = new Set();

  for (const item of fixture8g.fixtures || []) {
    const view = item.consumer_view || {};
    seenPaths.add(view.selected_path);

    const extracted = extractRouterDecisionContract({
      decision_contract: {
        selected_path: view.selected_path,
        intent_key: view.intent_key,
        legacy_intent_name: view.legacy_intent_name,
        confidence: view.confidence,
        needs_confirmation: view.needs_confirmation,
        dispatch_performed: view.dispatch_performed,
        allowed_to_dispatch: view.allowed_to_dispatch,
        eligible_for_dispatch: view.eligible_for_dispatch,
        model_call_required: view.model_call_required,
        dispatch_plan: {
          would_dispatch: view.would_dispatch,
        },
      },
    });

    if (extracted.selected_path !== view.selected_path) {
      throw new Error(`selected_path mismatch for ${item.name}`);
    }
    if (extracted.dispatch_performed !== false) {
      throw new Error(`dispatch_performed must be false for ${item.name}`);
    }
    if (extracted.allowed_to_dispatch !== false) {
      throw new Error(`allowed_to_dispatch must be false for ${item.name}`);
    }
    if (extracted.would_dispatch !== false) {
      throw new Error(`would_dispatch must be false for ${item.name}`);
    }
    if (isRouterDecisionShadowSafe(extracted) !== true) {
      throw new Error(`fixture should be shadow-safe for ${item.name}`);
    }

    console.log(`OK: fixture ${item.name}: selected_path=${extracted.selected_path}`);
  }

  for (const path of requiredPaths) {
    if (!seenPaths.has(path)) {
      throw new Error(`missing required selected_path fixture: ${path}`);
    }
  }

  const unsafeDecision = {
    selected_path: "study_command",
    dispatch_performed: false,
    allowed_to_dispatch: true,
    would_dispatch: true,
  };

  if (isRouterDecisionShadowSafe(unsafeDecision) !== false) {
    throw new Error("unsafe decision should be rejected");
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

  let apiCalled = false;
  const skipped = await routerShadowRead(async () => {
    apiCalled = true;
    throw new Error("api must not be called while disabled");
  }, payload);

  if (apiCalled) throw new Error("disabled routerShadowRead called API");
  if (skipped.skipped !== true) throw new Error("disabled routerShadowRead should skip");
  if (skipped.reason !== "router_shadow_read_disabled") throw new Error("wrong disabled reason");

  const candidateHooks = audit8h.candidate_hooks || [];
  const studyHooks = candidateHooks.filter((h) => h.surface === "study").slice(0, 8);
  const companionHooks = candidateHooks.filter((h) => h.surface === "companion").slice(0, 8);
  const sharedHooks = candidateHooks.filter((h) => h.surface === "shared").slice(0, 5);

  if (studyHooks.length === 0) throw new Error("expected Study hook candidates");
  if (companionHooks.length === 0) throw new Error("expected Companion hook candidates");

  const plan = {
    stage: "8J",
    stub_enabled: ROUTER_SHADOW_READ_ENABLED,
    source_fixture_stage: fixture8g.stage,
    source_audit_stage: audit8h.stage,
    verified_selected_paths: Array.from(seenPaths).sort(),
    first_safe_wiring_plan: {
      enabled_by_default: false,
      dispatch_allowed: false,
      model_call_allowed: false,
      user_visible_output_allowed: false,
      preferred_initial_surface: "study",
      preferred_hook_type: "near_existing_study_command_api_call",
      notes: [
        "Keep existing Study command behavior unchanged.",
        "Router shadow-read may observe only after a separate wiring stage.",
        "Do not dispatch based on router output.",
        "Do not block the user action on router response.",
      ],
    },
    candidate_hooks: {
      study: studyHooks,
      companion: companionHooks,
      shared: sharedHooks,
    },
  };

  fs.mkdirSync("docs/generated", { recursive: true });
  fs.writeFileSync(
    "docs/generated/stage-8j-frontend-router-shadow-read-stub-consumer-plan.json",
    JSON.stringify(plan, null, 2) + "\n"
  );

  console.log("wrote_plan=docs/generated/stage-8j-frontend-router-shadow-read-stub-consumer-plan.json");
  console.log("PASS: Stage 8J node consumer-plan checks passed");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
NODE

if ! grep -q "PASS: Stage 8J node consumer-plan checks passed" /tmp/stage8j-node-check.txt; then
  echo "FAIL: node consumer-plan checks failed"
  fail=1
fi

echo
echo "=== validate generated plan ==="
if [ -f "$PLAN" ]; then
  python3 -m json.tool "$PLAN" >/dev/null || fail=1
  grep -q '"stage": "8J"' "$PLAN" || fail=1
  grep -q '"stub_enabled": false' "$PLAN" || fail=1
  grep -q '"preferred_initial_surface": "study"' "$PLAN" || fail=1
  grep -q '"study_command"' "$PLAN" || fail=1
  grep -q '"companion_chat"' "$PLAN" || fail=1
  grep -q '"unsupported"' "$PLAN" || fail=1
  echo "OK: generated Stage 8J plan valid"
else
  echo "FAIL: missing generated plan $PLAN"
  fail=1
fi

echo
echo "=== live router endpoint must remain disabled ==="
for path in /api/router/dry-run /system/router/dry-run /router/dry-run; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage8j-${path//\//_}.out" -w "%{http_code}" \
    -X POST "http://127.0.0.1:7070${path}" \
    -H 'Content-Type: application/json' \
    --data '{"input":{"text":"next","source":"study","surface":"study_session"},"context":{"active_page":"study"}}' || true)"
  echo "$path code=$code"
  sed -n '1,8p' "/tmp/stage8j-${path//\//_}.out" || true

  if [ "$code" != "404" ]; then
    echo "FAIL: $path should remain disabled/not found"
    fail=1
  fi
done

echo
echo "=== platform remains clean ==="
curl -sS --max-time 10 http://127.0.0.1:7070/health | jq .

curl -sS --max-time 20 http://127.0.0.1:7070/system/status > /tmp/stage8j-system-status.json
jq '{
  overall_state,
  queue: (.services[]? | select(.id=="queue")),
  ct101_worker: (.services[]? | select(.id=="ct101-laptop-queue-worker"))
}' /tmp/stage8j-system-status.json

overall_state="$(jq -r '.overall_state' /tmp/stage8j-system-status.json)"
queue_failed="$(jq -r '.services[]? | select(.id=="queue") | .queue.failed' /tmp/stage8j-system-status.json)"
queue_queued="$(jq -r '.services[]? | select(.id=="queue") | .queue.queued' /tmp/stage8j-system-status.json)"
queue_running="$(jq -r '.services[]? | select(.id=="queue") | .queue.running' /tmp/stage8j-system-status.json)"

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
echo "=== verify no live frontend wiring changes ==="
if grep -q "router_shadow_read_stub" "$APP_JS" "$INDEX_HTML"; then
  echo "FAIL: stub should still not be wired"
  fail=1
else
  echo "OK: stub remains unwired"
fi

echo
echo "=== final repo status ==="
git status --short

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8J frontend router shadow-read stub consumer plan verified"
else
  echo "FAIL: Stage 8J smoke found an issue"
fi
