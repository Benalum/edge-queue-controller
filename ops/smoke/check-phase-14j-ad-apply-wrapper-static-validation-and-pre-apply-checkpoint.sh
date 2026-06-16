#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AD apply-wrapper static validation and pre-apply checkpoint ==="

PHASE="phase-14j-ad-apply-wrapper-static-validation-and-pre-apply-checkpoint"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
CHECKPOINT="docs/${PHASE}-checkpoint.txt"
WRAPPER="ops/db/apply-default-off-worker-registry-lane-metadata.sh"
SQL="ops/db/default-off-worker-registry-lane-metadata.sql"
AC_ARTIFACT="docs/phase-14j-ac-default-off-worker-registry-lane-metadata-apply-wrapper-artifact-no-execution-artifact.txt"
AB_PLAN="docs/phase-14j-ab-default-off-worker-registry-lane-metadata-apply-wrapper-plan-plan.txt"
AA_ARTIFACT="docs/phase-14j-aa-default-off-worker-registry-lane-metadata-schema-artifact-no-apply-artifact.txt"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$CHECKPOINT" "$WRAPPER" "$SQL" "$AC_ARTIFACT" "$AB_PLAN" "$AA_ARTIFACT" "edge_controller.py"; do
  test -f "$f"
done
test -x "$WRAPPER"
echo "PASS: required 14J-AD docs/smoke/checkpoint/wrapper/sql/source/runtime files exist"

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
echo "=== documentation and checkpoint markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-ad-apply-wrapper-static-validation-and-pre-apply-checkpoint.md").read_text()
checkpoint = Path("docs/phase-14j-ad-apply-wrapper-static-validation-and-pre-apply-checkpoint-checkpoint.txt").read_text()
wrapper = Path("ops/db/apply-default-off-worker-registry-lane-metadata.sh").read_text()
sql = Path("ops/db/default-off-worker-registry-lane-metadata.sql").read_text()
ac = Path("docs/phase-14j-ac-default-off-worker-registry-lane-metadata-apply-wrapper-artifact-no-execution-artifact.txt").read_text()
ab = Path("docs/phase-14j-ab-default-off-worker-registry-lane-metadata-apply-wrapper-plan-plan.txt").read_text()
aa = Path("docs/phase-14j-aa-default-off-worker-registry-lane-metadata-schema-artifact-no-apply-artifact.txt").read_text()

required_doc = [
    "docs/smoke-only static validation",
    "This phase does not execute the apply wrapper",
    "This phase does not apply the SQL artifact",
    "This phase does not query or mutate the database",
    "This phase does not change the database schema",
    "This phase does not change scheduler behavior",
    "This phase does not change runtime code",
    "This phase does not enable persistent lane workers",
    "This phase does not change service environment variables",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "APPLY_DEFAULT_OFF_WORKER_LANE_METADATA",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED=1",
    "Phase 14J-AE",
]

required_checkpoint = [
    "runtime_change_in_this_phase:no",
    "service_environment_change_in_this_phase:no",
    "persistent_lane_workers_enabled_in_this_phase:no",
    "ct101_mutation_in_this_phase:no",
    "live_model_call_in_this_phase:no",
    "database_query_or_mutation_in_this_phase:no",
    "database_schema_change_in_this_phase:no",
    "apply_wrapper_created_in_this_phase:no",
    "apply_wrapper_executed_in_this_phase:no",
    "sql_artifact_applied_in_this_phase:no",
    "static_validation_goal:",
    "pre_apply_checkpoint_decision:",
    "required_before_future_apply:",
    "Phase 14J-AE",
]

required_wrapper = [
    "REQUIRED_CONFIRM=\"APPLY_DEFAULT_OFF_WORKER_LANE_METADATA\"",
    "REFUSE: missing exact confirmation phrase",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "REFUSE: SQLite DB not found",
    "REFUSE: SQL artifact not found",
    "cp -- \"$DB_PATH\" \"$BACKUP_PATH\"",
    "ALTER TABLE \"workers\" ADD COLUMN",
    "PASS: default-off worker registry lane metadata schema apply complete",
]

required_sources = [
    "apply_wrapper_created_in_this_phase:yes",
    "apply_wrapper_executed_in_this_phase:no",
    "sql_artifact_applied_in_this_phase:no",
    "apply_wrapper_created_in_this_phase:no",
    "Do not apply this file directly in Phase 14J-AA",
]

