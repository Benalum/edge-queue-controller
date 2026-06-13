#!/usr/bin/env bash
set -u

fail=0
activated=0
dropin_created=0

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
if [ -z "${ROOT:-}" ] || [ ! -d "$ROOT" ]; then
  ROOT="."
fi

cd "$ROOT" || {
  echo "CHECK: could not cd into repo root"
  exit 1
}

REPORT="docs/generated/stage-8t-live-backend-router-dry-run-controlled-activation-rollback.md"
EVIDENCE="docs/generated/stage-8t-live-backend-router-dry-run-controlled-activation-rollback-evidence.json"
SMOKE="ops/smoke/check-stage-8t-live-backend-router-dry-run-controlled-activation-rollback.sh"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

SERVICE="edge-queue-controller"
DROPIN_DIR="/etc/systemd/system/${SERVICE}.service.d"
DROPIN="${DROPIN_DIR}/85-stage8t-router-dry-run.conf"
FLAG="EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1"

BASE="http://127.0.0.1:7070"
STATUS_URL="http://127.0.0.1:8787/api/system/status"

pass() {
  echo "PASS: $1"
}

check_fail() {
  echo "CHECK: $1"
  fail=1
}

record_evidence() {
  python3 - "$EVIDENCE" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
evidence = {
    "stage": "8T",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "controlled live backend router dry-run activation and rollback",
    "health_before": os.environ.get("STAGE8T_HEALTH_BEFORE"),
    "post_before": os.environ.get("STAGE8T_POST_BEFORE"),
    "health_enabled": os.environ.get("STAGE8T_HEALTH_ENABLED"),
    "post_enabled": os.environ.get("STAGE8T_POST_ENABLED"),
    "health_after": os.environ.get("STAGE8T_HEALTH_AFTER"),
    "post_after": os.environ.get("STAGE8T_POST_AFTER"),
    "queue_before_clean": os.environ.get("STAGE8T_QUEUE_BEFORE_CLEAN"),
    "queue_enabled_clean": os.environ.get("STAGE8T_QUEUE_ENABLED_CLEAN"),
    "queue_after_clean": os.environ.get("STAGE8T_QUEUE_AFTER_CLEAN"),
    "power_timer_after": os.environ.get("STAGE8T_POWER_TIMER_AFTER"),
    "remediation_timer_after": os.environ.get("STAGE8T_REMEDIATION_TIMER_AFTER"),
    "legacy_timer_active_after": os.environ.get("STAGE8T_LEGACY_TIMER_ACTIVE_AFTER"),
    "legacy_timer_enabled_after": os.environ.get("STAGE8T_LEGACY_TIMER_ENABLED_AFTER"),
    "final_result": os.environ.get("STAGE8T_FINAL_RESULT"),
}
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {path}")
PY
}

wait_for_health() {
  label="$1"
  code=""

  for i in $(seq 1 20); do
    code="$(curl -sS --max-time 5 -o "/tmp/stage8t-health-${label}.out" -w "%{http_code}" "$BASE/health" 2>"/tmp/stage8t-health-${label}.err" || printf 'curl_failed')"
    if [ "$code" = "200" ]; then
      echo "$code"
      return 0
    fi
    sleep 1
  done

  echo "$code"
  return 1
}

env_has_flag() {
  systemctl show "$SERVICE" -p Environment --value 2>/dev/null \
    | tr ' ' '\n' \
    | grep -qx "$FLAG"
}

queue_clean() {
  label="$1"
  code="$(curl -sS --max-time 5 -o "/tmp/stage8t-system-status-${label}.json" -w "%{http_code}" "$STATUS_URL" 2>"/tmp/stage8t-system-status-${label}.err" || printf 'curl_failed')"
  echo "queue_status_${label}_code=$code"

  if [ "$code" != "200" ]; then
    return 1
  fi

  python3 - "/tmp/stage8t-system-status-${label}.json" <<'PY'
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
}

