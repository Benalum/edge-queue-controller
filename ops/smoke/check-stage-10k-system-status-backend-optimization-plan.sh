#!/usr/bin/env bash
set -u

fail=0

pass() { echo "PASS: $1"; }
check_fail() { echo "CHECK: $1"; fail=1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
cd "$ROOT" || {
  echo "CHECK: could not cd into repo root"
  exit 1
}

REPORT="docs/generated/stage-10k-system-status-backend-optimization-plan.md"
SMOKE="ops/smoke/check-stage-10k-system-status-backend-optimization-plan.sh"

STAGE10J_EVIDENCE="docs/generated/stage-10j-api-system-status-latency-inspection-checkpoint-evidence.json"
STAGE10I_EVIDENCE="docs/generated/stage-10i-deferred-loader-post-implementation-stability-checkpoint-evidence.json"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="$FRONTEND_BASE/api/system/status"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"

echo "=== Stage 10K smoke: system status backend optimization plan ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10K report exists" || check_fail "Stage 10K report missing"
[ -x "$SMOKE" ] && pass "Stage 10K smoke script is executable" || check_fail "Stage 10K smoke script missing or not executable"

for needle in \
  "Stage 10K converts the Stage 10J /api/system/status latency evidence into a backend optimization plan." \
  "Stage 10K is plan-only." \
  "Stage 10K does not modify frontend/wrapper-ui/app.js." \
  "Stage 10K does not modify frontend/wrapper-ui/index.html." \
  "Stage 10K does not modify edge_controller.py." \
  "Stage 10K does not restart live services." \
  "Stage 10K does not add a mutation endpoint." \
  "Stage 10K does not enable browser router traffic." \
  "Stage 10K does not enable backend router dry-run." \
  "Stage 10K does not send frontend router POST traffic." \
  "The primary optimization target is the backend work inside /system/status." \
  "Stage 10L should inspect the /system/status handler source in detail." \
  "Stage 10M should implement a short TTL cache around expensive /system/status sections." \
  "The transition is functionally safe now." \
  "Stage 10N: final transition-complete operational checkpoint."
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10J/10I evidence validation ==="
[ -f "$STAGE10J_EVIDENCE" ] && pass "Stage 10J evidence exists" || check_fail "Stage 10J evidence missing"
[ -f "$STAGE10I_EVIDENCE" ] && pass "Stage 10I evidence exists" || check_fail "Stage 10I evidence missing"

python3 - "$STAGE10J_EVIDENCE" "$STAGE10I_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

j = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
i = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

bad = []

checks_j = {
    "final_result": {"pass"},
    "health_code": {"200"},
    "rollout_status_code": {"200"},
    "post_code": {"404"},
    "env_absent": {"true", "True"},
    "queue_clean": {"true", "True"},
}

for key, allowed in checks_j.items():
    actual = str(j.get(key))
    print(f"stage10j.{key}={actual}")
    if actual not in allowed:
        bad.append((f"stage10j.{key}", sorted(allowed), actual))

summary = j.get("api_system_status_latency_summary", {})
print(f"stage10j.latency_summary={summary}")
mean = summary.get("mean_seconds")
count = summary.get("count")
try:
    mean_value = float(mean)
except Exception:
    mean_value = 0.0

if str(count) != "5":
    bad.append(("stage10j.api_system_status_latency_summary.count", "5", count))
if mean_value <= 1.0:
    bad.append(("stage10j.api_system_status_latency_summary.mean_seconds", ">1.0", mean))

checks_i = {
    "final_result": {"pass"},
    "post_code": {"404"},
    "env_absent": {"true", "True"},
    "queue_clean": {"true", "True"},
    "local_index_contains_stage10h_marker": {"true", "True"},
    "local_index_plain_status_script_count": {"0"},
}

for key, allowed in checks_i.items():
    actual = str(i.get(key))
    print(f"stage10i.{key}={actual}")
    if actual not in allowed:
        bad.append((f"stage10i.{key}", sorted(allowed), actual))

if bad:
    print("CHECK: Stage 10J/10I evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10J/10I evidence supports system status backend optimization plan")
PY
[ "$?" = "0" ] && pass "Stage 10J/10I evidence values confirmed" || check_fail "Stage 10J/10I evidence validation failed"

echo
echo "=== source safety checks ==="
python3 -m py_compile "$CONTROLLER" \
  && pass "edge_controller.py compiles" \
  || check_fail "edge_controller.py failed py_compile"

grep -n '@app.get("/system/status")' "$CONTROLLER" \
  && pass "system status route exists" \
  || check_fail "system status route not found"

grep -n 'def system_status' "$CONTROLLER" \
  && pass "system_status handler exists" \
  || check_fail "system_status handler not found"

for helper in \
  "_system_pct_status" \
  "_system_frontend_wrapper_status" \
  "_system_queue_status_from_worker" \
  "_system_power_automation_status" \
  "_system_status_normalized_block" \
  "_system_ct101_laptop_queue_worker_status"
do
  grep -n "def $helper" "$CONTROLLER" \
    && pass "status helper exists: $helper" \
    || check_fail "status helper missing: $helper"
done

if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js directly contains /api/router/dry-run"
else
  pass "app.js contains no /api/router/dry-run"
fi

grep -q "stage10hDeferredQueuedChatStatusScript" "$INDEX_HTML" \
  && pass "index.html contains Stage 10H deferred loader marker" \
  || check_fail "index.html missing Stage 10H deferred loader marker"

if grep -Eq '<script\s+src=["'\'']/queued_chat_status\.js["'\'']\s*>\s*</script>' "$INDEX_HTML"; then
  check_fail "index.html still has plain queued_chat_status.js script tag"
else
  pass "index.html has no plain queued_chat_status.js script tag"
fi

grep -q 'const ROUTER_DRY_RUN_ENDPOINT = "/api/router/dry-run";' "$STUB" \
  && pass "stub contains backend dry-run endpoint boundary" \
  || check_fail "stub missing backend dry-run endpoint boundary"

grep -q "const ROUTER_SHADOW_READ_ENABLED = false;" "$STUB" \
  && pass "ROUTER_SHADOW_READ_ENABLED remains false" \
  || check_fail "ROUTER_SHADOW_READ_ENABLED=false marker missing"

grep -q "const ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT = false;" "$STUB" \
  && pass "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT remains false" \
  || check_fail "ROUTER_SHADOW_READ_FEATURE_FLAG_DEFAULT=false marker missing"

if grep -nE '@app\.(post|put|patch|delete)' "$CONTROLLER" | grep -E 'persistent-rollout/status|persistent-rollout/request|PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH'; then
  check_fail "persistent rollout mutation route unexpectedly exists"
else
  pass "persistent rollout mutation route does not exist"
fi

echo
echo "=== live parked posture checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage10k-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10k-health.err || printf 'curl_failed')"
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

rollout_code="$(curl -sS --max-time 5 -o /tmp/stage10k-rollout-status.json -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10k-rollout-status.err || printf 'curl_failed')"
echo "rollout_status_code=$rollout_code"
[ "$rollout_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10k system status optimization plan","source":"stage10k","surface":"backend-only"}' \
  -o /tmp/stage10k-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10k-router-post.err || printf 'curl_failed')"
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  check_fail "backend dry-run env is enabled"
else
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 10 -o /tmp/stage10k-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10k-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10k-system-status.json <<'PY'
import json
import sys

data = json.load(open(sys.argv[1], "r", encoding="utf-8"))
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
for label, q, r, f in matches:
    print(f"{label}: queued={q} running={r} failed={f}")

sys.exit(0 if any(str(q) == "0" and str(r) == "0" and str(f) == "0" for _, q, r, f in matches) else 2)
PY
  [ "$?" = "0" ] && pass "queue clean state confirmed with queued=0 running=0 failed=0" || check_fail "queue clean state was not confirmed"
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
else
  pass "port 7076 is not listening"
fi

echo
echo "=== Stage 10K smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10K system status backend optimization plan verified"
else
  echo "FAIL: Stage 10K system status backend optimization plan found issues"
fi

exit "$fail"
