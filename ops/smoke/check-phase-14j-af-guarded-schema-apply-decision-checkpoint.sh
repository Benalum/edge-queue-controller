#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AF guarded schema apply decision checkpoint ==="

PHASE="phase-14j-af-guarded-schema-apply-decision-checkpoint"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
DECISION="docs/${PHASE}-decision.txt"
AE_INSPECT="docs/phase-14j-ae-guarded-db-path-and-backup-readiness-inspection-bounded-inspection.txt"
AD_CHECKPOINT="docs/phase-14j-ad-apply-wrapper-static-validation-and-pre-apply-checkpoint-checkpoint.txt"
WRAPPER="ops/db/apply-default-off-worker-registry-lane-metadata.sh"
SQL="ops/db/default-off-worker-registry-lane-metadata.sql"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$DECISION" "$AE_INSPECT" "$AD_CHECKPOINT" "$WRAPPER" "$SQL" "edge_controller.py"; do
  test -f "$f"
done
test -x "$WRAPPER"
echo "PASS: required 14J-AF docs/smoke/decision/source/runtime files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== wrapper shell syntax check without execution ==="
bash -n "$WRAPPER"
echo "PASS: wrapper parses with bash -n"

echo
echo "=== documentation and decision markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-af-guarded-schema-apply-decision-checkpoint.md").read_text()
decision = Path("docs/phase-14j-af-guarded-schema-apply-decision-checkpoint-decision.txt").read_text()
ae = Path("docs/phase-14j-ae-guarded-db-path-and-backup-readiness-inspection-bounded-inspection.txt").read_text()
ad = Path("docs/phase-14j-ad-apply-wrapper-static-validation-and-pre-apply-checkpoint-checkpoint.txt").read_text()

required_doc = [
    "This phase does not execute the apply wrapper",
    "This phase does not apply the SQL artifact",
    "This phase does not create a backup",
    "This phase does not query or mutate the database",
    "This phase does not change the database schema",
    "This phase does not enable persistent lane workers",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "APPLY_DEFAULT_OFF_WORKER_LANE_METADATA",
    "Phase 14J-AG",
]

required_decision = [
    "runtime_change_in_this_phase:no",
    "service_environment_change_in_this_phase:no",
    "persistent_lane_workers_enabled_in_this_phase:no",
    "ct101_mutation_in_this_phase:no",
    "live_model_call_in_this_phase:no",
    "database_query_or_mutation_in_this_phase:no",
    "database_schema_change_in_this_phase:no",
    "apply_wrapper_executed_in_this_phase:no",
    "sql_artifact_applied_in_this_phase:no",
    "backup_created_in_this_phase:no",
    "READY_FOR_EXPLICIT_APPLY_APPROVAL:yes",
    "APPLY_IN_THIS_PHASE:no",
    "APPLY_DEFAULT_OFF_WORKER_LANE_METADATA",
    "Phase 14J-AG",
]

required_ae = [
    "PASS: pre-apply DB path and backup readiness checks are satisfied",
    "lane_worker_flag_disabled_or_absent:yes",
    "workers_table_exists:yes",
    "schema_apply_needed:yes",
    "backup_created:no",
]

required_ad = [
    "Do not apply schema in this phase.",
    "Do not run the wrapper in this phase.",
]

missing_doc = [m for m in required_doc if m not in doc]
missing_decision = [m for m in required_decision if m not in decision]
missing_ae = [m for m in required_ae if m not in ae]
missing_ad = [m for m in required_ad if m not in ad]

if missing_doc:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing_doc))
if missing_decision:
    raise SystemExit("FAIL: missing decision markers: " + ", ".join(missing_decision))
if missing_ae:
    raise SystemExit("FAIL: missing AE inspection markers: " + ", ".join(missing_ae))
if missing_ad:
    raise SystemExit("FAIL: missing AD checkpoint markers: " + ", ".join(missing_ad))

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

found = [m for m in sensitive_markers if m.lower() in decision.lower()]
if found:
    raise SystemExit("FAIL: decision contains sensitive marker: " + ", ".join(found))

print("PASS: documentation, decision, and source markers verified")
PY

echo
echo "=== no apply or backup occurred ==="
python3 - <<'PY'
from pathlib import Path

decision = Path("docs/phase-14j-af-guarded-schema-apply-decision-checkpoint-decision.txt").read_text()

required = [
    "database_query_or_mutation_in_this_phase:no",
    "database_schema_change_in_this_phase:no",
    "apply_wrapper_executed_in_this_phase:no",
    "sql_artifact_applied_in_this_phase:no",
    "backup_created_in_this_phase:no",
    "APPLY_IN_THIS_PHASE:no",
]

missing = [m for m in required if m not in decision]
if missing:
    raise SystemExit("FAIL: missing no-apply/no-backup markers: " + ", ".join(missing))

print("PASS: no apply or backup occurred")
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
echo "=== changed files limited to Phase 14J-AF docs/smoke/decision ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-af-guarded-schema-apply-decision-checkpoint.md",
    "docs/phase-14j-af-guarded-schema-apply-decision-checkpoint-decision.txt",
    "ops/smoke/check-phase-14j-af-guarded-schema-apply-decision-checkpoint.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-AF docs/smoke/decision")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-af-guarded-schema-apply-decision-checkpoint.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct|systemctl|journalctl|sqlite3)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

wrapper_exec_patterns = [
    re.compile(r'(^|[;&|]\s*)(bash|sh)\s+\S*apply-default-off-worker-registry-lane-metadata\.sh(\s|$)'),
    re.compile(r'(^|[;&|]\s*)\S*apply-default-off-worker-registry-lane-metadata\.sh\s+APPLY_DEFAULT_OFF_WORKER_LANE_METADATA'),
    re.compile(r'(^|[;&|]\s*)"?\$WRAPPER"?\s+APPLY_DEFAULT_OFF_WORKER_LANE_METADATA'),
]
bad_wrapper_exec = []
for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if stripped.startswith("#"):
        continue
    if "bash -n" in stripped:
        continue
    if any(pattern.search(stripped) for pattern in wrapper_exec_patterns):
        bad_wrapper_exec.append(f"line {lineno}: wrapper execution marker: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-AF smoke contains forbidden live/external behavior:\n" + "\n".join(bad))
if bad_wrapper_exec:
    raise SystemExit("FAIL: smoke appears to execute apply wrapper:\n" + "\n".join(bad_wrapper_exec))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-AF guarded schema apply decision checkpoint smoke complete ==="
