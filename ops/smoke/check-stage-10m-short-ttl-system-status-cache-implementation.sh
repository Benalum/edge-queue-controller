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

REPORT="docs/generated/stage-10m-short-ttl-system-status-cache-implementation.md"
EVIDENCE="docs/generated/stage-10m-short-ttl-system-status-cache-implementation-evidence.json"
SMOKE="ops/smoke/check-stage-10m-short-ttl-system-status-cache-implementation.sh"

STAGE10L_EVIDENCE="docs/generated/stage-10l-system-status-backend-dependency-inspection-evidence.json"
STAGE10J_EVIDENCE="docs/generated/stage-10j-api-system-status-latency-inspection-checkpoint-evidence.json"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="$FRONTEND_BASE/api/system/status"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"

SAMPLES="/tmp/stage10m-latency-samples.tsv"

export STAGE10M_FINAL_RESULT="unknown"
export STAGE10M_HEALTH_CODE="unknown"
export STAGE10M_ROLLOUT_STATUS_CODE="unknown"
export STAGE10M_POST_CODE="unknown"
export STAGE10M_ENV_ABSENT="unknown"
export STAGE10M_QUEUE_CLEAN="unknown"
export STAGE10M_STATUS_MEAN="unknown"
export STAGE10M_STATUS_MEDIAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" "$SAMPLES" "$CONTROLLER" "$INDEX_HTML" "$APP_JS" <<'PY'
import json
import os
import re
import statistics
import sys
from datetime import datetime, timezone
from pathlib import Path

evidence = Path(sys.argv[1])
samples_path = Path(sys.argv[2])
controller = Path(sys.argv[3])
index_html = Path(sys.argv[4])
app_js = Path(sys.argv[5])

samples = []
status_times = []
if samples_path.exists():
    for line in samples_path.read_text(encoding="utf-8").splitlines():
        parts = line.split("\t")
        if len(parts) == 5:
            name, url, code, time_total, size_download = parts
            item = {
                "name": name,
                "url": url,
                "code": code,
                "time_total_seconds": time_total,
                "size_download_bytes": size_download,
            }
            samples.append(item)
            if name.startswith("api_system_status_") and code == "200":
                try:
                    status_times.append(float(time_total))
                except Exception:
                    pass

summary = {}
if status_times:
    summary = {
        "count": len(status_times),
        "min_seconds": min(status_times),
        "max_seconds": max(status_times),
        "mean_seconds": statistics.mean(status_times),
        "median_seconds": statistics.median(status_times),
    }

controller_text = controller.read_text(encoding="utf-8", errors="replace") if controller.exists() else ""
index_text = index_html.read_text(encoding="utf-8", errors="replace") if index_html.exists() else ""
app_text = app_js.read_text(encoding="utf-8", errors="replace") if app_js.exists() else ""
plain_pattern = r'<script\s+src=["\']/queued_chat_status\.js["\']\s*>\s*</script>'

data = {
    "stage": "10M",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "short TTL system status cache implementation",
    "health_code": os.environ.get("STAGE10M_HEALTH_CODE"),
    "rollout_status_code": os.environ.get("STAGE10M_ROLLOUT_STATUS_CODE"),
    "post_code": os.environ.get("STAGE10M_POST_CODE"),
    "env_absent": os.environ.get("STAGE10M_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE10M_QUEUE_CLEAN"),
    "api_system_status_latency_summary": summary,
    "samples": samples,
    "controller_contains_cache": "_system_status_cached_payload" in controller_text,
    "controller_contains_uncached": "_system_status_uncached" in controller_text,
    "controller_contains_ttl_env": "EDGE_SYSTEM_STATUS_CACHE_TTL_SECONDS" in controller_text,
    "index_contains_stage10h_marker": "stage10hDeferredQueuedChatStatusScript" in index_text,
    "index_plain_status_script_count": len(re.findall(plain_pattern, index_text)),
    "app_contains_router_dry_run": "/api/router/dry-run" in app_text,
    "final_result": os.environ.get("STAGE10M_FINAL_RESULT"),
}
evidence.parent.mkdir(parents=True, exist_ok=True)
evidence.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {evidence}")
PY
}

echo "=== Stage 10M smoke: short TTL system status cache implementation ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10M report exists" || check_fail "Stage 10M report missing"
[ -x "$SMOKE" ] && pass "Stage 10M smoke script is executable" || check_fail "Stage 10M smoke script missing or not executable"

