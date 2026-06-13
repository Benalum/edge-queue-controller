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

REPORT="docs/generated/stage-10c-frontend-load-route-boundary-baseline-inspection.md"
EVIDENCE="docs/generated/stage-10c-frontend-load-route-boundary-baseline-inspection-evidence.json"
SMOKE="ops/smoke/check-stage-10c-frontend-load-route-boundary-baseline-inspection.sh"

STAGE10B_REPORT="docs/generated/stage-10b-router-rollout-pause-platform-stability-handoff-checkpoint.md"
STAGE9Z_EVIDENCE="docs/generated/stage-9z-end-of-stage-9-router-shadow-read-rollout-posture-checkpoint-evidence.json"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"
STATUS_URL="$FRONTEND_BASE/api/system/status"

METRICS="/tmp/stage10c-route-metrics.tsv"
LIVE_STATUS="/tmp/stage10c-persistent-rollout-status.json"

export STAGE10C_FINAL_RESULT="unknown"
export STAGE10C_HEALTH_CODE="unknown"
export STAGE10C_STATUS_CODE="unknown"
export STAGE10C_POST_CODE="unknown"
export STAGE10C_ENV_ABSENT="unknown"
export STAGE10C_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" "$METRICS" "$APP_JS" "$STUB" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

evidence = Path(sys.argv[1])
metrics_path = Path(sys.argv[2])
app_js = Path(sys.argv[3])
stub = Path(sys.argv[4])

routes = []
if metrics_path.exists():
    for line in metrics_path.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if len(parts) == 5:
            name, url, code, time_total, size_download = parts
            routes.append({
                "name": name,
                "url": url,
                "code": code,
                "time_total_seconds": time_total,
                "size_download_bytes": size_download,
            })

data = {
    "stage": "10C",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "frontend load-time and route-boundary baseline inspection",
    "health_code": os.environ.get("STAGE10C_HEALTH_CODE"),
    "status_code": os.environ.get("STAGE10C_STATUS_CODE"),
    "post_code": os.environ.get("STAGE10C_POST_CODE"),
    "env_absent": os.environ.get("STAGE10C_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE10C_QUEUE_CLEAN"),
    "app_js_bytes": app_js.stat().st_size if app_js.exists() else None,
    "stub_bytes": stub.stat().st_size if stub.exists() else None,
    "route_metrics": routes,
    "final_result": os.environ.get("STAGE10C_FINAL_RESULT"),
}
evidence.parent.mkdir(parents=True, exist_ok=True)
evidence.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {evidence}")
PY
}

echo "=== Stage 10C smoke: frontend load-time and route-boundary baseline inspection ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10C report exists" || check_fail "Stage 10C report missing"
[ -x "$SMOKE" ] && pass "Stage 10C smoke script is executable" || check_fail "Stage 10C smoke script missing or not executable"

for needle in \
  "Stage 10C records a frontend load-time and route-boundary baseline before platform stability changes." \
  "Stage 10C is inspection-only." \
  "Stage 10C does not modify frontend/wrapper-ui/app.js." \
  "Stage 10C does not modify edge_controller.py." \
  "Stage 10C does not restart live services." \
  "Stage 10C does not add a mutation endpoint." \
  "Stage 10C does not enable browser router traffic." \
  "Stage 10C does not enable backend router dry-run." \
  "Stage 10C does not send frontend router POST traffic." \
  "Reduce frontend load weight and unnecessary startup fetches without breaking logged-in/logged-out route boundaries."
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10B/9Z validation ==="
[ -f "$STAGE10B_REPORT" ] && pass "Stage 10B report exists" || check_fail "Stage 10B report missing"
[ -f "$STAGE9Z_EVIDENCE" ] && pass "Stage 9Z evidence exists" || check_fail "Stage 9Z evidence missing"

