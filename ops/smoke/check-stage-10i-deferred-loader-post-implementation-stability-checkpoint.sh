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

REPORT="docs/generated/stage-10i-deferred-loader-post-implementation-stability-checkpoint.md"
EVIDENCE="docs/generated/stage-10i-deferred-loader-post-implementation-stability-checkpoint-evidence.json"
SMOKE="ops/smoke/check-stage-10i-deferred-loader-post-implementation-stability-checkpoint.sh"

STAGE10H_EVIDENCE="docs/generated/stage-10h-deferred-queued-status-script-loader-implementation-evidence.json"
STAGE10G_EVIDENCE="docs/generated/stage-10g-deferred-queued-status-script-loader-preflight-evidence.json"

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

METRICS="/tmp/stage10i-route-metrics.tsv"
LIVE_ROOT="/tmp/stage10i-live-root.html"
LIVE_APP="/tmp/stage10i-live-app.js"

export STAGE10I_FINAL_RESULT="unknown"
export STAGE10I_HEALTH_CODE="unknown"
export STAGE10I_ROLLOUT_STATUS_CODE="unknown"
export STAGE10I_POST_CODE="unknown"
export STAGE10I_ENV_ABSENT="unknown"
export STAGE10I_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" "$METRICS" "$INDEX_HTML" "$APP_JS" "$LIVE_ROOT" <<'PY'
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

evidence = Path(sys.argv[1])
metrics_path = Path(sys.argv[2])
index_html = Path(sys.argv[3])
app_js = Path(sys.argv[4])
live_root = Path(sys.argv[5])

index_text = index_html.read_text(encoding="utf-8", errors="replace") if index_html.exists() else ""
live_text = live_root.read_text(encoding="utf-8", errors="replace") if live_root.exists() else ""

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

plain_pattern = r'<script\s+src=["\']/queued_chat_status\.js["\']\s*>\s*</script>'

data = {
    "stage": "10I",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "deferred loader post-implementation stability checkpoint",
    "health_code": os.environ.get("STAGE10I_HEALTH_CODE"),
    "rollout_status_code": os.environ.get("STAGE10I_ROLLOUT_STATUS_CODE"),
    "post_code": os.environ.get("STAGE10I_POST_CODE"),
    "env_absent": os.environ.get("STAGE10I_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE10I_QUEUE_CLEAN"),
    "index_html_bytes": index_html.stat().st_size if index_html.exists() else None,
    "app_js_bytes": app_js.stat().st_size if app_js.exists() else None,
    "local_index_contains_stage10h_marker": "stage10hDeferredQueuedChatStatusScript" in index_text,
    "local_index_plain_status_script_count": len(re.findall(plain_pattern, index_text)),
    "local_index_config_pos": index_text.find("queued_chat_config.js"),
    "local_index_marker_pos": index_text.find("stage10hDeferredQueuedChatStatusScript"),
    "live_root_contains_stage10h_marker": "stage10hDeferredQueuedChatStatusScript" in live_text,
    "live_root_plain_status_script_count": len(re.findall(plain_pattern, live_text)),
    "route_metrics": routes,
    "final_result": os.environ.get("STAGE10I_FINAL_RESULT"),
}
evidence.parent.mkdir(parents=True, exist_ok=True)
evidence.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {evidence}")
PY
}

echo "=== Stage 10I smoke: deferred loader post-implementation stability checkpoint ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10I report exists" || check_fail "Stage 10I report missing"
[ -x "$SMOKE" ] && pass "Stage 10I smoke script is executable" || check_fail "Stage 10I smoke script missing or not executable"

for needle in \
  "Stage 10I verifies the Stage 10H deferred queued-status script loader after implementation." \
  "Stage 10I is evidence/checkpoint only." \
  "Stage 10I does not modify frontend/wrapper-ui/app.js." \
  "Stage 10I does not modify frontend/wrapper-ui/index.html." \
  "Stage 10I does not modify queued_chat_config.js." \
  "Stage 10I does not modify queued_chat_status.js." \
  "Stage 10I does not modify edge_controller.py." \
  "Stage 10I does not restart live services." \
  "Stage 10I does not add a mutation endpoint." \
  "Stage 10I does not enable browser router traffic." \
  "Stage 10I does not enable backend router dry-run." \
  "Stage 10I does not send frontend router POST traffic." \
  "Stage 10I does not change runtime status polling behavior." \
  "live root still contains the Stage 10H deferred loader marker." \
  "Recommended default: Option C"
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10H/10G evidence validation ==="
[ -f "$STAGE10H_EVIDENCE" ] && pass "Stage 10H evidence exists" || check_fail "Stage 10H evidence missing"
[ -f "$STAGE10G_EVIDENCE" ] && pass "Stage 10G evidence exists" || check_fail "Stage 10G evidence missing"

