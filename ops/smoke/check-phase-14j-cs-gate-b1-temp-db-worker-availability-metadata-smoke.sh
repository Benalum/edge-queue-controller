#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cs-gate-b1-temp-db-worker-availability-metadata-smoke"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CS smoke: Gate B1 temp-DB worker availability metadata ==="

test -f "$DOC"
echo "PASS: CS doc exists"

for marker in \
  "PHASE_14J_CS_GATE_B1_TEMP_DB_WORKER_AVAILABILITY_METADATA_SMOKE" \
  "MUTATION_SCOPE=docs_smoke_repair2_temp_db_only_worker_availability_metadata_smoke" \
  "INITIAL_CS_ATTEMPT_RESULT=blocked_by_helper_dependency_name_drift" \
  "FIRST_CS_REPAIR_RESULT=blocked_by_temp_db_unhealthy_worker_fixture_mapping" \
  "REPAIR_STRATEGY=ast_recursive_helper_dependency_extraction" \
  "REPAIR2_STRATEGY=defensive_persisted_health_state_fixture_mapping" \
  "TEMP_DB_CREATED=verified" \
  "TEMP_DB_WORKER_ROWS_INSERTED=verified" \
  "TEMP_DB_ONLY_INSERTS=verified" \
  "DEFAULT_OFF_FILTER_PASSTHROUGH_WITH_TEMP_DB=verified" \
  "TEMP_DB_LANE_REQUIRED_ACCEPTS_ONLY_ELIGIBLE_STUDY_WORKER=verified" \
  "TEMP_DB_ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified" \
  "TEMP_DB_NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified" \
  "TEMP_DB_PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB=verified" \
  "TEMP_DB_WRONG_LANE_REJECTED=verified" \
  "TEMP_DB_MISSING_CAPABILITY_REJECTED=verified" \
  "TEMP_DB_OFFLINE_OR_UNHEALTHY_WORKER_REJECTED=verified" \
  "TEMP_DB_DISABLED_WORKER_REJECTED=verified" \
  "TEMP_DB_CAPACITY_SATURATED_WORKER_REJECTED=verified" \
  "TEMP_DB_LANE_REQUIRED_WITH_NO_ELIGIBLE_WORKER_FAILS_SAFE=verified" \
  "PRODUCTION_DB_UNCHANGED_AFTER_TEMP_DB_SMOKE=verified" \
  "ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST=verified" \
  "SOURCE_MUTATION=not_performed" \
  "PRODUCTION_DB_MUTATION=not_performed" \
  "TEMP_DB_MUTATION=performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "GATE_B1_TEMP_DB_WORKER_AVAILABILITY_SMOKE_RESULT=passed" \
  "NEXT_SAFE_PHASE=gate_b1_temp_db_worker_availability_result_checkpoint"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo
echo "=== runtime/default-off guard, read-only ==="
service_active="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"
service_enabled="$(systemctl is-enabled "$SERVICE" 2>/dev/null || true)"
service_flag="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null | tr ' ' '\n' | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
quick_check="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;")"
worker_facts_before="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT
  COUNT(*),
  COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'') NOT IN ('','primary') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0)
FROM workers;
")"

echo "service_active=${service_active}"
echo "service_enabled=${service_enabled}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
echo "sqlite_quick_check=${quick_check}"
echo "worker_facts_before=${worker_facts_before}"

IFS=',' read -r worker_count lane_enabled non_default_lane non_primary_role <<< "$worker_facts_before"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$lane_enabled" = "0"
test "$non_default_lane" = "0"
test "$non_primary_role" = "0"

echo "PASS: production runtime remains default-off before temp DB smoke"

echo
echo "=== run temp-DB persisted worker metadata helper smoke ==="
python3 - <<'PY2'
from pathlib import Path
import ast
import json
import os
import shutil
import sqlite3
import tempfile
import time

