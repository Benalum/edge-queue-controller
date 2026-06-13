#!/usr/bin/env bash
set -u

fail=0

pass() {
  echo "PASS: $1"
}

check_fail() {
  echo "CHECK: $1"
  fail=1
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
if [ -z "${ROOT:-}" ] || [ ! -d "$ROOT" ]; then
  check_fail "could not resolve repo root"
  ROOT="."
fi

cd "$ROOT" || check_fail "could not cd into repo root"

REPORT="docs/generated/stage-8w-frontend-router-shadow-read-disabled-call-boundary.md"
SMOKE="ops/smoke/check-stage-8w-frontend-router-shadow-read-disabled-call-boundary.sh"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

echo "=== Stage 8W smoke: frontend shadow-read disabled call boundary ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 8W report exists" || check_fail "Stage 8W report missing"
[ -x "$SMOKE" ] && pass "Stage 8W smoke script is executable" || check_fail "Stage 8W smoke script missing or not executable"

for needle in \
  "Stage 8W implements a frontend shadow-read call boundary without enabling browser router traffic." \
  "This stage intentionally adds /api/router/dry-run only to frontend/wrapper-ui/router_shadow_read_stub.js." \
  "frontend/wrapper-ui/app.js contains no /api/router/dry-run." \
  "frontend/wrapper-ui/app.js is not wired to sendRouterDryRunShadowRead." \
  "ROUTER_SHADOW_READ_ENABLED = false" \
  "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false" \
  "Disabled helper does not call fetch while flags are false." \
  "POST /api/router/dry-run remains HTTP 404." \
  "Stage 8X should not enable browser router traffic."
do
  if grep -Fq "$needle" "$REPORT" 2>/dev/null; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

echo
echo "=== frontend file boundary checks ==="
[ -f "$APP_JS" ] && pass "app.js exists" || check_fail "missing $APP_JS"
[ -f "$STUB" ] && pass "router shadow-read stub exists" || check_fail "missing $STUB"

if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js must not contain /api/router/dry-run at Stage 8W"
  grep -n "/api/router/dry-run" "$APP_JS" 2>/dev/null | sed -n '1,80p'
else
  pass "app.js contains no /api/router/dry-run"
fi

if grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$STUB" 2>/dev/null; then
  pass "stub contains the backend dry-run endpoint boundary"
else
  check_fail "stub missing ROUTER_DRY_RUN_ENDPOINT boundary"
fi

if grep -q "sendRouterDryRunShadowRead" "$APP_JS" 2>/dev/null; then
  check_fail "app.js is wired to sendRouterDryRunShadowRead"
  grep -n "sendRouterDryRunShadowRead" "$APP_JS" 2>/dev/null | sed -n '1,80p'
else
  pass "app.js is not wired to sendRouterDryRunShadowRead"
fi

if grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" 2>/dev/null; then
  pass "ROUTER_SHADOW_READ_ENABLED remains false"
else
  check_fail "ROUTER_SHADOW_READ_ENABLED=false marker missing"
fi

if grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" 2>/dev/null; then
  pass "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false"
else
  check_fail "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"
fi

for needle in \
  "function buildRouterDryRunShadowReadRequest" \
  "async function sendRouterDryRunShadowRead" \
  "router_shadow_read_disabled" \
  "dispatch_requested: false" \
  "dispatch_performed: false"
do
  if grep -Fq "$needle" "$STUB" 2>/dev/null; then
    pass "stub contains: $needle"
  else
    check_fail "stub missing: $needle"
  fi
done

echo
echo "=== JavaScript disabled-boundary runtime check ==="
if command -v node >/dev/null 2>&1; then
  node <<'NODE'
const fs = require("fs");
const vm = require("vm");

const code = fs.readFileSync("frontend/wrapper-ui/router_shadow_read_stub.js", "utf8");
let fetchCalls = 0;

const sandbox = {
  console,
  window: {},
  document: {
    addEventListener: () => {},
    removeEventListener: () => {},
    querySelector: () => null,
    querySelectorAll: () => []
  },
  navigator: { userAgent: "stage8w-smoke" },
  location: { href: "http://localhost/stage8w" },
  localStorage: {
    getItem: () => null,
    setItem: () => {},
    removeItem: () => {}
  },
  fetch: async () => {
    fetchCalls += 1;
    return {
      ok: true,
      status: 200,
      json: async () => ({ ok: true })
    };
  },
  setTimeout,
  clearTimeout
};

vm.createContext(sandbox);
vm.runInContext(code, sandbox, { filename: "router_shadow_read_stub.js" });

const shadow = sandbox.window.EdgeRouterShadowRead;
if (!shadow) {
  throw new Error("EdgeRouterShadowRead namespace missing");
}
if (shadow.ROUTER_SHADOW_READ_ENABLED !== false) {
  throw new Error("ROUTER_SHADOW_READ_ENABLED must remain false");
}
if (shadow.ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT !== false) {
  throw new Error("ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT must remain false");
}
if (shadow.ROUTER_DRY_RUN_ENDPOINT !== "/api/router/dry-run") {
  throw new Error("ROUTER_DRY_RUN_ENDPOINT mismatch");
}
if (typeof shadow.buildRouterDryRunShadowReadRequest !== "function") {
  throw new Error("buildRouterDryRunShadowReadRequest missing");
}
if (typeof shadow.sendRouterDryRunShadowRead !== "function") {
  throw new Error("sendRouterDryRunShadowRead missing");
}

const built = shadow.buildRouterDryRunShadowReadRequest({
  text: "stage8w runtime smoke",
  source: "stage8w",
  surface: "node-vm"
});

if (built.dry_run !== true) {
  throw new Error("request must mark dry_run=true");
}
if (built.dispatch_requested !== false || built.dispatch_performed !== false) {
  throw new Error("request must be non-dispatching");
}

Promise.resolve(
  shadow.sendRouterDryRunShadowRead(
    { text: "stage8w disabled call" },
    {
      fetch: async () => {
        fetchCalls += 1;
        return {
          ok: true,
          status: 200,
          json: async () => ({ ok: true })
        };
      }
    }
  )
).then((result) => {
  if (!result || result.skipped !== true) {
    throw new Error("disabled send must return skipped=true");
  }
  if (result.reason !== "router_shadow_read_disabled") {
    throw new Error("disabled send reason mismatch");
  }
  if (result.dispatch_requested !== false || result.dispatch_performed !== false) {
    throw new Error("disabled send must be non-dispatching");
  }
  if (fetchCalls !== 0) {
    throw new Error("fetch was called while disabled");
  }
  console.log("PASS: Node runtime confirmed disabled helper does not fetch");
}).catch((error) => {
  console.error("CHECK:", error.message || error);
  process.exit(1);
});
NODE
  node_check=$?
  if [ "$node_check" = "0" ]; then
    pass "disabled-boundary runtime check passed"
  else
    check_fail "disabled-boundary runtime check failed"
  fi
else
  check_fail "node is not available for frontend disabled-boundary runtime check"
fi

echo
echo "=== live backend disabled checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage8w-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage8w-health.err || printf 'curl_failed')"
echo "health_code=$health_code"
if [ "$health_code" = "200" ]; then
  pass "live controller /health returned HTTP 200"
else
  check_fail "live controller /health did not return HTTP 200"
  sed -n '1,80p' /tmp/stage8w-health.err 2>/dev/null || true
  sed -n '1,80p' /tmp/stage8w-health.out 2>/dev/null || true
fi

post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage8w disabled checkpoint","source":"stage8w","surface":"backend-only"}' \
  -o /tmp/stage8w-router-post.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage8w-router-post.err || printf 'curl_failed')"
echo "post_code=$post_code"
if [ "$post_code" = "404" ]; then
  pass "POST /api/router/dry-run remains HTTP 404"
else
  check_fail "POST /api/router/dry-run did not remain HTTP 404"
  sed -n '1,120p' /tmp/stage8w-router-post.out 2>/dev/null || true
fi

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -E 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED|ROUTER|INTENT|DRY_RUN|SHADOW' || true

if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  check_fail "live controller has EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 enabled"
else
  pass "live controller does not have EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 enabled"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage8w-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage8w-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage8w-system-status.json <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

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

if not matches:
    print("MISSING_QUEUE_TRIPLE")
    sys.exit(3)

for label, queued, running, failed in matches:
    print(f"{label}: queued={queued} running={running} failed={failed}")

clean = any(str(q) == "0" and str(r) == "0" and str(f) == "0" for _, q, r, f in matches)
sys.exit(0 if clean else 2)
PY
  queue_check=$?
  if [ "$queue_check" = "0" ]; then
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    check_fail "queue clean state was not confirmed"
    sed -n '1,160p' /tmp/stage8w-system-status.json 2>/dev/null || true
  fi
else
  check_fail "could not read queue/system status"
  sed -n '1,80p' /tmp/stage8w-system-status.err 2>/dev/null || true
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
  ss -ltnp | grep ':7076' || true
else
  pass "port 7076 is not listening"
fi

echo
echo "=== Stage 8W smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8W disabled frontend call boundary verified without browser traffic"
else
  echo "FAIL: Stage 8W disabled frontend call boundary found issues"
fi

exit "$fail"
