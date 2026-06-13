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

REPORT="docs/generated/stage-10g-deferred-queued-status-script-loader-preflight.md"
EVIDENCE="docs/generated/stage-10g-deferred-queued-status-script-loader-preflight-evidence.json"
SMOKE="ops/smoke/check-stage-10g-deferred-queued-status-script-loader-preflight.sh"

STAGE10F_REPORT="docs/generated/stage-10f-deferred-status-load-implementation-plan.md"
STAGE10E_EVIDENCE="docs/generated/stage-10e-frontend-startup-fetch-behavior-inspection-evidence.json"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"
QUEUED_CONFIG="frontend/wrapper-ui/queued_chat_config.js"
QUEUED_STATUS="frontend/wrapper-ui/queued_chat_status.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"
STATUS_URL="$FRONTEND_BASE/api/system/status"

export STAGE10G_FINAL_RESULT="unknown"
export STAGE10G_HEALTH_CODE="unknown"
export STAGE10G_ROLLOUT_STATUS_CODE="unknown"
export STAGE10G_POST_CODE="unknown"
export STAGE10G_ENV_ABSENT="unknown"
export STAGE10G_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" "$INDEX_HTML" "$QUEUED_CONFIG" "$QUEUED_STATUS" "$APP_JS" "$STUB" <<'PY'
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

evidence = Path(sys.argv[1])
paths = {
    "index_html": Path(sys.argv[2]),
    "queued_chat_config": Path(sys.argv[3]),
    "queued_chat_status": Path(sys.argv[4]),
    "app_js": Path(sys.argv[5]),
    "stub": Path(sys.argv[6]),
}

patterns = {
    "fetch_calls": r"\bfetch\s*\(",
    "api_system_status": r"/api/system/status",
    "queue_status_api": r"/api/chat/queue/status|queue/status",
    "queued_chat_config_js": r"queued_chat_config\.js",
    "queued_chat_status_js": r"queued_chat_status\.js",
    "set_interval": r"\bsetInterval\s*\(",
    "set_timeout": r"\bsetTimeout\s*\(",
    "dom_content_loaded": r"DOMContentLoaded",
    "window_load": r"addEventListener\s*\(\s*['\"]load['\"]",
    "local_storage": r"localStorage",
    "window_globals": r"\bwindow\.",
    "document_refs": r"\bdocument\.",
}

counts = {}
samples = {}

for label, path in paths.items():
    text = path.read_text(encoding="utf-8", errors="replace") if path.exists() else ""
    counts[label] = {
        "exists": path.exists(),
        "bytes": path.stat().st_size if path.exists() else None,
        "lines": text.count("\n") + 1 if text else 0,
    }
    samples[label] = {}
    for pname, pattern in patterns.items():
        matches = []
        for i, line in enumerate(text.splitlines(), start=1):
            if re.search(pattern, line):
                matches.append({"line": i, "text": line[:260]})
        counts[label][pname] = len(matches)
        samples[label][pname] = matches[:30]

data = {
    "stage": "10G",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "deferred queued-status script loader implementation preflight",
    "health_code": os.environ.get("STAGE10G_HEALTH_CODE"),
    "rollout_status_code": os.environ.get("STAGE10G_ROLLOUT_STATUS_CODE"),
    "post_code": os.environ.get("STAGE10G_POST_CODE"),
    "env_absent": os.environ.get("STAGE10G_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE10G_QUEUE_CLEAN"),
    "counts": counts,
    "samples": samples,
    "final_result": os.environ.get("STAGE10G_FINAL_RESULT"),
}
evidence.parent.mkdir(parents=True, exist_ok=True)
evidence.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {evidence}")
PY
}

echo "=== Stage 10G smoke: deferred queued-status script loader preflight ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10G report exists" || check_fail "Stage 10G report missing"
[ -x "$SMOKE" ] && pass "Stage 10G smoke script is executable" || check_fail "Stage 10G smoke script missing or not executable"

