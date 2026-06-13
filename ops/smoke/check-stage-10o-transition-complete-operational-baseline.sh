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

REPORT="docs/generated/stage-10o-transition-complete-operational-baseline.md"
EVIDENCE="docs/generated/stage-10o-transition-complete-operational-baseline-evidence.json"
SMOKE="ops/smoke/check-stage-10o-transition-complete-operational-baseline.sh"

STAGE10N_EVIDENCE="docs/generated/stage-10n-post-cache-system-status-stability-checkpoint-evidence.json"
STAGE10M_EVIDENCE="docs/generated/stage-10m-short-ttl-system-status-cache-implementation-evidence.json"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="$FRONTEND_BASE/api/system/status"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"

ROUTES="/tmp/stage10o-route-baseline.tsv"
SAMPLES="/tmp/stage10o-system-status-cache-samples.tsv"

export STAGE10O_FINAL_RESULT="unknown"
export STAGE10O_HEALTH_CODE="unknown"
export STAGE10O_ROLLOUT_STATUS_CODE="unknown"
export STAGE10O_POST_CODE="unknown"
export STAGE10O_ENV_ABSENT="unknown"
export STAGE10O_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" "$ROUTES" "$SAMPLES" "$CONTROLLER" "$INDEX_HTML" "$APP_JS" <<'PY'
import json
import os
import re
import statistics
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

evidence = Path(sys.argv[1])
routes_path = Path(sys.argv[2])
samples_path = Path(sys.argv[3])
controller = Path(sys.argv[4])
index_html = Path(sys.argv[5])
app_js = Path(sys.argv[6])

def read_tsv(path):
    rows = []
    if path.exists():
        for line in path.read_text(encoding="utf-8").splitlines():
            parts = line.split("\t")
            if len(parts) == 5:
                name, url, code, time_total, size_download = parts
                rows.append({
                    "name": name,
                    "url": url,
                    "code": code,
                    "time_total_seconds": time_total,
                    "size_download_bytes": size_download,
                })
    return rows

routes = read_tsv(routes_path)
samples = read_tsv(samples_path)

status_times = []
for item in samples:
    if item["name"].startswith("api_system_status_cached_") and item["code"] == "200":
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

def cmd(args):
    try:
        return subprocess.check_output(args, text=True).strip()
    except Exception as exc:
        return f"ERROR: {exc}"

controller_text = controller.read_text(encoding="utf-8", errors="replace") if controller.exists() else ""
index_text = index_html.read_text(encoding="utf-8", errors="replace") if index_html.exists() else ""
app_text = app_js.read_text(encoding="utf-8", errors="replace") if app_js.exists() else ""
plain_pattern = r'<script\s+src=["\']/queued_chat_status\.js["\']\s*>\s*</script>'

data = {
    "stage": "10O",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "transition-complete operational baseline",
    "health_code": os.environ.get("STAGE10O_HEALTH_CODE"),
    "rollout_status_code": os.environ.get("STAGE10O_ROLLOUT_STATUS_CODE"),
    "post_code": os.environ.get("STAGE10O_POST_CODE"),
    "env_absent": os.environ.get("STAGE10O_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE10O_QUEUE_CLEAN"),
    "git_head": cmd(["git", "rev-parse", "--short", "HEAD"]),
    "git_branch": cmd(["git", "branch", "--show-current"]),
    "git_status_short": cmd(["git", "status", "--short"]),
    "tags_at_head": cmd(["git", "tag", "--points-at", "HEAD"]),
    "route_metrics": routes,
    "api_system_status_cached_latency_summary": summary,
    "cache_samples": samples,
    "controller_contains_cache": "_system_status_cached_payload" in controller_text,
    "controller_contains_uncached": "_system_status_uncached" in controller_text,
    "controller_contains_ttl_env": "EDGE_SYSTEM_STATUS_CACHE_TTL_SECONDS" in controller_text,
    "index_contains_stage10h_marker": "stage10hDeferredQueuedChatStatusScript" in index_text,
    "index_plain_status_script_count": len(re.findall(plain_pattern, index_text)),
    "app_contains_router_dry_run": "/api/router/dry-run" in app_text,
    "final_result": os.environ.get("STAGE10O_FINAL_RESULT"),
}
evidence.parent.mkdir(parents=True, exist_ok=True)
evidence.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {evidence}")
PY
}

