#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-W read-only worker registry lane metadata inspection ==="

PHASE="phase-14j-w-read-only-worker-registry-lane-metadata-inspection"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
INSPECT="docs/${PHASE}-bounded-inspection.txt"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$INSPECT" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-W docs/smoke/inspection/runtime files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== documentation and inspection markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-w-read-only-worker-registry-lane-metadata-inspection.md").read_text()
inspection = Path("docs/phase-14j-w-read-only-worker-registry-lane-metadata-inspection-bounded-inspection.txt").read_text()

required_doc = [
    "bounded read-only worker registry lane metadata inspection",
    "This phase may perform a read-only database query",
    "This phase does not mutate the database",
    "This phase does not change scheduler behavior",
    "This phase does not change runtime code",
    "This phase does not enable persistent lane workers",
    "This phase does not change service environment variables",
    "This phase does not restart or reload services",
    "This phase does not call controller endpoints",
    "This phase does not call live model endpoints",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "worker_role",
    "worker_lane",
    "accepts_lane_jobs",
    "Phase 14J-X",
]

required_inspection = [
    "runtime_change_in_this_phase:no",
    "service_environment_change_in_this_phase:no",
    "persistent_lane_workers_enabled_in_this_phase:no",
    "ct101_mutation_in_this_phase:no",
    "live_model_call_in_this_phase:no",
    "database_mutation_in_this_phase:no",
    "database_query_scope:bounded_read_only_worker_registry",
    "job_23_mutation_in_this_phase:no",
    "service_restart_or_reload_in_this_phase:no",
    "endpoint_call_in_this_phase:no",
    "db_candidate_count:",
    "sqlite_candidate_count:",
    "db_open_mode:",
    "lane_metadata_status:",
    "inspection_result:",
]

missing_doc = [m for m in required_doc if m not in doc]
missing_inspection = [m for m in required_inspection if m not in inspection]

if missing_doc:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing_doc))
if missing_inspection:
    raise SystemExit("FAIL: missing inspection markers: " + ", ".join(missing_inspection))

sensitive_markers = [
    "Authorization:",
    "Bearer ",
    "Cookie:",
    "session=",
    "password",
    "secret",
    "private_key",
    "BEGIN ",
    "token",
]

found = [m for m in sensitive_markers if m.lower() in inspection.lower()]
if found:
    raise SystemExit("FAIL: inspection contains sensitive marker: " + ", ".join(found))

print("PASS: documentation and inspection markers verified")
PY

echo
echo "=== current scheduler shape remains unchanged ==="
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
    "workers = _phase14j_filter_workers_for_lane(workers, job)",
    "score_worker_for_job(worker, requirements)",
]

missing = [m for m in required if m not in src]
if missing:
    raise SystemExit("FAIL: missing scheduler readiness markers: " + ", ".join(missing))

if src.count("_phase14j_lane_workers_enabled(") != 1:
    raise SystemExit("FAIL: expected exactly one scheduler lane gate call")
if src.count("_phase14j_filter_workers_for_lane(") != 1:
    raise SystemExit("FAIL: expected exactly one scheduler lane filter call")

print("PASS: scheduler shape remains unchanged")
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
echo "=== changed files limited to Phase 14J-W docs/smoke/inspection ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-w-read-only-worker-registry-lane-metadata-inspection.md",
    "docs/phase-14j-w-read-only-worker-registry-lane-metadata-inspection-bounded-inspection.txt",
    "ops/smoke/check-phase-14j-w-read-only-worker-registry-lane-metadata-inspection.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-W docs/smoke/inspection")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-w-read-only-worker-registry-lane-metadata-inspection.sh").read_text()

forbidden_live_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct|systemctl|journalctl|sqlite3)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if forbidden_live_re.match(stripped):
        bad.append(f"line {lineno}: forbidden live/external command in smoke: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-W smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-W read-only worker registry lane metadata inspection smoke complete ==="
