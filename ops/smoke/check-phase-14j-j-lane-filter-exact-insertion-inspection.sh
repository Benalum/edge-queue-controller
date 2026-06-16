#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-J lane filter exact insertion inspection ==="

PHASE="phase-14j-j-lane-filter-exact-insertion-inspection"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
INSPECT="docs/${PHASE}-select-best-worker-snapshot.txt"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$INSPECT" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-J docs/smoke/inspection/runtime files exist"

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

doc = Path("docs/phase-14j-j-lane-filter-exact-insertion-inspection.md").read_text()

required = [
    "docs/smoke-only inspection phase",
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
    "Phase 14J-K",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== inspection snapshot sanity ==="
python3 - <<'PY'
from pathlib import Path

snapshot = Path("docs/phase-14j-j-lane-filter-exact-insertion-inspection-select-best-worker-snapshot.txt").read_text()

required = [
    "def select_best_worker_for_job",
    "Phase 14J-H disabled scheduler pre-filter integration skeleton",
    "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()",
    "init_worker_registry_db()",
    "estimate_job_requirements(job)",
    "score_worker_for_job",
]

missing = [m for m in required if m not in snapshot]
if missing:
    raise SystemExit("FAIL: snapshot missing expected markers: " + ", ".join(missing))

blocked = [
    "_phase14j_filter_workers_for_lane(",
    "_phase14j_worker_eligible_for_job(",
    "_phase14j_job_lane_metadata(",
    "_phase14j_worker_lane_metadata(",
]

found = [m for m in blocked if m in snapshot]
if found:
    raise SystemExit("FAIL: snapshot already contains future filter/metadata calls: " + ", ".join(found))

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

found_sensitive = [m for m in sensitive if m.lower() in snapshot.lower()]
if found_sensitive:
    raise SystemExit("FAIL: snapshot contains sensitive marker: " + ", ".join(found_sensitive))

print("PASS: inspection snapshot is bounded and safe")
PY

echo
echo "=== current scheduler shape still pre-filter-only ==="
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

found = [m for m in blocked if m in src]
if found:
    raise SystemExit("FAIL: scheduler already references future filter/metadata helpers: " + ", ".join(found))

print("PASS: scheduler remains pre-filter-only")
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
echo "=== changed files limited to Phase 14J-J docs/smoke/inspection ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-j-lane-filter-exact-insertion-inspection.md",
    "docs/phase-14j-j-lane-filter-exact-insertion-inspection-select-best-worker-snapshot.txt",
    "ops/smoke/check-phase-14j-j-lane-filter-exact-insertion-inspection.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-J docs/smoke/inspection")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-j-lane-filter-exact-insertion-inspection.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-J smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-J lane filter exact insertion inspection smoke complete ==="
