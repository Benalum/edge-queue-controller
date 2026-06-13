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

REPORT="docs/generated/stage-9k-disabled-operator-gated-browser-shadow-read-activation-boundary.md"
EVIDENCE="docs/generated/stage-9k-disabled-operator-gated-browser-shadow-read-activation-boundary-evidence.json"
SMOKE="ops/smoke/check-stage-9k-disabled-operator-gated-browser-shadow-read-activation-boundary.sh"

STAGE9G_EVIDENCE="docs/generated/stage-9g-controlled-browser-surface-activation-rollback-evidence.json"
STAGE9H_EVIDENCE="docs/generated/stage-9h-post-browser-surface-activation-rollback-stability-checkpoint-evidence.json"
STAGE9J_REPORT="docs/generated/stage-9j-operator-gated-browser-shadow-read-activation-boundary-plan.md"

APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

LIVE_APP="/tmp/stage9k-live-app.js"
LIVE_STUB="/tmp/stage9k-live-router-shadow-read-stub.js"

export STAGE9K_FINAL_RESULT="unknown"
export STAGE9K_LOCAL_DISABLED_RUNTIME="unknown"
export STAGE9K_HEALTH_CODE="unknown"
export STAGE9K_POST_CODE="unknown"
export STAGE9K_ENV_ABSENT="unknown"
export STAGE9K_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
data = {
    "stage": "9K",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "disabled operator-gated browser shadow-read activation boundary",
    "local_disabled_runtime": os.environ.get("STAGE9K_LOCAL_DISABLED_RUNTIME"),
    "health_code": os.environ.get("STAGE9K_HEALTH_CODE"),
    "post_code": os.environ.get("STAGE9K_POST_CODE"),
    "env_absent": os.environ.get("STAGE9K_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE9K_QUEUE_CLEAN"),
    "final_result": os.environ.get("STAGE9K_FINAL_RESULT"),
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {path}")
PY
}

echo "=== Stage 9K smoke: disabled operator-gated browser shadow-read activation boundary ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 9K report exists" || check_fail "Stage 9K report missing"
[ -x "$SMOKE" ] && pass "Stage 9K smoke script is executable" || check_fail "Stage 9K smoke script missing or not executable"

for needle in \
  "Stage 9K adds a disabled operator-gated browser shadow-read activation boundary." \
  "Stage 9K keeps the operator gate false by default." \
  "Stage 9K does not enable browser router traffic." \
  "Stage 9K does not enable backend router dry-run." \
  "Stage 9K does not restart live services." \
  "Stage 9K does not send frontend router POST traffic during smoke." \
  "Stage 9K does not put /api/router/dry-run directly in frontend/wrapper-ui/app.js." \
  "Stage 9K adds \`window.EdgeRouterShadowReadOperatorGate\` in \`frontend/wrapper-ui/app.js\`." \
  "Defines OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false." \
  "Wraps requestBrowserSurfaceRouterShadowRead." \
  "Returns operator_browser_shadow_read_activation_disabled while the operator gate is false." \
  "Does not call fetch while disabled." \
  "Does not call sendRouterDryRunShadowRead while disabled." \
  "frontend/wrapper-ui/app.js contains EdgeRouterShadowReadOperatorGate." \
  "frontend/wrapper-ui/app.js contains OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false." \
  "frontend/wrapper-ui/app.js contains no /api/router/dry-run." \
  "POST /api/router/dry-run remains HTTP 404." \
  "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent." \
  "Stage 9L should verify the live-served disabled operator gate after deployment."
do
  if grep -Fq "$needle" "$REPORT"; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

echo
echo "=== Stage 9G/9H/9J evidence and report validation ==="
[ -f "$STAGE9G_EVIDENCE" ] && pass "Stage 9G evidence exists" || check_fail "Stage 9G evidence missing"
[ -f "$STAGE9H_EVIDENCE" ] && pass "Stage 9H evidence exists" || check_fail "Stage 9H evidence missing"
[ -f "$STAGE9J_REPORT" ] && pass "Stage 9J report exists" || check_fail "Stage 9J report missing"

python3 - "$STAGE9G_EVIDENCE" "$STAGE9H_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

stage9g = Path(sys.argv[1])
stage9h = Path(sys.argv[2])

checks = [
    (stage9g, {
        "final_result": {"pass"},
        "post_enabled": {"200"},
        "browser_requests": {"1"},
        "browser_status": {"200"},
        "browser_surface": {"manual-diagnostic"},
        "browser_dry_run": {"True", "true"},
        "dispatch_requested": {"False", "false"},
        "dispatch_performed": {"False", "false"},
        "body_dispatch_performed": {"False", "false"},
        "post_after": {"404"},
        "rollback_env_absent": {"true", "True"},
    }),
    (stage9h, {
        "final_result": {"pass"},
        "post_code": {"404"},
        "env_absent": {"true", "True"},
        "queue_clean": {"true", "True"},
    }),
]

