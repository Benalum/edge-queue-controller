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

REPORT="docs/generated/stage-9v-live-disabled-persistent-rollout-status-verification.md"
EVIDENCE="docs/generated/stage-9v-live-disabled-persistent-rollout-status-verification-evidence.json"
SMOKE="ops/smoke/check-stage-9v-live-disabled-persistent-rollout-status-verification.sh"

STAGE9U_EVIDENCE="docs/generated/stage-9u-disabled-controller-side-persistent-rollout-status-boundary-evidence.json"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

LIVE_STATUS="/tmp/stage9v-persistent-rollout-status.json"
LIVE_APP="/tmp/stage9v-live-app.js"
LIVE_STUB="/tmp/stage9v-live-router-shadow-read-stub.js"

export STAGE9V_FINAL_RESULT="unknown"
export STAGE9V_HEALTH_BEFORE="unknown"
export STAGE9V_HEALTH_AFTER_RESTART="unknown"
export STAGE9V_STATUS_CODE="unknown"
export STAGE9V_STATUS_RUNTIME="unknown"
export STAGE9V_POST_CODE="unknown"
export STAGE9V_ENV_ABSENT="unknown"
export STAGE9V_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
data = {
    "stage": "9V",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "live disabled persistent rollout status verification",
    "health_before": os.environ.get("STAGE9V_HEALTH_BEFORE"),
    "health_after_restart": os.environ.get("STAGE9V_HEALTH_AFTER_RESTART"),
    "status_code": os.environ.get("STAGE9V_STATUS_CODE"),
    "status_runtime": os.environ.get("STAGE9V_STATUS_RUNTIME"),
    "post_code": os.environ.get("STAGE9V_POST_CODE"),
    "env_absent": os.environ.get("STAGE9V_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE9V_QUEUE_CLEAN"),
    "final_result": os.environ.get("STAGE9V_FINAL_RESULT"),
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {path}")
PY
}

wait_for_health() {
  label="$1"
  tries=30
  code="000"
  while [ "$tries" -gt 0 ]; do
    code="$(curl -sS --max-time 3 -o "/tmp/stage9v-health-${label}.out" -w "%{http_code}" "$BASE/health" 2>"/tmp/stage9v-health-${label}.err" || printf 'curl_failed')"
    if [ "$code" = "200" ]; then
      echo "$code"
      return 0
    fi
    tries=$((tries - 1))
    sleep 1
  done
  echo "$code"
  return 1
}

echo "=== Stage 9V smoke: controlled live disabled persistent rollout status verification ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 9V report exists" || check_fail "Stage 9V report missing"
[ -x "$SMOKE" ] && pass "Stage 9V smoke script is executable" || check_fail "Stage 9V smoke script missing or not executable"

for needle in \
  "Stage 9V performs controlled live verification of the disabled controller-side persistent rollout status endpoint." \
  "Stage 9V may restart edge-queue-controller to load the Stage 9U source route." \
  "Stage 9V does not enable browser router traffic." \
  "Stage 9V does not enable backend router dry-run." \
  "Stage 9V does not send frontend router POST traffic." \
  "Stage 9V does not add any mutation endpoint." \
  "GET /api/router/persistent-rollout/status must return HTTP 200" \
  "enabled = false" \
  "status = disabled" \
  "reason = persistent_operator_gated_rollout_disabled" \
  "mutation_supported = false" \
  "activation_supported = false" \
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
echo "=== Stage 9U evidence validation ==="
[ -f "$STAGE9U_EVIDENCE" ] && pass "Stage 9U evidence exists" || check_fail "Stage 9U evidence missing"

python3 - "$STAGE9U_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    sys.exit(1)

