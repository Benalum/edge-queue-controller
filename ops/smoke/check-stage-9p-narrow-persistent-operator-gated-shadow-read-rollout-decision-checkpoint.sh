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

REPORT="docs/generated/stage-9p-narrow-persistent-operator-gated-shadow-read-rollout-decision-checkpoint.md"
SMOKE="ops/smoke/check-stage-9p-narrow-persistent-operator-gated-shadow-read-rollout-decision-checkpoint.sh"

STAGE9N_EVIDENCE="docs/generated/stage-9n-controlled-operator-gated-browser-shadow-read-activation-rollback-evidence.json"
STAGE9O_EVIDENCE="docs/generated/stage-9o-post-operator-gated-activation-rollback-stability-checkpoint-evidence.json"

APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

LIVE_APP="/tmp/stage9p-live-app.js"
LIVE_STUB="/tmp/stage9p-live-router-shadow-read-stub.js"

echo "=== Stage 9P smoke: narrow persistent operator-gated rollout decision checkpoint ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 9P report exists" || check_fail "Stage 9P report missing"
[ -x "$SMOKE" ] && pass "Stage 9P smoke script is executable" || check_fail "Stage 9P smoke script missing or not executable"

for needle in \
  "Stage 9P records the decision checkpoint for a future narrow persistent operator-gated browser shadow-read rollout." \
  "Stage 9P does not modify frontend/wrapper-ui/app.js." \
  "Stage 9P does not enable browser router traffic." \
  "Stage 9P does not enable backend router dry-run." \
  "Stage 9P does not restart live services." \
  "Stage 9P does not send frontend router POST traffic." \
  "Stage 9N evidence final_result remains pass." \
  "Stage 9O evidence final_result remains pass." \
  "Keep default browser router traffic disabled." \
  "Keep backend router dry-run disabled by default." \
  "Keep the operator gate false by default." \
  "Require explicit operator approval before any persistent rollout." \
  "Start with one narrow surface only." \
  "Keep dry_run = true." \
  "Keep dispatch_requested = false." \
  "Keep dispatch_performed = false." \
  "frontend/wrapper-ui/app.js contains EdgeRouterShadowReadOperatorGate." \
  "frontend/wrapper-ui/app.js contains OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false." \
  "frontend/wrapper-ui/app.js contains no /api/router/dry-run." \
  "POST /api/router/dry-run remains HTTP 404." \
  "EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1 remains absent." \
  "Stage 9Q should prepare a persistent operator-gated rollout implementation plan only." \
  "Stage 9Q should not enable browser router traffic automatically." \
  "Stage 9Q should not enable backend router dry-run automatically."
do
  if grep -Fq "$needle" "$REPORT"; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

echo
echo "=== Stage 9N/9O evidence validation ==="
[ -f "$STAGE9N_EVIDENCE" ] && pass "Stage 9N evidence exists" || check_fail "Stage 9N evidence missing"
[ -f "$STAGE9O_EVIDENCE" ] && pass "Stage 9O evidence exists" || check_fail "Stage 9O evidence missing"

python3 - "$STAGE9N_EVIDENCE" "$STAGE9O_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

stage9n = Path(sys.argv[1])
stage9o = Path(sys.argv[2])

checks = [
    (stage9n, {
        "final_result": {"pass"},
        "post_before": {"404"},
        "post_enabled": {"200"},
        "browser_requests": {"1"},
        "browser_status": {"200"},
        "browser_surface": {"manual-diagnostic"},
        "browser_dry_run": {"True", "true"},
        "dispatch_requested": {"False", "false"},
        "dispatch_performed": {"False", "false"},
        "body_dispatch_performed": {"False", "false"},
        "operator_gate_enabled_in_vm": {"True", "true"},
        "operator_gate_restored_false_in_vm": {"True", "true"},
        "queue_before_clean": {"true", "True"},
        "queue_enabled_clean": {"true", "True"},
        "queue_after_clean": {"true", "True"},
        "post_after": {"404"},
        "rollback_env_absent": {"true", "True"},
    }),
    (stage9o, {
        "final_result": {"pass"},
        "health_code": {"200"},
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

print("PASS: Stage 9N and Stage 9O evidence values confirmed")
PY
if [ "$?" = "0" ]; then
  pass "Stage 9N/9O evidence values confirmed"
else
  check_fail "Stage 9N/9O evidence validation failed"
fi

echo
echo "=== local frontend state checks ==="
[ -f "$APP_JS" ] && pass "app.js exists" || check_fail "missing $APP_JS"
[ -f "$STUB" ] && pass "router shadow-read stub exists" || check_fail "missing $STUB"

grep -q "EdgeRouterShadowReadSurface" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadSurface" \
  || check_fail "app.js missing EdgeRouterShadowReadSurface"

grep -q "EdgeRouterShadowReadOperatorGate" "$APP_JS" 2>/dev/null \
  && pass "app.js contains EdgeRouterShadowReadOperatorGate" \
  || check_fail "app.js missing EdgeRouterShadowReadOperatorGate"

grep -q "OPERATOR_BROWSER_SHADOW_READ_ACTIVATION_ENABLED = false" "$APP_JS" 2>/dev/null \
  && pass "operator gate default false marker exists" \
  || check_fail "operator gate default false marker missing"

grep -q "operator_browser_shadow_read_activation_disabled" "$APP_JS" 2>/dev/null \
  && pass "operator gate disabled reason exists" \
  || check_fail "operator gate disabled reason missing"

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
echo "=== live-served frontend state checks ==="
live_app_code="$(curl -sS --max-time 8 -o "$LIVE_APP" -w "%{http_code}" "$FRONTEND_BASE/app.js" 2>/tmp/stage9p-live-app.err || printf 'curl_failed')"
live_stub_code="$(curl -sS --max-time 8 -o "$LIVE_STUB" -w "%{http_code}" "$FRONTEND_BASE/router_shadow_read_stub.js" 2>/tmp/stage9p-live-stub.err || printf 'curl_failed')"

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
    && pass "live-served operator gate default false marker exists" \
    || check_fail "live-served operator gate default false marker missing"

  grep -q "operator_browser_shadow_read_activation_disabled" "$LIVE_APP" 2>/dev/null \
    && pass "live-served operator gate disabled reason exists" \
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
echo "=== backend disabled state checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage9p-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage9p-health.err || printf 'curl_failed')"
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage9p rollout decision checkpoint","source":"stage9p","surface":"backend-only"}' \
  -o /tmp/stage9p-router-post.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage9p-router-post.err || printf 'curl_failed')"
echo "post_code=$post_code"

if [ "$post_code" = "404" ]; then
  pass "POST /api/router/dry-run remains HTTP 404"
else
  check_fail "POST /api/router/dry-run did not remain HTTP 404"
fi

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -E 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED|ROUTER|INTENT|DRY_RUN|SHADOW' || true

if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  check_fail "backend dry-run env is enabled"
else
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage9p-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage9p-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage9p-system-status.json <<'PY'
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
echo "=== Stage 9P smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 9P narrow persistent operator-gated rollout decision checkpoint verified without enablement"
else
  echo "FAIL: Stage 9P narrow persistent operator-gated rollout decision checkpoint found issues"
fi

exit "$fail"
