#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-P enabled synthetic lane filter behavior verification ==="

PHASE="phase-14j-p-enabled-synthetic-lane-filter-behavior-verification"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-P docs/smoke/runtime files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-p-enabled-synthetic-lane-filter-behavior-verification.md").read_text()

required = [
    "docs/smoke-only verification phase",
    "This phase verifies isolated enabled helper behavior",
    "This phase does not change scheduler behavior",
    "This phase does not change runtime code",
    "This phase does not enable persistent lane workers in the service environment",
    "This phase does not call controller endpoints",
    "This phase does not call live model endpoints",
    "This phase does not query or mutate the database",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "This phase does not change worker scoring",
    "This phase does not change worker assignment",
    "This phase does not change worker registration",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "_phase14j_filter_workers_for_lane(workers, job)",
    "Phase 14J-Q",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== scheduler call shape remains gated and ordered ==="
python3 - <<'PY'
from pathlib import Path
import ast

text = Path("edge_controller.py").read_text()
module = ast.parse(text)
defs = {node.name: node for node in module.body if isinstance(node, ast.FunctionDef)}

target = defs.get("select_best_worker_for_job")
if target is None:
    raise SystemExit("FAIL: select_best_worker_for_job missing")

src = ast.get_source_segment(text, target) or ""

required = [
    "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()",
    "workers = [worker_row_to_dict(row) for row in rows]",
    "if phase14j_lane_scheduler_gate_enabled:",
    "workers = _phase14j_filter_workers_for_lane(workers, job)",
    "candidates = []",
    "for worker in workers:",
    "score_worker_for_job(worker, requirements)",
]

missing = [m for m in required if m not in src]
if missing:
    raise SystemExit("FAIL: missing scheduler markers: " + ", ".join(missing))

if src.count("_phase14j_lane_workers_enabled(") != 1:
    raise SystemExit("FAIL: expected exactly one lane gate call in select_best_worker_for_job")

if src.count("_phase14j_filter_workers_for_lane(") != 1:
    raise SystemExit("FAIL: expected exactly one lane filter call in select_best_worker_for_job")

workers_index = src.index("workers = [worker_row_to_dict(row) for row in rows]")
filter_index = src.index("workers = _phase14j_filter_workers_for_lane(workers, job)")
candidates_index = src.index("candidates = []")
score_index = src.index("score_worker_for_job(worker, requirements)")

if not (workers_index < filter_index < candidates_index < score_index):
    raise SystemExit("FAIL: filter call ordering is unsafe")

print("PASS: scheduler filter call remains gated and ordered")
PY

echo
echo "=== isolated enabled synthetic helper behavior ==="
python3 - <<'PY'
from pathlib import Path
import os

text = Path("edge_controller.py").read_text()
start = text.index("# Phase 14J-E persistent lane worker default-off helper skeletons.")
end = text.index("def _phase14iag_queued_chat_router_shadow_enabled")
helper_src = text[start:end]

ns = {}
exec(helper_src, ns)

def worker(worker_id, lane="default", role="lane", caps=None, state="available", running=0, max_jobs=2, disabled=False):
    return {
        "worker_id": worker_id,
        "worker_role": role,
        "worker_lane": lane,
        "capabilities": caps or ["ollama_chat"],
        "state": state,
        "current_running_jobs": running,
        "max_concurrent_jobs": max_jobs,
        "disabled": disabled,
        "accepts_lane_jobs": True,
    }

job = {
    "job_lane": "study",
    "required_capabilities": ["ollama_chat"],
    "requires_lane_worker": True,
    "allow_primary_fallback": False,
}

enabled_values = ["1", "true", "TRUE", "yes", "on"]
for value in enabled_values:
    os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = value
    if ns["_phase14j_lane_workers_enabled"]() is not True:
        raise SystemExit(f"FAIL: gate did not enable for value={value!r}")

workers = [
    worker("primary", lane="default", role="primary"),
    worker("study-good", lane="study"),
    worker("wrong-lane", lane="companion"),
    worker("missing-cap", lane="study", caps=["tts"]),
    worker("offline", lane="study", state="offline"),
    worker("disabled", lane="study", disabled=True),
    worker("capacity", lane="study", running=2, max_jobs=2),
]

os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = "1"
filtered = ns["_phase14j_filter_workers_for_lane"](workers, job)
ids = [w["worker_id"] for w in filtered]

if ids != ["study-good"]:
    raise SystemExit("FAIL: enabled synthetic filter expected only study-good, got: " + repr(ids))

expected_reasons = {
    "primary": "primary_fallback_not_allowed",
    "wrong-lane": "lane_mismatch",
    "missing-cap": "missing_capabilities",
    "offline": "worker_offline",
    "disabled": "worker_disabled",
    "capacity": "capacity_reached",
}

for w in workers:
    result = ns["_phase14j_worker_eligible_for_job"](w, job)
    wid = w["worker_id"]
    if wid == "study-good":
        if result.get("eligible") is not True or result.get("reason_code") != "eligible":
            raise SystemExit("FAIL: study-good should be eligible, got: " + repr(result))
    elif wid in expected_reasons:
        if result.get("eligible") is not False or result.get("reason_code") != expected_reasons[wid]:
            raise SystemExit(f"FAIL: {wid} expected {expected_reasons[wid]}, got: {result!r}")

for value in [None, "", "0", "false", "no", "off"]:
    if value is None:
        os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    else:
        os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = value
    result = ns["_phase14j_filter_workers_for_lane"](workers, job)
    if result != workers:
        raise SystemExit(f"FAIL: disabled value {value!r} did not pass through all workers")

print("PASS: enabled synthetic helper behavior verified")
PY

echo
echo "=== score_worker_for_job remains free of lane helper calls ==="
python3 - <<'PY'
from pathlib import Path
import ast

text = Path("edge_controller.py").read_text()
module = ast.parse(text)
defs = {node.name: node for node in module.body if isinstance(node, ast.FunctionDef)}

score = defs.get("score_worker_for_job")
if score is None:
    raise SystemExit("FAIL: score_worker_for_job missing")

src = ast.get_source_segment(text, score) or ""
helpers = [
    "_phase14j_lane_workers_enabled",
    "_phase14j_filter_workers_for_lane",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
]

found = [h for h in helpers if h in src]
if found:
    raise SystemExit("FAIL: score_worker_for_job references lane helpers: " + ", ".join(found))

print("PASS: score_worker_for_job remains free of lane helper calls")
PY

echo
echo "=== safety boundaries still preserved ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

forbidden = [
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITE_ENABLED",
    "_phase14i_record_router_shadow_evidence",
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
]

found = [m for m in forbidden if m in text]
if found:
    raise SystemExit("FAIL: router evidence writer markers unexpectedly present: " + ", ".join(found))

required_disabled = [
    "_stage5p12l_disabled_manual_warmup_action_blueprint",
    "_stage5p12y_disabled_future_warmup_execution_skeleton",
]

missing = [m for m in required_disabled if m not in text]
if missing:
    raise SystemExit("FAIL: disabled warmup markers missing: " + ", ".join(missing))

print("PASS: router writer absent and disabled warmup markers still present")
PY

echo
echo "=== changed files limited to Phase 14J-P docs/smoke ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-p-enabled-synthetic-lane-filter-behavior-verification.md",
    "ops/smoke/check-phase-14j-p-enabled-synthetic-lane-filter-behavior-verification.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-P docs/smoke")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-p-enabled-synthetic-lane-filter-behavior-verification.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-P smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-P enabled synthetic lane filter behavior verification smoke complete ==="
