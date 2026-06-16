#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ck-gate-b0-synthetic-worker-availability-smoke-artifact"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CK smoke: Gate B0 observed gaps checkpoint ==="

test -f "$DOC"
echo "PASS: CK doc exists"

for marker in \
  "PHASE_14J_CK_GATE_B0_SYNTHETIC_WORKER_AVAILABILITY_SMOKE_ARTIFACT" \
  "MUTATION_SCOPE=docs_smoke_only_record_gate_b0_observed_gaps" \
  "HELPER_DEPENDENCY_CLOSURE_EXTRACTION=verified" \
  "DEFAULT_OFF_FILTER_PASSTHROUGH=verified" \
  "ENABLED_GATE_ACCEPTS_TRUTHY_VALUES=verified" \
  "SYNTHETIC_LANE_WORKER_ACCEPTED=verified" \
  "PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB=verified" \
  "WRONG_LANE_REJECTED=verified" \
  "MISSING_CAPABILITY_REJECTED=verified" \
  "OFFLINE_OR_UNHEALTHY_WORKER_REJECTED=verified" \
  "DISABLED_WORKER_REJECTED=verified" \
  "LANE_REQUIRED_WITH_NO_LANE_WORKER_FAILS_SAFE=verified" \
  "ENVIRONMENT_RESTORED_AFTER_IN_PROCESS_TEST=verified" \
  "ACCEPTS_LANE_JOBS_FALSE_REJECTION_GAP=observed" \
  "NO_LANE_ENABLED_GATE_ELIGIBILITY_PRUNING=observed" \
  "NO_LANE_FULL_LIST_PASSTHROUGH_NOT_VERIFIED=observed" \
  "GATE_B0_RESULT=blocked_by_accepts_lane_jobs_gap_and_no_lane_contract_clarification" \
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
  "SECURITY_FOLLOWUP_REQUIRED=rotate_exposed_smtp_credential" \
  "NEXT_SAFE_PHASE=patch_accepts_lane_jobs_filter_contract_and_clarify_no_lane_filter_contract"; do
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
echo "=== pure in-process helper extraction and observed gap verification ==="
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

if "_phase14j_bounded_label" not in include:
    raise SystemExit("FAIL: dependency closure missing _phase14j_bounded_label")

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
exec(compile(module, "phase14j_ck_observed_gaps_helpers", "exec"), ns)

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
    expected_lane_ids = ["study-good", "not-accepting"]
    if lane_ids != expected_lane_ids:
        raise SystemExit(f"FAIL: expected observed lane ids {expected_lane_ids!r}, got {lane_ids!r}")

    print("PASS: SYNTHETIC_LANE_WORKER_ACCEPTED")
    print("PASS: ACCEPTS_LANE_JOBS_FALSE_REJECTION_GAP_OBSERVED")

    for bad_id in ["primary", "wrong-lane", "missing-cap", "offline", "disabled"]:
        if bad_id in lane_ids:
            raise SystemExit(f"FAIL: unsafe/mismatched worker was not rejected: {bad_id} in {lane_ids!r}")

    print("PASS: PRIMARY_FALLBACK_BLOCKED_FOR_LANE_REQUIRED_JOB")
    print("PASS: WRONG_LANE_REJECTED")
    print("PASS: MISSING_CAPABILITY_REJECTED")
    print("PASS: OFFLINE_OR_UNHEALTHY_WORKER_REJECTED")
    print("PASS: DISABLED_WORKER_REJECTED")

    no_lane_ids = ids(ns["_phase14j_filter_workers_for_lane"](workers, no_lane_job))
    expected_no_lane_ids = ["primary", "study-good", "wrong-lane", "not-accepting"]
    if no_lane_ids != expected_no_lane_ids:
        raise SystemExit(f"FAIL: expected observed no-lane ids {expected_no_lane_ids!r}, got {no_lane_ids!r}")

    print("PASS: NO_LANE_ENABLED_GATE_ELIGIBILITY_PRUNING_OBSERVED")

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
print("PASS: Gate B0 observed gaps checkpoint helper tests complete")
PY

echo
echo "=== source mutation guard ==="
if git diff --name-only | grep -q '^edge_controller.py$'; then
  echo "FAIL: edge_controller.py was modified"
  exit 1
fi
echo "PASS: edge_controller.py unchanged"

echo "PASS: Phase 14J-CK observed gaps checkpoint smoke passed"
