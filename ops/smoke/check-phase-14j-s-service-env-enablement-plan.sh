#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-S service environment enablement plan ==="

PHASE="phase-14j-s-service-env-enablement-plan"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
PLAN="docs/${PHASE}-plan.txt"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$PLAN" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-S docs/smoke/plan/runtime files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== documentation and plan markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-s-service-env-enablement-plan.md").read_text()
plan = Path("docs/phase-14j-s-service-env-enablement-plan-plan.txt").read_text()

required_doc = [
    "docs/smoke-only plan",
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
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1",
    "This phase does not set that flag",
    "Phase 14J-T",
]

required_plan = [
    "runtime_change_in_this_phase:no",
    "service_environment_change_in_this_phase:no",
    "persistent_lane_workers_enabled_in_this_phase:no",
    "ct101_mutation_in_this_phase:no",
    "live_model_call_in_this_phase:no",
    "database_query_or_mutation_in_this_phase:no",
    "job_23_mutation_in_this_phase:no",
    "future_flag:",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1",
    "required_before_enablement:",
    "rollback_requirement:",
    "observability_requirement:",
    "candidate_next_phase:",
]

missing_doc = [m for m in required_doc if m not in doc]
missing_plan = [m for m in required_plan if m not in plan]

if missing_doc:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing_doc))
if missing_plan:
    raise SystemExit("FAIL: missing plan markers: " + ", ".join(missing_plan))

print("PASS: documentation and plan markers verified")
PY

echo
echo "=== current scheduler shape remains ready but not enabled here ==="
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

score = defs.get("score_worker_for_job")
if score is None:
    raise SystemExit("FAIL: score_worker_for_job missing")

score_src = ast.get_source_segment(text, score) or ""
helpers = [
    "_phase14j_lane_workers_enabled",
    "_phase14j_filter_workers_for_lane",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
]
found = [h for h in helpers if h in score_src]
if found:
    raise SystemExit("FAIL: score_worker_for_job references lane helpers: " + ", ".join(found))

print("PASS: scheduler shape remains ready and scoring remains isolated")
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
echo "=== changed files limited to Phase 14J-S docs/smoke/plan ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-s-service-env-enablement-plan.md",
    "docs/phase-14j-s-service-env-enablement-plan-plan.txt",
    "ops/smoke/check-phase-14j-s-service-env-enablement-plan.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-S docs/smoke/plan")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-s-service-env-enablement-plan.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct|systemctl|journalctl)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-S smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-S service environment enablement plan smoke complete ==="
