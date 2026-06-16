#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-K lane filter candidate variable map ==="

PHASE="phase-14j-k-lane-filter-candidate-variable-map"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
MAP="docs/${PHASE}-select-best-worker-variable-map.txt"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$MAP" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-K docs/smoke/map/runtime files exist"

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

doc = Path("docs/phase-14j-k-lane-filter-candidate-variable-map.md").read_text()

required = [
    "docs/smoke-only mapping phase",
    "This phase does not change scheduler behavior",
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
    "Phase 14J-L",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== variable map sanity ==="
python3 - <<'PY'
from pathlib import Path

m = Path("docs/phase-14j-k-lane-filter-candidate-variable-map-select-best-worker-variable-map.txt").read_text()

required = [
    "function:select_best_worker_for_job",
    "line_range:",
    "gate_call_count:1",
    "filter_call_present:no",
    "score_call_present:yes",
    "init_worker_registry_present:yes",
    "estimate_requirements_present:yes",
    "candidate_names_present:",
    "assignments:",
    "for_loops:",
    "calls:",
    "runtime_change_in_this_phase:no",
    "ct101_mutation_in_this_phase:no",
    "live_model_call_in_this_phase:no",
]

missing = [x for x in required if x not in m]
if missing:
    raise SystemExit("FAIL: variable map missing markers: " + ", ".join(missing))

sensitive = [
    "Authorization:",
    "Bearer ",
    "Cookie:",
    "session=",
    "password",
    "secret",
    "raw_prompt",
    "raw_message",
    "request_body",
]

found_sensitive = [x for x in sensitive if x.lower() in m.lower()]
if found_sensitive:
    raise SystemExit("FAIL: variable map contains sensitive marker: " + ", ".join(found_sensitive))

print("PASS: variable map is bounded and safe")
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

print("PASS: scheduler remains gate-only with no filter call")
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
echo "=== changed files limited to Phase 14J-K docs/smoke/map ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-k-lane-filter-candidate-variable-map.md",
    "docs/phase-14j-k-lane-filter-candidate-variable-map-select-best-worker-variable-map.txt",
    "ops/smoke/check-phase-14j-k-lane-filter-candidate-variable-map.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-K docs/smoke/map")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-k-lane-filter-candidate-variable-map.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-K smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-K lane filter candidate variable map smoke complete ==="