echo "=== Stage 10O smoke: transition-complete operational baseline ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10O report exists" || check_fail "Stage 10O report missing"
[ -x "$SMOKE" ] && pass "Stage 10O smoke script is executable" || check_fail "Stage 10O smoke script missing or not executable"

for needle in \
  "Stage 10O is the final operational baseline for the transition." \
  "Stage 10O verifies that the transition is complete, pushed, stable, and safe to stop." \
  "Stage 10O is evidence/checkpoint only." \
  "Stage 10O does not modify frontend/wrapper-ui/app.js." \
  "Stage 10O does not modify frontend/wrapper-ui/index.html." \
  "Stage 10O does not modify edge_controller.py." \
  "Stage 10O does not restart live services." \
  "Stage 10O does not add a mutation endpoint." \
  "Stage 10O does not enable browser router traffic." \
  "Stage 10O does not enable backend router dry-run." \
  "Stage 10O does not send frontend router POST traffic." \
  "Stage 10O does not change runtime status polling behavior." \
  "Stage 10O does not change cache TTL behavior." \
  "If Stage 10O passes and is pushed, the transition is complete."
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10N/10M evidence validation ==="
[ -f "$STAGE10N_EVIDENCE" ] && pass "Stage 10N evidence exists" || check_fail "Stage 10N evidence missing"
[ -f "$STAGE10M_EVIDENCE" ] && pass "Stage 10M evidence exists" || check_fail "Stage 10M evidence missing"

python3 - "$STAGE10N_EVIDENCE" "$STAGE10M_EVIDENCE" <<'PY'
import json
import sys
from pathlib import Path

n = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
m = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

bad = []

for label, data in [("stage10n", n), ("stage10m", m)]:
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

n_summary = n.get("api_system_status_cached_latency_summary", {})
m_summary = m.get("api_system_status_latency_summary", {})
print(f"stage10n.cached_latency_summary={n_summary}")
print(f"stage10m.latency_summary={m_summary}")

try:
    n_median = float(n_summary.get("median_seconds", 999))
except Exception:
    n_median = 999
try:
    m_median = float(m_summary.get("median_seconds", 999))
except Exception:
    m_median = 999

if n_median > 0.10:
    bad.append(("stage10n.cached_median_seconds", "<=0.10", n_median))
if m_median > 0.10:
    bad.append(("stage10m.median_seconds", "<=0.10", m_median))

for key in ["controller_contains_cache", "controller_contains_uncached", "controller_contains_ttl_env"]:
    actual = str(n.get(key))
    print(f"stage10n.{key}={actual}")
    if actual not in {"true", "True"}:
        bad.append((f"stage10n.{key}", "true", actual))

routes = n.get("route_metrics", [])
if len(routes) < 10:
    bad.append(("stage10n.route_metrics", ">=10", len(routes)))
else:
    for route in routes:
        if str(route.get("code")) != "200":
            bad.append((f"stage10n.route.{route.get('name')}", "200", route.get("code")))

if bad:
    print("CHECK: Stage 10N/10M evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10N/10M evidence supports final transition baseline")
PY
[ "$?" = "0" ] && pass "Stage 10N/10M evidence values confirmed" || check_fail "Stage 10N/10M evidence validation failed"

echo
echo "=== source stability checks ==="
python3 -m py_compile "$CONTROLLER" \
  && pass "edge_controller.py compiles" \
  || check_fail "edge_controller.py failed py_compile"

