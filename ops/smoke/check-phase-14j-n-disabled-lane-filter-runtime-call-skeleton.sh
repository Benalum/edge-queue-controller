#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-normal}"

echo "=== Phase 14J-N disabled lane filter runtime call skeleton ==="

PHASE="phase-14j-n-disabled-lane-filter-runtime-call-skeleton"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-N docs/smoke/runtime files exist"

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

doc = Path("docs/phase-14j-n-disabled-lane-filter-runtime-call-skeleton.md").read_text()
required = [
    "adds the first runtime lane filter call skeleton",
    "This phase does not enable persistent lane workers",
    "This phase does not filter workers while the gate is disabled",
    "This phase does not change worker scoring while the gate is disabled",
    "This phase does not change worker assignment while the gate is disabled",
    "This phase does not change worker registration",
    "This phase does not call live model endpoints",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "workers = [worker_row_to_dict(row) for row in rows]",
    "candidates = []",
    "_phase14j_filter_workers_for_lane(workers, job)",
    "phase14j_lane_scheduler_gate_enabled",
    "Phase 14J-O",
]
missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))
print("PASS: documentation markers verified")
PY

echo
echo "=== scheduler filter call shape ==="
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
    "Phase 14J-H disabled scheduler pre-filter integration skeleton",
    "Phase 14J-N disabled lane filter runtime call skeleton",
    "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()",
    "if phase14j_lane_scheduler_gate_enabled:",
    "workers = _phase14j_filter_workers_for_lane(workers, job)",
    "candidates = []",
    "for worker in workers:",
    "score_worker_for_job(worker, requirements)",
]
missing = [m for m in required if m not in src]
if missing:
    raise SystemExit("FAIL: missing scheduler runtime markers: " + ", ".join(missing))

if src.count("_phase14j_lane_workers_enabled(") != 1:
    raise SystemExit("FAIL: expected exactly one lane gate call in select_best_worker_for_job")
if src.count("_phase14j_filter_workers_for_lane(") != 1:
    raise SystemExit("FAIL: expected exactly one lane filter call in select_best_worker_for_job")

workers_index = src.index("workers = [worker_row_to_dict(row) for row in rows]")
filter_index = src.index("workers = _phase14j_filter_workers_for_lane(workers, job)")
candidates_index = src.index("candidates = []")
score_index = src.index("score_worker_for_job(worker, requirements)")
if not (workers_index < filter_index < candidates_index < score_index):
    raise SystemExit("FAIL: filter call is not after workers construction and before scoring")

blocked = [
    "_phase14j_worker_eligible_for_job(",
    "_phase14j_job_lane_metadata(",
    "_phase14j_worker_lane_metadata(",
]
found = [m for m in blocked if m in src]
if found:
    raise SystemExit("FAIL: scheduler references lower-level metadata helpers directly: " + ", ".join(found))

print("PASS: scheduler filter call is present, gated, and ordered")
PY

echo
echo "=== helper default-off pass-through behavior ==="
python3 - <<'PY'
from pathlib import Path
import os

text = Path("edge_controller.py").read_text()
start = text.index("# Phase 14J-E persistent lane worker default-off helper skeletons.")
end = text.index("def _phase14iag_queued_chat_router_shadow_enabled")
helper_src = text[start:end]

ns = {}
exec(helper_src, ns)

workers = [
    {"worker_id": "primary", "worker_role": "primary", "capabilities": ["ollama_chat"], "state": "available"},
    {"worker_id": "lane", "worker_role": "lane", "worker_lane": "study", "capabilities": ["ollama_chat"], "state": "available", "accepts_lane_jobs": True},
]
job = {"job_lane": "study", "required_capabilities": ["ollama_chat"], "requires_lane_worker": True}

for value in [None, "", "0", "false", "no", "off"]:
    if value is None:
        os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    else:
        os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = value
    result = ns["_phase14j_filter_workers_for_lane"](workers, job)
    if result != workers:
        raise SystemExit(f"FAIL: helper did not pass through workers while gate disabled value={value!r}")

print("PASS: helper remains pass-through while gate is disabled")
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

if [ "$MODE" != "--compat-only" ]; then
  echo
  echo "=== changed files limited to Phase 14J-N runtime/docs/smoke and compatibility smoke updates ==="
  python3 - <<'PY'
import subprocess

allowed = {
    "edge_controller.py",
    "docs/phase-14j-n-disabled-lane-filter-runtime-call-skeleton.md",
    "ops/smoke/check-phase-14j-n-disabled-lane-filter-runtime-call-skeleton.sh",
    "ops/smoke/check-phase-14j-h-disabled-scheduler-prefilter-skeleton.sh",
    "ops/smoke/check-phase-14j-i-disabled-lane-filter-call-plan.sh",
    "ops/smoke/check-phase-14j-j-lane-filter-exact-insertion-inspection.sh",
    "ops/smoke/check-phase-14j-k-lane-filter-candidate-variable-map.sh",
    "ops/smoke/check-phase-14j-l-lane-filter-map-review-pre-runtime-decision.sh",
    "ops/smoke/check-phase-14j-m-disabled-lane-filter-runtime-patch-contract.sh",
}
out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))
print("PASS: changed files are limited to Phase 14J-N allowed set")
PY

  echo
  echo "=== smoke script behavior guard ==="
  python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-n-disabled-lane-filter-runtime-call-skeleton.sh").read_text()
live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []
for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")
if bad:
    raise SystemExit("FAIL: 14J-N smoke contains forbidden live/external behavior:\n" + "\n".join(bad))
print("PASS: smoke behavior guard passed")
PY
fi

echo
echo "=== done: Phase 14J-N disabled lane filter runtime call skeleton smoke complete ==="
