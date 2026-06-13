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

REPORT="docs/generated/stage-10e-frontend-startup-fetch-behavior-inspection.md"
EVIDENCE="docs/generated/stage-10e-frontend-startup-fetch-behavior-inspection-evidence.json"
SMOKE="ops/smoke/check-stage-10e-frontend-startup-fetch-behavior-inspection.sh"

STAGE10C_EVIDENCE="docs/generated/stage-10c-frontend-load-route-boundary-baseline-inspection-evidence.json"
STAGE10D_REPORT="docs/generated/stage-10d-frontend-performance-target-selection-plan.md"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"
STATUS_URL="$FRONTEND_BASE/api/system/status"

INSPECT_DIR="/tmp/stage10e-inspection"
mkdir -p "$INSPECT_DIR"

export STAGE10E_FINAL_RESULT="unknown"
export STAGE10E_HEALTH_CODE="unknown"
export STAGE10E_ROLLOUT_STATUS_CODE="unknown"
export STAGE10E_POST_CODE="unknown"
export STAGE10E_ENV_ABSENT="unknown"
export STAGE10E_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" "$APP_JS" "$INDEX_HTML" "$STUB" "$INSPECT_DIR" <<'PY'
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

evidence = Path(sys.argv[1])
app_js = Path(sys.argv[2])
index_html = Path(sys.argv[3])
stub = Path(sys.argv[4])
inspect_dir = Path(sys.argv[5])

files = {
    "app_js": app_js,
    "index_html": index_html,
    "stub": stub,
}

patterns = {
    "api_system_status": r"/api/system/status",
    "queued_chat_status_js": r"queued_chat_status\.js",
    "queued_chat_config_js": r"queued_chat_config\.js",
    "fetch_calls": r"\bfetch\s*\(",
    "set_interval": r"\bsetInterval\s*\(",
    "set_timeout": r"\bsetTimeout\s*\(",
    "dom_content_loaded": r"DOMContentLoaded",
    "window_load": r"addEventListener\s*\(\s*['\"]load['\"]",
    "status_terms": r"status|Status|systemStatus|SystemStatus",
    "queue_terms": r"queue|Queue|queued",
    "startup_terms": r"init|initialize|bootstrap|startup|render",
}

counts = {}
samples = {}

for label, path in files.items():
    text = path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""
    counts[label] = {"bytes": path.stat().st_size if path.exists() else None, "lines": text.count("\n") + 1 if text else 0}
    samples[label] = {}
    for pname, pattern in patterns.items():
        matches = []
        for i, line in enumerate(text.splitlines(), start=1):
            if re.search(pattern, line):
                matches.append({"line": i, "text": line[:240]})
        counts[label][pname] = len(matches)
        samples[label][pname] = matches[:25]

route_metrics = []
stage10c = Path("docs/generated/stage-10c-frontend-load-route-boundary-baseline-inspection-evidence.json")
if stage10c.exists():
    try:
        route_metrics = json.loads(stage10c.read_text(encoding="utf-8")).get("route_metrics", [])
    except Exception:
        route_metrics = []

data = {
    "stage": "10E",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "frontend startup fetch behavior inspection",
    "health_code": os.environ.get("STAGE10E_HEALTH_CODE"),
    "rollout_status_code": os.environ.get("STAGE10E_ROLLOUT_STATUS_CODE"),
    "post_code": os.environ.get("STAGE10E_POST_CODE"),
    "env_absent": os.environ.get("STAGE10E_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE10E_QUEUE_CLEAN"),
    "counts": counts,
    "samples": samples,
    "stage10c_route_metrics": route_metrics,
    "final_result": os.environ.get("STAGE10E_FINAL_RESULT"),
}
evidence.parent.mkdir(parents=True, exist_ok=True)
evidence.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {evidence}")
PY
}

echo "=== Stage 10E smoke: frontend startup fetch behavior inspection ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10E report exists" || check_fail "Stage 10E report missing"
[ -x "$SMOKE" ] && pass "Stage 10E smoke script is executable" || check_fail "Stage 10E smoke script missing or not executable"

for needle in \
  "Stage 10E inspects frontend startup fetch behavior before any performance optimization is implemented." \
  "Stage 10E is inspection-only." \
  "Stage 10E does not modify frontend/wrapper-ui/app.js." \
  "Stage 10E does not modify edge_controller.py." \
  "Stage 10E does not restart live services." \
  "Stage 10E does not add a mutation endpoint." \
  "Stage 10E does not enable browser router traffic." \
  "Stage 10E does not enable backend router dry-run." \
  "Stage 10E does not send frontend router POST traffic." \
  "Stage 10E does not change runtime status polling behavior." \
  "Stage 10D selected startup/status load pressure as the first optimization target." \
  "Stage 10F should convert the Stage 10E inspection into a narrow implementation plan."
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10C/10D validation ==="
[ -f "$STAGE10C_EVIDENCE" ] && pass "Stage 10C evidence exists" || check_fail "Stage 10C evidence missing"
[ -f "$STAGE10D_REPORT" ] && pass "Stage 10D report exists" || check_fail "Stage 10D report missing"

grep -Fq "The first optimization target should be startup/status load pressure." "$STAGE10D_REPORT" \
  && pass "Stage 10D selected startup/status load pressure" \
  || check_fail "Stage 10D target text missing"