rollback() {
  echo
  echo "=== rollback: remove Stage 8T dry-run drop-in and restart controller ==="

  if [ "$dropin_created" = "1" ]; then
    sudo rm -f "$DROPIN" || check_fail "could not remove $DROPIN"
    sudo systemctl daemon-reload || check_fail "daemon-reload failed during rollback"
  fi

  if [ "$activated" = "1" ]; then
    sudo systemctl restart "$SERVICE" || check_fail "could not restart $SERVICE during rollback"
    activated=0
  fi
}

trap 'rollback' EXIT

echo "=== Stage 8T smoke: controlled live backend dry-run activation and rollback ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 8T report exists" || check_fail "Stage 8T report missing"
[ -x "$SMOKE" ] && pass "Stage 8T smoke script is executable" || check_fail "Stage 8T smoke script is missing or not executable"

echo
echo "=== repo cleanliness check allowing only Stage 8T files ==="
dirty_unexpected="$(git status --short | grep -vF "$REPORT" | grep -vF "$EVIDENCE" | grep -vF "$SMOKE" || true)"
if [ -z "$dirty_unexpected" ]; then
  pass "repo has no unexpected dirty files"
else
  check_fail "repo has unexpected dirty files"
  printf '%s\n' "$dirty_unexpected"
fi

echo
echo "=== Stage 8S ancestry check ==="
if git log --oneline -5 | grep -q "stage 8s"; then
  pass "recent history includes Stage 8S"
else
  check_fail "recent history does not show Stage 8S"
fi

echo
echo "=== frontend/browser safety checks before activation ==="
if grep -q "/api/router/dry-run" "$APP_JS" "$STUB" 2>/dev/null; then
  check_fail "frontend app/stub contains /api/router/dry-run"
  grep -n "/api/router/dry-run" "$APP_JS" "$STUB" 2>/dev/null | sed -n '1,80p'
else
  pass "frontend app/stub contains no /api/router/dry-run string"
fi

grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_ENABLED remains false" \
  || check_fail "ROUTER_SHADOW_READ_ENABLED=false marker missing"

grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" 2>/dev/null \
  && pass "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
  || check_fail "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"

echo
echo "=== pre-activation live safety checks ==="
STAGE8T_HEALTH_BEFORE="$(wait_for_health before || true)"
export STAGE8T_HEALTH_BEFORE
echo "health_before=$STAGE8T_HEALTH_BEFORE"
[ "$STAGE8T_HEALTH_BEFORE" = "200" ] && pass "health before activation is HTTP 200" || check_fail "health before activation failed"

STAGE8T_POST_BEFORE="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage8t pre activation disabled check","source":"stage8t","surface":"backend-only"}' \
  -o /tmp/stage8t-post-before.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage8t-post-before.err || printf 'curl_failed')"
export STAGE8T_POST_BEFORE
echo "post_before=$STAGE8T_POST_BEFORE"
[ "$STAGE8T_POST_BEFORE" = "404" ] && pass "POST /api/router/dry-run is disabled before activation" || check_fail "POST /api/router/dry-run was not 404 before activation"

if env_has_flag; then
  check_fail "$FLAG already enabled before activation"
else
  pass "$FLAG absent before activation"
fi

if queue_clean before; then
  STAGE8T_QUEUE_BEFORE_CLEAN="true"
  pass "queue clean before activation"
else
  STAGE8T_QUEUE_BEFORE_CLEAN="false"
  check_fail "queue not clean before activation"
fi
export STAGE8T_QUEUE_BEFORE_CLEAN

if [ -e "$DROPIN" ]; then
  check_fail "Stage 8T drop-in already exists: $DROPIN"
fi

if [ "$fail" != "0" ]; then
  STAGE8T_FINAL_RESULT="failed_before_activation"
  export STAGE8T_FINAL_RESULT
  record_evidence
  exit "$fail"
fi

echo
echo "=== activate backend dry-run using temporary systemd drop-in ==="
sudo mkdir -p "$DROPIN_DIR" || check_fail "could not create $DROPIN_DIR"
cat > /tmp/stage8t-router-dry-run.conf <<EOF
[Service]
Environment=$FLAG
EOF