bad = []
for path, expected in checks:
    if not path.exists():
        bad.append((str(path), "missing", "missing"))
        continue
    data = json.loads(path.read_text(encoding="utf-8"))
    for key, allowed in expected.items():
        actual = str(data.get(key))
        print(f"{path.name}:{key}={actual}")
        if actual not in allowed:
            bad.append((f"{path.name}:{key}", sorted(allowed), actual))

if bad:
    print("CHECK: evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 9G and Stage 9H evidence values confirmed")
PY
if [ "$?" = "0" ]; then
  pass "Stage 9G/9H evidence values confirmed"
else
  check_fail "Stage 9G/9H evidence validation failed"
fi

echo
echo "=== local frontend static checks ==="
[ -f "$APP_JS" ] && pass "app.js exists" || check_fail "missing $APP_JS"
[ -f "$STUB" ] && pass "router shadow-read stub exists" || check_fail "missing $STUB"

grep -q "EdgeRouterShadowReadSurface" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadSurface" \
  || check_fail "app.js missing EdgeRouterShadowReadSurface"

grep -q "EdgeRouterShadowReadOperatorGate" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadOperatorGate" \
  || check_fail "app.js missing EdgeRouterShadowReadOperatorGate"

grep -q "OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false" "$APP_JS" 2>/dev/null \
  && pass "operator gate default remains false" \
  || check_fail "operator gate default false marker missing"

grep -q "operator_browser_shadow_read_activation_disabled" "$APP_JS" 2>/dev/null \
  && pass "app.js contains disabled operator gate reason" \
  || check_fail "app.js missing disabled operator gate reason"

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
echo "=== local disabled operator gate runtime check ==="
if command -v node >/dev/null 2>&1; then
  python3 - <<'PY'
from pathlib import Path

app = Path("frontend/wrapper-ui/app.js").read_text(encoding="utf-8")

stage9d_start = "// Stage 9D disabled narrow browser-surface router shadow-read wiring."
stage9d_end = "// End Stage 9D disabled narrow browser-surface router shadow-read wiring."
stage9k_start = "// Stage 9K disabled operator-gated browser shadow-read activation boundary."
stage9k_end = "// End Stage 9K disabled operator-gated browser shadow-read activation boundary."

for marker in (stage9d_start, stage9d_end, stage9k_start, stage9k_end):
    if marker not in app:
        raise SystemExit(f"missing marker: {marker}")

stage9d = app.split(stage9d_start, 1)[1].split(stage9d_end, 1)[0]
stage9k = app.split(stage9k_start, 1)[1].split(stage9k_end, 1)[0]

Path("/tmp/stage9k-app-blocks.js").write_text(
    stage9d_start + stage9d + stage9d_end + "\n\n" +
    stage9k_start + stage9k + stage9k_end + "\n",
    encoding="utf-8"
)
PY

  node <<'NODE'
const fs = require("fs");
const vm = require("vm");

const stub = fs.readFileSync("frontend/wrapper-ui/router_shadow_read_stub.js", "utf8");
const appBlocks = fs.readFileSync("/tmp/stage9k-app-blocks.js", "utf8");

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
  navigator: { userAgent: "stage9k-disabled-operator-gate" },
  location: { href: "http://localhost/stage9k" },
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
vm.runInContext(stub, sandbox, { filename: "router_shadow_read_stub.js" });
vm.runInContext(appBlocks, sandbox, { filename: "stage9k-app-blocks.js" });

const shadow = sandbox.window.EdgeRouterShadowRead;
const surface = sandbox.window.EdgeRouterShadowReadSurface;
const gate = sandbox.window.EdgeRouterShadowReadOperatorGate;

if (!shadow) throw new Error("EdgeRouterShadowRead missing");
if (!surface) throw new Error("EdgeRouterShadowReadSurface missing");
if (!gate) throw new Error("EdgeRouterShadowReadOperatorGate missing");

if (gate.OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED !== false) {
  throw new Error("operator gate must default false");
}
if (typeof surface.requestBrowserSurfaceRouterShadowRead !== "function") {
  throw new Error("requestBrowserSurfaceRouterShadowRead missing");
}

shadow.ROUTER_SHADOW_READ_ENABLED = true;
shadow.ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = true;

shadow.sendRouterDryRunShadowRead = async () => {
  stubCalls += 1;
  throw new Error("sendRouterDryRunShadowRead should not be called while operator gate is disabled");
};

