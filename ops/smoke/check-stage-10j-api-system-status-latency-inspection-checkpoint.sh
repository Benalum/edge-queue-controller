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

REPORT="docs/generated/stage-10j-api-system-status-latency-inspection-checkpoint.md"
EVIDENCE="docs/generated/stage-10j-api-system-status-latency-inspection-checkpoint-evidence.json"
SMOKE="ops/smoke/check-stage-10j-api-system-status-latency-inspection-checkpoint.sh"

STAGE10I_EVIDENCE="docs/generated/stage-10i-deferred-loader-post-implementation-stability-checkpoint-evidence.json"
STAGE10C_EVIDENCE="docs/generated/stage-10c-frontend-load-route-boundary-baseline-inspection-evidence.json"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="$FRONTEND_BASE/api/system/status"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"

SAMPLES="/tmp/stage10j-latency-samples.tsv"
SOURCE_REFS="/tmp/stage10j-system-status-source-refs.txt"

export STAGE10J_FINAL_RESULT="unknown"
export STAGE10J_HEALTH_CODE="unknown"
export STAGE10J_ROLLOUT_STATUS_CODE="unknown"
export STAGE10J_POST_CODE="unknown"
export STAGE10J_ENV_ABSENT="unknown"
export STAGE10J_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" "$SAMPLES" "$SOURCE_REFS" "$INDEX_HTML" "$APP_JS" <<'PY'
import json
import os
import re
import statistics
import sys
from datetime import datetime, timezone
from pathlib import Path

evidence = Path(sys.argv[1])
samples_path = Path(sys.argv[2])
source_refs_path = Path(sys.argv[3])
index_html = Path(sys.argv[4])
app_js = Path(sys.argv[5])

samples = []
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

status_times = []
for item in samples:
    if item["name"].startswith("api_system_status_") and item["code"] == "200":
        try:
            status_times.append(float(item["time_total_seconds"]))
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

index_text = index_html.read_text(encoding="utf-8", errors="replace") if index_html.exists() else ""
app_text = app_js.read_text(encoding="utf-8", errors="replace") if app_js.exists() else ""

plain_pattern = r'<script\s+src=["\']/queued_chat_status\.js["\']\s*>\s*</script>'

data = {
    "stage": "10J",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "api system status latency inspection checkpoint",
    "health_code": os.environ.get("STAGE10J_HEALTH_CODE"),
    "rollout_status_code": os.environ.get("STAGE10J_ROLLOUT_STATUS_CODE"),
    "post_code": os.environ.get("STAGE10J_POST_CODE"),
    "env_absent": os.environ.get("STAGE10J_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE10J_QUEUE_CLEAN"),
    "api_system_status_latency_summary": summary,
    "samples": samples,
    "source_reference_line_count": len(source_refs_path.read_text(encoding="utf-8").splitlines()) if source_refs_path.exists() else 0,
    "index_contains_stage10h_marker": "stage10hDeferredQueuedChatStatusScript" in index_text,
    "index_plain_status_script_count": len(re.findall(plain_pattern, index_text)),
    "app_contains_router_dry_run": "/api/router/dry-run" in app_text,
    "final_result": os.environ.get("STAGE10J_FINAL_RESULT"),
}
evidence.parent.mkdir(parents=True, exist_ok=True)
evidence.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {evidence}")
PY
}

echo "=== Stage 10J smoke: api system status latency inspection checkpoint ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10J report exists" || check_fail "Stage 10J report missing"
[ -x "$SMOKE" ] && pass "Stage 10J smoke script is executable" || check_fail "Stage 10J smoke script missing or not executable"

for needle in \
  "Stage 10J inspects /api/system/status latency after the Stage 10H deferred queued-status loader optimization." \
  "Stage 10J is inspection-only." \
  "Stage 10J does not modify frontend/wrapper-ui/app.js." \
  "Stage 10J does not modify frontend/wrapper-ui/index.html." \
  "Stage 10J does not modify edge_controller.py." \
  "Stage 10J does not restart live services." \
  "Stage 10J does not add a mutation endpoint." \
  "Stage 10J does not enable browser router traffic." \
  "Stage 10J does not enable backend router dry-run." \
  "Stage 10J does not send frontend router POST traffic." \
  "Stage 10J does not change runtime status polling behavior." \
  "Stage 10C measured /api/system/status at about 2.058351 seconds." \
  "Stage 10I measured /api/system/status at about 2.110265 seconds." \
  "Recommended default: Option A first"
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10I/10C evidence validation ==="
[ -f "$STAGE10I_EVIDENCE" ] && pass "Stage 10I evidence exists" || check_fail "Stage 10I evidence missing"
[ -f "$STAGE10C_EVIDENCE" ] && pass "Stage 10C evidence exists" || check_fail "Stage 10C evidence missing"

python3 - "$STAGE10I_EVIDENCE" "$STAGE10C_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

i = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
c = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

bad = []

for label, data in [("stage10i", i), ("stage10c", c)]:
    checks = {
        "final_result": {"pass"},
        "post_code": {"404"},
        "env_absent": {"true", "True"},
        "queue_clean": {"true", "True"},
    }
    for key, allowed in checks.items():
        actual = str(data.get(key))
        print(f"{label}.{key}={actual}")
        if actual not in allowed:
            bad.append((f"{label}.{key}", sorted(allowed), actual))

