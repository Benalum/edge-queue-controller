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

REPORT="docs/generated/stage-8u-router-dry-run-evidence-review-no-browser-traffic-checkpoint.md"
SMOKE="ops/smoke/check-stage-8u-router-dry-run-evidence-review-no-browser-traffic-checkpoint.sh"
STAGE8T_EVIDENCE="docs/generated/stage-8t-live-backend-router-dry-run-controlled-activation-rollback-evidence.json"

APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

echo "=== Stage 8U smoke: evidence review and no-browser-traffic checkpoint ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 8U report exists" || check_fail "Stage 8U report missing"
[ -x "$SMOKE" ] && pass "Stage 8U smoke script is executable" || check_fail "Stage 8U smoke script missing or not executable"

for needle in \
  "Decision: do not enable browser/frontend router traffic yet." \
  "Stage 8U is non-invasive." \
  "Live backend dry-run remains disabled." \
  "POST /api/router/dry-run remains HTTP 404." \
  "ROUTER_SHADOW_READ_ENABLED = false" \
  "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false" \
  "Stage 8V should prepare a frontend/browser shadow-read activation plan only."
do
  if grep -Fq "$needle" "$REPORT" 2>/dev/null; then
    pass "report contains: $needle"
  else
    check_fail "report missing required text: $needle"
  fi
done

echo
echo "=== Stage 8T evidence checks ==="
if [ -f "$STAGE8T_EVIDENCE" ]; then
  pass "Stage 8T evidence exists"
else
  check_fail "missing Stage 8T evidence: $STAGE8T_EVIDENCE"
fi

python3 - "$STAGE8T_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.exists():
    print("CHECK: evidence file missing")
    sys.exit(1)

data = json.loads(path.read_text(encoding="utf-8"))

expected = {
    "final_result": "pass",
    "post_before": "404",
    "post_enabled": "200",
    "post_after": "404",
    "health_before": "200",
    "health_enabled": "200",
    "health_after": "200",
    "queue_before_clean": "true",
    "queue_enabled_clean": "true",
    "queue_after_clean": "true",
    "power_timer_after": "active",
    "remediation_timer_after": "active",
    "legacy_timer_active_after": "inactive",
    "legacy_timer_enabled_after": "disabled",
}

bad = []
for key, value in expected.items():
    actual = str(data.get(key))
    print(f"{key}={actual}")
    if actual != value:
        bad.append((key, value, actual))

if bad:
    print("CHECK: Stage 8T evidence did not match expected values")
    for key, expected_value, actual in bad:
        print(f"  {key}: expected={expected_value} actual={actual}")
    sys.exit(2)

print("PASS: Stage 8T evidence values match expected activation/rollback proof")
PY
evidence_check=$?
if [ "$evidence_check" = "0" ]; then
  pass "Stage 8T evidence confirms activation and rollback"
else
  check_fail "Stage 8T evidence validation failed"
fi

echo
echo "=== frontend/browser no-traffic checks ==="
if [ -f "$APP_JS" ]; then
  pass "app.js exists"
else
  check_fail "missing $APP_JS"
fi

if [ -f "$STUB" ]; then
  pass "router shadow-read stub exists"
else
  check_fail "missing $STUB"
fi

if grep -q "/api/router/dry-run" "$APP_JS" "$STUB" 2>/dev/null; then
  check_fail "frontend app/stub contains /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" "$STUB" 2>/dev/null | sed -n '1,80p'
else
  pass "frontend app/stub contains no /api/router/dry-run string"
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

echo
echo "=== live backend disabled checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage8u-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage8u-health.err || printf 'curl_failed')"
echo "health_code=$health_code"
if [ "$health_code" = "200" ]; then
  pass "live controller /health returned HTTP 200"
else
  check_fail "live controller /health did not return HTTP 200"
  sed -n '1,80p' /tmp/stage8u-health.err 2>/dev/null || true
  sed -n '1,80p' /tmp/stage8u-health.out 2>/dev/null || true
fi

post_code="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage8u disabled checkpoint","source":"stage8u","surface":"backend-only"}' \
  -o /tmp/stage8u-router-post.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage8u-router-post.err || printf 'curl_failed')"
echo "post_code=$post_code"
if [ "$post_code" = "404" ]; then
  pass "POST /api/router/dry-run remains HTTP 404"
else
  check_fail "POST /api/router/dry-run did not remain HTTP 404"
  sed -n '1,120p' /tmp/stage8u-router-post.out 2>/dev/null || true
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
queue_code="$(curl -sS --max-time 5 -o /tmp/stage8u-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage8u-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage8u-system-status.json <<'PY'
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
    sed -n '1,160p' /tmp/stage8u-system-status.json 2>/dev/null || true
  fi
else
  check_fail "could not read queue/system status"
  sed -n '1,80p' /tmp/stage8u-system-status.err 2>/dev/null || true
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
echo "=== Stage 8U smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8U evidence review and no-browser-traffic checkpoint verified"
else
  echo "FAIL: Stage 8U evidence review/no-browser-traffic checkpoint found issues"
fi

exit "$fail"