for needle in \
  "Stage 10G performs a deferred queued-status script loader implementation preflight." \
  "Stage 10G is inspection/preflight only." \
  "Stage 10G does not modify frontend/wrapper-ui/app.js." \
  "Stage 10G does not modify frontend/wrapper-ui/index.html." \
  "Stage 10G does not modify queued_chat_config.js." \
  "Stage 10G does not modify queued_chat_status.js." \
  "Stage 10G does not modify edge_controller.py." \
  "Stage 10G does not restart live services." \
  "Stage 10G does not add a mutation endpoint." \
  "Stage 10G does not enable browser router traffic." \
  "Stage 10G does not enable backend router dry-run." \
  "Stage 10G does not send frontend router POST traffic." \
  "Stage 10G does not change runtime status polling behavior." \
  "Stage 10H may implement a tiny deferred script loader for queued_chat_status.js." \
  "Keep queued_chat_config.js loading before queued_chat_status.js." \
  "Preserve logged-in/logged-out route boundaries."
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10F/10E validation ==="
[ -f "$STAGE10F_REPORT" ] && pass "Stage 10F report exists" || check_fail "Stage 10F report missing"
[ -f "$STAGE10E_EVIDENCE" ] && pass "Stage 10E evidence exists" || check_fail "Stage 10E evidence missing"

grep -Fq "The safest first runtime optimization should be deferred non-critical status loading." "$STAGE10F_REPORT" \
  && pass "Stage 10F selected deferred non-critical status loading" \
  || check_fail "Stage 10F selected direction text missing"