data = json.loads(path.read_text(encoding="utf-8"))
checks = {
    "final_result": {"pass"},
    "source_status_runtime": {"pass"},
    "py_compile": {"pass"},
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
    print("CHECK: Stage 9U evidence did not match expected values")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 9U evidence confirms disabled controller status boundary")
PY
if [ "$?" = "0" ]; then
  pass "Stage 9U evidence values confirmed"
else
  check_fail "Stage 9U evidence validation failed"
fi

echo
echo "=== source safety checks before restart ==="
python3 -m py_compile "$CONTROLLER"
if [ "$?" = "0" ]; then
  pass "edge_controller.py compiles before restart"
else
  check_fail "edge_controller.py failed py_compile before restart"
fi

for needle in \
  "PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH" \
  '"/api/router/persistent-rollout/status"' \
  "PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = False" \
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

if grep -RInE '@app\.(post|put|patch|delete)\("/api/router/persistent-rollout/status"|@app\.(post|put|patch|delete)\(PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH' "$CONTROLLER" 2>/dev/null; then
  check_fail "persistent rollout status has unexpected mutation route"
else
  pass "persistent rollout status has no mutation route"
fi

echo
echo "=== pre-restart health and backend disabled checks ==="
health_before="$(wait_for_health before || true)"
STAGE9V_HEALTH_BEFORE="$health_before"
export STAGE9V_HEALTH_BEFORE
echo "health_before=$health_before"
[ "$health_before" = "200" ] && pass "health before restart is HTTP 200" || check_fail "health before restart is not HTTP 200"

pre_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$pre_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  check_fail "backend dry-run env is enabled before restart"
else
  pass "backend dry-run env absent before restart"
fi

if [ "$fail" != "0" ]; then
  echo "CHECK: pre-restart checks failed, refusing to restart"
else
  echo
  echo "=== restart controller to load Stage 9U read-only status route ==="
  sudo systemctl restart edge-queue-controller || fail=1

  health_after="$(wait_for_health after-restart || true)"
  STAGE9V_HEALTH_AFTER_RESTART="$health_after"
  export STAGE9V_HEALTH_AFTER_RESTART
  echo "health_after_restart=$health_after"
  [ "$health_after" = "200" ] && pass "health after restart is HTTP 200" || check_fail "health after restart is not HTTP 200"
fi

echo
echo "=== live read-only persistent rollout status endpoint check ==="
status_code="$(curl -sS --max-time 5 -o "$LIVE_STATUS" -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage9v-rollout-status.err || printf 'curl_failed')"
STAGE9V_STATUS_CODE="$status_code"
export STAGE9V_STATUS_CODE
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

print("PASS: live status endpoint returns disabled read-only state")
PY
  status_runtime=$?
  if [ "$status_runtime" = "0" ]; then
    STAGE9V_STATUS_RUNTIME="pass"
    export STAGE9V_STATUS_RUNTIME
    pass "live status response values confirmed"
  else
    STAGE9V_STATUS_RUNTIME="fail"
    export STAGE9V_STATUS_RUNTIME
    check_fail "live status response validation failed"
  fi
else
  STAGE9V_STATUS_RUNTIME="not_run"
  export STAGE9V_STATUS_RUNTIME
  check_fail "GET /api/router/persistent-rollout/status did not return HTTP 200"
fi

echo
echo "=== confirm mutation path is not available ==="
mutation_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"enabled":true}' \
  -o /tmp/stage9v-rollout-mutation.out \
  -w "%{http_code}" \
  "$ROLLOUT_STATUS_URL" 2>/tmp/stage9v-rollout-mutation.err || printf 'curl_failed')"
echo "mutation_code=$mutation_code"

case "$mutation_code" in
  404|405)
    pass "persistent rollout status mutation is not available"
    ;;
  *)
    check_fail "persistent rollout status mutation unexpectedly returned $mutation_code"
    ;;
esac

echo
echo "=== post-restart backend disabled state checks ==="
post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage9v live status verification checkpoint","source":"stage9v","surface":"backend-only"}' \
  -o /tmp/stage9v-router-post.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage9v-router-post.err || printf 'curl_failed')"
STAGE9V_POST_CODE="$post_code"
export STAGE9V_POST_CODE
echo "post_code=$post_code"

if [ "$post_code" = "404" ]; then
  pass "POST /api/router/dry-run remains HTTP 404"
else
  check_fail "POST /api/router/dry-run did not remain HTTP 404"
fi

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -E 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED|ROUTER|INTENT|DRY_RUN|SHADOW' || true

if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE9V_ENV_ABSENT="false"
  export STAGE9V_ENV_ABSENT
  check_fail "backend dry-run env is enabled after restart"
else
  STAGE9V_ENV_ABSENT="true"
  export STAGE9V_ENV_ABSENT
  pass "backend dry-run env remains absent after restart"
fi

echo
echo "=== frontend static/live safety checks ==="
if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js directly contains /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" | sed -n '1,80p'
else
  pass "app.js contains no /api/router/dry-run"
fi

grep -q "EdgeRouterShadowReadPersistentRollout" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadPersistentRollout" \
  || check_fail "app.js missing EdgeRouterShadowReadPersistentRollout"

grep -q "PERSISTENT_OPERATOR_GATED_ROLLOUT_ENABLED = false" "$APP_JS" 2>/dev/null \
  && pass "persistent rollout default false marker exists" \
  || check_fail "persistent rollout default false marker missing"

grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$STUB" 2>/dev/null \
  && pass "stub contains backend dry-run endpoint boundary" \
  || check_fail "stub missing backend dry-run endpoint boundary"

grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_ENABLED remains false" \
  || check_fail "ROUTER_SHADOW_READ_ENABLED=false marker missing"

grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
  || check_fail "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"

live_app_code="$(curl -sS --max-time 8 -o "$LIVE_APP" -w "%{http_code}" "$FRONTEND_BASE/app.js" 2>/tmp/stage9v-live-app.err || printf 'curl_failed')"
live_stub_code="$(curl -sS --max-time 8 -o "$LIVE_STUB" -w "%{http_code}" "$FRONTEND_BASE/router_shadow_read_stub.js" 2>/tmp/stage9v-live-stub.err || printf 'curl_failed')"

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
else
  check_fail "could not fetch live-served router shadow-read stub"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage9v-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage9v-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage9v-system-status.json <<'PY'
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
    STAGE9V_QUEUE_CLEAN="true"
    export STAGE9V_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE9V_QUEUE_CLEAN="false"
    export STAGE9V_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE9V_QUEUE_CLEAN="status_failed"
  export STAGE9V_QUEUE_CLEAN
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
echo "=== write Stage 9V evidence ==="
if [ "$fail" = "0" ]; then
  STAGE9V_FINAL_RESULT="pass"
else
  STAGE9V_FINAL_RESULT="fail"
fi
export STAGE9V_FINAL_RESULT
write_evidence

echo
echo "=== Stage 9V smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 9V live disabled persistent rollout status verified"
else
  echo "FAIL: Stage 9V live disabled persistent rollout status found issues"
fi

exit "$fail"