missing_doc = [m for m in required_doc if m not in doc]
missing_checkpoint = [m for m in required_checkpoint if m not in checkpoint]
missing_wrapper = [m for m in required_wrapper if m not in wrapper]
missing_sources = [m for m in required_sources if m not in ac + "\n" + ab + "\n" + aa + "\n" + sql]

if missing_doc:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing_doc))
if missing_checkpoint:
    raise SystemExit("FAIL: missing checkpoint markers: " + ", ".join(missing_checkpoint))
if missing_wrapper:
    raise SystemExit("FAIL: missing wrapper markers: " + ", ".join(missing_wrapper))
if missing_sources:
    raise SystemExit("FAIL: missing source markers: " + ", ".join(missing_sources))

print("PASS: documentation, checkpoint, wrapper, and source markers verified")
PY

echo
echo "=== wrapper remains guarded and not service-calling ==="
python3 - <<'PY'
from pathlib import Path
import re

wrapper = Path("ops/db/apply-default-off-worker-registry-lane-metadata.sh").read_text()

forbidden = [
    r"\bcurl\b",
    r"\bpsql\b",
    r"\bollama\b",
    r"\bssh\b",
    r"\bdocker\b",
    r"\bpct\b",
    r"\bsystemctl\b",
    r"\bjournalctl\b",
]

bad = [pattern for pattern in forbidden if re.search(pattern, wrapper)]
if bad:
    raise SystemExit("FAIL: wrapper contains forbidden service/endpoint command markers: " + ", ".join(bad))

required = [
    "CONFIRM=\"${1:-}\"",
    "REQUIRED_CONFIRM=\"APPLY_DEFAULT_OFF_WORKER_LANE_METADATA\"",
    "if [ \"$CONFIRM\" != \"$REQUIRED_CONFIRM\" ]; then",
    "if [ \"${EDGE_PERSISTENT_LANE_WORKERS_ENABLED:-}\" = \"1\" ]; then",
]

missing = [m for m in required if m not in wrapper]
if missing:
    raise SystemExit("FAIL: wrapper missing guard markers: " + ", ".join(missing))

print("PASS: wrapper remains guarded and not service-calling")
PY

echo
echo "=== SQL artifact remains additive-only ==="
python3 - <<'PY'
from pathlib import Path
import re

sql = Path("ops/db/default-off-worker-registry-lane-metadata.sql").read_text()

forbidden = [
    r"\bDROP\b",
    r"\bDELETE\b",
    r"\bUPDATE\b",
    r"\bINSERT\b",
    r"\bREPLACE\b",
    r"\bCREATE\s+TABLE\b",
    r"\bALTER\s+TABLE\s+(?!workers\s+ADD\s+COLUMN)",
    r"\bPRAGMA\s+writable_schema\b",
    r"\bVACUUM\b",
]

bad = [pattern for pattern in forbidden if re.search(pattern, sql, re.IGNORECASE)]
if bad:
    raise SystemExit("FAIL: SQL artifact contains forbidden non-additive markers: " + ", ".join(bad))

alter_lines = [
    line.strip()
    for line in sql.splitlines()
    if line.strip().upper().startswith("ALTER TABLE")
]
if len(alter_lines) != 8:
    raise SystemExit(f"FAIL: expected 8 ALTER TABLE ADD COLUMN statements, found {len(alter_lines)}")

print("PASS: SQL artifact remains additive-only")
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
echo "=== changed files limited to Phase 14J-AD docs/smoke/checkpoint ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-ad-apply-wrapper-static-validation-and-pre-apply-checkpoint.md",
    "docs/phase-14j-ad-apply-wrapper-static-validation-and-pre-apply-checkpoint-checkpoint.txt",
    "ops/smoke/check-phase-14j-ad-apply-wrapper-static-validation-and-pre-apply-checkpoint.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-AD docs/smoke/checkpoint")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-ad-apply-wrapper-static-validation-and-pre-apply-checkpoint.sh").read_text()

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
    raise SystemExit("FAIL: 14J-AD smoke contains forbidden live/external behavior:\n" + "\n".join(bad))
if bad_wrapper_exec:
    raise SystemExit("FAIL: smoke appears to execute apply wrapper:\n" + "\n".join(bad_wrapper_exec))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-AD static validation and pre-apply checkpoint smoke complete ==="
