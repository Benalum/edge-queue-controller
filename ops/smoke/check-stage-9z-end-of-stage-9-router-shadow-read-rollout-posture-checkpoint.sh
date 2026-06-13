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

REPORT="docs/generated/stage-9z-end-of-stage-9-router-shadow-read-rollout-posture-checkpoint.md"
EVIDENCE="docs/generated/stage-9z-end-of-stage-9-router-shadow-read-rollout-posture-checkpoint-evidence.json"
SMOKE="ops/smoke/check-stage-9z-end-of-stage-9-router-shadow-read-rollout-posture-checkpoint.sh"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

STAGE9A_EVIDENCE="docs/generated/stage-9a-controlled-full-stack-router-shadow-read-activation-rollback-evidence.json"
STAGE9G_EVIDENCE="docs/generated/stage-9g-controlled-browser-surface-activation-rollback-evidence.json"
STAGE9N_EVIDENCE="docs/generated/stage-9n-controlled-operator-gated-browser-shadow-read-activation-rollback-evidence.json"
STAGE9V_EVIDENCE="docs/generated/stage-9v-live-disabled-persistent-rollout-status-verification-evidence.json"
STAGE9W_EVIDENCE="docs/generated/stage-9w-live-persistent-rollout-status-stability-checkpoint-evidence.json"
STAGE9X_REPORT="docs/generated/stage-9x-persistent-activation-mutation-design-plan.md"
STAGE9Y_REPORT="docs/generated/stage-9y-disabled-mutation-boundary-implementation-plan.md"

BASE="http://127.0.0.1:7070"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

LIVE_STATUS="/tmp/stage9z-persistent-rollout-status.json"
LIVE_APP="/tmp/stage9z-live-app.js"
LIVE_STUB="/tmp/stage9z-live-router-shadow-read-stub.js"

export STAGE9Z_FINAL_RESULT="unknown"
export STAGE9Z_HEALTH_CODE="unknown"
export STAGE9Z_STATUS_CODE="unknown"
export STAGE9Z_STATUS_RUNTIME="unknown"
export STAGE9Z_STATUS_MUTATION_CODE="unknown"
export STAGE9Z_REQUEST_MUTATION_CODE="unknown"
export STAGE9Z_POST_CODE="unknown"
export STAGE9Z_ENV_ABSENT="unknown"
export STAGE9Z_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
data = {
    "stage": "9Z",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "end-of-Stage-9 router shadow-read rollout posture checkpoint",
    "health_code": os.environ.get("STAGE9Z_HEALTH_CODE"),
    "status_code": os.environ.get("STAGE9Z_STATUS_CODE"),
    "status_runtime": os.environ.get("STAGE9Z_STATUS_RUNTIME"),
    "status_mutation_code": os.environ.get("STAGE9Z_STATUS_MUTATION_CODE"),
    "request_mutation_code": os.environ.get("STAGE9Z_REQUEST_MUTATION_CODE"),
    "post_code": os.environ.get("STAGE9Z_POST_CODE"),
    "env_absent": os.environ.get("STAGE9Z_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE9Z_QUEUE_CLEAN"),
    "final_result": os.environ.get("STAGE9Z_FINAL_RESULT"),
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {path}")
PY
}

echo "=== Stage 9Z smoke: end-of-Stage-9 router shadow-read rollout posture checkpoint ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 9Z report exists" || check_fail "Stage 9Z report missing"
[ -x "$SMOKE" ] && pass "Stage 9Z smoke script is executable" || check_fail "Stage 9Z smoke script missing or not executable"

for needle in \
  "Stage 9Z closes Stage 9 with a final router shadow-read rollout posture checkpoint." \
  "Stage 9Z summarizes Stage 9A through Stage 9Y." \
  "Stage 9Z does not modify frontend/wrapper-ui/app.js." \
  "Stage 9Z does not modify edge_controller.py." \
  "Stage 9Z does not restart live services." \
  "Stage 9Z does not add a mutation endpoint." \
  "Stage 9Z does not enable browser router traffic." \
  "Stage 9Z does not enable backend router dry-run." \
  "Stage 9Z does not send frontend router POST traffic." \
  "Browser router traffic remains disabled by default." \
  "Backend router dry-run remains disabled by default." \
  "The frontend app.js contains no /api/router/dry-run." \
  "No persistent rollout mutation route exists." \
  "POST /api/router/dry-run remains HTTP 404." \
  "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent." \
  "Stage 10A should start a new phase for persistent rollout mutation readiness."
do
  if grep -Fq "$needle" "$REPORT"; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

for stage in 9A 9B 9C 9D 9E 9F 9G 9H 9I 9J 9K 9L 9M 9N 9O 9P 9Q 9R 9S 9T 9U 9V 9W 9X 9Y; do
  if grep -Fq "Stage $stage" "$REPORT"; then
    pass "report summarizes Stage $stage"
  else
    check_fail "report missing Stage $stage summary"
  fi
done