python3 - "$STAGE10H_EVIDENCE" "$STAGE10G_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

h = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
g = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

bad = []

checks_h = {
    "final_result": {"pass"},
    "health_code": {"200"},
    "rollout_status_code": {"200"},
    "post_code": {"404"},
    "env_absent": {"true", "True"},
    "queue_clean": {"true", "True"},
    "local_index_plain_status_script_count": {"0"},
    "live_root_plain_status_script_count": {"0"},
    "local_index_contains_deferred_marker": {"True", "true"},
    "live_root_contains_deferred_marker": {"True", "true"},
}

for key, allowed in checks_h.items():
    actual = str(h.get(key))
    print(f"stage10h.{key}={actual}")
    if actual not in allowed:
        bad.append((f"stage10h.{key}", sorted(allowed), actual))

checks_g = {
    "final_result": {"pass"},
    "health_code": {"200"},
    "rollout_status_code": {"200"},
    "post_code": {"404"},
    "env_absent": {"true", "True"},
    "queue_clean": {"true", "True"},
}

for key, allowed in checks_g.items():
    actual = str(g.get(key))
    print(f"stage10g.{key}={actual}")
    if actual not in allowed:
        bad.append((f"stage10g.{key}", sorted(allowed), actual))

if bad:
    print("CHECK: Stage 10H/10G evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10H/10G evidence supports post-implementation stability checkpoint")
PY
[ "$?" = "0" ] && pass "Stage 10H/10G evidence values confirmed" || check_fail "Stage 10H/10G evidence validation failed"

echo
echo "=== source deferred loader checks ==="
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
plain_count = len(re.findall(r'<script\s+src=["\']/queued_chat_status\.js["\']\s*>\s*</script>', text))
config_pos = text.find("queued_chat_config.js")
marker_pos = text.find("stage10hDeferredQueuedChatStatusScript")

print(f"plain_queued_chat_status_script_count={plain_count}")
print(f"queued_chat_config_pos={config_pos}")
print(f"stage10h_marker_pos={marker_pos}")
print(f"contains_dataset_marker={'dataset.stage10hDeferredQueuedStatus' in text}")
print(f"contains_window_load={'window.addEventListener(\"load\"' in text}")
print(f"contains_complete_fallback={'document.readyState === \"complete\"' in text}")

bad = []
if plain_count != 0:
    bad.append("plain queued_chat_status.js script tag exists")
if config_pos < 0:
    bad.append("queued_chat_config.js missing")
if marker_pos < 0:
    bad.append("Stage 10H marker missing")
if config_pos >= 0 and marker_pos >= 0 and not config_pos < marker_pos:
    bad.append("queued config is not before Stage 10H loader")
if "dataset.stage10hDeferredQueuedStatus" not in text:
    bad.append("dataset marker missing")
if 'window.addEventListener("load"' not in text:
    bad.append("window load hook missing")
if 'document.readyState === "complete"' not in text:
    bad.append("complete fallback missing")

if bad:
    print("CHECK: Stage 10H source loader stability validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10H source loader remains stable")
PY
[ "$?" = "0" ] && pass "Stage 10H source loader remains stable" || check_fail "Stage 10H source loader validation failed"

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
echo "=== live route stability baseline ==="
: > "$METRICS"

