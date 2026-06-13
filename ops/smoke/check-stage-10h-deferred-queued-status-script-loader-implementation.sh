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

REPORT="docs/generated/stage-10h-deferred-queued-status-script-loader-implementation.md"
EVIDENCE="docs/generated/stage-10h-deferred-queued-status-script-loader-implementation-evidence.json"
SMOKE="ops/smoke/check-stage-10h-deferred-queued-status-script-loader-implementation.sh"

STAGE10G_EVIDENCE="docs/generated/stage-10g-deferred-queued-status-script-loader-preflight-evidence.json"
STAGE10F_REPORT="docs/generated/stage-10f-deferred-status-load-implementation-plan.md"

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

LIVE_ROOT="/tmp/stage10h-live-root.html"
LIVE_APP="/tmp/stage10h-live-app.js"

export STAGE10H_FINAL_RESULT="unknown"
export STAGE10H_HEALTH_CODE="unknown"
export STAGE10H_ROLLOUT_STATUS_CODE="unknown"
export STAGE10H_POST_CODE="unknown"
export STAGE10H_ENV_ABSENT="unknown"
export STAGE10H_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" "$INDEX_HTML" "$APP_JS" "$QUEUED_CONFIG" "$QUEUED_STATUS" "$LIVE_ROOT" <<'PY'
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

evidence = Path(sys.argv[1])
index_html = Path(sys.argv[2])
app_js = Path(sys.argv[3])
queued_config = Path(sys.argv[4])
queued_status = Path(sys.argv[5])
live_root = Path(sys.argv[6])

index_text = index_html.read_text(encoding="utf-8", errors="replace")
live_text = live_root.read_text(encoding="utf-8", errors="replace") if live_root.exists() else ""

def count(pattern, text):
    return len(re.findall(pattern, text))

data = {
    "stage": "10H",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "deferred queued-status script loader implementation",
    "health_code": os.environ.get("STAGE10H_HEALTH_CODE"),
    "rollout_status_code": os.environ.get("STAGE10H_ROLLOUT_STATUS_CODE"),
    "post_code": os.environ.get("STAGE10H_POST_CODE"),
    "env_absent": os.environ.get("STAGE10H_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE10H_QUEUE_CLEAN"),
    "index_html_bytes": index_html.stat().st_size,
    "app_js_bytes": app_js.stat().st_size if app_js.exists() else None,
    "queued_config_bytes": queued_config.stat().st_size if queued_config.exists() else None,
    "queued_status_bytes": queued_status.stat().st_size if queued_status.exists() else None,
    "local_index_contains_deferred_marker": "stage10hDeferredQueuedChatStatusScript" in index_text,
    "local_index_plain_status_script_count": count(r'<script\s+src=["\\\']/queued_chat_status\.js["\\\']\s*>\s*</script>', index_text),
    "local_index_config_pos": index_text.find("queued_chat_config.js"),
    "local_index_deferred_marker_pos": index_text.find("stage10hDeferredQueuedChatStatusScript"),
    "live_root_contains_deferred_marker": "stage10hDeferredQueuedChatStatusScript" in live_text,
    "live_root_plain_status_script_count": count(r'<script\s+src=["\\\']/queued_chat_status\.js["\\\']\s*>\s*</script>', live_text),
    "final_result": os.environ.get("STAGE10H_FINAL_RESULT"),
}
evidence.parent.mkdir(parents=True, exist_ok=True)
evidence.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {evidence}")
PY
}

echo "=== Stage 10H smoke: deferred queued-status script loader implementation ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10H report exists" || check_fail "Stage 10H report missing"
[ -x "$SMOKE" ] && pass "Stage 10H smoke script is executable" || check_fail "Stage 10H smoke script missing or not executable"