echo
echo "=== key Stage 9 evidence/report validation ==="
for required in "$STAGE9A_EVIDENCE" "$STAGE9G_EVIDENCE" "$STAGE9N_EVIDENCE" "$STAGE9V_EVIDENCE" "$STAGE9W_EVIDENCE" "$STAGE9X_REPORT" "$STAGE9Y_REPORT"; do
  if [ -f "$required" ]; then
    pass "required artifact exists: $required"
  else
    check_fail "missing required artifact: $required"
  fi
done

python3 - "$STAGE9A_EVIDENCE" "$STAGE9G_EVIDENCE" "$STAGE9N_EVIDENCE" "$STAGE9V_EVIDENCE" "$STAGE9W_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

checks = [
    (Path(sys.argv[1]), {
        "final_result": {"pass"},
        "post_before": {"404"},
        "post_enabled": {"200"},
        "post_after": {"404"},
        "rollback_env_absent": {"true", "True"},
    }),
    (Path(sys.argv[2]), {
        "final_result": {"pass"},
        "post_before": {"404"},
        "post_enabled": {"200"},
        "browser_requests": {"1"},
        "browser_status": {"200"},
        "browser_surface": {"manual-diagnostic"},
        "post_after": {"404"},
        "rollback_env_absent": {"true", "True"},
    }),
    (Path(sys.argv[3]), {
        "final_result": {"pass"},
        "post_before": {"404"},
        "post_enabled": {"200"},
        "browser_requests": {"1"},
        "browser_status": {"200"},
        "browser_surface": {"manual-diagnostic"},
        "operator_gate_enabled_in_vm": {"True", "true"},
        "operator_gate_restored_false_in_vm": {"True", "true"},
        "post_after": {"404"},
        "rollback_env_absent": {"true", "True"},
    }),
    (Path(sys.argv[4]), {
        "final_result": {"pass"},
        "health_before": {"200"},
        "health_after_restart": {"200"},
        "status_code": {"200"},
        "status_runtime": {"pass"},
        "post_code": {"404"},
        "env_absent": {"true", "True"},
        "queue_clean": {"true", "True"},
    }),
    (Path(sys.argv[5]), {
        "final_result": {"pass"},
        "health_code": {"200"},
        "status_code": {"200"},
        "status_runtime": {"pass"},
        "mutation_code": {"404", "405"},
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
    print("CHECK: key Stage 9 evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: key Stage 9 evidence values confirmed")
PY
if [ "$?" = "0" ]; then
  pass "key Stage 9 evidence values confirmed"
else
  check_fail "key Stage 9 evidence validation failed"
fi

echo
echo "=== source safety checks, no restart ==="
python3 -m py_compile "$CONTROLLER"
if [ "$?" = "0" ]; then
  pass "edge_controller.py compiles"
else
  check_fail "edge_controller.py failed py_compile"
fi

for needle in \
  "PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH" \
  '"/api/router/persistent-rollout/status"' \
  "PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = False" \
  'PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS = "disabled"' \
  'PERSISTENT_OPERATOR_GATED_ROLLOUT_REASON = "persistent_operator_gated_rollout_disabled"' \
  "build_persistent_operator_gated_rollout_status" \
  "@app.get(PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH)" \
  '"mutation_supported": False' \
  '"activation_supported": False'
do
  if grep -Fq "$needle" "$CONTROLLER"; then
    pass "controller contains: $needle"
  else
    check_fail "controller missing required text: $needle"
  fi
done

if grep -RInE '@app\.(post|put|patch|delete)\("/api/router/persistent-rollout/status"|@app\.(post|put|patch|delete)\(PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH|/api/router/persistent-rollout/request' "$CONTROLLER" 2>/dev/null; then
  check_fail "persistent rollout mutation route unexpectedly exists"
else
  pass "persistent rollout mutation route does not exist"
fi

echo
echo "=== live disabled status endpoint check ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage9z-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage9z-health.err || printf 'curl_failed')"
STAGE9Z_HEALTH_CODE="$health_code"
export STAGE9Z_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

status_code="$(curl -sS --max-time 5 -o "$LIVE_STATUS" -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage9z-rollout-status.err || printf 'curl_failed')"
STAGE9Z_STATUS_CODE="$status_code"
export STAGE9Z_STATUS_CODE
echo "status_code=$status_code"

if [ "$status_code" = "200" ]; then
  pass "GET /api/router/persistent-rollout/status returned HTTP 200"

  python3 - "$LIVE_STATUS" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))

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
    actual = data.get(key)
    print(f"{key}={actual!r}")
    if actual != expected:
        bad.append((key, expected, actual))

if bad:
    print("CHECK: live status response mismatch")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: live status endpoint remains disabled and read-only")
PY
  status_runtime=$?
  if [ "$status_runtime" = "0" ]; then
    STAGE9Z_STATUS_RUNTIME="pass"
    export STAGE9Z_STATUS_RUNTIME
    pass "live status response values confirmed"
  else
    STAGE9Z_STATUS_RUNTIME="fail"
    export STAGE9Z_STATUS_RUNTIME
    check_fail "live status response validation failed"
  fi
else
  STAGE9Z_STATUS_RUNTIME="not_run"
  export STAGE9Z_STATUS_RUNTIME
  check_fail "GET /api/router/persistent-rollout/status did not return HTTP 200"
fi

echo
echo "=== mutation paths remain unavailable ==="
status_mutation_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"enabled":true}' \
  -o /tmp/stage9z-rollout-status-mutation.out \
  -w "%{http_code}" \
  "$ROLLOUT_STATUS_URL" 2>/tmp/stage9z-rollout-status-mutation.err || printf 'curl_failed')"