sudo cp /tmp/stage8t-router-dry-run.conf "$DROPIN" || check_fail "could not write $DROPIN"
dropin_created=1

sudo systemctl daemon-reload || check_fail "systemctl daemon-reload failed"
sudo systemctl restart "$SERVICE" || check_fail "could not restart $SERVICE for activation"
activated=1

STAGE8T_HEALTH_ENABLED="$(wait_for_health enabled || true)"
export STAGE8T_HEALTH_ENABLED
echo "health_enabled=$STAGE8T_HEALTH_ENABLED"
[ "$STAGE8T_HEALTH_ENABLED" = "200" ] && pass "health after activation is HTTP 200" || check_fail "health after activation failed"

if env_has_flag; then
  pass "$FLAG present during controlled activation"
else
  check_fail "$FLAG not visible during controlled activation"
fi

echo
echo "=== call enabled backend dry-run endpoint directly ==="
STAGE8T_POST_ENABLED="$(curl -sS --max-time 15 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage8t controlled backend dry run only","source":"stage8t","surface":"backend-only"}' \
  -o /tmp/stage8t-post-enabled.json \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage8t-post-enabled.err || printf 'curl_failed')"
export STAGE8T_POST_ENABLED
echo "post_enabled=$STAGE8T_POST_ENABLED"

if [ "$STAGE8T_POST_ENABLED" = "200" ]; then
  pass "enabled backend dry-run POST returned HTTP 200"
else
  check_fail "enabled backend dry-run POST did not return HTTP 200"
  echo "--- enabled response body ---"
  sed -n '1,160p' /tmp/stage8t-post-enabled.json 2>/dev/null || true
  echo "--- enabled response err ---"
  sed -n '1,80p' /tmp/stage8t-post-enabled.err 2>/dev/null || true
fi

python3 - /tmp/stage8t-post-enabled.json <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception as exc:
    print(f"CHECK: enabled dry-run response was not valid JSON: {exc}")
    sys.exit(1)

print("enabled_response_top_level_keys=" + ",".join(sorted(map(str, data.keys()))))
text = json.dumps(data, sort_keys=True).lower()

if "error" in data and data.get("error"):
    print("CHECK: enabled dry-run JSON includes top-level error")
    sys.exit(2)

print("PASS: enabled dry-run response is valid JSON")
PY
json_check=$?
if [ "$json_check" = "0" ]; then
  pass "enabled dry-run JSON parsed"
else
  check_fail "enabled dry-run JSON validation failed"
fi

if queue_clean enabled; then
  STAGE8T_QUEUE_ENABLED_CLEAN="true"
  pass "queue remained clean after enabled dry-run call"
else
  STAGE8T_QUEUE_ENABLED_CLEAN="false"
  check_fail "queue did not remain clean after enabled dry-run call"
fi
export STAGE8T_QUEUE_ENABLED_CLEAN

echo
echo "=== explicit rollback now ==="
rollback

echo
echo "=== post-rollback safety checks ==="
STAGE8T_HEALTH_AFTER="$(wait_for_health after || true)"
export STAGE8T_HEALTH_AFTER
echo "health_after=$STAGE8T_HEALTH_AFTER"
[ "$STAGE8T_HEALTH_AFTER" = "200" ] && pass "health after rollback is HTTP 200" || check_fail "health after rollback failed"

if env_has_flag; then
  check_fail "$FLAG still enabled after rollback"
else
  pass "$FLAG absent after rollback"
fi

STAGE8T_POST_AFTER="$(curl -sS --max-time 5 -X POST \
  -H 'Content-Type: application/json' \
  -d '{"text":"stage8t post rollback disabled check","source":"stage8t","surface":"backend-only"}' \
  -o /tmp/stage8t-post-after.out \
  -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage8t-post-after.err || printf 'curl_failed')"
export STAGE8T_POST_AFTER
echo "post_after=$STAGE8T_POST_AFTER"
[ "$STAGE8T_POST_AFTER" = "404" ] && pass "POST /api/router/dry-run returned HTTP 404 after rollback" || check_fail "POST /api/router/dry-run did not return HTTP 404 after rollback"

