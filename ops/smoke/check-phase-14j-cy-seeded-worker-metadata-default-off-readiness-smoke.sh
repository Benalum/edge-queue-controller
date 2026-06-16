#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cy-seeded-worker-metadata-default-off-readiness-smoke"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CY smoke: seeded worker metadata default-off readiness ==="

test -f "$DOC"
echo "PASS: CY doc exists"

for marker in \
  "PHASE_14J_CY_SEEDED_WORKER_METADATA_DEFAULT_OFF_READINESS_SMOKE" \
  "MUTATION_SCOPE=docs_smoke_only_seeded_worker_metadata_default_off_readiness_smoke" \
  "SEEDED_WORKER_ROWS_PRESENT=verified" \
  "STUDY_LANE_METADATA_SHAPE=verified" \
  "SEEDED_ROWS_DISABLED_OR_OFFLINE=verified" \
  "DEFAULT_OFF_ENV_REMAINED_UNSET=verified" \
  "DEFAULT_OFF_FILTER_PASSTHROUGH_WITH_SEEDED_METADATA=verified" \
  "IN_PROCESS_GATE_OVERRIDE_DISABLED_OFFLINE_SEEDED_LANE_NOT_ELIGIBLE=verified" \
  "PRODUCTION_DB_UNCHANGED_AFTER_READINESS_SMOKE=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST=verified" \
  "SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=not_performed" \
  "ENVIRONMENT_OVERRIDE_SCOPE=in_process_test_only" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "GATE_B3_SEEDED_METADATA_DEFAULT_OFF_READINESS_SMOKE_RESULT=passed" \
  "NEXT_SAFE_PHASE=seeded_worker_metadata_default_off_readiness_result_checkpoint"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo
echo "=== pre-readiness runtime/default-off guard ==="
service_active="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"
service_enabled="$(systemctl is-enabled "$SERVICE" 2>/dev/null || true)"
service_flag="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null | tr ' ' '\n' | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
quick_check_before="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;")"
worker_facts_before="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT
  COUNT(*),
  COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'') NOT IN ('','primary') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0)
FROM workers;
")"
jobs_summary_before="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT COALESCE(status,'<null>'), COUNT(*)
FROM jobs
GROUP BY COALESCE(status,'<null>')
ORDER BY COALESCE(status,'<null>');
" | tr '\n' ';' | sed 's/;$//')"

echo "service_active=${service_active}"
echo "service_enabled=${service_enabled}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
echo "sqlite_quick_check_before=${quick_check_before}"
echo "worker_facts_before=${worker_facts_before}"
echo "jobs_summary_before=${jobs_summary_before:-<none>}"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check_before" = "ok"
test "$worker_facts_before" = "2,1,1,1"

echo
echo "=== run in-process seeded metadata readiness helper test ==="
python3 - <<'PY'
from pathlib import Path
import ast
import os
import sqlite3

repo = Path.cwd()
db = repo / "edge_queue.sqlite3"
source_path = repo / "edge_controller.py"

def facts():
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    try:
        quick = conn.execute("PRAGMA quick_check;").fetchone()[0]
        worker_facts = conn.execute("""
            SELECT
              COUNT(*),
              COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0),
              COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'') NOT IN ('','primary') THEN 1 ELSE 0 END),0),
              COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0)
            FROM workers;
        """).fetchone()
        jobs_summary = conn.execute("""
            SELECT COALESCE(status,'<null>'), COUNT(*)
            FROM jobs
            GROUP BY COALESCE(status,'<null>')
            ORDER BY COALESCE(status,'<null>');
        """).fetchall()
        return quick, tuple(worker_facts), tuple(jobs_summary)
    finally:
        conn.close()

before = facts()

conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
conn.row_factory = sqlite3.Row
try:
    rows = [dict(row) for row in conn.execute("SELECT * FROM workers ORDER BY worker_id;").fetchall()]
    study = conn.execute("""
        SELECT worker_role, worker_lane, accepts_lane_jobs, disabled, state, computed_health
        FROM workers
        WHERE worker_id='study-lane-metadata-default-off';
    """).fetchone()
finally:
    conn.close()

if len(rows) != 2:
    raise SystemExit(f"FAIL: expected 2 seeded worker rows, got {len(rows)}")

if not study:
    raise SystemExit("FAIL: study seeded row missing")

