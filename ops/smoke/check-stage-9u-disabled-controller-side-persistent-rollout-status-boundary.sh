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

REPORT="docs/generated/stage-9u-disabled-controller-side-persistent-rollout-status-boundary.md"
EVIDENCE="docs/generated/stage-9u-disabled-controller-side-persistent-rollout-status-boundary-evidence.json"
SMOKE="ops/smoke/check-stage-9u-disabled-controller-side-persistent-rollout-status-boundary.sh"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

STAGE9R_EVIDENCE="docs/generated/stage-9r-disabled-persistent-operator-gated-rollout-boundary-evidence.json"
STAGE9S_EVIDENCE="docs/generated/stage-9s-live-served-disabled-persistent-rollout-verification-evidence.json"
STAGE9T_REPORT="docs/generated/stage-9t-persistent-rollout-activation-control-plane-plan.md"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

LIVE_APP="/tmp/stage9u-live-app.js"
LIVE_STUB="/tmp/stage9u-live-router-shadow-read-stub.js"

export STAGE9U_FINAL_RESULT="unknown"
export STAGE9U_SOURCE_STATUS_RUNTIME="unknown"
export STAGE9U_PY_COMPILE="unknown"
export STAGE9U_HEALTH_CODE="unknown"
export STAGE9U_POST_CODE="unknown"
export STAGE9U_ENV_ABSENT="unknown"
export STAGE9U_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
data = {
    "stage": "9U",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "disabled controller-side persistent rollout status boundary",
    "source_status_runtime": os.environ.get("STAGE9U_SOURCE_STATUS_RUNTIME"),
    "py_compile": os.environ.get("STAGE9U_PY_COMPILE"),
    "health_code": os.environ.get("STAGE9U_HEALTH_CODE"),
    "post_code": os.environ.get("STAGE9U_POST_CODE"),
    "env_absent": os.environ.get("STAGE9U_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE9U_QUEUE_CLEAN"),
    "final_result": os.environ.get("STAGE9U_FINAL_RESULT"),
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {path}")
PY
}

echo "=== Stage 9U smoke: disabled controller-side persistent rollout status boundary ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 9U report exists" || check_fail "Stage 9U report missing"
[ -x "$SMOKE" ] && pass "Stage 9U smoke script is executable" || check_fail "Stage 9U smoke script missing or not executable"

for needle in \
  "Stage 9U adds a disabled controller-side persistent rollout status boundary." \
  "Stage 9U does not modify frontend/wrapper-ui/app.js." \
  "Stage 9U does not enable browser router traffic." \
  "Stage 9U does not enable backend router dry-run." \
  "Stage 9U does not restart live services." \
  "Stage 9U does not send frontend router POST traffic." \
  "Stage 9U does not add any mutation endpoint." \
  "GET /api/router/persistent-rollout/status" \
  "enabled = false" \
  "status = disabled" \
  "reason = persistent_operator_gated_rollout_disabled" \
  "mutation_supported = false" \
  "activation_supported = false" \
  "Stage 9U intentionally does not restart edge-queue-controller." \
  "Stage 9V should perform controlled live verification of the disabled controller-side persistent rollout status endpoint."
do
  if grep -Fq "$needle" "$REPORT"; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

echo
echo "=== Stage 9R/9S/9T evidence and report validation ==="
[ -f "$STAGE9R_EVIDENCE" ] && pass "Stage 9R evidence exists" || check_fail "Stage 9R evidence missing"
[ -f "$STAGE9S_EVIDENCE" ] && pass "Stage 9S evidence exists" || check_fail "Stage 9S evidence missing"
[ -f "$STAGE9T_REPORT" ] && pass "Stage 9T report exists" || check_fail "Stage 9T report missing"

python3 - "$STAGE9R_EVIDENCE" "$STAGE9S_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

stage9r = Path(sys.argv[1])
stage9s = Path(sys.argv[2])

