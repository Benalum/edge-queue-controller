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
cd "$ROOT" || {
  echo "CHECK: could not cd into repo root"
  exit 1
}

REPORT="docs/generated/stage-9e-live-served-disabled-browser-surface-bridge-verification.md"
EVIDENCE="docs/generated/stage-9e-live-served-disabled-browser-surface-bridge-verification-evidence.json"
SMOKE="ops/smoke/check-stage-9e-live-served-disabled-browser-surface-bridge-verification.sh"
STAGE9D_EVIDENCE="docs/generated/stage-9d-disabled-narrow-browser-surface-shadow-read-wiring-evidence.json"

APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

LIVE_APP="/tmp/stage9e-live-app.js"
LIVE_STUB="/tmp/stage9e-live-router-shadow-read-stub.js"
LIVE_APP_BLOCK="/tmp/stage9e-live-app-block.js"

export STAGE9E_FINAL_RESULT="unknown"
export STAGE9E_LIVE_APP_CODE="unknown"
export STAGE9E_LIVE_STUB_CODE="unknown"
export STAGE9E_LIVE_DISABLED_RUNTIME="unknown"
export STAGE9E_HEALTH_CODE="unknown"
export STAGE9E_POST_CODE="unknown"
export STAGE9E_ENV_ABSENT="unknown"
export STAGE9E_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
data = {
    "stage": "9E",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "live-served disabled browser-surface bridge verification",
    "live_app_code": os.environ.get("STAGE9E_LIVE_APP_CODE"),
    "live_stub_code": os.environ.get("STAGE9E_LIVE_STUB_CODE"),
    "live_disabled_runtime": os.environ.get("STAGE9E_LIVE_DISABLED_RUNTIME"),
    "health_code": os.environ.get("STAGE9E_HEALTH_CODE"),
    "post_code": os.environ.get("STAGE9E_POST_CODE"),
    "env_absent": os.environ.get("STAGE9E_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE9E_QUEUE_CLEAN"),
    "final_result": os.environ.get("STAGE9E_FINAL_RESULT"),
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {path}")
PY
}

echo "=== Stage 9E smoke: live-served disabled browser-surface bridge verification ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 9E report exists" || check_fail "Stage 9E report missing"
[ -x "$SMOKE" ] && pass "Stage 9E smoke script is executable" || check_fail "Stage 9E smoke script missing or not executable"

for needle in \
  "Stage 9E verifies the pushed/live-served disabled browser-surface shadow-read bridge." \
  "Stage 9E does not modify frontend/wrapper-ui/app.js." \
  "Stage 9E does not enable browser router traffic." \
  "Stage 9E does not enable backend router dry-run." \
  "Stage 9E does not restart live services." \
  "Stage 9E does not send frontend router POST traffic." \
  "Stage 9D evidence final_result remains pass." \
  "frontend/wrapper-ui/app.js contains EdgeRouterShadowReadSurface." \
  "frontend/wrapper-ui/app.js contains requestBrowserSurfaceRouterShadowRead." \
  "frontend/wrapper-ui/app.js contains no /api/router/dry-run." \
  "Live-served app.js contains EdgeRouterShadowReadSurface." \
  "Live-served app.js contains requestBrowserSurfaceRouterShadowRead." \
  "Live-served app.js contains no /api/router/dry-run." \
  "Live-served disabled browser-surface bridge returns router_shadow_read_surface_disabled." \
  "Live-served disabled browser-surface bridge does not call fetch." \
  "Live-served disabled browser-surface bridge does not call sendRouterDryRunShadowRead." \
  "POST /api/router/dry-run remains HTTP 404." \
  "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent."
do
  if grep -Fq "$needle" "$REPORT"; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

echo
echo "=== Stage 9D evidence validation ==="
if [ -f "$STAGE9D_EVIDENCE" ]; then
  pass "Stage 9D evidence exists"
else
  check_fail "Stage 9D evidence missing"
fi

python3 - "$STAGE9D_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    sys.exit(1)

data = json.loads(path.read_text(encoding="utf-8"))
checks = {
    "final_result": {"pass"},
    "local_disabled_runtime": {"pass"},
    "post_code": {"404"},
    "env_absent": {"true", "True"},
    "queue_clean": {"true", "True"},
}

bad = []
for key, allowed in checks.items():
    actual = str(data.get(key))
    print(f"{key}={actual}")
    if actual not in allowed:
        bad.append((key, sorted(allowed), actual))

if bad:
    print("CHECK: Stage 9D evidence did not match expected values")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 9D evidence confirms disabled bridge and rollback-safe state")
PY
if [ "$?" = "0" ]; then
  pass "Stage 9D evidence values confirmed"