Promise.resolve(
  surface.requestBrowserSurfaceRouterShadowRead("manual-diagnostic", {
    text: "stage9k disabled operator gate runtime"
  })
).then((result) => {
  if (!result || result.skipped !== true) throw new Error("operator gate must skip");
  if (result.reason !== "operator_browser_shadow_read_activation_disabled") {
    throw new Error("operator gate disabled reason mismatch");
  }
  if (result.dry_run !== true) throw new Error("dry_run must remain true");
  if (result.dispatch_requested !== false) throw new Error("dispatch_requested must be false");
  if (result.dispatch_performed !== false) throw new Error("dispatch_performed must be false");
  if (fetchCalls !== 0) throw new Error("fetch was called while operator gate disabled");
  if (stubCalls !== 0) throw new Error("stub send helper was called while operator gate disabled");
  console.log("PASS: disabled operator gate skipped without fetch or stub call");
}).catch((error) => {
  console.error("CHECK:", error.message || error);
  process.exit(1);
});
NODE
  runtime_check=$?
  if [ "$runtime_check" = "0" ]; then
    STAGE9K_LOCAL_DISABLED_RUNTIME="pass"
    export STAGE9K_LOCAL_DISABLED_RUNTIME
    pass "local disabled operator gate runtime check passed"
  else
    STAGE9K_LOCAL_DISABLED_RUNTIME="fail"
    export STAGE9K_LOCAL_DISABLED_RUNTIME
    check_fail "local disabled operator gate runtime check failed"
  fi
else
  STAGE9K_LOCAL_DISABLED_RUNTIME="node_missing"
  export STAGE9K_LOCAL_DISABLED_RUNTIME
  check_fail "node is not available for runtime check"
fi

echo
echo "=== live-served frontend state checks ==="
live_app_code="$(curl -sS --max-time 8 -o "$LIVE_APP" -w "%{http_code}" "$FRONTEND_BASE/app.js" 2>/tmp/stage9k-live-app.err || printf 'curl_failed')"
live_stub_code="$(curl -sS --max-time 8 -o "$LIVE_STUB" -w "%{http_code}" "$FRONTEND_BASE/router_shadow_read_stub.js" 2>/tmp/stage9k-live-stub.err || printf 'curl_failed')"

echo "live_app_code=$live_app_code"
echo "live_stub_code=$live_stub_code"

if [ "$live_app_code" = "200" ]; then
  pass "live-served app.js fetched with HTTP 200"
  grep -q "/api/router/dry-run" "$LIVE_APP" 2>/dev/null \
    && check_fail "live-served app.js contains /api/router/dry-run" \
    || pass "live-served app.js contains no /api/router/dry-run"
else
  check_fail "could not fetch live-served app.js"
fi

if [ "$live_stub_code" = "200" ]; then
  pass "live-served router_shadow_read_stub.js fetched with HTTP 200"
  grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$LIVE_STUB" 2>/dev/null \
    && pass "live-served stub contains backend dry-run endpoint boundary" \
    || check_fail "live-served stub missing endpoint boundary"
else
  check_fail "could not fetch live-served router shadow-read stub"
fi

echo
echo "=== backend disabled state checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage9k-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage9k-health.err || printf 'curl_failed')"
STAGE9K_HEALTH_CODE="$health_code"
export STAGE9K_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage9k disabled operator gate checkpoint","source":"stage9k","surface":"backend-only"}' \
  -o /tmp/stage9k-router-post.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage9k-router-post.err || printf 'curl_failed')"
STAGE9K_POST_CODE="$post_code"
export STAGE9K_POST_CODE
echo "post_code=$post_code"

if [ "$post_code" = "404" ]; then
  pass "POST /api/router/dry-run remains HTTP 404"
else
  check_fail "POST /api/router/dry-run did not remain HTTP 404"
fi

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -E 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED|ROUTER|INTENT|DRY_RUN|SHADOW' || true

if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE9K_ENV_ABSENT="false"
  export STAGE9K_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE9K_ENV_ABSENT="true"
  export STAGE9K_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage9k-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage9k-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage9k-system-status.json <<'PY'
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
    STAGE9K_QUEUE_CLEAN="true"
    export STAGE9K_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE9K_QUEUE_CLEAN="false"
    export STAGE9K_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE9K_QUEUE_CLEAN="status_failed"
  export STAGE9K_QUEUE_CLEAN
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
echo "=== write Stage 9K evidence ==="
if [ "$fail" = "0" ]; then
  STAGE9K_FINAL_RESULT="pass"
else
  STAGE9K_FINAL_RESULT="fail"
fi
export STAGE9K_FINAL_RESULT
write_evidence

echo
echo "=== Stage 9K smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 9K disabled operator-gated browser shadow-read activation boundary verified without enablement"
else
  echo "FAIL: Stage 9K disabled operator-gated browser shadow-read activation boundary found issues"
fi

exit "$fail"