python3 - "$STAGE9Z_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
checks = {
    "final_result": {"pass"},
    "health_code": {"200"},
    "status_code": {"200"},
    "status_runtime": {"pass"},
    "status_mutation_code": {"404", "405"},
    "request_mutation_code": {"404", "405"},
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
    print("CHECK: Stage 9Z evidence mismatch")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 9Z evidence confirms safe parked router posture")
PY
[ "$?" = "0" ] && pass "Stage 9Z evidence values confirmed" || check_fail "Stage 9Z evidence validation failed"

echo
echo "=== source safety checks ==="
python3 -m py_compile "$CONTROLLER" \
  && pass "edge_controller.py compiles" \
  || check_fail "edge_controller.py failed py_compile"

if grep -RInE '@app\.(post|put|patch|delete)\("/api/router/persistent-rollout/status"|@app\.(post|put|patch|delete)\(PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH|/api/router/persistent-rollout/request' "$CONTROLLER" 2>/dev/null; then
  check_fail "persistent rollout mutation route unexpectedly exists"
else
  pass "persistent rollout mutation route does not exist"
fi

if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js directly contains /api/router/dry-run"
else
  pass "app.js contains no /api/router/dry-run"
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

echo
echo "=== local asset size baseline ==="
if [ -f "$APP_JS" ]; then
  app_bytes="$(wc -c < "$APP_JS" | tr -d ' ')"
  app_lines="$(wc -l < "$APP_JS" | tr -d ' ')"
  echo "app_js_bytes=$app_bytes"
  echo "app_js_lines=$app_lines"
  pass "recorded local app.js size baseline"
else
  check_fail "missing local app.js"
fi

if [ -f "$STUB" ]; then
  stub_bytes="$(wc -c < "$STUB" | tr -d ' ')"
  stub_lines="$(wc -l < "$STUB" | tr -d ' ')"
  echo "stub_bytes=$stub_bytes"
  echo "stub_lines=$stub_lines"
  pass "recorded local router shadow-read stub size baseline"
else
  check_fail "missing router shadow-read stub"
fi

echo
echo "=== live route/load baseline ==="
: > "$METRICS"

record_route() {
  name="$1"
  path="$2"
  url="$FRONTEND_BASE$path"
  out="/tmp/stage10c-${name//[^A-Za-z0-9_]/_}.out"
  result="$(curl -sS -L --max-time 10 -o "$out" -w "%{http_code}\t%{time_total}\t%{size_download}" "$url" 2>"/tmp/stage10c-${name//[^A-Za-z0-9_]/_}.err" || printf 'curl_failed\t0\t0')"
  code="$(printf '%s' "$result" | cut -f1)"
  time_total="$(printf '%s' "$result" | cut -f2)"
  size_download="$(printf '%s' "$result" | cut -f3)"
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$url" "$code" "$time_total" "$size_download" | tee -a "$METRICS"
}

record_route root "/"
record_route chat "/chat"
record_route study "/study"
record_route companion "/companion"
record_route profile "/profile"
record_route admin "/admin"
record_route system "/system"
record_route styles_css "/styles.css"
record_route app_js "/app.js"
record_route queued_chat_config "/queued_chat_config.js"
record_route queued_chat_status "/queued_chat_status.js"
record_route router_shadow_read_stub "/router_shadow_read_stub.js"
record_route api_system_status "/api/system/status"

python3 - "$METRICS" <<'PY'
import sys
from pathlib import Path

metrics = Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
required_ok = {"root", "styles_css", "app_js", "router_shadow_read_stub", "api_system_status"}
bad = []

for line in metrics:
    name, url, code, time_total, size_download = line.split("\t")
    print(f"{name}: code={code} time={time_total}s size={size_download} url={url}")
    if name in required_ok and code != "200":
        bad.append((name, code))

if bad:
    print("CHECK: required frontend baseline route failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: required frontend baseline routes returned HTTP 200")
PY
[ "$?" = "0" ] && pass "required frontend baseline routes returned HTTP 200" || check_fail "required frontend baseline routes did not all return HTTP 200"

echo
echo "=== live router parked posture ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage10c-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10c-health.err || printf 'curl_failed')"
STAGE10C_HEALTH_CODE="$health_code"
export STAGE10C_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

status_code="$(curl -sS --max-time 5 -o "$LIVE_STATUS" -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10c-rollout-status.err || printf 'curl_failed')"
STAGE10C_STATUS_CODE="$status_code"
export STAGE10C_STATUS_CODE
echo "rollout_status_code=$status_code"
[ "$status_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10c frontend load baseline","source":"stage10c","surface":"backend-only"}' \
  -o /tmp/stage10c-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10c-router-post.err || printf 'curl_failed')"
STAGE10C_POST_CODE="$post_code"
export STAGE10C_POST_CODE
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE10C_ENV_ABSENT="false"
  export STAGE10C_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE10C_ENV_ABSENT="true"
  export STAGE10C_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage10c-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10c-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10c-system-status.json <<'PY'
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
  if [ "$?" = "0" ]; then
    STAGE10C_QUEUE_CLEAN="true"
    export STAGE10C_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE10C_QUEUE_CLEAN="false"
    export STAGE10C_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE10C_QUEUE_CLEAN="status_failed"
  export STAGE10C_QUEUE_CLEAN
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
echo "=== write Stage 10C evidence ==="
if [ "$fail" = "0" ]; then
  STAGE10C_FINAL_RESULT="pass"
else
  STAGE10C_FINAL_RESULT="fail"
fi
export STAGE10C_FINAL_RESULT
write_evidence

echo
echo "=== Stage 10C smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10C frontend load-time and route-boundary baseline verified"
else
  echo "FAIL: Stage 10C frontend load-time and route-boundary baseline found issues"
fi

exit "$fail"
