#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cm-source-patch-accepts-lane-jobs-and-no-lane-filter-contract"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CM smoke: source patch accepts_lane_jobs and no-lane filter contract ==="

test -f "$DOC"
echo "PASS: CM doc exists"

for marker in \
  "PHASE_14J_CM_SOURCE_PATCH_ACCEPTS_LANE_JOBS_AND_NO_LANE_FILTER_CONTRACT" \
  "MUTATION_SCOPE=source_docs_smoke_only_lane_filter_contract_patch" \
  "PATCHED_EDGE_CONTROLLER=yes" \
  "PATCHED_ACCEPTS_LANE_JOBS_ENFORCEMENT=yes" \
  "PATCHED_NO_LANE_FILTER_PASSTHROUGH=yes" \
  "ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified" \
  "NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified" \
  "DEFAULT_OFF_FILTER_PASSTHROUGH=verified" \
  "SYNTHETIC_LANE_WORKER_ACCEPTED=verified" \
  "PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB=verified" \
  "WRONG_LANE_REJECTED=verified" \
  "MISSING_CAPABILITY_REJECTED=verified" \
  "OFFLINE_OR_UNHEALTHY_WORKER_REJECTED=verified" \
  "DISABLED_WORKER_REJECTED=verified" \
  "LANE_REQUIRED_WITH_NO_LANE_WORKER_FAILS_SAFE=verified" \
  "ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST=verified" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "CK_HISTORICAL_GAP_SMOKE_NOT_RERUN_AS_CURRENT_BEHAVIOR=yes" \
  "SECURITY_FOLLOWUP_REQUIRED=rotate_exposed_smtp_credential" \
  "GATE_B0_PATCH_RESULT=accepts_lane_jobs_and_no_lane_filter_contract_patched" \
  "NEXT_SAFE_PHASE=post_patch_gate_b0_result_checkpoint"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo
echo "=== runtime/default-off guard, read-only ==="
service_active="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"
service_flag="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null | tr ' ' '\n' | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
quick_check="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;")"
lane_enabled="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0) FROM workers;")"

echo "service_active=${service_active}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
echo "sqlite_quick_check=${quick_check}"
echo "lane_enabled_worker_count=${lane_enabled}"

test "$service_active" = "active"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$lane_enabled" = "0"
echo "PASS: production runtime remains default-off"

echo
echo "=== python compile ==="
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== source structure checks ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    'if job_meta["requires_lane_worker"] and not worker_meta["accepts_lane_jobs"]:',
    '"reason_code": "lane_jobs_not_accepted"',
    'job_meta = _phase14j_job_lane_metadata(job)',
    'if not job_meta["requires_lane_worker"] or job_meta["job_lane"] == "default":',
]

for marker in required:
    if marker not in text:
        raise SystemExit("FAIL: missing source marker: " + marker)
    print("PASS: source marker found: " + marker)

if text.count("def _phase14j_filter_workers_for_lane(") != 1:
    raise SystemExit("FAIL: unexpected filter helper count")
if text.count("def _phase14j_worker_eligible_for_job(") != 1:
    raise SystemExit("FAIL: unexpected eligible helper count")

print("PASS: helper counts stable")
PY

echo
echo "=== pure in-process patched helper behavior tests ==="
python3 - <<'PY'
from pathlib import Path
import ast
import json
import os
import re
from typing import Any, Dict, List, Optional, Tuple, Set

text = Path("edge_controller.py").read_text()
tree = ast.parse(text)

top_funcs = {node.name: node for node in tree.body if isinstance(node, ast.FunctionDef)}
seed = {
    "_phase14j_bool",
    "_phase14j_bounded_capability_labels",
    "_phase14j_lane_workers_enabled",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_filter_workers_for_lane",
}

include = set(seed)
missing = sorted(name for name in include if name not in top_funcs)
if missing:
    raise SystemExit("FAIL: missing seed helpers: " + ", ".join(missing))

changed = True
while changed:
    changed = False
    for name in list(include):
        for node in ast.walk(top_funcs[name]):
            if isinstance(node, ast.Name):
                dep = node.id
                if dep.startswith("_phase14j_") and dep in top_funcs and dep not in include:
                    include.add(dep)
                    changed = True

ordered = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in include]
module = ast.Module(body=ordered, type_ignores=[])
ast.fix_missing_locations(module)