study_tuple = tuple(study)
if study_tuple != ("lane", "study", 1, 1, "offline", "offline"):
    raise SystemExit(f"FAIL: unexpected study seeded row shape: {study_tuple}")

print("PASS: SEEDED_WORKER_ROWS_PRESENT")
print("PASS: STUDY_LANE_METADATA_SHAPE")
print("PASS: SEEDED_ROWS_DISABLED_OR_OFFLINE")

source = source_path.read_text()
tree = ast.parse(source)
func_nodes = {
    node.name: node
    for node in tree.body
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
}

root = "_phase14j_filter_workers_for_lane"
if root not in func_nodes:
    raise SystemExit("FAIL: root helper missing: " + root)

required, seen = [], set()

def visit_func(name: str):
    if name in seen or name not in func_nodes:
        return
    seen.add(name)
    node = func_nodes[name]
    for sub in ast.walk(node):
        if isinstance(sub, ast.Name) and sub.id in func_nodes and sub.id.startswith("_phase14j_"):
            visit_func(sub.id)
    required.append(name)

visit_func(root)

helper_source = "\n".join([
    "from __future__ import annotations",
    "from typing import Any, Dict, List, Optional, Sequence, Tuple",
    "import json",
    "import os",
    "import time",
    "",
    *[ast.get_source_segment(source, func_nodes[name]) for name in required],
])

namespace = {}
exec(helper_source, namespace, namespace)
filter_workers = namespace[root]

def worker_id(row: dict) -> str:
    return str(row.get("worker_id") or row.get("id") or row.get("name") or "")

def ids(items) -> list[str]:
    return [worker_id(item) for item in items]

lane_job = {
    "job_id": "synthetic-readiness-study-lane-job",
    "job_lane": "study",
    "requires_lane_worker": True,
    "required_capabilities": ["ollama_chat"],
    "allow_primary_fallback": False,
}

old_env = os.environ.get("EDGE_PERSISTENT_LANE_WORKERS_ENABLED")
try:
    os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    default_off_ids = ids(filter_workers(rows, lane_job))
    all_ids = ids(rows)
    if default_off_ids != all_ids:
        raise SystemExit(f"FAIL: default-off passthrough expected {all_ids}, got {default_off_ids}")
    print("PASS: DEFAULT_OFF_FILTER_PASSTHROUGH_WITH_SEEDED_METADATA")

    os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = "1"
    enabled_ids = ids(filter_workers(rows, lane_job))
    if enabled_ids != []:
        raise SystemExit(f"FAIL: disabled/offline seeded lane should not be eligible, got {enabled_ids}")
    print("PASS: IN_PROCESS_GATE_OVERRIDE_DISABLED_OFFLINE_SEEDED_LANE_NOT_ELIGIBLE")

finally:
    if old_env is None:
        os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    else:
        os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = old_env

if os.environ.get("EDGE_PERSISTENT_LANE_WORKERS_ENABLED") != old_env:
    raise SystemExit("FAIL: environment was not restored")

print("PASS: ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST")

after = facts()
if after != before:
    raise SystemExit(f"FAIL: DB facts changed: before={before} after={after}")

print("PASS: PRODUCTION_DB_UNCHANGED_AFTER_READINESS_SMOKE")
print("PASS: JOB_SUMMARY_UNCHANGED")
print("PASS: Phase 14J-CY seeded readiness helper test complete")
PY

echo
echo "=== post-readiness runtime/default-off unchanged guard ==="
quick_check_after="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;")"
worker_facts_after="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT
  COUNT(*),
  COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'') NOT IN ('','primary') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0)
FROM workers;
")"
jobs_summary_after="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT COALESCE(status,'<null>'), COUNT(*)
FROM jobs
GROUP BY COALESCE(status,'<null>')
ORDER BY COALESCE(status,'<null>');
" | tr '\n' ';' | sed 's/;$//')"
service_flag_after="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null | tr ' ' '\n' | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"

echo "sqlite_quick_check_after=${quick_check_after}"
echo "worker_facts_after=${worker_facts_after}"
echo "jobs_summary_after=${jobs_summary_after:-<none>}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED_after=${service_flag_after:-<unset>}"

test "$quick_check_after" = "ok"
test "$worker_facts_after" = "$worker_facts_before"
test "$jobs_summary_after" = "$jobs_summary_before"
test -z "$service_flag_after"

echo "PASS: production DB/job facts unchanged after readiness smoke"
echo "PASS: Phase 14J-CY seeded worker metadata default-off readiness smoke passed"