for needle in \
  "Stage 10H implements a narrow deferred loader for queued_chat_status.js." \
  "Stage 10H modifies frontend/wrapper-ui/index.html." \
  "Stage 10H does not modify frontend/wrapper-ui/app.js." \
  "Stage 10H does not modify queued_chat_config.js." \
  "Stage 10H does not modify queued_chat_status.js." \
  "Stage 10H does not modify edge_controller.py." \
  "Stage 10H does not restart live services." \
  "Stage 10H does not add a mutation endpoint." \
  "Stage 10H does not enable browser router traffic." \
  "Stage 10H does not enable backend router dry-run." \
  "Stage 10H does not send frontend router POST traffic." \
  "Stage 10H preserves logged-in/logged-out route boundaries." \
  "Stage 10H replaces the direct queued_chat_status.js script tag with a tiny deferred loader." \
  "data-stage10h-deferred-queued-status" \
  "queued_chat_status.js only defines helper functions on the global object"
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10G/10F validation ==="
[ -f "$STAGE10G_EVIDENCE" ] && pass "Stage 10G evidence exists" || check_fail "Stage 10G evidence missing"
[ -f "$STAGE10F_REPORT" ] && pass "Stage 10F report exists" || check_fail "Stage 10F report missing"

grep -Fq "The safest first runtime optimization should be deferred non-critical status loading." "$STAGE10F_REPORT" \
  && pass "Stage 10F deferred status direction confirmed" \
  || check_fail "Stage 10F deferred status direction missing"

python3 - "$STAGE10G_EVIDENCE" <<'PY'
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

counts = data.get("counts", {})
status_counts = counts.get("queued_chat_status", {})
config_counts = counts.get("queued_chat_config", {})

for key in ["fetch_calls", "set_interval", "set_timeout", "dom_content_loaded", "window_load", "document_refs"]:
    actual = status_counts.get(key)
    print(f"queued_chat_status.{key}={actual}")
    if str(actual) != "0":
        bad.append((f"queued_chat_status.{key}", "0", actual))

for key in ["fetch_calls", "set_interval", "set_timeout", "dom_content_loaded", "window_load", "document_refs"]:
    actual = config_counts.get(key)
    print(f"queued_chat_config.{key}={actual}")
    if str(actual) != "0":
        bad.append((f"queued_chat_config.{key}", "0", actual))

if bad:
    print("CHECK: Stage 10G evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10G evidence supports deferred loader implementation")
PY
[ "$?" = "0" ] && pass "Stage 10G evidence values confirmed" || check_fail "Stage 10G evidence validation failed"

echo
echo "=== source file checks ==="
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
deferred_pos = text.find("stage10hDeferredQueuedChatStatusScript")
plain_status_count = len(re.findall(r'<script\s+src=["\']/queued_chat_status\.js["\']\s*>\s*</script>', text))

print(f"queued_chat_config_pos={config_pos}")
print(f"stage10h_deferred_marker_pos={deferred_pos}")
print(f"plain_queued_chat_status_script_count={plain_status_count}")

bad = []
if config_pos < 0:
    bad.append("queued_chat_config.js missing")
if deferred_pos < 0:
    bad.append("Stage 10H deferred marker missing")
if plain_status_count != 0:
    bad.append("plain queued_chat_status.js script tag still exists")
if config_pos >= 0 and deferred_pos >= 0 and not config_pos < deferred_pos:
    bad.append("queued_chat_config.js is not before deferred loader")

required = [
    "loadQueuedChatStatusAfterInitialPageLoad",
    "stage10hDeferredQueuedChatStatusScript",
    "/queued_chat_status.js",
    "dataset.stage10hDeferredQueuedStatus",
    "window.addEventListener(\"load\"",
    "document.readyState === \"complete\"",
]
for needle in required:
    if needle not in text:
        bad.append(f"missing required loader text: {needle}")

if bad:
    print("CHECK: index.html deferred loader validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: index.html deferred queued status loader validated")
