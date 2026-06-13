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

REPORT="docs/generated/stage-9o-post-operator-gated-activation-rollback-stability-checkpoint.md"
EVIDENCE="docs/generated/stage-9o-post-operator-gated-activation-rollback-stability-checkpoint-evidence.json"
SMOKE="ops/smoke/check-stage-9o-post-operator-gated-activation-rollback-stability-checkpoint.sh"

STAGE9N_EVIDENCE="docs/generated/stage-9n-controlled-operator-gated-browser-shadow-read-activation-rollback-evidence.json"

APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

LIVE_APP="/tmp/stage9o-live-app.js"
LIVE_STUB="/tmp/stage9o-live-router-shadow-read-stub.js"

export STAGE9O_FINAL_RESULT="unknown"
export STAGE9O_HEALTH_CODE="unknown"
export STAGE9O_POST_CODE="unknown"
export STAGE9O_ENV_ABSENT="unknown"
export STAGE9O_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
data = {
    "stage": "9O",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "post-operator-gated activation rollback stability checkpoint",
    "health_code": os.environ.get("STAGE9O_HEALTH_CODE"),
    "post_code": os.environ.get("STAGE9O_POST_CODE"),
    "env_absent": os.environ.get("STAGE9O_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE9O_QUEUE_CLEAN"),
    "final_result": os.environ.get("STAGE9O_FINAL_RESULT"),
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {path}")
PY
}

echo "=== Stage 9O smoke: post-operator-gated activation rollback stability checkpoint ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 9O report exists" || check_fail "Stage 9O report missing"
[ -x "$SMOKE" ] && pass "Stage 9O smoke script is executable" || check_fail "Stage 9O smoke script missing or not executable"

for needle in \
  "Stage 9O verifies that Stage 9N controlled operator-gated browser shadow-read activation rolled back cleanly and remains rolled back after push." \
  "Stage 9O does not modify frontend/wrapper-ui/app.js." \
  "Stage 9O does not enable browser router traffic." \
  "Stage 9O does not enable backend router dry-run." \
  "Stage 9O does not restart live services." \
  "Stage 9O does not send frontend router POST traffic." \
  "Stage 9N evidence final_result remains pass." \
  "frontend/wrapper-ui/app.js contains EdgeRouterShadowReadOperatorGate." \
  "frontend/wrapper-ui/app.js contains OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false." \
  "frontend/wrapper-ui/app.js contains operator_browser_shadow_read_activation_disabled." \
  "frontend/wrapper-ui/app.js contains no /api/router/dry-run." \
  "POST /api/router/dry-run remains HTTP 404." \
  "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent." \
  "Stage 9P should prepare a narrow persistent operator-gated shadow-read rollout decision checkpoint."
do
  if grep -Fq "$needle" "$REPORT"; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

echo
echo "=== Stage 9N evidence validation ==="
[ -f "$STAGE9N_EVIDENCE" ] && pass "Stage 9N evidence exists" || check_fail "Stage 9N evidence missing"

python3 - "$STAGE9N_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    sys.exit(1)

data = json.loads(path.read_text(encoding="utf-8"))
checks = {
    "final_result": {"pass"},
    "health_before": {"200"},
    "post_before": {"404"},
    "queue_before_clean": {"true", "True"},
    "health_enabled": {"200"},
    "post_enabled": {"200"},
    "browser_requests": {"1"},
    "browser_status": {"200"},
    "browser_ok": {"True", "true"},
    "browser_surface": {"manual-diagnostic"},
    "browser_dry_run": {"True", "true"},
    "dispatch_requested": {"False", "false"},
    "dispatch_performed": {"False", "false"},
    "body_dispatch_performed": {"False", "false"},
    "operator_gate_enabled_in_vm": {"True", "true"},
    "operator_gate_restored_false_in_vm": {"True", "true"},
    "queue_enabled_clean": {"true", "True"},
    "health_after": {"200"},
    "post_after": {"404"},
    "rollback_env_absent": {"true", "True"},
    "queue_after_clean": {"true", "True"},
}

bad = []
for key, allowed in checks.items():
    actual = str(data.get(key))
    print(f"{key}={actual}")
    if actual not in allowed:
        bad.append((key, sorted(allowed), actual))

if bad:
    print("CHECK: Stage 9N evidence did not match expected values")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 9N evidence confirms controlled operator-gated activation and rollback")
PY
if [ "$?" = "0" ]; then
  pass "Stage 9N evidence values confirmed"