routes_i = {r.get("name"): r for r in i.get("route_metrics", [])}
api_i = routes_i.get("api_system_status")
if api_i:
    print(f"stage10i.api_system_status.code={api_i.get('code')}")
    print(f"stage10i.api_system_status.time={api_i.get('time_total_seconds')}")
    if str(api_i.get("code")) != "200":
        bad.append(("stage10i.api_system_status.code", "200", api_i.get("code")))
else:
    bad.append(("stage10i.api_system_status", "present", "missing"))

routes_c = {r.get("name"): r for r in c.get("route_metrics", [])}
api_c = routes_c.get("api_system_status")
if api_c:
    print(f"stage10c.api_system_status.code={api_c.get('code')}")
    print(f"stage10c.api_system_status.time={api_c.get('time_total_seconds')}")
    if str(api_c.get("code")) != "200":
        bad.append(("stage10c.api_system_status.code", "200", api_c.get("code")))
else:
    bad.append(("stage10c.api_system_status", "present", "missing"))

if bad:
    print("CHECK: Stage 10I/10C evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10I/10C evidence confirms system status latency target")
PY
[ "$?" = "0" ] && pass "Stage 10I/10C evidence values confirmed" || check_fail "Stage 10I/10C evidence validation failed"

echo
echo "=== source safety and deferred loader checks ==="
python3 -m py_compile "$CONTROLLER" \
  && pass "edge_controller.py compiles" \
  || check_fail "edge_controller.py failed py_compile"

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

if grep -RInE '@app\.(post|put|patch|delete)\("/api/router/persistent-rollout/status"|@app\.(post|put|patch|delete)\(PERSISTENT_OPERATOR_GATED_ROLLOUT_STATUS_PATH|/api/router/persistent-rollout/request' "$CONTROLLER" 2>/dev/null; then
  check_fail "persistent rollout mutation route unexpectedly exists"
else
  pass "persistent rollout mutation route does not exist"
fi

echo
echo "=== source references for status handlers ==="
{
  echo "=== edge_controller.py status references ==="
  grep -nE 'api/system/status|/system/status|public-status|system_status|status.*route|@app\.(get|post).*status|def .*status|queue.*status|power.*status' "$CONTROLLER" | sed -n '1,260p' || true
  echo
  echo "=== frontend status references ==="
  grep -nE 'api/system/status|/system/status|public-status|refresh.*status|load.*status|systemStatus|SystemStatus|lastStatus|adminSystemStatus' "$APP_JS" | sed -n '1,260p' || true
} | tee "$SOURCE_REFS"

source_ref_count="$(wc -l < "$SOURCE_REFS" | tr -d ' ')"
echo "source_ref_count=$source_ref_count"
[ "$source_ref_count" -gt 0 ] && pass "status source references recorded" || check_fail "no status source references recorded"

echo
echo "=== repeated live latency samples ==="
: > "$SAMPLES"

record_sample() {
  name="$1"
  url="$2"
  out="/tmp/stage10j-${name}.out"
  result="$(curl -sS -L --max-time 10 -o "$out" -w "%{http_code}\t%{time_total}\t%{size_download}" "$url" 2>"/tmp/stage10j-${name}.err" || printf 'curl_failed\t0\t0')"
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
    print(f"api_system_status_count={len(status_times)}")
    print(f"api_system_status_min={min(status_times):.6f}")
    print(f"api_system_status_max={max(status_times):.6f}")
    print(f"api_system_status_mean={statistics.mean(status_times):.6f}")
    print(f"api_system_status_median={statistics.median(status_times):.6f}")

if bad:
    print("CHECK: latency sample validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: repeated /api/system/status latency samples recorded")
PY
[ "$?" = "0" ] && pass "latency samples recorded and returned HTTP 200" || check_fail "latency sampling failed"

echo
echo "=== live router parked posture checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage10j-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10j-health.err || printf 'curl_failed')"
STAGE10J_HEALTH_CODE="$health_code"
export STAGE10J_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

rollout_code="$(curl -sS --max-time 5 -o /tmp/stage10j-rollout-status.json -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10j-rollout-status.err || printf 'curl_failed')"
STAGE10J_ROLLOUT_STATUS_CODE="$rollout_code"
export STAGE10J_ROLLOUT_STATUS_CODE
echo "rollout_status_code=$rollout_code"
[ "$rollout_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10j system status latency inspection","source":"stage10j","surface":"backend-only"}' \
  -o /tmp/stage10j-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10j-router-post.err || printf 'curl_failed')"
STAGE10J_POST_CODE="$post_code"
export STAGE10J_POST_CODE
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE10J_ENV_ABSENT="false"
  export STAGE10J_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE10J_ENV_ABSENT="true"
  export STAGE10J_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 10 -o /tmp/stage10j-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10j-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10j-system-status.json <<'PY'
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
    STAGE10J_QUEUE_CLEAN="true"
    export STAGE10J_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE10J_QUEUE_CLEAN="false"
    export STAGE10J_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE10J_QUEUE_CLEAN="status_failed"
  export STAGE10J_QUEUE_CLEAN
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
echo "=== write Stage 10J evidence ==="
if [ "$fail" = "0" ]; then
  STAGE10J_FINAL_RESULT="pass"
else
  STAGE10J_FINAL_RESULT="fail"
fi
export STAGE10J_FINAL_RESULT
write_evidence

echo
echo "=== Stage 10J smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10J api system status latency inspection verified"
else
  echo "FAIL: Stage 10J api system status latency inspection found issues"
fi

exit "$fail"
