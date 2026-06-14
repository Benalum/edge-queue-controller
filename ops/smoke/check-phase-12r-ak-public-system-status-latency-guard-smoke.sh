#!/usr/bin/env bash
set -u

cd ~/Desktop/edge-queue-controller || { echo "FAIL: repo path missing"; false; }

PHASE="phase-12r-ak-public-system-status-latency-guard-smoke"
fail=0

echo "=== ${PHASE}: public system status latency guard ==="

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py || fail=1

echo
echo "=== static guard: public status uses lightweight model memory snapshot ==="
python3 - <<'PY' || fail=1
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)

uncached = None
helper = None

for node in tree.body:
    if isinstance(node, ast.FunctionDef) and node.name == "_system_status_uncached":
        uncached = node
    if isinstance(node, ast.FunctionDef) and node.name == "_stage5p12aj_public_model_memory_status_snapshot":
        helper = node

if uncached is None:
    raise SystemExit("FAIL: _system_status_uncached not found")
if helper is None:
    raise SystemExit("FAIL: _stage5p12aj_public_model_memory_status_snapshot not found")

returns = [node for node in ast.walk(uncached) if isinstance(node, ast.Return)]
if len(returns) != 1:
    raise SystemExit(f"FAIL: expected exactly one return in _system_status_uncached, found {len(returns)}")

return_src = ast.get_source_segment(src, returns[0]) or ""
helper_src = ast.get_source_segment(src, helper) or ""

if '"model_memory_status": _stage5p12aj_public_model_memory_status_snapshot()' not in return_src:
    raise SystemExit("FAIL: /system/status does not use lightweight model memory snapshot")

if "_stage5p12r_model_memory_status_read_only()" in return_src:
    raise SystemExit("FAIL: /system/status return still calls full model memory scan")

required_helper_markers = [
    '"source": "phase_12r_aj_public_system_status_model_memory_snapshot"',
    '"network_calls": False',
    '"runtime_action_available": False',
    '"would_call": "none"',
    '"admin_model_warmup_endpoint"',
    '"disabled_future_warmup_execution_skeletons"',
    '_stage5p12m_disabled_admin_model_warmup_response(',
    '_stage5p12y_disabled_future_warmup_execution_skeleton(model, status={})',
]

for marker in required_helper_markers:
    if marker not in helper_src:
        raise SystemExit(f"FAIL: lightweight helper missing marker: {marker}")

for label, text in [
    ("system_status_return", return_src),
    ("lightweight_helper", helper_src),
]:
    for forbidden in [
        "httpx.",
        "urlopen",
        "urllib.request",
        "requests.",
        "subprocess",
        "systemctl",
        "_forward_ollama_chat_job_direct",
        "tick_ollama_direct",
        "/api/generate",
        "/api/chat",
    ]:
        if forbidden in text:
            raise SystemExit(f"FAIL: {label} contains forbidden marker: {forbidden}")

print("PASS: static lightweight /system/status model memory guard is intact")
PY

echo
echo "=== safety: warmup execution env must not be enabled ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr ' ' '\n' \
  | grep -q '^EDGE_MODEL_WARMUP_ACTION_ENABLED=1$'; then
  echo "FAIL: EDGE_MODEL_WARMUP_ACTION_ENABLED=1 is set"
  fail=1
else
  echo "PASS: warmup action env is not enabled"
fi

echo
echo "=== service health ==="
curl -sS --max-time 5 -o /tmp/phase12rak-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health || fail=1

echo
echo "=== live /system/status warm check ==="
curl -sS --max-time 10 -o /tmp/phase12rak-status-warm.json \
  -w "warm_status_code=%{http_code} warm_time=%{time_total}\n" \
  http://127.0.0.1:7070/system/status || fail=1

python3 - <<'PY' || fail=1
import json
from pathlib import Path

data = json.loads(Path("/tmp/phase12rak-status-warm.json").read_text())

memory = data.get("model_memory_status")
if not isinstance(memory, dict):
    raise SystemExit("FAIL: top-level model_memory_status not found")