else
  check_fail "Stage 9N evidence validation failed"
fi

echo
echo "=== local frontend rollback state checks ==="
[ -f "$APP_JS" ] && pass "app.js exists" || check_fail "missing $APP_JS"
[ -f "$STUB" ] && pass "router shadow-read stub exists" || check_fail "missing $STUB"

grep -q "EdgeRouterShadowReadSurface" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadSurface" \
  || check_fail "app.js missing EdgeRouterShadowReadSurface"

grep -q "EdgeRouterShadowReadOperatorGate" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadOperatorGate" \
  || check_fail "app.js missing EdgeRouterShadowReadOperatorGate"

grep -q "OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false" "$APP_JS" 2>/dev/null \
  && pass "repo operator gate default remains false" \
  || check_fail "repo operator gate default false marker missing"

grep -q "operator_browser_shadow_read_activation_disabled" "$APP_JS" 2>/dev/null \
  && pass "repo operator gate disabled reason remains present" \
  || check_fail "repo operator gate disabled reason missing"

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
echo "=== live-served frontend rollback state checks ==="
live_app_code="$(curl -sS --max-time 8 -o "$LIVE_APP" -w "%{http_code}" "$FRONTEND_BASE/app.js" 2>/tmp/stage9o-live-app.err || printf 'curl_failed')"
live_stub_code="$(curl -sS --max-time 8 -o "$LIVE_STUB" -w "%{http_code}" "$FRONTEND_BASE/router_shadow_read_stub.js" 2>/tmp/stage9o-live-stub.err || printf 'curl_failed')"

echo "live_app_code=$live_app_code"
echo "live_stub_code=$live_stub_code"

if [ "$live_app_code" = "200" ]; then
  pass "live-served app.js fetched with HTTP 200"

  grep -q "EdgeRouterShadowReadSurface" "$LIVE_APP" 2>/dev/null \
    && pass "live-served app.js contains EdgeRouterShadowReadSurface" \
    || check_fail "live-served app.js missing EdgeRouterShadowReadSurface"

  grep -q "EdgeRouterShadowReadOperatorGate" "$LIVE_APP" 2>/dev/null \
    && pass "live-served app.js contains EdgeRouterShadowReadOperatorGate" \
    || check_fail "live-served app.js missing EdgeRouterShadowReadOperatorGate"

  grep -q "OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false" "$LIVE_APP" 2>/dev/null \
    && pass "live-served operator gate default remains false" \
    || check_fail "live-served operator gate default false marker missing"

  grep -q "operator_browser_shadow_read_activation_disabled" "$LIVE_APP" 2>/dev/null \
    && pass "live-served operator gate disabled reason remains present" \
    || check_fail "live-served operator gate disabled reason missing"

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
echo "=== current backend rollback state checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage9o-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage9o-health.err || printf 'curl_failed')"
STAGE9O_HEALTH_CODE="$health_code"
export STAGE9O_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage9o rollback stability check","source":"stage9o","surface":"backend-only"}' \
  -o /tmp/stage9o-router-post.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage9o-router-post.err || printf 'curl_failed')"
STAGE9O_POST_CODE="$post_code"
export STAGE9O_POST_CODE
echo "post_code=$post_code"

if [ "$post_code" = "404" ]; then
  pass "POST /api/router/dry-run remains HTTP 404"
else
  check_fail "POST /api/router/dry-run did not remain HTTP 404"
fi

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -E 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED|ROUTER|INTENT|DRY_RUN|SHADOW' || true

if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE9O_ENV_ABSENT="false"
  export STAGE9O_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE9O_ENV_ABSENT="true"
  export STAGE9O_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage9o-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage9o-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage9o-system-status.json <<'PY'
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
    STAGE9O_QUEUE_CLEAN="true"
    export STAGE9O_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE9O_QUEUE_CLEAN="false"
    export STAGE9O_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE9O_QUEUE_CLEAN="status_failed"
  export STAGE9O_QUEUE_CLEAN
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
echo "=== write Stage 9O evidence ==="
if [ "$fail" = "0" ]; then
  STAGE9O_FINAL_RESULT="pass"
else
  STAGE9O_FINAL_RESULT="fail"
fi
export STAGE9O_FINAL_RESULT
write_evidence

echo
echo "=== Stage 9O smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 9O post-operator-gated activation rollback stability verified"
else
  echo "FAIL: Stage 9O post-operator-gated activation rollback stability found issues"
fi

exit "$fail"
