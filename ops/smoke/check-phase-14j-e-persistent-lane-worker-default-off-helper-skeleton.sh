#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-E persistent lane worker default-off helper skeleton ==="

PHASE="phase-14j-e-persistent-lane-worker-default-off-helper-skeleton"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-E docs/smoke/runtime files exist"

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

doc = Path("docs/phase-14j-e-persistent-lane-worker-default-off-helper-skeleton.md").read_text()

required = [
    "adds helper code only",
    "This phase does not enable persistent lane workers",
    "This phase does not change worker registration",
    "This phase does not change scheduler behavior",
    "This phase does not filter the primary worker",
    "This phase does not call live model endpoints",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "_phase14j_lane_workers_enabled",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_filter_workers_for_lane",
    "scheduler functions are not wired",
    "Prior Smoke Compatibility",
    "Still Not Done",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== helper markers present in runtime ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "_phase14j_lane_workers_enabled",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_filter_workers_for_lane",
]

missing = [m for m in required if m not in text]
if missing:
    raise SystemExit("FAIL: missing helper markers: " + ", ".join(missing))

print("PASS: Phase 14J-E helper markers present")
PY

echo
echo "=== helper behavior unit check without importing app ==="
python3 - <<'PY'
from pathlib import Path
import ast
import os

text = Path("edge_controller.py").read_text()
module = ast.parse(text, filename="edge_controller.py")

selected = []
for node in module.body:
    if isinstance(node, ast.FunctionDef) and node.name.startswith("_phase14j_"):
        selected.append(node)

names = {node.name for node in selected}
required = {
    "_phase14j_lane_workers_enabled",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_filter_workers_for_lane",
}

missing = sorted(required - names)
if missing:
    raise SystemExit("FAIL: missing Phase 14J-E function definitions: " + ", ".join(missing))

isolated = ast.Module(body=selected, type_ignores=[])
ast.fix_missing_locations(isolated)
ns = {}
exec(compile(isolated, "phase14j_helpers_only", "exec"), ns, ns)

gate = ns["_phase14j_lane_workers_enabled"]
job_meta = ns["_phase14j_job_lane_metadata"]
worker_meta = ns["_phase14j_worker_lane_metadata"]
eligible = ns["_phase14j_worker_eligible_for_job"]
filter_workers = ns["_phase14j_filter_workers_for_lane"]

old = os.environ.get("EDGE_PERSISTENT_LANE_WORKERS_ENABLED")
try:
    os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    assert gate() is False

    for value in ["", "0", "false", "False", "FALSE", "no", "off", "banana"]:
        os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = value
        assert gate() is False, value

    for value in ["1", "true", "yes", "on"]:
        os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = value
        assert gate() is True, value

    os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    workers = [{"worker_id": "w1"}, {"worker_id": "w2"}]
    assert filter_workers(workers, {"job_lane": "study"}) == workers
    assert eligible({"worker_id": "w1"}, {"job_lane": "study"})["eligible"] is True
    assert eligible({"worker_id": "w1"}, {"job_lane": "study"})["reason_code"] == "lane_gate_disabled"

    os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = "1"
    good_worker = {
        "worker_id": "w1",
        "worker_lane": "study",
        "capabilities": ["study", "chat"],
        "max_concurrent_jobs": 2,
        "current_running_jobs": 0,
    }
    good_job = {
        "job_lane": "study",
        "required_capabilities": ["study"],
        "requires_lane_worker": True,
    }
    result = eligible(good_worker, good_job)
    assert result["eligible"] is True, result
    assert result["reason_code"] == "eligible", result

    bad_worker = dict(good_worker)
    bad_worker["disabled"] = True
    result = eligible(bad_worker, good_job)
    assert result["eligible"] is False, result
    assert result["reason_code"] == "worker_disabled", result

    bad_caps = dict(good_worker)
    bad_caps["capabilities"] = ["chat"]
    result = eligible(bad_caps, good_job)
    assert result["eligible"] is False, result
    assert result["reason_code"] == "missing_capabilities", result

    jm = job_meta({"job_lane": "Study Lane", "required_capabilities": "study,chat"})
    wm = worker_meta({"worker_id": "Worker 1", "capabilities": ["study", "chat"]})
    assert set(jm.keys()) <= {
        "job_lane",
        "required_capabilities",
        "preferred_worker_role",
        "allow_primary_fallback",
        "allow_legacy_fallback",
        "requires_lane_worker",
        "estimated_vram_mb",
        "estimated_ram_mb",
        "estimated_duration_class",
        "priority_class",
    }
    assert set(wm.keys()) <= {
        "worker_id",
        "worker_role",
        "worker_lane",
        "worker_pool",
        "capabilities",
        "max_concurrent_jobs",
        "current_running_jobs",
        "supports_primary_fallback",
        "accepts_lane_jobs",
        "disabled",
        "stale",
        "unhealthy",
        "offline",
    }

finally:
    if old is None:
        os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    else:
        os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = old

print("PASS: helper behavior unit check passed without importing app")
PY

echo
echo "=== helper skeletons are not wired into scheduler surfaces ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

start_marker = "# Phase 14J-E persistent lane worker default-off helper skeletons."
before, marker, after_marker = text.partition(start_marker)
if not marker:
    raise SystemExit("FAIL: helper skeleton marker not found")

helper_body, end_marker, after = after_marker.partition("def _phase14iag_queued_chat_router_shadow_enabled")
if not end_marker:
    raise SystemExit("FAIL: helper block boundary not found")

outside = before + "def _phase14iag_queued_chat_router_shadow_enabled" + after
helper_names = [
    "_phase14j_lane_workers_enabled",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_filter_workers_for_lane",
]

found_outside = [name for name in helper_names if name in outside]
if found_outside:
    raise SystemExit("FAIL: helper names found outside helper block, possible integration: " + ", ".join(found_outside))

print("PASS: helper skeletons are not wired outside their helper block")
PY

echo
echo "=== safety boundaries still preserved ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

router_forbidden = [
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITE_ENABLED",
    "_phase14i_record_router_shadow_evidence",
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
]

found_router = [m for m in router_forbidden if m in text]
if found_router:
    raise SystemExit("FAIL: router evidence writer markers unexpectedly present: " + ", ".join(found_router))

required_warmup_disabled = [
    "_stage5p12l_disabled_manual_warmup_action_blueprint",
    "_stage5p12y_disabled_future_warmup_execution_skeleton",
]

missing = [m for m in required_warmup_disabled if m not in text]
if missing:
    raise SystemExit("FAIL: disabled warmup markers missing: " + ", ".join(missing))

print("PASS: router writer absent and disabled warmup markers still present")
PY

echo
echo "=== changed files limited to Phase 14J-E runtime/docs/smoke and compatibility smoke updates ==="
python3 - <<'PY'
import subprocess

allowed = {
    "edge_controller.py",
    "docs/phase-14j-e-persistent-lane-worker-default-off-helper-skeleton.md",
    "ops/smoke/check-phase-14j-e-persistent-lane-worker-default-off-helper-skeleton.sh",
    "ops/smoke/check-phase-14j-b-persistent-lane-worker-surface-inspection.sh",
    "ops/smoke/check-phase-14j-c-persistent-lane-worker-eligibility-contract.sh",
    "ops/smoke/check-phase-14j-d-persistent-lane-worker-default-off-helper-plan.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-E allowed set")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-e-persistent-lane-worker-default-off-helper-skeleton.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-E smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-E persistent lane worker default-off helper skeleton smoke complete ==="