if queue_clean after; then
  STAGE8T_QUEUE_AFTER_CLEAN="true"
  pass "queue clean after rollback"
else
  STAGE8T_QUEUE_AFTER_CLEAN="false"
  check_fail "queue not clean after rollback"
fi
export STAGE8T_QUEUE_AFTER_CLEAN

echo
echo "=== post-rollback frontend/browser safety checks ==="
if grep -q "/api/router/dry-run" "$APP_JS" "$STUB" 2>/dev/null; then
  check_fail "frontend app/stub contains /api/router/dry-run after rollback"
else
  pass "frontend app/stub still contains no /api/router/dry-run string"
fi

echo
echo "=== timer safety checks after rollback ==="
STAGE8T_POWER_TIMER_AFTER="$(systemctl is-active edge-queue-power-auto-tick.timer 2>/dev/null || true)"
STAGE8T_REMEDIATION_TIMER_AFTER="$(systemctl is-active edge-queue-remediation-tick.timer 2>/dev/null || true)"
STAGE8T_LEGACY_TIMER_ACTIVE_AFTER="$(systemctl is-active edge-queue-scheduler-tick.timer 2>/dev/null || true)"
STAGE8T_LEGACY_TIMER_ENABLED_AFTER="$(systemctl is-enabled edge-queue-scheduler-tick.timer 2>/dev/null || true)"
export STAGE8T_POWER_TIMER_AFTER
export STAGE8T_REMEDIATION_TIMER_AFTER
export STAGE8T_LEGACY_TIMER_ACTIVE_AFTER
export STAGE8T_LEGACY_TIMER_ENABLED_AFTER

echo "edge-queue-power-auto-tick.timer active=$STAGE8T_POWER_TIMER_AFTER"
echo "edge-queue-remediation-tick.timer active=$STAGE8T_REMEDIATION_TIMER_AFTER"
echo "edge-queue-scheduler-tick.timer active=$STAGE8T_LEGACY_TIMER_ACTIVE_AFTER enabled=$STAGE8T_LEGACY_TIMER_ENABLED_AFTER"

[ "$STAGE8T_POWER_TIMER_AFTER" = "active" ] && pass "modern power auto timer is active" || check_fail "modern power auto timer is not active"
[ "$STAGE8T_REMEDIATION_TIMER_AFTER" = "active" ] && pass "modern remediation timer is active" || check_fail "modern remediation timer is not active"

if [ "$STAGE8T_LEGACY_TIMER_ACTIVE_AFTER" = "inactive" ] || [ "$STAGE8T_LEGACY_TIMER_ACTIVE_AFTER" = "unknown" ]; then
  pass "legacy scheduler timer is not active"
else
  check_fail "legacy scheduler timer is unexpectedly active/state=$STAGE8T_LEGACY_TIMER_ACTIVE_AFTER"
fi

if [ "$STAGE8T_LEGACY_TIMER_ENABLED_AFTER" = "disabled" ] || [ "$STAGE8T_LEGACY_TIMER_ENABLED_AFTER" = "masked" ]; then
  pass "legacy scheduler timer is disabled/masked"
else
  check_fail "legacy scheduler timer is not disabled/masked; enabled_state=$STAGE8T_LEGACY_TIMER_ENABLED_AFTER"
fi

echo
echo "=== port 7076 temporary controller check ==="
if ss -ltnp 2>/dev/null | grep -q ':7076'; then
  check_fail "port 7076 appears to be listening"
  ss -ltnp | grep ':7076' || true
else
  pass "port 7076 is not listening"
fi

echo
echo "=== write Stage 8T evidence ==="
if [ "$fail" = "0" ]; then
  STAGE8T_FINAL_RESULT="pass"
else
  STAGE8T_FINAL_RESULT="fail"
fi
export STAGE8T_FINAL_RESULT
record_evidence

echo
echo "=== Stage 8T smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 8T controlled activation and rollback verified"
else
  echo "FAIL: Stage 8T controlled activation and rollback found issues"
fi

exit "$fail"
