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

REPORT="docs/generated/stage-10l-system-status-backend-dependency-inspection.md"
EVIDENCE="docs/generated/stage-10l-system-status-backend-dependency-inspection-evidence.json"
SMOKE="ops/smoke/check-stage-10l-system-status-backend-dependency-inspection.sh"

STAGE10K_REPORT="docs/generated/stage-10k-system-status-backend-optimization-plan.md"
STAGE10J_EVIDENCE="docs/generated/stage-10j-api-system-status-latency-inspection-checkpoint-evidence.json"

CONTROLLER="edge_controller.py"
APP_JS="frontend/wrapper-ui/app.js"
INDEX_HTML="frontend/wrapper-ui/index.html"
STUB="frontend/wrapper-ui/router_shadow_read_stub.js"

BASE="http://127.0.0.1:7070"
FRONTEND_BASE="http://127.0.0.1:8787"
STATUS_URL="$FRONTEND_BASE/api/system/status"
ROLLOUT_STATUS_URL="$BASE/api/router/persistent-rollout/status"

SOURCE_MAP="/tmp/stage10l-system-status-source-map.txt"
HELPER_SCAN="/tmp/stage10l-helper-dependency-scan.txt"

export STAGE10L_FINAL_RESULT="unknown"
export STAGE10L_HEALTH_CODE="unknown"
export STAGE10L_ROLLOUT_STATUS_CODE="unknown"
export STAGE10L_POST_CODE="unknown"
export STAGE10L_ENV_ABSENT="unknown"
export STAGE10L_QUEUE_CLEAN="unknown"

write_evidence() {
  python3 - "$EVIDENCE" "$CONTROLLER" "$SOURCE_MAP" "$HELPER_SCAN" "$INDEX_HTML" "$APP_JS" <<'PY'
import ast
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

evidence = Path(sys.argv[1])
controller = Path(sys.argv[2])
source_map = Path(sys.argv[3])
helper_scan = Path(sys.argv[4])
index_html = Path(sys.argv[5])
app_js = Path(sys.argv[6])

text = controller.read_text(encoding="utf-8", errors="replace")
tree = ast.parse(text)

targets = [
    "system_status",
    "_system_pct_status",
    "_system_frontend_wrapper_status",
    "_system_queue_status_from_worker",
    "_system_power_automation_status",
    "_system_status_normalized_block",
    "_system_ct101_laptop_queue_worker_status",
]

patterns = {
    "subprocess": r"\bsubprocess\b",
    "ssh": r"\bssh\b|EDGE_PROXMOX|prox?mox|pveso",
    "curl": r"\bcurl\b",
    "systemctl": r"\bsystemctl\b",
    "pct": r"\bpct\b",
    "requests": r"\brequests\.",
    "urlopen": r"\burlopen\b",
    "sqlite": r"\bsqlite3\b|\.execute\(|get_db_connection|connect\(",
    "file_io": r"\bopen\(|Path\(|read_text|write_text",
    "sleep_timeout": r"\bsleep\b|timeout|max-time",
    "power_auto": r"power_auto|power automation|_system_power_automation_status",
    "queue_worker": r"queue|worker|_system_queue_status_from_worker|_system_ct101_laptop_queue_worker_status",
}

functions = {}
for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name in targets:
        start = node.lineno
        end = getattr(node, "end_lineno", node.lineno)
        body = "\n".join(text.splitlines()[start-1:end])
        functions[node.name] = {
            "start_line": start,
            "end_line": end,
            "line_count": end - start + 1,
            "pattern_counts": {name: len(re.findall(pattern, body, flags=re.IGNORECASE)) for name, pattern in patterns.items()},
            "called_names": sorted({
                n.func.id for n in ast.walk(node)
                if isinstance(n, ast.Call) and isinstance(n.func, ast.Name)
            } | {
                n.func.attr for n in ast.walk(node)
                if isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute)
            }),
        }

index_text = index_html.read_text(encoding="utf-8", errors="replace") if index_html.exists() else ""
app_text = app_js.read_text(encoding="utf-8", errors="replace") if app_js.exists() else ""
plain_pattern = r'<script\s+src=["\']/queued_chat_status\.js["\']\s*>\s*</script>'

data = {
    "stage": "10L",
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "purpose": "system status backend dependency inspection",
    "health_code": os.environ.get("STAGE10L_HEALTH_CODE"),
    "rollout_status_code": os.environ.get("STAGE10L_ROLLOUT_STATUS_CODE"),
    "post_code": os.environ.get("STAGE10L_POST_CODE"),
    "env_absent": os.environ.get("STAGE10L_ENV_ABSENT"),
    "queue_clean": os.environ.get("STAGE10L_QUEUE_CLEAN"),
    "functions": functions,
    "source_map_line_count": len(source_map.read_text(encoding="utf-8").splitlines()) if source_map.exists() else 0,
    "helper_scan_line_count": len(helper_scan.read_text(encoding="utf-8").splitlines()) if helper_scan.exists() else 0,
    "index_contains_stage10h_marker": "stage10hDeferredQueuedChatStatusScript" in index_text,
    "index_plain_status_script_count": len(re.findall(plain_pattern, index_text)),
    "app_contains_router_dry_run": "/api/router/dry-run" in app_text,
    "final_result": os.environ.get("STAGE10L_FINAL_RESULT"),
}
evidence.parent.mkdir(parents=True, exist_ok=True)
evidence.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
print(f"wrote evidence: {evidence}")
PY
}