grep -n '@app.get("/system/status")' "$CONTROLLER" \
  && pass "system status route exists" \
  || check_fail "system status route not found"

grep -n 'def _system_status_cached_payload' "$CONTROLLER" \
  && pass "_system_status_cached_payload exists" \
  || check_fail "_system_status_cached_payload missing"

grep -n 'def _system_status_uncached' "$CONTROLLER" \
  && pass "_system_status_uncached exists" \
  || check_fail "_system_status_uncached missing"

grep -n 'EDGE_SYSTEM_STATUS_CACHE_TTL_SECONDS' "$CONTROLLER" \
  && pass "TTL env knob exists" \
  || check_fail "TTL env knob missing"

if grep -q "/api/router/dry-run" "$APP_JS" 2>/dev/null; then
  check_fail "app.js directly contains /api/router/dry-run"
else
  pass "app.js contains no /api/router/dry-run"
fi

python3 - "$INDEX_HTML" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace")
plain_count = len(re.findall(r'<script\s+src=["\']/queued_chat_status\.js["\']\s*>\s*</script>', text))
contains_marker = "stage10hDeferredQueuedChatStatusScript" in text
print(f"index_contains_stage10h_marker={contains_marker}")
print(f"plain_queued_chat_status_script_count={plain_count}")
sys.exit(0 if contains_marker and plain_count == 0 else 2)
PY
[ "$?" = "0" ] && pass "index.html deferred loader remains stable" || check_fail "index.html deferred loader is not stable"

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
echo "=== live route baseline ==="
: > "$ROUTES"

record_route() {
  name="$1"
  url="$2"
  out="/tmp/stage10o-route-${name}.out"
  result="$(curl -sS -L --max-time 10 -o "$out" -w "%{http_code}\t%{time_total}\t%{size_download}" "$url" 2>"/tmp/stage10o-route-${name}.err" || printf 'curl_failed\t0\t0')"
  code="$(printf '%s' "$result" | cut -f1)"
  time_total="$(printf '%s' "$result" | cut -f2)"
  size_download="$(printf '%s' "$result" | cut -f3)"
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$url" "$code" "$time_total" "$size_download" | tee -a "$ROUTES"
}

record_route root "$FRONTEND_BASE/"
record_route chat "$FRONTEND_BASE/chat"
record_route study "$FRONTEND_BASE/study"
record_route companion "$FRONTEND_BASE/companion"
record_route profile "$FRONTEND_BASE/profile"
record_route admin "$FRONTEND_BASE/admin"
record_route system "$FRONTEND_BASE/system"
record_route app_js "$FRONTEND_BASE/app.js"
record_route styles_css "$FRONTEND_BASE/styles.css"
record_route queued_chat_config "$FRONTEND_BASE/queued_chat_config.js"
record_route queued_chat_status "$FRONTEND_BASE/queued_chat_status.js"
record_route router_shadow_read_stub "$FRONTEND_BASE/router_shadow_read_stub.js"

python3 - "$ROUTES" <<'PY'
import sys
from pathlib import Path

bad = []
for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    name, url, code, time_total, size_download = line.split("\t")
    print(f"{name}: code={code} time={time_total}s size={size_download} url={url}")
    if code != "200":
        bad.append((name, code))

if bad:
    print("CHECK: one or more Stage 10O live routes failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: all Stage 10O live routes returned HTTP 200")
PY
[ "$?" = "0" ] && pass "all Stage 10O live routes returned HTTP 200" || check_fail "live route baseline failed"

echo
echo "=== warmed cache baseline ==="
: > "$SAMPLES"

curl -sS -L --max-time 10 -o /tmp/stage10o-cache-warmup.out "$STATUS_URL" 2>/tmp/stage10o-cache-warmup.err || true

