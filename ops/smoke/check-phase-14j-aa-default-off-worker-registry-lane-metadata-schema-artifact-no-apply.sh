#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AA default-off worker registry lane metadata schema artifact, no apply ==="

PHASE="phase-14j-aa-default-off-worker-registry-lane-metadata-schema-artifact-no-apply"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
SQL="ops/db/default-off-worker-registry-lane-metadata.sql"
ARTIFACT="docs/${PHASE}-artifact.txt"
Z_CONTRACT="docs/phase-14j-z-default-off-worker-registry-lane-metadata-schema-patch-contract-contract.txt"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$SQL" "$ARTIFACT" "$Z_CONTRACT" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-AA docs/smoke/sql/artifact/source/runtime files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== documentation, artifact, and SQL markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-aa-default-off-worker-registry-lane-metadata-schema-artifact-no-apply.md").read_text()
artifact = Path("docs/phase-14j-aa-default-off-worker-registry-lane-metadata-schema-artifact-no-apply-artifact.txt").read_text()
sql = Path("ops/db/default-off-worker-registry-lane-metadata.sql").read_text()
contract = Path("docs/phase-14j-z-default-off-worker-registry-lane-metadata-schema-patch-contract-contract.txt").read_text()

required_doc = [
    "creates a no-apply SQL schema artifact",
    "This phase does not apply the schema artifact",
    "This phase does not query or mutate the database",
    "This phase does not change the database schema",
    "This phase does not change scheduler behavior",
    "This phase does not change runtime code",
    "This phase does not enable persistent lane workers",
    "This phase does not change service environment variables",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "ops/db/default-off-worker-registry-lane-metadata.sql",
    "Phase 14J-AB",
]

required_artifact = [
    "runtime_change_in_this_phase:no",
    "service_environment_change_in_this_phase:no",
    "persistent_lane_workers_enabled_in_this_phase:no",
    "ct101_mutation_in_this_phase:no",
    "live_model_call_in_this_phase:no",
    "database_query_or_mutation_in_this_phase:no",
    "database_schema_change_in_this_phase:no",
    "sql_artifact_created:yes",
    "sql_artifact_applied:no",
    "no_apply_boundary:",
    "future_apply_requirement:",
    "Phase 14J-AB",
]

required_sql = [
    "This file is an artifact only in Phase 14J-AA",
    "Do not apply this file directly in Phase 14J-AA",
    "ALTER TABLE workers ADD COLUMN worker_role TEXT DEFAULT 'primary';",
    "ALTER TABLE workers ADD COLUMN worker_lane TEXT DEFAULT '';",
    "ALTER TABLE workers ADD COLUMN accepts_lane_jobs INTEGER DEFAULT 0;",
    "ALTER TABLE workers ADD COLUMN capabilities TEXT DEFAULT '[]';",
    "ALTER TABLE workers ADD COLUMN disabled INTEGER DEFAULT 0;",
    "ALTER TABLE workers ADD COLUMN current_running_jobs INTEGER DEFAULT 0;",
    "ALTER TABLE workers ADD COLUMN state TEXT DEFAULT 'available';",
    "ALTER TABLE workers ADD COLUMN computed_health TEXT DEFAULT '';",
]

required_contract = [
    "future_target_table:",
    "workers",
    "future_additive_columns:",
    "No scheduler activation.",
    "No service flag enablement.",
]

missing_doc = [m for m in required_doc if m not in doc]
missing_artifact = [m for m in required_artifact if m not in artifact]
missing_sql = [m for m in required_sql if m not in sql]
missing_contract = [m for m in required_contract if m not in contract]

if missing_doc:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing_doc))
if missing_artifact:
    raise SystemExit("FAIL: missing artifact markers: " + ", ".join(missing_artifact))
if missing_sql:
    raise SystemExit("FAIL: missing SQL markers: " + ", ".join(missing_sql))
if missing_contract:
    raise SystemExit("FAIL: missing contract markers: " + ", ".join(missing_contract))

print("PASS: documentation, artifact, SQL, and contract markers verified")
PY

echo
echo "=== SQL artifact is additive-only and no-apply ==="
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

bad = []
for pattern in forbidden:
    if re.search(pattern, sql, re.IGNORECASE):
        bad.append(pattern)

if bad:
    raise SystemExit("FAIL: SQL artifact contains forbidden non-additive markers: " + ", ".join(bad))

alter_lines = [
    line.strip()
    for line in sql.splitlines()
    if line.strip().upper().startswith("ALTER TABLE")
]

if len(alter_lines) != 8:
    raise SystemExit(f"FAIL: expected 8 ALTER TABLE ADD COLUMN statements, found {len(alter_lines)}")

for line in alter_lines:
    if not line.startswith("ALTER TABLE workers ADD COLUMN "):
        raise SystemExit("FAIL: non-workers or non-add-column ALTER statement found: " + line)

print("PASS: SQL artifact is additive-only and no-apply")
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
echo "=== changed files limited to Phase 14J-AA docs/smoke/sql/artifact ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-aa-default-off-worker-registry-lane-metadata-schema-artifact-no-apply.md",
    "docs/phase-14j-aa-default-off-worker-registry-lane-metadata-schema-artifact-no-apply-artifact.txt",
    "ops/db/default-off-worker-registry-lane-metadata.sql",
    "ops/smoke/check-phase-14j-aa-default-off-worker-registry-lane-metadata-schema-artifact-no-apply.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-AA docs/smoke/sql/artifact")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-aa-default-off-worker-registry-lane-metadata-schema-artifact-no-apply.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct|systemctl|journalctl|sqlite3)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-AA smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-AA default-off worker registry lane metadata schema artifact smoke complete ==="