echo "=== Stage 10L smoke: system status backend dependency inspection ==="

echo
echo "=== report/script checks ==="
[ -f "$REPORT" ] && pass "Stage 10L report exists" || check_fail "Stage 10L report missing"
[ -x "$SMOKE" ] && pass "Stage 10L smoke script is executable" || check_fail "Stage 10L smoke script missing or not executable"

for needle in \
  "Stage 10L inspects backend dependencies used by /system/status before any optimization is implemented." \
  "Stage 10L is inspection-only." \
  "Stage 10L does not modify frontend/wrapper-ui/app.js." \
  "Stage 10L does not modify frontend/wrapper-ui/index.html." \
  "Stage 10L does not modify edge_controller.py." \
  "Stage 10L does not restart live services." \
  "Stage 10L does not add a mutation endpoint." \
  "Stage 10L does not enable browser router traffic." \
  "Stage 10L does not enable backend router dry-run." \
  "Stage 10L does not send frontend router POST traffic." \
  "Stage 10L does not change runtime status polling behavior." \
  "Stage 10L does not add caching." \
  "Stage 10J confirmed /api/system/status averages about 1.91 seconds." \
  "Stage 10M should either:" \
  "Recommended default: implement a very short 2-second TTL cache"
do
  grep -Fq "$needle" "$REPORT" && pass "report contains: $needle" || check_fail "report missing: $needle"
done

echo
echo "=== Stage 10K/10J validation ==="
[ -f "$STAGE10K_REPORT" ] && pass "Stage 10K report exists" || check_fail "Stage 10K report missing"
[ -f "$STAGE10J_EVIDENCE" ] && pass "Stage 10J evidence exists" || check_fail "Stage 10J evidence missing"

grep -Fq "The primary optimization target is the backend work inside /system/status." "$STAGE10K_REPORT" \
  && pass "Stage 10K selected backend /system/status optimization" \
  || check_fail "Stage 10K target text missing"

python3 - "$STAGE10J_EVIDENCE" <<'PY'
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

summary = data.get("api_system_status_latency_summary", {})
print(f"latency_summary={summary}")
try:
    mean = float(summary.get("mean_seconds", 0))
except Exception:
    mean = 0
if mean <= 1.0:
    bad.append(("api_system_status_latency_summary.mean_seconds", ">1.0", summary.get("mean_seconds")))

if bad:
    print("CHECK: Stage 10J evidence validation failed")
    for item in bad:
        print(item)
    sys.exit(2)

print("PASS: Stage 10J evidence supports Stage 10L dependency inspection")
PY
[ "$?" = "0" ] && pass "Stage 10J evidence values confirmed" || check_fail "Stage 10J evidence validation failed"

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
echo "=== system_status source map ==="
python3 - "$CONTROLLER" "$SOURCE_MAP" <<'PY'
import ast
import sys
from pathlib import Path

controller = Path(sys.argv[1])
out = Path(sys.argv[2])
text = controller.read_text(encoding="utf-8", errors="replace")
tree = ast.parse(text)

targets = [
    "system_status",
    "_system_pct_status",
    "_system_frontend_wrapper_status",
    "_system_queue_status_from_worker",
    "_system_power_automation_status",
    "_system_status_normalized_block",
    "_system_ct101_laptop_queue_worker_status",
]

lines = []
for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name in targets:
        start = node.lineno
        end = getattr(node, "end_lineno", node.lineno)
        calls = sorted({
            n.func.id for n in ast.walk(node)
            if isinstance(n, ast.Call) and isinstance(n.func, ast.Name)
        } | {
            n.func.attr for n in ast.walk(node)
            if isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute)
        })
        lines.append(f"{node.name}\tstart={start}\tend={end}\tlines={end-start+1}\tcalls={','.join(calls[:80])}")

out.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(out.read_text(encoding="utf-8"))
PY

[ -s "$SOURCE_MAP" ] && pass "system status source map recorded" || check_fail "system status source map missing"

echo
echo "=== helper dependency scan ==="
python3 - "$CONTROLLER" "$HELPER_SCAN" <<'PY'
import ast
import re
import sys
from pathlib import Path

controller = Path(sys.argv[1])
out = Path(sys.argv[2])
text = controller.read_text(encoding="utf-8", errors="replace")
tree = ast.parse(text)

targets = [
    "system_status",
    "_system_pct_status",
    "_system_frontend_wrapper_status",
    "_system_queue_status_from_worker",
    "_system_power_automation_status",
    "_system_status_normalized_block",
    "_system_ct101_laptop_queue_worker_status",
]

