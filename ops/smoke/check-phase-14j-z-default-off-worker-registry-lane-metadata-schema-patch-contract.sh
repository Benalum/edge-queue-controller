#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-Z default-off worker registry lane metadata schema patch contract ==="

PHASE="phase-14j-z-default-off-worker-registry-lane-metadata-schema-patch-contract"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
CONTRACT="docs/${PHASE}-contract.txt"
Y_DESIGN="docs/phase-14j-y-default-off-worker-registry-lane-metadata-design-plan-design.txt"
X_REVIEW="docs/phase-14j-x-lane-metadata-result-review-and-next-step-decision-review.txt"
W_INSPECT="docs/phase-14j-w-read-only-worker-registry-lane-metadata-inspection-bounded-inspection.txt"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$CONTRACT" "$Y_DESIGN" "$X_REVIEW" "$W_INSPECT" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-Z docs/smoke/contract/source/runtime files exist"

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

doc = Path("docs/phase-14j-z-default-off-worker-registry-lane-metadata-schema-patch-contract.md").read_text()
contract = Path("docs/phase-14j-z-default-off-worker-registry-lane-metadata-schema-patch-contract-contract.txt").read_text()
y_design = Path("docs/phase-14j-y-default-off-worker-registry-lane-metadata-design-plan-design.txt").read_text()
x_review = Path("docs/phase-14j-x-lane-metadata-result-review-and-next-step-decision-review.txt").read_text()
w_inspect = Path("docs/phase-14j-w-read-only-worker-registry-lane-metadata-inspection-bounded-inspection.txt").read_text()

required_doc = [
    "docs/smoke-only schema patch contract",
    "This phase does not query or mutate the database",
    "This phase does not change the database schema",
    "This phase does not change scheduler behavior",
    "This phase does not change runtime code",
    "This phase does not enable persistent lane workers",
    "This phase does not change service environment variables",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "edge_queue.sqlite3",
    "workers",
    "worker_role TEXT DEFAULT 'primary'",
    "worker_lane TEXT DEFAULT ''",
    "accepts_lane_jobs INTEGER DEFAULT 0",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1",
    "Phase 14J-AA",
]

required_contract = [
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
    "future_target_table:",
    "workers",
    "future_additive_columns:",
    "worker_role TEXT DEFAULT 'primary'",
    "worker_lane TEXT DEFAULT ''",
    "accepts_lane_jobs INTEGER DEFAULT 0",
    "capabilities TEXT DEFAULT '[]'",
    "disabled INTEGER DEFAULT 0",
    "current_running_jobs INTEGER DEFAULT 0",
    "state TEXT DEFAULT 'available'",
    "computed_health TEXT DEFAULT ''",
    "future_patch_constraints:",
    "Additive only.",
    "No destructive migration.",
    "No scheduler activation.",
    "No service flag enablement.",
    "future_pre_apply_checks:",
    "future_post_apply_checks:",
    "rollback_policy:",
    "candidate_next_phase:",
]

required_source = [
    "lane_metadata_status:missing_lane_metadata",
    "BLOCK_ENABLEMENT",
    "worker registry lane metadata columns are missing",
    "Schema support alone must not enable filtering",
    "Registration support alone must not enable filtering",
    "chosen_db_basename:edge_queue.sqlite3",
    "chosen_worker_table:workers",
]

combined_source = y_design + "\n" + x_review + "\n" + w_inspect

missing_doc = [m for m in required_doc if m not in doc]
missing_contract = [m for m in required_contract if m not in contract]
missing_source = [m for m in required_source if m not in combined_source]

if missing_doc:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing_doc))
if missing_contract:
    raise SystemExit("FAIL: missing contract markers: " + ", ".join(missing_contract))
if missing_source:
    raise SystemExit("FAIL: missing source markers: " + ", ".join(missing_source))

print("PASS: documentation, contract, and source markers verified")
PY

echo
echo "=== contract remains default-off and non-mutating ==="
python3 - <<'PY'
from pathlib import Path

contract = Path("docs/phase-14j-z-default-off-worker-registry-lane-metadata-schema-patch-contract-contract.txt").read_text()

required = [
    "database_schema_change_in_this_phase:no",
    "worker_registry_mutation_in_this_phase:no",
    "worker_registration_change_in_this_phase:no",
    "scheduler_behavior_change_in_this_phase:no",
    "Existing workers must not become lane workers by default.",
    "Existing workers must not accept lane jobs by default.",
    "Service flag rollback remains separate",
]

missing = [m for m in required if m not in contract]
if missing:
    raise SystemExit("FAIL: missing default-off/non-mutating contract markers: " + ", ".join(missing))

print("PASS: contract remains default-off and non-mutating")
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
echo "=== changed files limited to Phase 14J-Z docs/smoke/contract ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-z-default-off-worker-registry-lane-metadata-schema-patch-contract.md",
    "docs/phase-14j-z-default-off-worker-registry-lane-metadata-schema-patch-contract-contract.txt",
    "ops/smoke/check-phase-14j-z-default-off-worker-registry-lane-metadata-schema-patch-contract.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-Z docs/smoke/contract")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-z-default-off-worker-registry-lane-metadata-schema-patch-contract.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct|systemctl|journalctl|sqlite3)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-Z smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-Z default-off worker registry lane metadata schema patch contract smoke complete ==="
