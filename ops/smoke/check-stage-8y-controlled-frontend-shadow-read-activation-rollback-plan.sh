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

REPORT="docs/generated/stage-8y-controlled-frontend-shadow-read-activation-rollback-plan.md"
SMOKE="ops/smoke/check-stage-8y-controlled-frontend-shadow-read-activation-rollback-plan.sh"
STAGE8X_EVIDENCE="docs/generated/stage-8x-live-served-frontend-router-shadow-read-disabled-boundary-evidence.json"

APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

LIVE_STUB="/tmp/stage8y-live-router-shadow-read-stub.js"
LIVE_APP="/tmp/stage8y-live-app.js"

echo "=== Stage 8Y smoke: controlled frontend shadow-read activation rollback plan only ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 8Y report exists" || check_fail "Stage 8Y report missing"
[ -x "$SMOKE" ] && pass "Stage 8Y smoke script is executable" || check_fail "Stage 8Y smoke script missing or not executable"

for needle in \
  "Stage 8Y does not enable browser router traffic." \
  "Stage 8Y does not enable backend router dry-run." \
  "Stage 8Y does not restart live services." \
  "Stage 8X evidence final_result remains pass." \
  "frontend/wrapper-ui/router_shadow_read_stub.js contains /api/router/dry-run." \
  "frontend/wrapper-ui/app.js contains no /api/router/dry-run." \
  "frontend/wrapper-ui/app.js is not wired to sendRouterDryRunShadowRead." \
  "ROUTER_SHADOW_READ_ENABLED = false" \
  "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false" \
  "POST /api/router/dry-run remains HTTP 404." \
  "Stage 8Z may perform a controlled full-stack shadow-read activation only if explicitly chosen."
do
  if grep -Fq "$needle" "$REPORT" 2>/dev/null; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

echo
echo "=== Stage 8X evidence checks ==="
if [ -f "$STAGE8X_EVIDENCE" ]; then
  pass "Stage 8X evidence exists"
else
  check_fail "missing Stage 8X evidence"
fi

python3 - "$STAGE8X_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    print("CHECK: Stage 8X evidence missing")
    sys.exit(1)

data = json.loads(path.read_text(encoding="utf-8"))

expected = {
    "final_result": "pass",
    "local_runtime": "pass",
    "live_stub_code": "200",
    "live_runtime": "pass",
    "post_code": "404",
    "queue_clean": "true",
}

bad = []
for key, value in expected.items():
    actual = str(data.get(key))
    print(f"{key}={actual}")
    if actual != value:
        bad.append((key, value, actual))

if bad:
    print("CHECK: Stage 8X evidence values did not match expected")
    for key, expected_value, actual in bad:
        print(f"  {key}: expected={expected_value} actual={actual}")
    sys.exit(2)

print("PASS: Stage 8X evidence confirms disabled live-served frontend boundary")
PY
evidence_check=$?
if [ "$evidence_check" = "0" ]; then
  pass "Stage 8X evidence values confirmed"
else
  check_fail "Stage 8X evidence validation failed"
fi

echo
echo "=== local frontend safety checks ==="
[ -f "$APP_JS" ] && pass "app.js exists" || check_fail "missing $APP_JS"
[ -f "$STUB" ] && pass "router shadow-read stub exists" || check_fail "missing $STUB"

if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js must not contain /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" 2>/dev/null | sed -n '1,80p'
else
  pass "app.js contains no /api/router/dry-run"
fi

if grep -q "sendRouterDryRunShadowRead" "$APP_JS" 2>/dev/null; then
  check_fail "app.js is wired to sendRouterDryRunShadowRead"
  grep -n "sendRouterDryRunShadowRead" "$APP_JS" 2>/dev/null | sed -n '1,80p'
else
  pass "app.js is not wired to sendRouterDryRunShadowRead"
fi

if grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$STUB" 2>/dev/null; then
  pass "stub contains backend dry-run endpoint boundary"
else
  check_fail "stub missing backend dry-run endpoint boundary"
fi

grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_ENABLED remains false" \
  || check_fail "ROUTER_SHADOW_READ_ENABLED=false marker missing"

grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
  || check_fail "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"

echo
echo "=== local disabled-boundary runtime check ==="
if command -v node >/dev/null 2>&1; then
  node <<'NODE'
const fs = require("fs");
const vm = require("vm");

function checkStub(code, label) {
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
    navigator: { userAgent: label },
    location: { href: "http://localhost/" + label },
    localStorage: {
      getItem: () => null,
      setItem: () => {},
      removeItem: () => {}
    },
    fetch: async () => {
      fetchCalls += 1;
      return { ok: true, status: 200, json: async () => ({ ok: true }) };
    },
    setTimeout,
    clearTimeout
  };

  vm.createContext(sandbox);
  vm.runInContext(code, sandbox, { filename: label + ".js" });

  const shadow = sandbox.window.EdgeRouterShadowRead;
  if (!shadow) throw new Error(label + ": EdgeRouterShadowRead namespace missing");
  if (shadow.ROUTER_SHADOW_READ_ENABLED !== false) throw new Error(label + ": enabled flag must be false");
  if (shadow.ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT !== false) throw new Error(label + ": feature default must be false");
  if (shadow.ROUTER_DRY_RUN_ENDPOINT !== "/api/router/dry-run") throw new Error(label + ": endpoint mismatch");
  if (typeof shadow.sendRouterDryRunShadowRead !== "function") throw new Error(label + ": send helper missing");

  return Promise.resolve(
    shadow.sendRouterDryRunShadowRead(
      { text: label + " disabled check" },
      { fetch: async () => {
        fetchCalls += 1;
        return { ok: true, status: 200, json: async () => ({ ok: true }) };
      }}
    )
  ).then((result) => {
    if (!result || result.skipped !== true) throw new Error(label + ": disabled call must skip");
    if (result.reason !== "router_shadow_read_disabled") throw new Error(label + ": disabled reason mismatch");
    if (fetchCalls !== 0) throw new Error(label + ": fetch was called while disabled");
    console.log("PASS: " + label + " disabled helper skipped without fetch");
  });
}