patterns = {
    "subprocess": r"\bsubprocess\b",
    "ssh": r"\bssh\b|EDGE_PROXMOX|proxmox|pveso",
    "curl": r"\bcurl\b",
    "systemctl": r"\bsystemctl\b",
    "pct": r"\bpct\b",
    "requests": r"\brequests\.",
    "urlopen": r"\burlopen\b",
    "sqlite": r"\bsqlite3\b|\.execute\(|get_db_connection|connect\(",
    "file_io": r"\bopen\(|Path\(|read_text|write_text",
    "sleep_timeout": r"\bsleep\b|timeout|max-time",
    "power_auto": r"power_auto|power automation|_system_power_automation_status",
    "queue_worker": r"queue|worker|_system_queue_status_from_worker|_system_ct101_laptop_queue_worker_status",
}

rows = []
for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name in targets:
        start = node.lineno
        end = getattr(node, "end_lineno", node.lineno)
        body = "\n".join(text.splitlines()[start-1:end])
        counts = []
        for name, pattern in patterns.items():
            count = len(re.findall(pattern, body, flags=re.IGNORECASE))
            counts.append(f"{name}={count}")
        rows.append(f"{node.name}\tstart={start}\tend={end}\t" + "\t".join(counts))

out.write_text("\n".join(rows) + "\n", encoding="utf-8")
print(out.read_text(encoding="utf-8"))
PY

[ -s "$HELPER_SCAN" ] && pass "helper dependency scan recorded" || check_fail "helper dependency scan missing"

echo
echo "=== live parked posture checks ==="
health_code="$(curl -sS --max-time 5 -o /tmp/stage10l-health.out -w "%{http_code}" "$BASE/health" 2>/tmp/stage10l-health.err || printf 'curl_failed')"
STAGE10L_HEALTH_CODE="$health_code"
export STAGE10L_HEALTH_CODE
echo "health_code=$health_code"
[ "$health_code" = "200" ] && pass "live controller /health returned HTTP 200" || check_fail "live controller /health did not return HTTP 200"

rollout_code="$(curl -sS --max-time 5 -o /tmp/stage10l-rollout-status.json -w "%{http_code}" "$ROLLOUT_STATUS_URL" 2>/tmp/stage10l-rollout-status.err || printf 'curl_failed')"
STAGE10L_ROLLOUT_STATUS_CODE="$rollout_code"
export STAGE10L_ROLLOUT_STATUS_CODE
echo "rollout_status_code=$rollout_code"
[ "$rollout_code" = "200" ] && pass "persistent rollout status returned HTTP 200" || check_fail "persistent rollout status did not return HTTP 200"

post_code="$(curl -sS --max-time 5 -X POST -H 'Content-Type: application/json' \
  -d '{"text":"stage10l system status dependency inspection","source":"stage10l","surface":"backend-only"}' \
  -o /tmp/stage10l-router-post.out -w "%{http_code}" \
  "$BASE/api/router/dry-run" 2>/tmp/stage10l-router-post.err || printf 'curl_failed')"
STAGE10L_POST_CODE="$post_code"
export STAGE10L_POST_CODE
echo "post_code=$post_code"
[ "$post_code" = "404" ] && pass "POST /api/router/dry-run remains HTTP 404" || check_fail "POST /api/router/dry-run did not remain HTTP 404"

controller_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
if printf '%s\n' "$controller_env" | tr ' ' '\n' | grep -qx 'EDGE_UNIVERSAL_INTENT_ROUTER_DRY_RUN_ENABLED=1'; then
  STAGE10L_ENV_ABSENT="false"
  export STAGE10L_ENV_ABSENT
  check_fail "backend dry-run env is enabled"
else
  STAGE10L_ENV_ABSENT="true"
  export STAGE10L_ENV_ABSENT
  pass "backend dry-run env remains absent"
fi

echo
echo "=== queue clean check ==="
queue_code="$(curl -sS --max-time 10 -o /tmp/stage10l-system-status.json -w "%{http_code}" "$STATUS_URL" 2>/tmp/stage10l-system-status.err || printf 'curl_failed')"
echo "queue_status_code=$queue_code"

if [ "$queue_code" = "200" ]; then
  python3 - /tmp/stage10l-system-status.json <<'PY'
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
    STAGE10L_QUEUE_CLEAN="true"
    export STAGE10L_QUEUE_CLEAN
    pass "queue clean state confirmed with queued=0 running=0 failed=0"
  else
    STAGE10L_QUEUE_CLEAN="false"
    export STAGE10L_QUEUE_CLEAN
    check_fail "queue clean state was not confirmed"
  fi
else
  STAGE10L_QUEUE_CLEAN="status_failed"
  export STAGE10L_QUEUE_CLEAN
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
echo "=== write Stage 10L evidence ==="
if [ "$fail" = "0" ]; then
  STAGE10L_FINAL_RESULT="pass"
else
  STAGE10L_FINAL_RESULT="fail"
fi
export STAGE10L_FINAL_RESULT
write_evidence

echo
echo "=== Stage 10L smoke result ==="
if [ "$fail" = "0" ]; then
  echo "PASS: Stage 10L system status backend dependency inspection verified"
else
  echo "FAIL: Stage 10L system status backend dependency inspection found issues"
fi

exit "$fail"
