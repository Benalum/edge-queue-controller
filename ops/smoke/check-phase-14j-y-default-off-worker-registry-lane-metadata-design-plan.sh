#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-Y default-off worker registry lane metadata design plan ==="

PHASE="phase-14j-y-default-off-worker-registry-lane-metadata-design-plan"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
DESIGN="docs/${PHASE}-design.txt"
X_REVIEW="docs/phase-14j-x-lane-metadata-result-review-and-next-step-decision-review.txt"
W_INSPECT="docs/phase-14j-w-read-only-worker-registry-lane-metadata-inspection-bounded-inspection.txt"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$DESIGN" "$X_REVIEW" "$W_INSPECT" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-Y docs/smoke/design/source/runtime files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== documentation and design markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-y-default-off-worker-registry-lane-metadata-design-plan.md").read_text()
design = Path("docs/phase-14j-y-default-off-worker-registry-lane-metadata-design-plan-design.txt").read_text()
x_review = Path("docs/phase-14j-x-lane-metadata-result-review-and-next-step-decision-review.txt").read_text()
w_inspect = Path("docs/phase-14j-w-read-only-worker-registry-lane-metadata-inspection-bounded-inspection.txt").read_text()

required_doc = [
    "docs/smoke-only design plan",
    "This phase does not query or mutate the database",
    "This phase does not change the database schema",
    "This phase does not change scheduler behavior",
    "This phase does not change runtime code",
    "This phase does not enable persistent lane workers",
    "This phase does not change service environment variables",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "worker_role",
    "worker_lane",
    "accepts_lane_jobs",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "Phase 14J-Z",
]

required_design = [
    "runtime_change_in_this_phase:no",
    "service_environment_change_in_this_phase:no",
    "persistent_lane_workers_enabled_in_this_phase:no",
    "ct101_mutation_in_this_phase:no",
    "live_model_call_in_this_phase:no",
    "database_query_or_mutation_in_this_phase:no",
    "database_schema_change_in_this_phase:no",
    "job_23_mutation_in_this_phase:no",
    "worker_registry_mutation_in_this_phase:no",
    "worker_registration_change_in_this_phase:no",
    "scheduler_behavior_change_in_this_phase:no",
    "candidate_schema_additions:",
    "worker_role TEXT DEFAULT 'primary'",
    "worker_lane TEXT DEFAULT ''",
    "accepts_lane_jobs INTEGER DEFAULT 0",
    "capabilities TEXT DEFAULT '[]'",
    "compatibility_policy:",
    "activation_policy:",
    "candidate_next_phase:",
]

required_source = [
    "lane_metadata_status:missing_lane_metadata",
    "BLOCK_ENABLEMENT",
    "worker registry lane metadata columns are missing",
]

missing_doc = [m for m in required_doc if m not in doc]
missing_design = [m for m in required_design if m not in design]
missing_source = [m for m in required_source if m not in x_review + "\n" + w_inspect]

if missing_doc:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing_doc))
if missing_design:
    raise SystemExit("FAIL: missing design markers: " + ", ".join(missing_design))
if missing_source:
    raise SystemExit("FAIL: missing source review/inspection markers: " + ", ".join(missing_source))

print("PASS: documentation, design, and source markers verified")
PY

echo
echo "=== enablement remains blocked pending metadata support ==="
python3 - <<'PY'
from pathlib import Path

design = Path("docs/phase-14j-y-default-off-worker-registry-lane-metadata-design-plan-design.txt").read_text()

required = [
    "Existing workers default to primary role",
    "Existing workers do not accept lane jobs by default",
    "Lane filtering remains behind EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "Schema support alone must not enable filtering",
    "Registration support alone must not enable filtering",
    "Service environment enablement remains separate",
]

missing = [m for m in required if m not in design]
if missing:
    raise SystemExit("FAIL: missing blocked/default-off design markers: " + ", ".join(missing))

print("PASS: default-off metadata design preserves blocked enablement")
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
echo "=== changed files limited to Phase 14J-Y docs/smoke/design ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-y-default-off-worker-registry-lane-metadata-design-plan.md",
    "docs/phase-14j-y-default-off-worker-registry-lane-metadata-design-plan-design.txt",
    "ops/smoke/check-phase-14j-y-default-off-worker-registry-lane-metadata-design-plan.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-Y docs/smoke/design")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-y-default-off-worker-registry-lane-metadata-design-plan.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct|systemctl|journalctl|sqlite3)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-Y smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-Y default-off worker registry lane metadata design plan smoke complete ==="