for needle in \
  "Stage 10M implements a very short in-process TTL cache around /system/status." \
  "Stage 10M modifies edge_controller.py." \
  "Stage 10M does not modify frontend/wrapper-ui/app.js." \
  "Stage 10M does not modify frontend/wrapper-ui/index.html." \
  "Stage 10M does not add a mutation endpoint." \
  "Stage 10M does not enable browser router traffic." \
  "Stage 10M does not enable backend router dry-run." \
  "Stage 10M does not send frontend router POST traffic." \
  "Stage 10M performs a controlled edge-queue-controller restart to load the backend implementation." \
  "uses a default TTL of 2 seconds" \
  "EDGE_SYSTEM_STATUS_CACHE_TTL_SECONDS"
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10L/10J evidence validation ==="
[ -f "$STAGE10L_EVIDENCE" ] && pass "Stage 10L evidence exists" || check_fail "Stage 10L evidence missing"
[ -f "$STAGE10J_EVIDENCE" ] && pass "Stage 10J evidence exists" || check_fail "Stage 10J evidence missing"

python3 - "$STAGE10L_EVIDENCE" "$STAGE10J_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

l = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
j = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

bad = []
for label, data in [("stage10l", l), ("stage10j", j)]:
    checks = {
        "final_result": {"pass"},
        "health_code": {"200"},
        "rollout_status_code": {"200"},
        "post_code": {"404"},
        "env_absent": {"true", "True"},
        "queue_clean": {"true", "True"},
    }
    for key, allowed in checks.items():
        actual = str(data.get(key))
        print(f"{label}.{key}={actual}")
        if actual not in allowed:
            bad.append((f"{label}.{key}", sorted(allowed), actual))

summary = j.get("api_system_status_latency_summary", {})
print(f"stage10j.latency_summary={summary}")
try:
    mean = float(summary.get("mean_seconds", 0))
except Exception:
    mean = 0
if mean <= 1.0:
    bad.append(("stage10j.mean_seconds", ">1.0", summary.get("mean_seconds")))

functions = l.get("functions", {})
for name in ["system_status", "_system_ct101_laptop_queue_worker_status", "_system_pct_status"]:
    if name not in functions:
        bad.append((f"stage10l.functions.{name}", "present", "missing"))
    else:
        print(f"stage10l.functions.{name}.line_count={functions[name].get('line_count')}")

if bad:
    print("CHECK: Stage 10L/10J evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10L/10J evidence supports short TTL cache implementation")
PY
[ "$?" = "0" ] && pass "Stage 10L/10J evidence values confirmed" || check_fail "Stage 10L/10J evidence validation failed"

echo
echo "=== source implementation checks ==="
python3 -m py_compile "$CONTROLLER" \
  && pass "edge_controller.py compiles before restart" \
  || check_fail "edge_controller.py failed py_compile before restart"

grep -n '@app.get("/system/status")' "$CONTROLLER" \
  && pass "system status route exists" \
  || check_fail "system status route not found"

grep -n 'def system_status' "$CONTROLLER" \
  && pass "system_status route wrapper exists" \
  || check_fail "system_status route wrapper not found"

grep -n 'def _system_status_uncached' "$CONTROLLER" \
  && pass "_system_status_uncached exists" \
  || check_fail "_system_status_uncached missing"

grep -n 'def _system_status_cached_payload' "$CONTROLLER" \
  && pass "_system_status_cached_payload exists" \
  || check_fail "_system_status_cached_payload missing"

grep -n 'EDGE_SYSTEM_STATUS_CACHE_TTL_SECONDS' "$CONTROLLER" \
  && pass "TTL env knob exists" \
  || check_fail "TTL env knob missing"

grep -n 'import time as _stage10m_time' "$CONTROLLER" \
  && pass "monotonic time import exists" \
  || check_fail "monotonic time import missing"

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
echo "=== controlled service restart ==="
before_health="$(curl -sS --max-time 5 -o /tmp/stage10m-health-before.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10m-health-before.err || printf 'curl_failed')"
echo "health_before_restart=$before_health"

sudo systemctl restart edge-queue-controller || fail=1
sleep 2