checks = [
    (stage9r, {
        "final_result": {"pass"},
        "local_disabled_runtime": {"pass"},
        "post_code": {"404"},
        "env_absent": {"true", "True"},
        "queue_clean": {"true", "True"},
    }),
    (stage9s, {
        "final_result": {"pass"},
        "live_app_code": {"200"},
        "live_stub_code": {"200"},
        "live_disabled_runtime": {"pass"},
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

print("PASS: Stage 9R and Stage 9S evidence values confirmed")
PY
if [ "$?" = "0" ]; then
  pass "Stage 9R/9S evidence values confirmed"
else
  check_fail "Stage 9R/9S evidence validation failed"
fi

echo
echo "=== controller source boundary checks ==="
[ -f "$CONTROLLER" ] && pass "edge_controller.py exists" || check_fail "missing edge_controller.py"

for needle in \
  "Stage 9U disabled controller-side persistent rollout status boundary." \
  "PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH" \
  '"/api/router/persistent-rollout/status"' \
  "PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = False" \
  'PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS = "disabled"' \
  'PERSISTENT_OPERATOR_GATED_ROLLOUT_REASON = "persistent_operator_gated_rollout_disabled"' \
  "build_persistent_operator_gated_rollout_status" \
  "@app.get(PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH)" \
  '"mutation_supported": False' \
  '"activation_supported": False' \
  '"/api/router/dry-run"'
do
  if grep -Fq "$needle" "$CONTROLLER"; then
    pass "controller contains: $needle"
  else
    check_fail "controller missing required text: $needle"
  fi
done

if grep -RInE '@app\.(post|put|patch|delete)\("/api/router/persistent-rollout/status"|@app\.(post|put|patch|delete)\(PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH' "$CONTROLLER" 2>/dev/null; then
  check_fail "persistent rollout status has unexpected mutation route"
else
  pass "persistent rollout status has no mutation route"
fi

echo
echo "=== source status function runtime check without importing app ==="
python3 - "$CONTROLLER" <<'PY'
import ast
import sys
from pathlib import Path

path = Path(sys.argv[1])
source = path.read_text(encoding="utf-8")
module = ast.parse(source)

needed = {
    "PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH",
    "PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED",
    "PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS",
    "PERSISTENT_OPERATOR_GATED_ROLLOUT_REASON",
    "PERSISTENT_OPERATOR_GATED_ROLLOUT_ALLOWED_SURFACES",
    "build_persistent_operator_gated_rollout_status",
}

names = {node.name for node in module.body if isinstance(node, ast.FunctionDef)}
assigns = set()
for node in module.body:
    if isinstance(node, ast.Assign):
        for target in node.targets:
            if isinstance(target, ast.Name):
                assigns.add(target.id)

missing = sorted((needed - names) - assigns)
if missing:
    raise SystemExit(f"missing source symbols: {missing}")

ns = {
    "PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH": "/api/router/persistent-rollout/status",
    "PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED": False,
    "PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS": "disabled",
    "PERSISTENT_OPERATOR_GATED_ROLLOUT_REASON": "persistent_operator_gated_rollout_disabled",
    "PERSISTENT_OPERATOR_GATED_ROLLOUT_ALLOWED_SURFACES": ["manual-diagnostic"],
}

func_node = None
for node in module.body:
    if isinstance(node, ast.FunctionDef) and node.name == "build_persistent_operator_gated_rollout_status":
        func_node = node
        break

if func_node is None:
    raise SystemExit("build_persistent_operator_gated_rollout_status missing")

code = compile(ast.Module(body=[func_node], type_ignores=[]), str(path), "exec")
exec(code, ns)
status = ns["build_persistent_operator_gated_rollout_status"]()

checks = {
    "ok": True,
    "path": "/api/router/persistent-rollout/status",
    "enabled": False,
    "status": "disabled",
    "reason": "persistent_operator_gated_rollout_disabled",
    "allowed_surfaces": ["manual-diagnostic"],
    "dry_run": True,
    "dispatch_requested": False,
    "dispatch_performed": False,
    "mutation_supported": False,
    "activation_supported": False,
    "stage": "9U",
}

bad = []
for key, expected in checks.items():
    actual = status.get(key)
    print(f"{key}={actual!r}")
    if actual != expected:
        bad.append((key, expected, actual))

if bad:
    print("CHECK: status function mismatch")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: source status function returns disabled read-only state")
PY
runtime_check=$?
if [ "$runtime_check" = "0" ]; then
  STAGE9U_SOURCE_STATUS_RUNTIME="pass"
  export STAGE9U_SOURCE_STATUS_RUNTIME
  pass "source status function runtime check passed"
else
  STAGE9U_SOURCE_STATUS_RUNTIME="fail"
  export STAGE9U_SOURCE_STATUS_RUNTIME
  check_fail "source status function runtime check failed"
fi

echo
echo "=== py_compile check ==="
python3 -m py_compile "$CONTROLLER"
compile_check=$?
if [ "$compile_check" = "0" ]; then
  STAGE9U_PY_COMPILE="pass"
  export STAGE9U_PY_COMPILE
  pass "edge_controller.py compiles"
else
  STAGE9U_PY_COMPILE="fail"
  export STAGE9U_PY_COMPILE
  check_fail "edge_controller.py failed py_compile"
fi

echo
echo "=== frontend static safety checks ==="
[ -f "$APP_JS" ] && pass "app.js exists" || check_fail "missing app.js"
[ -f "$STUB" ] && pass "router shadow-read stub exists" || check_fail "missing router shadow-read stub"

grep -q "EdgeRouterShadowReadSurface" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadSurface" \
  || check_fail "app.js missing EdgeRouterShadowReadSurface"

grep -q "EdgeRouterShadowReadOperatorGate" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadOperatorGate" \
  || check_fail "app.js missing EdgeRouterShadowReadOperatorGate"

grep -q "EdgeRouterShadowReadPersistentRollout" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadPersistentRollout" \
  || check_fail "app.js missing EdgeRouterShadowReadPersistentRollout"

grep -q "PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = false" "$APP_JS" 2>/dev/null \
  && pass "persistent rollout default false marker exists" \
  || check_fail "persistent rollout default false marker missing"

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
echo "=== live-served frontend still guarded checks ==="
live_app_code="$(curl -sS --max-time 8 -o "$LIVE_APP" -w "%{http_code}" "$FRONTEND_BASE/app.js" 2>/tmp/stage9u-live-app.err || printf 'curl_failed')"
live_stub_code="$(curl -sS --max-time 8 -o "$LIVE_STUB" -w "%{http_code}" "$FRONTEND_BASE/router_shadow_read_stub.js" 2>/tmp/stage9u-live-stub.err || printf 'curl_failed')"

echo "live_app_code=$live_app_code"
echo "live_stub_code=$live_stub_code"

if [ "$live_app_code" = "200" ]; then
  pass "live-served app.js fetched with HTTP 200"
  grep -q "EdgeRouterShadowReadPersistentRollout" "$LIVE_APP" 2>/dev/null \
    && pass "live-served app.js contains EdgeRouterShadowReadPersistentRollout" \
    || check_fail "live-served app.js missing EdgeRouterShadowReadPersistentRollout"

  if grep -q "/api/router/dry-run" "$LIVE_APP" 2>/dev/null; then
    check_fail "live-served app.js contains /api/router/dry-run"
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
echo "=== backend disabled state checks without service restart ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage9u-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage9u-health.err || printf 'curl_failed')"
STAGE9U_HEALTH_CODE="$health_code"
export STAGE9U_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage9u disabled controller status boundary checkpoint","source":"stage9u","surface":"backend-only"}' \
  -o /tmp/stage9u-router-post.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage9u-router-post.err || printf 'curl_failed')"
STAGE9U_POST_CODE="$post_code"
export STAGE9U_POST_CODE
echo "post_code=$post_code"

if [ "$post_code" = "404" ]; then
  pass "POST /api/router/dry-run remains HTTP 404"
else
  check_fail "POST /api/router/dry-run did not remain HTTP 404"
fi

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -E 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED|ROUTER|INTENT|DRY_RUN|SHADOW' || true

if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE9U_ENV_ABSENT="false"
  export STAGE9U_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE9U_ENV_ABSENT="true"
  export STAGE9U_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage9u-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage9u-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage9u-system-status.json <<'PY'
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
    STAGE9U_QUEUE_CLEAN="true"
    export STAGE9U_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE9U_QUEUE_CLEAN="false"
    export STAGE9U_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE9U_QUEUE_CLEAN="status_failed"
  export STAGE9U_QUEUE_CLEAN
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
echo "=== write Stage 9U evidence ==="
if [ "$fail" = "0" ]; then
  STAGE9U_FINAL_RESULT="pass"
else
  STAGE9U_FINAL_RESULT="fail"
fi
export STAGE9U_FINAL_RESULT
write_evidence

echo
echo "=== Stage 9U smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 9U disabled controller-side persistent rollout status boundary verified without live restart"
else
  echo "FAIL: Stage 9U disabled controller-side persistent rollout status boundary found issues"
fi

exit "$fail"