python3 - "$STAGE10C_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
checks = {
    "final_result": {"pass"},
    "health_code": {"200"},
    "status_code": {"200"},
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

routes = {r.get("name"): r for r in data.get("route_metrics", [])}
api_status = routes.get("api_system_status")
if not api_status:
    bad.append(("api_system_status", "present", "missing"))
else:
    print(f"api_system_status_time={api_status.get('time_total_seconds')}")
    print(f"api_system_status_code={api_status.get('code')}")
    if str(api_status.get("code")) != "200":
        bad.append(("api_system_status.code", "200", api_status.get("code")))

if bad:
    print("CHECK: Stage 10C evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10C evidence supports Stage 10E inspection")
PY
[ "$?" = "0" ] && pass "Stage 10C evidence values confirmed" || check_fail "Stage 10C evidence validation failed"

echo
echo "=== source safety checks ==="
python3 -m py_compile "$CONTROLLER" \
  && pass "edge_controller.py compiles" \
  || check_fail "edge_controller.py failed py_compile"

[ -f "$APP_JS" ] && pass "app.js exists" || check_fail "missing app.js"
[ -f "$INDEX_HTML" ] && pass "index.html exists" || check_fail "missing index.html"
[ -f "$STUB" ] && pass "router shadow-read stub exists" || check_fail "missing router shadow-read stub"

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
echo "=== frontend startup/status reference inspection ==="
grep -nE "/api/system/status|queued_chat_status\.js|queued_chat_config\.js|fetch\s*\(|setInterval\s*\(|setTimeout\s*\(|DOMContentLoaded|addEventListener\s*\(\s*['\"]load['\"]|status|Status|queue|Queue|queued" "$APP_JS" \
  | sed -n '1,220p' \
  | tee "$INSPECT_DIR/app-js-startup-status-references.txt" || true

grep -nE "app\.js|styles\.css|queued_chat_status\.js|queued_chat_config\.js|router_shadow_read_stub\.js|defer|async" "$INDEX_HTML" \
  | sed -n '1,160p' \
  | tee "$INSPECT_DIR/index-html-script-references.txt" || true

python3 - "$APP_JS" "$INDEX_HTML" "$STUB" <<'PY'
import re
import sys
from pathlib import Path

files = {
    "app_js": Path(sys.argv[1]),
    "index_html": Path(sys.argv[2]),
    "stub": Path(sys.argv[3]),
}
patterns = {
    "api_system_status": r"/api/system/status",
    "queued_chat_status_js": r"queued_chat_status\.js",
    "queued_chat_config_js": r"queued_chat_config\.js",
    "fetch_calls": r"\bfetch\s*\(",
    "set_interval": r"\bsetInterval\s*\(",
    "set_timeout": r"\bsetTimeout\s*\(",
    "dom_content_loaded": r"DOMContentLoaded",
    "status_terms": r"status|Status|systemStatus|SystemStatus",
    "queue_terms": r"queue|Queue|queued",
}
for label, path in files.items():
    text = path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""
    print(f"{label}_bytes={path.stat().st_size if path.exists() else 0}")
    for name, pattern in patterns.items():
        count = sum(1 for line in text.splitlines() if re.search(pattern, line))
        print(f"{label}_{name}_line_count={count}")
print("PASS: startup/status reference counts recorded")
PY
[ "$?" = "0" ] && pass "startup/status reference counts recorded" || check_fail "startup/status reference count failed"

echo
echo "=== live router parked posture checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage10e-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10e-health.err || printf 'curl_failed')"
STAGE10E_HEALTH_CODE="$health_code"
export STAGE10E_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

rollout_code="$(curl -sS --max-time 5 -o /tmp/stage10e-rollout-status.json -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10e-rollout-status.err || printf 'curl_failed')"
STAGE10E_ROLLOUT_STATUS_CODE="$rollout_code"
export STAGE10E_ROLLOUT_STATUS_CODE
echo "rollout_status_code=$rollout_code"
[ "$rollout_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10e startup fetch inspection","source":"stage10e","surface":"backend-only"}' \
  -o /tmp/stage10e-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10e-router-post.err || printf 'curl_failed')"
STAGE10E_POST_CODE="$post_code"
export STAGE10E_POST_CODE
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE10E_ENV_ABSENT="false"
  export STAGE10E_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE10E_ENV_ABSENT="true"
  export STAGE10E_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== live frontend static availability ==="
for path in "/" "/app.js" "/styles.css" "/queued_chat_config.js" "/queued_chat_status.js" "/router_shadow_read_stub.js" "/api/system/status"; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage10e-${path//[^A-Za-z0-9_]/_}.out" -w "%{http_code}" "$FRONTEND_BASE$path" 2>/tmp/stage10e-frontend.err || printf 'curl_failed')"
  echo "$path code=$code"
  if [ "$code" = "200" ]; then
    pass "live frontend path $path returned HTTP 200"
  else
    check_fail "live frontend path $path did not return HTTP 200"
  fi
done

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage10e-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10e-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10e-system-status.json <<'PY'
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
    STAGE10E_QUEUE_CLEAN="true"
    export STAGE10E_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE10E_QUEUE_CLEAN="false"
    export STAGE10E_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE10E_QUEUE_CLEAN="status_failed"
  export STAGE10E_QUEUE_CLEAN
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
echo "=== write Stage 10E evidence ==="
if [ "$fail" = "0" ]; then
  STAGE10E_FINAL_RESULT="pass"
else
  STAGE10E_FINAL_RESULT="fail"
fi
export STAGE10E_FINAL_RESULT
write_evidence

echo
echo "=== Stage 10E smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10E frontend startup fetch behavior inspection verified"
else
  echo "FAIL: Stage 10E frontend startup fetch behavior inspection found issues"
fi

exit "$fail"