else
  check_fail "Stage 9D evidence validation failed"
fi

echo
echo "=== local static state checks ==="
[ -f "$APP_JS" ] && pass "app.js exists" || check_fail "missing $APP_JS"
[ -f "$STUB" ] && pass "router shadow-read stub exists" || check_fail "missing $STUB"

grep -q "EdgeRouterShadowReadSurface" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadSurface" \
  || check_fail "app.js missing EdgeRouterShadowReadSurface"

grep -q "requestBrowserSurfaceRouterShadowRead" "$APP_JS" 2>/dev/null \
  && pass "app.js contains requestBrowserSurfaceRouterShadowRead" \
  || check_fail "app.js missing requestBrowserSurfaceRouterShadowRead"

if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js directly contains /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" | sed -n '1,80p'
else
  pass "app.js contains no /api/router/dry-run"
fi

grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$STUB" 2>/dev/null \
  && pass "stub contains backend dry-run endpoint boundary" \
  || check_fail "stub missing backend dry-run endpoint boundary"

grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_ENABLED remains false" \
  || check_fail "ROUTER_SHADOW_READ_ENABLED=false marker missing"

grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
  || check_fail "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"

echo
echo "=== live-served static checks ==="
live_app_code="$(curl -sS --max-time 8 -o "$LIVE_APP" -w "%{http_code}" "$FRONTEND_BASE/app.js" 2>/tmp/stage9e-live-app.err || printf 'curl_failed')"
live_stub_code="$(curl -sS --max-time 8 -o "$LIVE_STUB" -w "%{http_code}" "$FRONTEND_BASE/router_shadow_read_stub.js" 2>/tmp/stage9e-live-stub.err || printf 'curl_failed')"
STAGE9E_LIVE_APP_CODE="$live_app_code"
STAGE9E_LIVE_STUB_CODE="$live_stub_code"
export STAGE9E_LIVE_APP_CODE STAGE9E_LIVE_STUB_CODE

echo "live_app_code=$live_app_code"
echo "live_stub_code=$live_stub_code"

if [ "$live_app_code" = "200" ]; then
  pass "live-served app.js fetched with HTTP 200"

  grep -q "EdgeRouterShadowReadSurface" "$LIVE_APP" 2>/dev/null \
    && pass "live-served app.js contains EdgeRouterShadowReadSurface" \
    || check_fail "live-served app.js missing EdgeRouterShadowReadSurface"

  grep -q "requestBrowserSurfaceRouterShadowRead" "$LIVE_APP" 2>/dev/null \
    && pass "live-served app.js contains requestBrowserSurfaceRouterShadowRead" \
    || check_fail "live-served app.js missing requestBrowserSurfaceRouterShadowRead"

  if grep -q "/api/router/dry-run" "$LIVE_APP" 2>/dev/null; then
    check_fail "live-served app.js contains /api/router/dry-run"
    grep -n "/api/router/dry-run" "$LIVE_APP" | sed -n '1,80p'
  else
    pass "live-served app.js contains no /api/router/dry-run"
  fi
else
  check_fail "could not fetch live-served app.js"
fi

if [ "$live_stub_code" = "200" ]; then
  pass "live-served router_shadow_read_stub.js fetched with HTTP 200"
  grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$LIVE_STUB" 2>/dev/null \
    && pass "live-served stub contains backend dry-run endpoint boundary" \
    || check_fail "live-served stub missing endpoint boundary"

  grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$LIVE_STUB" 2>/dev/null \
    && pass "live-served ROUTER_SHADOW_READ_ENABLED remains false" \
    || check_fail "live-served ROUTER_SHADOW_READ_ENABLED=false marker missing"

  grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$LIVE_STUB" 2>/dev/null \
    && pass "live-served ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
    || check_fail "live-served ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"
else
  check_fail "could not fetch live-served router shadow-read stub"
fi

echo
echo "=== live-served disabled runtime check ==="
if command -v node >/dev/null 2>&1 && [ "$live_app_code" = "200" ] && [ "$live_stub_code" = "200" ]; then
  python3 - "$LIVE_APP" "$LIVE_APP_BLOCK" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1]).read_text(encoding="utf-8")
out = Path(sys.argv[2])

start = "// Stage 9D disabled narrow browser-surface router shadow-read wiring."
end = "// End Stage 9D disabled narrow browser-surface router shadow-read wiring."

if start not in source or end not in source:
    raise SystemExit("missing Stage 9D block markers in live-served app.js")

block = source.split(start, 1)[1].split(end, 1)[0]
out.write_text(start + block + end + "\n", encoding="utf-8")
PY
  extract_check=$?

  if [ "$extract_check" = "0" ]; then
    node <<'NODE'
