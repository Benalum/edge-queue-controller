#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-M disabled lane filter runtime patch contract ==="

PHASE="phase-14j-m-disabled-lane-filter-runtime-patch-contract"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
CONTRACT="docs/${PHASE}-contract.txt"
MAP="docs/phase-14j-k-lane-filter-candidate-variable-map-select-best-worker-variable-map.txt"
REVIEW="docs/phase-14j-l-lane-filter-map-review-pre-runtime-decision-candidate-map-review.txt"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$CONTRACT" "$MAP" "$REVIEW" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-M docs/smoke/contract/map/runtime files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== documentation and contract markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-m-disabled-lane-filter-runtime-patch-contract.md").read_text()
contract = Path("docs/phase-14j-m-disabled-lane-filter-runtime-patch-contract-contract.txt").read_text()

required_doc = [
    "docs/smoke-only contract phase",
    "This phase does not change scheduler behavior",
    "This phase does not call the lane worker filter helper",
    "This phase does not filter the primary worker",
    "This phase does not change worker scoring",
    "This phase does not change worker assignment",
    "This phase does not change worker registration",
    "This phase does not call live model endpoints",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "workers = [worker_row_to_dict(row) for row in rows]",
    "candidates = []",
    "_phase14j_filter_workers_for_lane(workers, job)",
    "Phase 14J-N",
]

required_contract = [
    "runtime_change_in_this_phase:no",
    "ct101_mutation_in_this_phase:no",
    "live_model_call_in_this_phase:no",
    "job_23_mutation_in_this_phase:no",
    "selected_candidate_variable:workers",
    "source_rows_variable:rows",
    "scored_output_variable:candidates",
    "approved_future_helper:_phase14j_filter_workers_for_lane",
    "approved_future_runtime_function:select_best_worker_for_job",
    "approved_future_insertion_after:workers = [worker_row_to_dict(row) for row in rows]",
    "approved_future_insertion_before:candidates = []",
]

missing_doc = [m for m in required_doc if m not in doc]
missing_contract = [m for m in required_contract if m not in contract]

if missing_doc:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing_doc))
if missing_contract:
    raise SystemExit("FAIL: missing contract markers: " + ", ".join(missing_contract))

print("PASS: documentation and contract markers verified")
PY

echo
echo "=== map and review confirm workers candidate variable ==="
python3 - <<'PY'
from pathlib import Path

m = Path("docs/phase-14j-k-lane-filter-candidate-variable-map-select-best-worker-variable-map.txt").read_text()
review = Path("docs/phase-14j-l-lane-filter-map-review-pre-runtime-decision-candidate-map-review.txt").read_text()

required = [
    "- workers",
    "filter_call_present:no",
    "score_call_present:yes",
    "line 421: workers = [worker_row_to_dict(row) for row in rows]",
    "line 423: candidates = []",
    "line 426: for worker in workers",
]

missing = [x for x in required if x not in m and x not in review]
if missing:
    raise SystemExit("FAIL: map/review missing expected candidate markers: " + ", ".join(missing))

print("PASS: map/review confirm workers candidate variable")
PY

echo
echo "=== current scheduler still has no filter call ==="
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
    "candidates = []",
    "for worker in workers:",
    "score_worker_for_job(worker, requirements)",
]

missing = [x for x in required if x not in src]
if missing:
    raise SystemExit("FAIL: select_best_worker_for_job missing expected markers: " + ", ".join(missing))

if src.count("_phase14j_lane_workers_enabled(") != 1:
    raise SystemExit("FAIL: expected exactly one lane gate call in select_best_worker_for_job")

blocked = [
    "_phase14j_filter_workers_for_lane(",
    "_phase14j_worker_eligible_for_job(",
    "_phase14j_job_lane_metadata(",
    "_phase14j_worker_lane_metadata(",
]

found = [x for x in blocked if x in src]
if found:
    raise SystemExit("FAIL: scheduler already references future filter/metadata helpers: " + ", ".join(found))

print("PASS: scheduler remains gate-only and ready for future filter insertion")
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
echo "=== changed files limited to Phase 14J-M docs/smoke/contract ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-m-disabled-lane-filter-runtime-patch-contract.md",
    "docs/phase-14j-m-disabled-lane-filter-runtime-patch-contract-contract.txt",
    "ops/smoke/check-phase-14j-m-disabled-lane-filter-runtime-patch-contract.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-M docs/smoke/contract")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-m-disabled-lane-filter-runtime-patch-contract.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-M smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-M disabled lane filter runtime patch contract smoke complete ==="