python3 - "$STAGE10E_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
checks = {
    "final_result": {"pass"},
    "health_code": {"200"},
    "rollout_status_code": {"200"},
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
    print("CHECK: Stage 10E evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)
print("PASS: Stage 10E evidence values confirmed")
PY
[ "$?" = "0" ] && pass "Stage 10E evidence values confirmed" || check_fail "Stage 10E evidence validation failed"

echo
echo "=== source file existence and script order checks ==="
[ -f "$APP_JS" ] && pass "app.js exists" || check_fail "missing app.js"
[ -f "$INDEX_HTML" ] && pass "index.html exists" || check_fail "missing index.html"
[ -f "$STUB" ] && pass "router shadow-read stub exists" || check_fail "missing router shadow-read stub"
[ -f "$QUEUED_CONFIG" ] && pass "queued_chat_config.js exists" || check_fail "missing queued_chat_config.js"
[ -f "$QUEUED_STATUS" ] && pass "queued_chat_status.js exists" || check_fail "missing queued_chat_status.js"

python3 - "$INDEX_HTML" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
config_pos = text.find("queued_chat_config.js")
status_pos = text.find("queued_chat_status.js")
print(f"queued_chat_config_pos={config_pos}")
print(f"queued_chat_status_pos={status_pos}")

if config_pos < 0 or status_pos < 0:
    print("CHECK: queued script references missing from index.html")
    sys.exit(2)

if config_pos < status_pos:
    print("PASS: queued_chat_config.js is referenced before queued_chat_status.js")
    sys.exit(0)

print("CHECK: queued_chat_config.js is not before queued_chat_status.js")
sys.exit(3)
PY
[ "$?" = "0" ] && pass "queued config/status script order confirmed" || check_fail "queued config/status script order check failed"

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
echo "=== queued script behavior inspection ==="
echo "--- queued_chat_config.js references ---"
grep -nE "window\.|fetch\s*\(|setInterval\s*\(|setTimeout\s*\(|DOMContentLoaded|addEventListener\s*\(\s*['\"]load['\"]|queue|Queue|status|Status" "$QUEUED_CONFIG" \
  | sed -n '1,180p' || true

echo
echo "--- queued_chat_status.js references ---"
grep -nE "window\.|fetch\s*\(|/api/system/status|/api/chat/queue/status|queue/status|setInterval\s*\(|setTimeout\s*\(|DOMContentLoaded|addEventListener\s*\(\s*['\"]load['\"]|queue|Queue|status|Status" "$QUEUED_STATUS" \
  | sed -n '1,260p' || true

python3 - "$QUEUED_CONFIG" "$QUEUED_STATUS" <<'PY'
import re
import sys
from pathlib import Path

files = {
    "queued_chat_config": Path(sys.argv[1]),
    "queued_chat_status": Path(sys.argv[2]),
}
patterns = {
    "fetch_calls": r"\bfetch\s*\(",
    "api_system_status": r"/api/system/status",
    "queue_status_api": r"/api/chat/queue/status|queue/status",
    "set_interval": r"\bsetInterval\s*\(",
    "set_timeout": r"\bsetTimeout\s*\(",
    "dom_content_loaded": r"DOMContentLoaded",
    "window_load": r"addEventListener\s*\(\s*['\"]load['\"]",
    "window_globals": r"\bwindow\.",
    "document_refs": r"\bdocument\.",
}
for label, path in files.items():
    text = path.read_text(encoding="utf-8", errors="replace")
    print(f"{label}_bytes={path.stat().st_size}")
    for name, pattern in patterns.items():
        count = sum(1 for line in text.splitlines() if re.search(pattern, line))
        print(f"{label}_{name}_line_count={count}")

print("PASS: queued script behavior reference counts recorded")
PY
[ "$?" = "0" ] && pass "queued script behavior counts recorded" || check_fail "queued script behavior count failed"

echo
echo "=== live router parked posture checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage10g-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10g-health.err || printf 'curl_failed')"
STAGE10G_HEALTH_CODE="$health_code"
export STAGE10G_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

rollout_code="$(curl -sS --max-time 5 -o /tmp/stage10g-rollout-status.json -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10g-rollout-status.err || printf 'curl_failed')"
STAGE10G_ROLLOUT_STATUS_CODE="$rollout_code"
export STAGE10G_ROLLOUT_STATUS_CODE
echo "rollout_status_code=$rollout_code"
[ "$rollout_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10g queued status loader preflight","source":"stage10g","surface":"backend-only"}' \
  -o /tmp/stage10g-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10g-router-post.err || printf 'curl_failed')"
STAGE10G_POST_CODE="$post_code"
export STAGE10G_POST_CODE
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE10G_ENV_ABSENT="false"
  export STAGE10G_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE10G_ENV_ABSENT="true"
  export STAGE10G_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== live frontend static availability ==="
for path in "/" "/app.js" "/styles.css" "/queued_chat_config.js" "/queued_chat_status.js" "/router_shadow_read_stub.js" "/api/system/status"; do
  code="$(curl -sS --max-time 10 -o "/tmp/stage10g-${path//[^A-Za-z0-9_]/_}.out" -w "%{http_code}" "$FRONTEND_BASE$path" 2>/tmp/stage10g-frontend.err || printf 'curl_failed')"
  echo "$path code=$code"
  if [ "$code" = "200" ]; then
    pass "live frontend path $path returned HTTP 200"
  else
    check_fail "live frontend path $path did not return HTTP 200"
  fi
done

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage10g-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10g-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10g-system-status.json <<'PY'
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
    STAGE10G_QUEUE_CLEAN="true"
    export STAGE10G_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE10G_QUEUE_CLEAN="false"
    export STAGE10G_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE10G_QUEUE_CLEAN="status_failed"
  export STAGE10G_QUEUE_CLEAN
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
echo "=== write Stage 10G evidence ==="
if [ "$fail" = "0" ]; then
  STAGE10G_FINAL_RESULT="pass"
else
  STAGE10G_FINAL_RESULT="fail"
fi
export STAGE10G_FINAL_RESULT
write_evidence

echo
echo "=== Stage 10G smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10G deferred queued-status script loader preflight verified"
else
  echo "FAIL: Stage 10G deferred queued-status script loader preflight found issues"
fi

exit "$fail"