const fs = require("fs");
const vm = require("vm");

const stub = fs.readFileSync("/tmp/stage9e-live-router-shadow-read-stub.js", "utf8");
const appBlock = fs.readFileSync("/tmp/stage9e-live-app-block.js", "utf8");

let fetchCalls = 0;
let stubCalls = 0;

const sandbox = {
  console,
  window: {},
  document: {
    addEventListener: () => {},
    removeEventListener: () => {},
    querySelector: () => null,
    querySelectorAll: () => []
  },
  navigator: { userAgent: "stage9e-live-disabled-runtime" },
  location: { href: "http://127.0.0.1:8787/stage9e" },
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
vm.runInContext(stub, sandbox, { filename: "stage9e-live-stub.js" });
vm.runInContext(appBlock, sandbox, { filename: "stage9e-live-app-block.js" });

const surface = sandbox.window.EdgeRouterShadowReadSurface;
if (!surface) throw new Error("EdgeRouterShadowReadSurface missing");
if (typeof surface.requestBrowserSurfaceRouterShadowRead !== "function") {
  throw new Error("requestBrowserSurfaceRouterShadowRead missing");
}

sandbox.window.EdgeRouterShadowRead.sendRouterDryRunShadowRead = async () => {
  stubCalls += 1;
  throw new Error("sendRouterDryRunShadowRead should not be called while disabled");
};

Promise.resolve(
  surface.requestBrowserSurfaceRouterShadowRead("manual-diagnostic", {
    text: "stage9e live disabled runtime"
  })
).then((result) => {
  if (!result || result.skipped !== true) throw new Error("disabled bridge must skip");
  if (result.reason !== "router_shadow_read_surface_disabled") throw new Error("disabled reason mismatch");
  if (result.dispatch_requested !== false) throw new Error("dispatch_requested must be false");
  if (result.dispatch_performed !== false) throw new Error("dispatch_performed must be false");
  if (fetchCalls !== 0) throw new Error("fetch was called while disabled");
  if (stubCalls !== 0) throw new Error("stub send helper was called while disabled");
  console.log("PASS: live-served disabled bridge skipped without fetch or stub call");
}).catch((error) => {
  console.error("CHECK:", error.message || error);
  process.exit(1);
});
NODE
    runtime_check=$?
  else
    runtime_check=1
  fi

  if [ "$runtime_check" = "0" ]; then
    STAGE9E_LIVE_DISABLED_RUNTIME="pass"
    export STAGE9E_LIVE_DISABLED_RUNTIME
    pass "live-served disabled runtime check passed"
  else
    STAGE9E_LIVE_DISABLED_RUNTIME="fail"
    export STAGE9E_LIVE_DISABLED_RUNTIME
    check_fail "live-served disabled runtime check failed"
  fi
else
  STAGE9E_LIVE_DISABLED_RUNTIME="not_run"
  export STAGE9E_LIVE_DISABLED_RUNTIME
  check_fail "node or live-served files unavailable for runtime check"
fi

echo
echo "=== backend disabled state checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage9e-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage9e-health.err || printf 'curl_failed')"
STAGE9E_HEALTH_CODE="$health_code"
export STAGE9E_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage9e live disabled bridge checkpoint","source":"stage9e","surface":"backend-only"}' \
  -o /tmp/stage9e-router-post.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage9e-router-post.err || printf 'curl_failed')"
STAGE9E_POST_CODE="$post_code"
export STAGE9E_POST_CODE
echo "post_code=$post_code"

if [ "$post_code" = "404" ]; then
  pass "POST /api/router/dry-run remains HTTP 404"
else
  check_fail "POST /api/router/dry-run did not remain HTTP 404"
fi

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -E 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED|ROUTER|INTENT|DRY_RUN|SHADOW' || true

if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE9E_ENV_ABSENT="false"
  export STAGE9E_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE9E_ENV_ABSENT="true"
  export STAGE9E_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage9e-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage9e-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage9e-system-status.json <<'PY'
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
    STAGE9E_QUEUE_CLEAN="true"
    export STAGE9E_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE9E_QUEUE_CLEAN="false"
    export STAGE9E_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE9E_QUEUE_CLEAN="status_failed"
  export STAGE9E_QUEUE_CLEAN
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
echo "=== write Stage 9E evidence ==="
if [ "$fail" = "0" ]; then
  STAGE9E_FINAL_RESULT="pass"
else
  STAGE9E_FINAL_RESULT="fail"
fi
export STAGE9E_FINAL_RESULT
write_evidence

echo
echo "=== Stage 9E smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 9E live-served disabled browser-surface bridge verified"
else
  echo "FAIL: Stage 9E live-served disabled browser-surface bridge found issues"
fi

exit "$fail"