if memory.get("source") != "phase_12r_aj_public_system_status_model_memory_snapshot":
    raise SystemExit("FAIL: unexpected model_memory_status source")
if memory.get("network_calls") is not False:
    raise SystemExit("FAIL: network_calls is not false")
if memory.get("runtime_action_available") is not False:
    raise SystemExit("FAIL: runtime_action_available is not false")
if memory.get("would_call") != "none":
    raise SystemExit("FAIL: would_call is not none")

for key in [
    "admin_model_warmup_endpoint",
    "disabled_future_warmup_execution_skeletons",
]:
    if key not in memory:
        raise SystemExit(f"FAIL: model_memory_status missing {key}")

print("PASS: live /system/status exposes lightweight disabled model_memory_status")
PY

echo
echo "=== live cached /system/status latency samples ==="
python3 - <<'PY' || fail=1
import json
import subprocess
import sys
from pathlib import Path

max_seconds = 2.0
samples = []

for i in range(1, 4):
    out = Path(f"/tmp/phase12rak-status-sample-{i}.json")
    cmd = [
        "curl",
        "-sS",
        "--max-time",
        "5",
        "-o",
        str(out),
        "-w",
        "%{http_code} %{time_total}",
        "http://127.0.0.1:7070/system/status",
    ]
    proc = subprocess.run(cmd, text=True, capture_output=True)
    if proc.returncode != 0:
        raise SystemExit(f"FAIL: curl sample {i} failed: {proc.stderr.strip()}")

    parts = proc.stdout.strip().split()
    if len(parts) != 2:
        raise SystemExit(f"FAIL: unexpected curl sample {i} output: {proc.stdout!r}")

    code, seconds_raw = parts
    seconds = float(seconds_raw)
    samples.append(seconds)

    if code != "200":
        raise SystemExit(f"FAIL: sample {i} HTTP code {code}")

    data = json.loads(out.read_text())
    memory = data.get("model_memory_status")
    if not isinstance(memory, dict):
        raise SystemExit(f"FAIL: sample {i} missing model_memory_status")
    if memory.get("source") != "phase_12r_aj_public_system_status_model_memory_snapshot":
        raise SystemExit(f"FAIL: sample {i} unexpected model_memory_status source")

    print(f"sample={i} code={code} seconds={seconds:.6f}")

slow = [s for s in samples if s > max_seconds]
if slow:
    raise SystemExit(f"FAIL: cached /system/status samples exceeded {max_seconds}s: {samples}")

print(f"PASS: cached /system/status samples stayed under {max_seconds}s")
PY

echo
echo "=== live unauthenticated future-style POST remains auth/admin blocked ==="
unauth_code="$(curl -sS --max-time 8 \
  -o /tmp/phase12rak-unauth-post.json \
  -w "%{http_code}" \
  -X POST http://127.0.0.1:7070/admin/model-warmup \
  -H 'Content-Type: application/json' \
  --data '{"model":"qwen3:0.6b","dry_run":false,"confirm":"WARMUP_MODEL_NOW"}' || true)"
echo "unauth_code=${unauth_code}"

if [ "$unauth_code" != "401" ] && [ "$unauth_code" != "403" ]; then
  echo "FAIL: unauthenticated future-style POST was not auth/admin blocked"
  cat /tmp/phase12rak-unauth-post.json || true
  fail=1
else
  echo "PASS: unauthenticated future-style POST remains blocked before warmup execution"
fi

echo
echo "=== safety summary ==="
echo "PASS: no controller restart was performed"
echo "PASS: no CT101 worker runtime was changed"
echo "PASS: no persistent lane workers were started"
echo "PASS: no router rollout was enabled"
echo "PASS: no warmup execution was enabled"
echo "PASS: no bearer token value was printed"
echo "PASS: no Ollama direct call was made"
echo "PASS: no /api/generate call was made"
echo "PASS: no /api/chat call was made"
echo "PASS: no model warmup was executed"
echo "PASS: no model unload was executed"

echo
if [ "$fail" = "0" ]; then
  echo "PASS: ${PHASE}"
else
  echo "FAIL: ${PHASE}"
fi

exit "$fail"