record_route() {
  name="$1"
  path="$2"
  url="$FRONTEND_BASE$path"
  out="/tmp/stage10i-${name}.out"
  result="$(curl -sS -L --max-time 10 -o "$out" -w "%{http_code}\t%{time_total}\t%{size_download}" "$url" 2>"/tmp/stage10i-${name}.err" || printf 'curl_failed\t0\t0')"
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
record_route app_js "/app.js"
record_route styles_css "/styles.css"
record_route queued_chat_config "/queued_chat_config.js"
record_route queued_chat_status "/queued_chat_status.js"
record_route router_shadow_read_stub "/router_shadow_read_stub.js"
record_route api_system_status "/api/system/status"

python3 - "$METRICS" <<'PY'
import sys
from pathlib import Path

bad = []
for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    name, url, code, time_total, size_download = line.split("\t")
    print(f"{name}: code={code} time={time_total}s size={size_download} url={url}")
    if code != "200":
        bad.append((name, code))

if bad:
    print("CHECK: one or more live routes did not return HTTP 200")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: all Stage 10I live routes returned HTTP 200")
PY
[ "$?" = "0" ] && pass "all Stage 10I live routes returned HTTP 200" || check_fail "live route stability failed"

curl -sS -L --max-time 10 -o "$LIVE_ROOT" "$FRONTEND_BASE/" 2>/tmp/stage10i-live-root.err || true
curl -sS -L --max-time 10 -o "$LIVE_APP" "$FRONTEND_BASE/app.js" 2>/tmp/stage10i-live-app.err || true

python3 - "$LIVE_ROOT" "$LIVE_APP" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace") if Path(sys.argv[1]).exists() else ""
app = Path(sys.argv[2]).read_text(encoding="utf-8", errors="replace") if Path(sys.argv[2]).exists() else ""

plain_count = len(re.findall(r'<script\s+src=["\']/queued_chat_status\.js["\']\s*>\s*</script>', root))
contains_marker = "stage10hDeferredQueuedChatStatusScript" in root
app_has_router_dry_run = "/api/router/dry-run" in app

print(f"live_plain_queued_chat_status_script_count={plain_count}")
print(f"live_contains_stage10h_marker={contains_marker}")
print(f"live_app_contains_router_dry_run={app_has_router_dry_run}")

bad = []
if plain_count != 0:
    bad.append("live root has plain queued_chat_status.js script tag")
if not contains_marker:
    bad.append("live root missing Stage 10H deferred marker")
if app_has_router_dry_run:
    bad.append("live app.js contains /api/router/dry-run")

if bad:
    print("CHECK: live deferred loader stability validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: live deferred loader remains stable")
PY
[ "$?" = "0" ] && pass "live deferred loader remains stable" || check_fail "live deferred loader stability validation failed"

echo
echo "=== live router parked posture checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage10i-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10i-health.err || printf 'curl_failed')"
STAGE10I_HEALTH_CODE="$health_code"
export STAGE10I_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

rollout_code="$(curl -sS --max-time 5 -o /tmp/stage10i-rollout-status.json -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10i-rollout-status.err || printf 'curl_failed')"
STAGE10I_ROLLOUT_STATUS_CODE="$rollout_code"
export STAGE10I_ROLLOUT_STATUS_CODE
echo "rollout_status_code=$rollout_code"
[ "$rollout_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10i deferred loader stability","source":"stage10i","surface":"backend-only"}' \
  -o /tmp/stage10i-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10i-router-post.err || printf 'curl_failed')"
STAGE10I_POST_CODE="$post_code"
export STAGE10I_POST_CODE
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE10I_ENV_ABSENT="false"
  export STAGE10I_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE10I_ENV_ABSENT="true"
  export STAGE10I_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 5 -o /tmp/stage10i-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10i-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10i-system-status.json <<'PY'
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
    STAGE10I_QUEUE_CLEAN="true"
    export STAGE10I_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE10I_QUEUE_CLEAN="false"
    export STAGE10I_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE10I_QUEUE_CLEAN="status_failed"
  export STAGE10I_QUEUE_CLEAN
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
echo "=== write Stage 10I evidence ==="
if [ "$fail" = "0" ]; then
  STAGE10I_FINAL_RESULT="pass"
else
  STAGE10I_FINAL_RESULT="fail"
fi
export STAGE10I_FINAL_RESULT
write_evidence

echo
echo "=== Stage 10I smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10I deferred loader post-implementation stability verified"
else
  echo "FAIL: Stage 10I deferred loader post-implementation stability found issues"
fi

exit "$fail"
