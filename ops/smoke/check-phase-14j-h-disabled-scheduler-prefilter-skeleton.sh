#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-H disabled scheduler pre-filter skeleton ==="

PHASE="phase-14j-h-disabled-scheduler-prefilter-skeleton"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-H docs/smoke/runtime files exist"

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

doc = Path("docs/phase-14j-h-disabled-scheduler-prefilter-skeleton.md").read_text()

required = [
    "adds a scheduler gate check only",
    "This phase does not enable persistent lane workers",
    "This phase does not call the lane worker filter helper",
    "This phase does not filter the primary worker",
    "This phase does not change worker scoring",
    "This phase does not change worker assignment",
    "This phase does not change worker registration",
    "This phase does not call live model endpoints",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "select_best_worker_for_job",
    "_phase14j_lane_workers_enabled",
    "_phase14j_filter_workers_for_lane",
    "When the gate is enabled in this phase, behavior still remains unchanged",
    "This phase does not modify score_worker_for_job",
    "Phase 14J-I",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== scheduler gate skeleton present and bounded ==="
python3 - <<'PY'
from pathlib import Path
import ast

text = Path("edge_controller.py").read_text()
module = ast.parse(text)

defs = {node.name: node for node in module.body if isinstance(node, ast.FunctionDef)}

required_defs = [
    "select_best_worker_for_job",
    "score_worker_for_job",
    "estimate_job_requirements",
    "scheduler_preview",
]

missing = [name for name in required_defs if name not in defs]
if missing:
    raise SystemExit("FAIL: missing scheduler surfaces: " + ", ".join(missing))

target_src = ast.get_source_segment(text, defs["select_best_worker_for_job"]) or ""

required_markers = [
    "Phase 14J-H disabled scheduler pre-filter integration skeleton",
    "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()",
    "if phase14j_lane_scheduler_gate_enabled:",
]

missing_markers = [m for m in required_markers if m not in target_src]
if missing_markers:
    raise SystemExit("FAIL: missing scheduler skeleton markers: " + ", ".join(missing_markers))

if target_src.count("_phase14j_lane_workers_enabled(") != 1:
    raise SystemExit("FAIL: expected exactly one lane gate call in select_best_worker_for_job")

blocked_calls = [
    "_phase14j_filter_workers_for_lane(",
    "_phase14j_worker_eligible_for_job(",
    "_phase14j_job_lane_metadata(",
    "_phase14j_worker_lane_metadata(",
]

found = [m for m in blocked_calls if m in target_src]
if found:
    raise SystemExit("FAIL: scheduler skeleton calls filter/metadata helpers too early: " + ", ".join(found))

print("PASS: scheduler gate skeleton is present and bounded")
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

print("PASS: score_worker_for_job remains unchanged by lane helpers")
PY

echo
echo "=== helper block and post-H scheduler call shape ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

start_marker = "# Phase 14J-E persistent lane worker default-off helper skeletons."
before, marker, after_marker = text.partition(start_marker)
if not marker:
    raise SystemExit("FAIL: Phase 14J-E helper block marker missing")

helper_body, end_marker, after = after_marker.partition("def _phase14iag_queued_chat_router_shadow_enabled")
if not end_marker:
    raise SystemExit("FAIL: Phase 14J-E helper block boundary missing")

outside = before + "def _phase14iag_queued_chat_router_shadow_enabled" + after

allowed = {"_phase14j_lane_workers_enabled("}
helper_calls = [
    "_phase14j_lane_workers_enabled(",
    "_phase14j_job_lane_metadata(",
    "_phase14j_worker_lane_metadata(",
    "_phase14j_worker_eligible_for_job(",
    "_phase14j_filter_workers_for_lane(",
]

unexpected = [m for m in helper_calls if m in outside and m not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected helper calls outside helper block: " + ", ".join(unexpected))

if outside.count("_phase14j_lane_workers_enabled(") != 1:
    raise SystemExit("FAIL: expected exactly one scheduler gate call outside helper block")

print("PASS: only the approved scheduler gate call exists outside helper block")
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
echo "=== changed files limited to Phase 14J-H runtime/docs/smoke and compatibility smoke updates ==="
python3 - <<'PY'
import subprocess

allowed = {
    "edge_controller.py",
    "docs/phase-14j-h-disabled-scheduler-prefilter-skeleton.md",
    "ops/smoke/check-phase-14j-h-disabled-scheduler-prefilter-skeleton.sh",
    "ops/smoke/check-phase-14j-e-persistent-lane-worker-default-off-helper-skeleton.sh",
    "ops/smoke/check-phase-14j-f-persistent-lane-worker-scheduler-integration-readiness.sh",
    "ops/smoke/check-phase-14j-g-disabled-scheduler-integration-plan.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-H allowed set")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-h-disabled-scheduler-prefilter-skeleton.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-H smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-H disabled scheduler pre-filter skeleton smoke complete ==="