PY
[ "$?" = "0" ] && pass "index.html deferred loader validated" || check_fail "index.html deferred loader validation failed"

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
echo "=== live frontend route checks ==="
for path in "/" "/chat" "/study" "/companion" "/profile" "/admin" "/system" "/app.js" "/styles.css" "/queued_chat_config.js" "/queued_chat_status.js" "/router_shadow_read_stub.js" "/api/system/status"; do
  out="/tmp/stage10h-${path//[^A-Za-z0-9_]/_}.out"
  code="$(curl -sS -L --max-time 10 -o "$out" -w "%{http_code}" "$FRONTEND_BASE$path" 2>/tmp/stage10h-frontend.err || printf 'curl_failed')"
  echo "$path code=$code"
  if [ "$code" = "200" ]; then
    pass "live frontend path $path returned HTTP 200"
  else
    check_fail "live frontend path $path did not return HTTP 200"
  fi
done

cp /tmp/stage10h-_.out "$LIVE_ROOT" 2>/dev/null || true
curl -sS -L --max-time 10 -o "$LIVE_ROOT" "$FRONTEND_BASE/" 2>/tmp/stage10h-live-root.err || true
curl -sS -L --max-time 10 -o "$LIVE_APP" "$FRONTEND_BASE/app.js" 2>/tmp/stage10h-live-app.err || true

python3 - "$LIVE_ROOT" "$LIVE_APP" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace") if Path(sys.argv[1]).exists() else ""
app = Path(sys.argv[2]).read_text(encoding="utf-8", errors="replace") if Path(sys.argv[2]).exists() else ""

plain_status_count = len(re.findall(r'<script\s+src=["\']/queued_chat_status\.js["\']\s*>\s*</script>', root))
print(f"live_plain_queued_chat_status_script_count={plain_status_count}")
print(f"live_contains_stage10h_marker={'stage10hDeferredQueuedChatStatusScript' in root}")
print(f"live_app_contains_router_dry_run={'/api/router/dry-run' in app}")

bad = []
if "stage10hDeferredQueuedChatStatusScript" not in root:
    bad.append("live root missing Stage 10H deferred marker")
if plain_status_count != 0:
    bad.append("live root still has plain queued_chat_status.js script tag")
if "/api/router/dry-run" in app:
    bad.append("live app.js contains /api/router/dry-run")

if bad:
    print("CHECK: live frontend Stage 10H validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: live frontend reflects Stage 10H deferred queued status loader")
PY
[ "$?" = "0" ] && pass "live frontend deferred loader validated" || check_fail "live frontend deferred loader validation failed"

echo
echo "=== live router parked posture checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage10h-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10h-health.err || printf 'curl_failed')"
STAGE10H_HEALTH_CODE="$health_code"
export STAGE10H_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

rollout_code="$(curl -sS --max-time 5 -o /tmp/stage10h-rollout-status.json -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10h-rollout-status.err || printf 'curl_failed')"
STAGE10H_ROLLOUT_STATUS_CODE="$rollout_code"
export STAGE10H_ROLLOUT_STATUS_CODE
echo "rollout_status_code=$rollout_code"
[ "$rollout_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10h deferred queued status loader","source":"stage10h","surface":"backend-only"}' \
  -o /tmp/stage10h-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10h-router-post.err || printf 'curl_failed')"
STAGE10H_POST_CODE="$post_code"
export STAGE10H_POST_CODE
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE10H_ENV_ABSENT="false"
  export STAGE10H_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE10H_ENV_ABSENT="true"
  export STAGE10H_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage10h-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10h-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10h-system-status.json <<'PY'
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
    STAGE10H_QUEUE_CLEAN="true"
    export STAGE10H_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE10H_QUEUE_CLEAN="false"
    export STAGE10H_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE10H_QUEUE_CLEAN="status_failed"
  export STAGE10H_QUEUE_CLEAN
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
echo "=== write Stage 10H evidence ==="
if [ "$fail" = "0" ]; then
  STAGE10H_FINAL_RESULT="pass"
else
  STAGE10H_FINAL_RESULT="fail"
fi
export STAGE10H_FINAL_RESULT
write_evidence

echo
echo "=== Stage 10H smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10H deferred queued-status script loader verified"
else
  echo "FAIL: Stage 10H deferred queued-status script loader found issues"
fi

exit "$fail"