repo = Path.cwd()
prod_db = repo / "edge_queue.sqlite3"
source_path = repo / "edge_controller.py"

def prod_facts() -> tuple:
    conn = sqlite3.connect(f"file:{prod_db}?mode=ro", uri=True)
    try:
        quick = conn.execute("PRAGMA quick_check;").fetchone()[0]
        facts = conn.execute("""
            SELECT
              COUNT(*),
              COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0),
              COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'') NOT IN ('','primary') THEN 1 ELSE 0 END),0),
              COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0)
            FROM workers;
        """).fetchone()
        return (quick,) + tuple(facts)
    finally:
        conn.close()

prod_before = prod_facts()
fd, temp_name = tempfile.mkstemp(prefix="apc_14j_cs_workers_", suffix=".sqlite3")
os.close(fd)
temp_db = Path(temp_name)

try:
    shutil.copy2(prod_db, temp_db)
    print("PASS: TEMP_DB_CREATED")

    conn = sqlite3.connect(temp_db)
    conn.row_factory = sqlite3.Row

    cols_info = conn.execute("PRAGMA table_info(workers);").fetchall()
    cols = [row["name"] for row in cols_info]
    info_by_col = {row["name"]: row for row in cols_info}
    if not cols:
        raise SystemExit("FAIL: workers table missing in temp DB")

    conn.execute("DELETE FROM workers;")
    now = int(time.time())

    synthetic = [
        dict(worker_id="primary", worker_role="primary", worker_lane="primary", accepts_lane_jobs=0, capabilities=["ollama_chat"], disabled=0, current_running_jobs=0, max_concurrent_jobs=5, state="available", status="available", computed_health="healthy", health="healthy"),
        dict(worker_id="study-good", worker_role="lane", worker_lane="study", accepts_lane_jobs=1, capabilities=["ollama_chat", "study"], disabled=0, current_running_jobs=0, max_concurrent_jobs=5, state="available", status="available", computed_health="healthy", health="healthy"),
        dict(worker_id="study-not-accepting", worker_role="lane", worker_lane="study", accepts_lane_jobs=0, capabilities=["ollama_chat", "study"], disabled=0, current_running_jobs=0, max_concurrent_jobs=5, state="available", status="available", computed_health="healthy", health="healthy"),
        dict(worker_id="study-saturated", worker_role="lane", worker_lane="study", accepts_lane_jobs=1, capabilities=["ollama_chat", "study"], disabled=0, current_running_jobs=5, max_concurrent_jobs=5, state="available", status="available", computed_health="healthy", health="healthy"),
        dict(worker_id="wrong-lane", worker_role="lane", worker_lane="companion", accepts_lane_jobs=1, capabilities=["ollama_chat", "study"], disabled=0, current_running_jobs=0, max_concurrent_jobs=5, state="available", status="available", computed_health="healthy", health="healthy"),
        dict(worker_id="missing-capability", worker_role="lane", worker_lane="study", accepts_lane_jobs=1, capabilities=["tts"], disabled=0, current_running_jobs=0, max_concurrent_jobs=5, state="available", status="available", computed_health="healthy", health="healthy"),
        dict(worker_id="offline-worker", worker_role="lane", worker_lane="study", accepts_lane_jobs=1, capabilities=["ollama_chat", "study"], disabled=0, current_running_jobs=0, max_concurrent_jobs=5, state="offline", status="offline", computed_health="offline", health="offline"),
        dict(worker_id="unhealthy-worker", worker_role="lane", worker_lane="study", accepts_lane_jobs=1, capabilities=["ollama_chat", "study"], disabled=0, current_running_jobs=0, max_concurrent_jobs=5, state="unhealthy", status="unhealthy", computed_health="unhealthy", health="unhealthy"),
        dict(worker_id="disabled-worker", worker_role="lane", worker_lane="study", accepts_lane_jobs=1, capabilities=["ollama_chat", "study"], disabled=1, current_running_jobs=0, max_concurrent_jobs=5, state="available", status="available", computed_health="healthy", health="healthy"),
    ]

    def default_for_unknown(col: str, typ: str, wid: str):
        lower = col.lower()
        upper_typ = (typ or "").upper()
        if "id" in lower:
            return wid
        if "time" in lower or lower.endswith("_at") or "heartbeat" in lower:
            return now
        if "count" in lower or "num" in lower or "total" in lower or "running" in lower:
            return 0
        if "enabled" in lower or "disabled" in lower or "accepts" in lower:
            return 0
        if "INT" in upper_typ or "REAL" in upper_typ or "NUM" in upper_typ:
            return 0
        return ""

    def value_for(col: str, row: dict):
        lower = col.lower()
        if col in row:
            val = row[col]
        elif col in ("id", "name", "worker_name", "hostname", "host"):
            val = row["worker_id"]
        elif lower in ("status", "state", "worker_state"):
            val = row["state"]
        elif lower in ("health", "worker_health", "computed_health", "health_state"):
            val = row["computed_health"]
        elif col in ("max_running_jobs", "max_jobs", "capacity", "concurrency", "worker_capacity"):
            val = row["max_concurrent_jobs"]
        elif col in ("last_heartbeat", "updated_at", "created_at", "registered_at"):
            val = now
        else:
            info = info_by_col[col]
            if info["notnull"] and info["dflt_value"] is None:
                val = default_for_unknown(col, info["type"], row["worker_id"])
            else:
                return None, False

        if isinstance(val, list):
            val = json.dumps(val)
        return val, True

    for row in synthetic:
        insert_cols, vals = [], []
        for col in cols:
            info = info_by_col[col]
            col_type = (info["type"] or "").upper()
            if info["pk"] and "INT" in col_type:
                continue
            val, include = value_for(col, row)
            if include:
                insert_cols.append(col)
                vals.append(val)
        conn.execute(
            f"INSERT INTO workers ({','.join(insert_cols)}) VALUES ({','.join(['?'] * len(insert_cols))})",
            vals,
        )

    conn.commit()
    temp_count = conn.execute("SELECT COUNT(*) FROM workers;").fetchone()[0]
    if temp_count != len(synthetic):
        raise SystemExit(f"FAIL: expected {len(synthetic)} temp workers, got {temp_count}")
    print(f"PASS: TEMP_DB_WORKER_ROWS_INSERTED={temp_count}")
    print("PASS: TEMP_DB_ONLY_INSERTS")

    rows = [dict(row) for row in conn.execute("SELECT * FROM workers;").fetchall()]
    conn.close()

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

    print("PASS: REPAIR_STRATEGY=ast_recursive_helper_dependency_extraction")
    print("PASS: REPAIR2_STRATEGY=defensive_persisted_health_state_fixture_mapping")
    print("PASS: HELPER_DEPENDENCIES_EXTRACTED=" + ",".join(required))

    def worker_id(row: dict) -> str:
        return str(row.get("worker_id") or row.get("id") or row.get("name") or "")

    def ids(items) -> list[str]:
        return [worker_id(item) for item in items]

    lane_job = {
        "job_id": "synthetic-study-lane-job",
        "job_lane": "study",
        "requires_lane_worker": True,
        "required_capabilities": ["ollama_chat"],
        "allow_primary_fallback": False,
    }
    no_lane_job = {"job_id": "synthetic-default-job", "required_capabilities": ["ollama_chat"]}
    no_eligible_lane_job = {
        "job_id": "synthetic-no-eligible-lane-job",
        "job_lane": "science",
        "requires_lane_worker": True,
        "required_capabilities": ["ollama_chat"],
        "allow_primary_fallback": False,
    }

    old_env = os.environ.get("EDGE_PERSISTENT_LANE_WORKERS_ENABLED")
    try:
        os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
        all_ids = ids(rows)
        default_off_ids = ids(filter_workers(rows, lane_job))
        if default_off_ids != all_ids:
            raise SystemExit(f"FAIL: default-off passthrough expected {all_ids}, got {default_off_ids}")
        print("PASS: DEFAULT_OFF_FILTER_PASSTHROUGH_WITH_TEMP_DB")

        os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = "1"
        eligible_ids = ids(filter_workers(rows, lane_job))
        if eligible_ids != ["study-good"]:
            raise SystemExit(f"FAIL: lane-required expected ['study-good'], got {eligible_ids}")
        print("PASS: TEMP_DB_LANE_REQUIRED_ACCEPTS_ONLY_ELIGIBLE_STUDY_WORKER")

        expected_rejected = {
            "primary",
            "study-not-accepting",
            "study-saturated",
            "wrong-lane",
            "missing-capability",
            "offline-worker",
            "unhealthy-worker",
            "disabled-worker",
        }
        rejected = set(all_ids) - set(eligible_ids)
        missing_rejections = expected_rejected - rejected
        if missing_rejections:
            raise SystemExit("FAIL: expected rejected workers were accepted: " + ",".join(sorted(missing_rejections)))

        print("PASS: TEMP_DB_ACCEPTS_LANE_JOBS_FALSE_REJECTED")
        print("PASS: TEMP_DB_PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB")
        print("PASS: TEMP_DB_WRONG_LANE_REJECTED")
        print("PASS: TEMP_DB_MISSING_CAPABILITY_REJECTED")
        print("PASS: TEMP_DB_OFFLINE_OR_UNHEALTHY_WORKER_REJECTED")
        print("PASS: TEMP_DB_DISABLED_WORKER_REJECTED")
        print("PASS: TEMP_DB_CAPACITY_SATURATED_WORKER_REJECTED")

        no_lane_ids = ids(filter_workers(rows, no_lane_job))
        if no_lane_ids != all_ids:
            raise SystemExit(f"FAIL: no-lane passthrough expected {all_ids}, got {no_lane_ids}")
        print("PASS: TEMP_DB_NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH")

        no_eligible_ids = ids(filter_workers(rows, no_eligible_lane_job))
        if no_eligible_ids != []:
            raise SystemExit(f"FAIL: no eligible lane expected [], got {no_eligible_ids}")
        print("PASS: TEMP_DB_LANE_REQUIRED_WITH_NO_ELIGIBLE_WORKER_FAILS_SAFE")
    finally:
        if old_env is None:
            os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
        else:
            os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = old_env

    if os.environ.get("EDGE_PERSISTENT_LANE_WORKERS_ENABLED") != old_env:
        raise SystemExit("FAIL: environment was not restored")
    print("PASS: ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST")

finally:
    try:
        temp_db.unlink()
    except FileNotFoundError:
        pass

prod_after = prod_facts()
if prod_after != prod_before:
    raise SystemExit(f"FAIL: production DB facts changed: before={prod_before} after={prod_after}")

print("PASS: PRODUCTION_DB_UNCHANGED_AFTER_TEMP_DB_SMOKE")
print("PASS: Phase 14J-CS temp-DB worker availability smoke complete")
PY2

echo
echo "=== post-temp production DB unchanged guard ==="
quick_check_after="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;")"
worker_facts_after="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT
  COUNT(*),
  COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'') NOT IN ('','primary') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0)
FROM workers;
")"
service_flag_after="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null | tr ' ' '\n' | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"

echo "sqlite_quick_check_after=${quick_check_after}"
echo "worker_facts_after=${worker_facts_after}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED_after=${service_flag_after:-<unset>}"

test "$quick_check_after" = "ok"
test "$worker_facts_after" = "$worker_facts_before"
test -z "$service_flag_after"

echo "PASS: production runtime remains default-off after temp DB smoke"
echo "PASS: Phase 14J-CS Gate B1 temp-DB worker availability metadata smoke passed"