STAGE9Z_STATUS_MUTATION_CODE="$status_mutation_code"
export STAGE9Z_STATUS_MUTATION_CODE
echo "status_mutation_code=$status_mutation_code"

case "$status_mutation_code" in
  404|405)
    pass "persistent rollout status mutation remains unavailable"
    ;;
  *)
    check_fail "persistent rollout status mutation unexpectedly returned $status_mutation_code"
    ;;
esac

request_mutation_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"enabled":true}' \
  -o /tmp/stage9z-rollout-request-mutation.out \
  -w "%{http_code}" \
  "$BASE/api/router/persistent-rollout/request" 2>/tmp/stage9z-rollout-request-mutation.err || printf 'curl_failed')"
STAGE9Z_REQUEST_MUTATION_CODE="$request_mutation_code"
export STAGE9Z_REQUEST_MUTATION_CODE
echo "request_mutation_code=$request_mutation_code"

case "$request_mutation_code" in
  404|405)
    pass "future persistent rollout request mutation route is unavailable"
    ;;
  *)
    check_fail "future persistent rollout request mutation route unexpectedly returned $request_mutation_code"
    ;;
esac

echo
echo "=== backend dry-run remains disabled ==="
post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage9z final posture checkpoint","source":"stage9z","surface":"backend-only"}' \
  -o /tmp/stage9z-router-post.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage9z-router-post.err || printf 'curl_failed')"
STAGE9Z_POST_CODE="$post_code"
export STAGE9Z_POST_CODE
echo "post_code=$post_code"

if [ "$post_code" = "404" ]; then
  pass "POST /api/router/dry-run remains HTTP 404"
else
  check_fail "POST /api/router/dry-run did not remain HTTP 404"
fi

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -E 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED|ROUTER|INTENT|DRY_RUN|SHADOW' || true

if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE9Z_ENV_ABSENT="false"
  export STAGE9Z_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE9Z_ENV_ABSENT="true"
  export STAGE9Z_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== frontend static/live safety checks ==="
if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js directly contains /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" | sed -n '1,80p'
else
  pass "app.js contains no /api/router/dry-run"
fi

for needle in \
  "EdgeRouterShadowReadSurface" \
  "EdgeRouterShadowReadOperatorGate" \
  "EdgeRouterShadowReadPersistentRollout" \
  "OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false" \
  "PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = false" \
  "operator_browser_shadow_read_activation_disabled" \
  "persistent_operator_gated_rollout_disabled"
do
  if grep -Fq "$needle" "$APP_JS"; then
    pass "app.js contains: $needle"
  else
    check_fail "app.js missing required text: $needle"
  fi
done

grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$STUB" 2>/dev/null \
  && pass "stub contains backend dry-run endpoint boundary" \
  || check_fail "stub missing backend dry-run endpoint boundary"

grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_ENABLED remains false" \
  || check_fail "ROUTER_SHADOW_READ_ENABLED=false marker missing"

grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
  || check_fail "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"

live_app_code="$(curl -sS --max-time 8 -o "$LIVE_APP" -w "%{http_code}" "$FRONTEND_BASE/app.js" 2>/tmp/stage9z-live-app.err || printf 'curl_failed')"
live_stub_code="$(curl -sS --max-time 8 -o "$LIVE_STUB" -w "%{http_code}" "$FRONTEND_BASE/router_shadow_read_stub.js" 2>/tmp/stage9z-live-stub.err || printf 'curl_failed')"

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
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage9z-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage9z-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage9z-system-status.json <<'PY'
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
    STAGE9Z_QUEUE_CLEAN="true"
    export STAGE9Z_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE9Z_QUEUE_CLEAN="false"
    export STAGE9Z_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE9Z_QUEUE_CLEAN="status_failed"
  export STAGE9Z_QUEUE_CLEAN
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
echo "=== write Stage 9Z evidence ==="
if [ "$fail" = "0" ]; then
  STAGE9Z_FINAL_RESULT="pass"
else
  STAGE9Z_FINAL_RESULT="fail"
fi
export STAGE9Z_FINAL_RESULT
write_evidence

echo
echo "=== Stage 9Z smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 9Z end-of-Stage-9 router shadow-read rollout posture verified"
else
  echo "FAIL: Stage 9Z end-of-Stage-9 router shadow-read rollout posture found issues"
fi

exit "$fail"
