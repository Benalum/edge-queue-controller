#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-R runtime enablement readiness checkpoint ==="

PHASE="phase-14j-r-runtime-enablement-readiness-checkpoint"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
READINESS="docs/${PHASE}-readiness.txt"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$READINESS" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-R docs/smoke/readiness/runtime files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== documentation and readiness markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-r-runtime-enablement-readiness-checkpoint.md").read_text()
readiness = Path("docs/phase-14j-r-runtime-enablement-readiness-checkpoint-readiness.txt").read_text()

required_doc = [
    "docs/smoke-only readiness checkpoint",
    "This phase does not change scheduler behavior",
    "This phase does not change runtime code",
    "This phase does not enable persistent lane workers",
    "This phase does not change service environment variables",
    "This phase does not call controller endpoints",
    "This phase does not call live model endpoints",
    "This phase does not query or mutate the database",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "This phase does not change worker scoring",
    "This phase does not change worker assignment",
    "This phase does not change worker registration",
    "This phase does not enable router evidence writer persistence",
    "_phase14j_lane_workers_enabled()",
    "_phase14j_filter_workers_for_lane(workers, job)",
    "if phase14j_lane_scheduler_gate_enabled:",
    "Phase 14J-S",
]

required_readiness = [
    "runtime_change_in_this_phase:no",
    "service_environment_change_in_this_phase:no",
    "persistent_lane_workers_enabled_in_this_phase:no",
    "ct101_mutation_in_this_phase:no",
    "live_model_call_in_this_phase:no",
    "database_query_or_mutation_in_this_phase:no",
    "job_23_mutation_in_this_phase:no",
    "warmup_execution_enablement_in_this_phase:no",
    "router_model_selection_enablement_in_this_phase:no",
    "router_evidence_writer_enablement_in_this_phase:no",
    "current_scheduler_shape:",
    "not_ready_for_real_enablement_until:",
    "candidate_next_phase:",
]

missing_doc = [m for m in required_doc if m not in doc]
missing_readiness = [m for m in required_readiness if m not in readiness]

if missing_doc:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing_doc))
if missing_readiness:
    raise SystemExit("FAIL: missing readiness markers: " + ", ".join(missing_readiness))

print("PASS: documentation and readiness markers verified")
PY

echo
echo "=== scheduler readiness shape ==="
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
    "workers = _phase14j_filter_workers_for_lane(workers, job)",
    "candidates = []",
    "for worker in workers:",
    "score_worker_for_job(worker, requirements)",
]

missing = [m for m in required if m not in src]
if missing:
    raise SystemExit("FAIL: missing scheduler markers: " + ", ".join(missing))

if src.count("_phase14j_lane_workers_enabled(") != 1:
    raise SystemExit("FAIL: expected exactly one scheduler lane gate call")

if src.count("_phase14j_filter_workers_for_lane(") != 1:
    raise SystemExit("FAIL: expected exactly one scheduler lane filter call")

workers_index = src.index("workers = [worker_row_to_dict(row) for row in rows]")
filter_index = src.index("workers = _phase14j_filter_workers_for_lane(workers, job)")
candidates_index = src.index("candidates = []")
score_index = src.index("score_worker_for_job(worker, requirements)")

if not (workers_index < filter_index < candidates_index < score_index):
    raise SystemExit("FAIL: scheduler filter call ordering is unsafe")

gate_blocks = []
filter_gate_blocks = []

for node in ast.walk(target):
    if isinstance(node, ast.If):
        test_src = ast.get_source_segment(text, node.test) or ""
        body_src = "\n".join(ast.get_source_segment(text, item) or "" for item in node.body)
        if test_src == "phase14j_lane_scheduler_gate_enabled":
            gate_blocks.append(body_src)
            if "workers = _phase14j_filter_workers_for_lane(workers, job)" in body_src:
                filter_gate_blocks.append(body_src)

if len(gate_blocks) != 2:
    raise SystemExit(f"FAIL: expected two phase14j gate blocks after 14J-N, found {len(gate_blocks)}")

if len(filter_gate_blocks) != 1:
    raise SystemExit(f"FAIL: expected exactly one filter-containing gate block, found {len(filter_gate_blocks)}")

print("PASS: scheduler readiness shape verified")
PY

echo
echo "=== isolated helper behavior still bounded ==="
python3 - <<'PY'
from pathlib import Path
import os
import copy

text = Path("edge_controller.py").read_text()
start = text.index("# Phase 14J-E persistent lane worker default-off helper skeletons.")
end = text.index("def _phase14iag_queued_chat_router_shadow_enabled")
helper_src = text[start:end]

ns = {}
exec(helper_src, ns)

workers = [
    {"worker_id": "primary", "worker_role": "primary", "worker_lane": "default", "capabilities": ["ollama_chat"], "state": "available"},
    {"worker_id": "study-good", "worker_role": "lane", "worker_lane": "study", "capabilities": ["ollama_chat"], "state": "available", "accepts_lane_jobs": True},
    {"worker_id": "wrong-lane", "worker_role": "lane", "worker_lane": "companion", "capabilities": ["ollama_chat"], "state": "available", "accepts_lane_jobs": True},
]
job = {
    "job_lane": "study",
    "required_capabilities": ["ollama_chat"],
    "requires_lane_worker": True,
    "allow_primary_fallback": False,
}

os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
original = copy.deepcopy(workers)
disabled_result = ns["_phase14j_filter_workers_for_lane"](workers, job)

if disabled_result != original:
    raise SystemExit("FAIL: disabled helper did not preserve worker list")
if workers != original:
    raise SystemExit("FAIL: disabled helper mutated worker list")

os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = "1"
enabled_result = ns["_phase14j_filter_workers_for_lane"](workers, job)
enabled_ids = [w["worker_id"] for w in enabled_result]

if enabled_ids != ["study-good"]:
    raise SystemExit("FAIL: enabled helper behavior changed unexpectedly: " + repr(enabled_ids))

print("PASS: isolated helper behavior remains bounded")
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
echo "=== changed files limited to Phase 14J-R docs/smoke/readiness ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-r-runtime-enablement-readiness-checkpoint.md",
    "docs/phase-14j-r-runtime-enablement-readiness-checkpoint-readiness.txt",
    "ops/smoke/check-phase-14j-r-runtime-enablement-readiness-checkpoint.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-R docs/smoke/readiness")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-r-runtime-enablement-readiness-checkpoint.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct|systemctl|journalctl)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-R smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-R runtime enablement readiness checkpoint smoke complete ==="