record_sample() {
  name="$1"
  url="$2"
  out="/tmp/stage10o-${name}.out"
  result="$(curl -sS -L --max-time 10 -o "$out" -w "%{http_code}\t%{time_total}\t%{size_download}" "$url" 2>"/tmp/stage10o-${name}.err" || printf 'curl_failed\t0\t0')"
  code="$(printf '%s' "$result" | cut -f1)"
  time_total="$(printf '%s' "$result" | cut -f2)"
  size_download="$(printf '%s' "$result" | cut -f3)"
  printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$url" "$code" "$time_total" "$size_download" | tee -a "$SAMPLES"
}

record_sample health "$BASE/health"
record_sample persistent_rollout_status "$ROLLOUT_STATUS_URL"

for n in 1 2 3 4 5; do
  record_sample "api_system_status_cached_${n}" "$STATUS_URL"
done

python3 - "$SAMPLES" <<'PY'
import statistics
import sys
from pathlib import Path

bad = []
times = []

for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines():
    name, url, code, time_total, size_download = line.split("\t")
    print(f"{name}: code={code} time={time_total}s size={size_download} url={url}")
    if code != "200":
        bad.append((name, code))
    if name.startswith("api_system_status_cached_") and code == "200":
        try:
            times.append(float(time_total))
        except Exception:
            bad.append((name, "bad_time", time_total))

if len(times) < 5:
    bad.append(("api_system_status_cached_samples", "5", len(times)))

if times:
    mean = statistics.mean(times)
    median = statistics.median(times)
    print(f"api_system_status_cached_count={len(times)}")
    print(f"api_system_status_cached_min={min(times):.6f}")
    print(f"api_system_status_cached_max={max(times):.6f}")
    print(f"api_system_status_cached_mean={mean:.6f}")
    print(f"api_system_status_cached_median={median:.6f}")
    if mean > 0.50:
        bad.append(("api_system_status_cached_mean", "<=0.50", mean))
    if median > 0.10:
        bad.append(("api_system_status_cached_median", "<=0.10", median))

if bad:
    print("CHECK: Stage 10O cache baseline failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10O warmed /api/system/status cache baseline remains fast")
PY
[ "$?" = "0" ] && pass "warmed cache baseline remains fast" || check_fail "warmed cache baseline failed"

echo
echo "=== live parked posture checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage10o-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10o-health.err || printf 'curl_failed')"
STAGE10O_HEALTH_CODE="$health_code"
export STAGE10O_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

rollout_code="$(curl -sS --max-time 5 -o /tmp/stage10o-rollout-status.json -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10o-rollout-status.err || printf 'curl_failed')"
STAGE10O_ROLLOUT_STATUS_CODE="$rollout_code"
export STAGE10O_ROLLOUT_STATUS_CODE
echo "rollout_status_code=$rollout_code"
[ "$rollout_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10o final transition baseline","source":"stage10o","surface":"backend-only"}' \
  -o /tmp/stage10o-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10o-router-post.err || printf 'curl_failed')"
STAGE10O_POST_CODE="$post_code"
export STAGE10O_POST_CODE
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE10O_ENV_ABSENT="false"
  export STAGE10O_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE10O_ENV_ABSENT="true"
  export STAGE10O_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 10 -o /tmp/stage10o-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10o-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10o-system-status.json <<'PY'
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
    STAGE10O_QUEUE_CLEAN="true"
    export STAGE10O_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE10O_QUEUE_CLEAN="false"
    export STAGE10O_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE10O_QUEUE_CLEAN="status_failed"
  export STAGE10O_QUEUE_CLEAN
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
echo "=== write Stage 10O evidence ==="
if [ "$fail" = "0" ]; then
  STAGE10O_FINAL_RESULT="pass"
else
  STAGE10O_FINAL_RESULT="fail"
fi
export STAGE10O_FINAL_RESULT
write_evidence

echo
echo "=== Stage 10O smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10O transition-complete operational baseline verified"
else
  echo "FAIL: Stage 10O transition-complete operational baseline found issues"
fi

exit "$fail"