const code = fs.readFileSync("frontend/wrapper-ui/router_shadow_read_stub.js", "utf8");
checkStub(code, "stage8y-local").catch((error) => {
  console.error("CHECK:", error.message || error);
  process.exit(1);
});
NODE
  node_check=$?
  if [ "$node_check" = "0" ]; then
    pass "local disabled-boundary runtime check passed"
  else
    check_fail "local disabled-boundary runtime check failed"
  fi
else
  check_fail "node is not available for disabled-boundary runtime check"
fi

echo
echo "=== live-served frontend safety checks ==="
live_stub_code="$(curl -sS --max-time 8 -o "$LIVE_STUB" -w "%{http_code}" "$FRONTEND_BASE/router_shadow_read_stub.js" 2>/tmp/stage8y-live-stub.err || printf 'curl_failed')"
live_app_code="$(curl -sS --max-time 8 -o "$LIVE_APP" -w "%{http_code}" "$FRONTEND_BASE/app.js" 2>/tmp/stage8y-live-app.err || printf 'curl_failed')"

echo "live_stub_code=$live_stub_code"
echo "live_app_code=$live_app_code"

if [ "$live_app_code" = "200" ]; then
  pass "live-served app.js fetched with HTTP 200"
  if grep -q "/api/router/dry-run" "$LIVE_APP" 2>/dev/null; then
    check_fail "live-served app.js contains /api/router/dry-run"
    grep -n "/api/router/dry-run" "$LIVE_APP" 2>/dev/null | sed -n '1,80p'
  else
    pass "live-served app.js contains no /api/router/dry-run"
  fi

  if grep -q "sendRouterDryRunShadowRead" "$LIVE_APP" 2>/dev/null; then
    check_fail "live-served app.js is wired to sendRouterDryRunShadowRead"
    grep -n "sendRouterDryRunShadowRead" "$LIVE_APP" 2>/dev/null | sed -n '1,80p'
  else
    pass "live-served app.js is not wired to sendRouterDryRunShadowRead"
  fi
else
  check_fail "could not fetch live-served app.js"
  sed -n '1,80p' /tmp/stage8y-live-app.err 2>/dev/null || true
fi

if [ "$live_stub_code" = "200" ]; then
  pass "live-served router_shadow_read_stub.js fetched with HTTP 200"
  grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$LIVE_STUB" 2>/dev/null \
    && pass "live-served stub contains backend dry-run endpoint boundary" \
    || check_fail "live-served stub missing backend dry-run endpoint boundary"

  grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$LIVE_STUB" 2>/dev/null \
    && pass "live-served ROUTER_SHADOW_READ_ENABLED remains false" \
    || check_fail "live-served ROUTER_SHADOW_READ_ENABLED=false marker missing"

  grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$LIVE_STUB" 2>/dev/null \
    && pass "live-served ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
    || check_fail "live-served ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"
else
  check_fail "could not fetch live-served router shadow-read stub"
  sed -n '1,80p' /tmp/stage8y-live-stub.err 2>/dev/null || true
fi

echo
echo "=== live backend disabled checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage8y-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage8y-health.err || printf 'curl_failed')"
echo "health_code=$health_code"
if [ "$health_code" = "200" ]; then
  pass "live controller /health returned HTTP 200"
else
  check_fail "live controller /health did not return HTTP 200"
  sed -n '1,80p' /tmp/stage8y-health.err 2>/dev/null || true
fi

post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage8y disabled checkpoint","source":"stage8y","surface":"backend-only"}' \
  -o /tmp/stage8y-router-post.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage8y-router-post.err || printf 'curl_failed')"
echo "post_code=$post_code"

if [ "$post_code" = "404" ]; then
  pass "POST /api/router/dry-run remains HTTP 404"
else
  check_fail "POST /api/router/dry-run did not remain HTTP 404"
  sed -n '1,120p' /tmp/stage8y-router-post.out 2>/dev/null || true
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
queue_code="$(curl -sS --max-time 5 -o /tmp/stage8y-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage8y-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage8y-system-status.json <<'PY'
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
  fi
else
  check_fail "could not read queue/system status"
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
echo "=== Stage 8Y smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8Y controlled frontend activation/rollback plan verified without enablement"
else
  echo "FAIL: Stage 8Y controlled frontend activation/rollback plan found issues"
fi

exit "$fail"