ns = {
    "os": os,
    "json": json,
    "re": re,
    "Any": Any,
    "Dict": Dict,
    "List": List,
    "Optional": Optional,
    "Tuple": Tuple,
    "Set": Set,
}
exec(compile(module, "phase14j_cm_patched_helpers", "exec"), ns)

def worker(worker_id, *, lane="study", role="lane-worker", caps=None, state="available",
           computed_health="available", disabled=False, accepts=True):
    if caps is None:
        caps = ["ollama_chat"]
    return {
        "worker_id": worker_id,
        "worker_role": role,
        "worker_lane": lane,
        "accepts_lane_jobs": accepts,
        "capabilities": caps,
        "state": state,
        "computed_health": computed_health,
        "disabled": disabled,
    }

def ids(items):
    return [item.get("worker_id") for item in items]

lane_job = {
    "job_lane": "study",
    "required_capabilities": ["ollama_chat"],
    "requires_lane_worker": True,
    "allow_primary_fallback": False,
}

no_lane_job = {
    "job_lane": "",
    "required_capabilities": ["ollama_chat"],
    "requires_lane_worker": False,
    "allow_primary_fallback": True,
}

workers = [
    worker("primary", lane="", role="primary"),
    worker("study-good"),
    worker("wrong-lane", lane="companion"),
    worker("missing-cap", caps=["tts"]),
    worker("offline", state="offline", computed_health="offline"),
    worker("disabled", disabled=True),
    worker("not-accepting", accepts=False),
]

old_env = os.environ.get("EDGE_PERSISTENT_LANE_WORKERS_ENABLED")

try:
    os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    if ns["_phase14j_filter_workers_for_lane"](workers, lane_job) != workers:
        raise SystemExit("FAIL: default-off filter did not pass through")
    print("PASS: DEFAULT_OFF_FILTER_PASSTHROUGH")

    for value in ["1", "true", "TRUE", "yes", "on"]:
        os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = value
        if ns["_phase14j_lane_workers_enabled"]() is not True:
            raise SystemExit(f"FAIL: truthy value did not enable gate: {value!r}")
    print("PASS: ENABLED_GATE_ACCEPTS_TRUTHY_VALUES")

    os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = "1"

    lane_ids = ids(ns["_phase14j_filter_workers_for_lane"](workers, lane_job))
    if lane_ids != ["study-good"]:
        raise SystemExit(f"FAIL: patched lane filter expected ['study-good'], got {lane_ids!r}")

    print("PASS: SYNTHETIC_LANE_WORKER_ACCEPTED")
    print("PASS: ACCEPTS_LANE_JOBS_FALSE_REJECTED")

    for bad_id in ["primary", "wrong-lane", "missing-cap", "offline", "disabled", "not-accepting"]:
        if bad_id in lane_ids:
            raise SystemExit(f"FAIL: bad worker was not rejected: {bad_id} in {lane_ids!r}")

    print("PASS: PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB")
    print("PASS: WRONG_LANE_REJECTED")
    print("PASS: MISSING_CAPABILITY_REJECTED")
    print("PASS: OFFLINE_OR_UNHEALTHY_WORKER_REJECTED")
    print("PASS: DISABLED_WORKER_REJECTED")

    no_lane = ns["_phase14j_filter_workers_for_lane"](workers, no_lane_job)
    if no_lane != workers:
        raise SystemExit(f"FAIL: no-lane job did not preserve default path: {ids(no_lane)!r}")

    print("PASS: NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH")

    lane_missing = ns["_phase14j_filter_workers_for_lane"]([workers[0]], lane_job)
    if ids(lane_missing) != []:
        raise SystemExit(f"FAIL: lane-required missing worker should fail safe, got {ids(lane_missing)!r}")

    print("PASS: LANE_REQUIRED_WITH_NO_LANE_WORKER_FAILS_SAFE")

finally:
    if old_env is None:
        os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    else:
        os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = old_env

if os.environ.get("EDGE_PERSISTENT_LANE_WORKERS_ENABLED") != old_env:
    raise SystemExit("FAIL: environment restoration mismatch")

print("PASS: ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST")
print("PASS: patched helper behavior tests complete")
PY

echo "PASS: Phase 14J-CM source patch smoke passed"