after_health="$(curl -sS --max-time 8 -o /tmp/stage10m-health-after.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10m-health-after.err || printf 'curl_failed')"
STAGE10M_HEALTH_CODE="$after_health"
export STAGE10M_HEALTH_CODE
echo "health_after_restart=$after_health"
[ "$after_health" = "200" ] && pass "live controller /health returned HTTP 200 after restart" || check_fail "live controller /health did not return HTTP 200 after restart"

echo
echo "=== repeated live latency samples after cache ==="
: > "$SAMPLES"

record_sample() {
  name="$1"
  url="$2"
  out="/tmp/stage10m-${name}.out"
  result="$(curl -sS -L --max-time 10 -o "$out" -w "%{http_code}\t%{time_total}\t%{size_download}" "$url" 2>"/tmp/stage10m-${name}.err" || printf 'curl_failed\t0\t0')"
  code="$(printf '%s' "$result" | cut -f1)"
  time_total="$(printf '%s' "$result" | cut -f2)"
  size_download="$(printf '%s' "$result" | cut -f3)"
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$url" "$code" "$time_total" "$size_download" | tee -a "$SAMPLES"
}

record_sample health "$BASE/health"
record_sample persistent_rollout_status "$ROLLOUT_STATUS_URL"

for n in 1 2 3 4 5; do
  record_sample "api_system_status_${n}" "$STATUS_URL"
done

python3 - "$SAMPLES" <<'PY'
import statistics
import sys
from pathlib import Path

bad = []
status_times = []

for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    name, url, code, time_total, size_download = line.split("\t")
    print(f"{name}: code={code} time={time_total}s size={size_download} url={url}")
    if code != "200":
        bad.append((name, code))
    if name.startswith("api_system_status_") and code == "200":
        try:
            status_times.append(float(time_total))
        except Exception:
            bad.append((name, "bad_time", time_total))

if len(status_times) < 5:
    bad.append(("api_system_status_samples", "5", len(status_times)))

if status_times:
    mean = statistics.mean(status_times)
    median = statistics.median(status_times)
    print(f"api_system_status_count={len(status_times)}")
    print(f"api_system_status_min={min(status_times):.6f}")
    print(f"api_system_status_max={max(status_times):.6f}")
    print(f"api_system_status_mean={mean:.6f}")
    print(f"api_system_status_median={median:.6f}")
    if mean > 1.5:
        bad.append(("api_system_status_mean", "<=1.5 expected after short cache", mean))
    if min(status_times) > 0.75:
        bad.append(("api_system_status_min", "<=0.75 expected cached hit", min(status_times)))

if bad:
    print("CHECK: cached latency sample validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: repeated /api/system/status latency samples show cached improvement")
PY
[ "$?" = "0" ] && pass "cached latency samples recorded and improved" || check_fail "cached latency sampling failed"

echo
echo "=== live router parked posture checks ==="
rollout_code="$(curl -sS --max-time 5 -o /tmp/stage10m-rollout-status.json -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10m-rollout-status.err || printf 'curl_failed')"
STAGE10M_ROLLOUT_STATUS_CODE="$rollout_code"
export STAGE10M_ROLLOUT_STATUS_CODE
echo "rollout_status_code=$rollout_code"
[ "$rollout_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10m short ttl system status cache","source":"stage10m","surface":"backend-only"}' \
  -o /tmp/stage10m-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10m-router-post.err || printf 'curl_failed')"
STAGE10M_POST_CODE="$post_code"
export STAGE10M_POST_CODE
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE10M_ENV_ABSENT="false"
  export STAGE10M_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE10M_ENV_ABSENT="true"
  export STAGE10M_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 10 -o /tmp/stage10m-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10m-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10m-system-status.json <<'PY'
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
    STAGE10M_QUEUE_CLEAN="true"
    export STAGE10M_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE10M_QUEUE_CLEAN="false"
    export STAGE10M_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE10M_QUEUE_CLEAN="status_failed"
  export STAGE10M_QUEUE_CLEAN
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
echo "=== write Stage 10M evidence ==="
if [ "$fail" = "0" ]; then
  STAGE10M_FINAL_RESULT="pass"
else
  STAGE10M_FINAL_RESULT="fail"
fi
export STAGE10M_FINAL_RESULT
write_evidence

echo
echo "=== Stage 10M smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10M short TTL system status cache verified"
else
  echo "FAIL: Stage 10M short TTL system status cache found issues"
fi

exit "$fail"
