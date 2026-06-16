#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BD smoke: synthetic fallback and rollback smoke artifact ==="

DOC="docs/phase-14j-bd-synthetic-fallback-and-rollback-smoke-artifact.md"
DB="edge_queue.sqlite3"
fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-bc-synthetic-fallback-and-rollback-smoke-design.md" \
  "ops/smoke/check-phase-14j-bc-synthetic-fallback-and-rollback-smoke-design.sh" \
  "docs/phase-14j-bb-no-lane-fallback-and-rollback-evidence-checkpoint.md" \
  "docs/phase-14j-az-no-lane-fallback-and-rollback-plan.md" \
  "docs/phase-14j-ao-default-off-worker-registration-update-preserve-existing-metadata-wiring-patch.md" \
  "ops/db/default-off-worker-registry-lane-metadata.sql" \
  "$DB"
do
  if [ -e "$p" ]; then
    echo "PASS: exists $p"
  else
    echo "FAIL: missing $p"
    fail=1
  fi
done

echo
echo "=== documentation markers ==="
python3 - <<'APC_BD_DOC_CHECK'
from pathlib import Path

text = Path("docs/phase-14j-bd-synthetic-fallback-and-rollback-smoke-artifact.md").read_text()

required = [
    "This phase is smoke-only plus documentation.",
    "disabled gate behavior preserves the original worker list",
    "no-lane normal jobs preserve primary/default eligibility",
    "lane-tagged jobs can select a matching lane worker only inside a temporary Python process",
    "`lane_missing_with_fallback_currently_blocked`",
    "`lane_missing_no_fallback_blocked`",
    "The current helper contract does not yet implement a no-lane production fallback worker",
    "enable `EDGE_PERSISTENT_LANE_WORKERS_ENABLED` in systemd or the shell",
    "The only enabled-gate checks are isolated inside a short-lived Python process.",
    "In-process helper testing is not service activation.",
    "`fallback_worker_contract_pending`",
    "`rollback_smoke_pending`",
    "`synthetic_enabled_lane_smoke_pending`",
    "`activation_approval_required`",
    "Phase 14J-BE: synthetic fallback and rollback smoke result checkpoint, docs/smoke only",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
APC_BD_DOC_CHECK

echo
echo "=== compile check ==="
python3 - <<'APC_BD_COMPILE'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
APC_BD_COMPILE

echo
echo "=== pure/in-process synthetic fallback and rollback helper tests ==="
python3 - <<'APC_BD_HELPER_TEST'
from pathlib import Path
import ast
import os

text = Path("edge_controller.py").read_text()

needed = {
    "_phase14j_bounded_label",
    "_phase14j_bounded_int",
    "_phase14j_bool",
    "_phase14j_bounded_capability_labels",
    "_phase14j_lane_workers_enabled",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_filter_workers_for_lane",
}

tree = ast.parse(text)
funcs = [node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name in needed]
found = {node.name for node in funcs}

if found != needed:
    raise SystemExit("FAIL: missing helper functions: " + ", ".join(sorted(needed - found)))

module = ast.Module(body=funcs, type_ignores=[])
ast.fix_missing_locations(module)
ns = {}
exec(compile(module, "phase14j_bd_lane_helpers", "exec"), ns)

workers = [
    {
        "worker_id": "primary",
        "worker_role": "primary",
        "worker_lane": "",
        "capabilities": ["ollama_chat"],
        "state": "available",
        "max_concurrent_jobs": 2,
        "current_running_jobs": 0,
        "accepts_lane_jobs": 0,
    },
    {
        "worker_id": "study-lane",
        "worker_role": "lane",
        "worker_lane": "study",
        "capabilities": ["ollama_chat"],
        "state": "available",
        "max_concurrent_jobs": 1,
        "current_running_jobs": 0,
        "accepts_lane_jobs": 1,
    },
]

lane_job = {
    "job_lane": "study",
    "required_capabilities": ["ollama_chat"],
    "requires_lane_worker": True,
    "allow_primary_fallback": False,
}

lane_job_allowing_fallback = {
    "job_lane": "study",
    "required_capabilities": ["ollama_chat"],
    "requires_lane_worker": True,
    "allow_primary_fallback": True,
}

no_lane_job = {
    "job_lane": "",
    "required_capabilities": ["ollama_chat"],
    "requires_lane_worker": False,
    "allow_primary_fallback": True,
}

old_env = os.environ.get("EDGE_PERSISTENT_LANE_WORKERS_ENABLED")

def worker_ids(items):
    return [item.get("worker_id") for item in items]

try:
    os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)

    disabled_equivalence = ns["_phase14j_filter_workers_for_lane"](workers, lane_job)
    if disabled_equivalence != workers:
        raise SystemExit(f"FAIL: disabled_equivalence expected original worker list, got {disabled_equivalence!r}")
    print("PASS: disabled_equivalence")

    os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = "1"

    primary_no_lane = ns["_phase14j_worker_eligible_for_job"](workers[0], no_lane_job)
    if primary_no_lane.get("eligible") is not True:
        raise SystemExit(f"FAIL: no_lane_primary expected primary eligible, got {primary_no_lane!r}")
    print("PASS: no_lane_primary")

    lane_match = ns["_phase14j_filter_workers_for_lane"](workers, lane_job)
    if worker_ids(lane_match) != ["study-lane"]:
        raise SystemExit(f"FAIL: lane_match expected study-lane only, got {worker_ids(lane_match)!r}")
    print("PASS: lane_match")

    lane_missing_with_fallback = ns["_phase14j_filter_workers_for_lane"]([workers[0]], lane_job_allowing_fallback)
    if worker_ids(lane_missing_with_fallback) != []:
        raise SystemExit(
            "FAIL: lane_missing_with_fallback_currently_blocked expected no eligible workers "
            f"under current helper contract, got {worker_ids(lane_missing_with_fallback)!r}"
        )
    print("PASS: lane_missing_with_fallback_currently_blocked")

    lane_missing_no_fallback = ns["_phase14j_filter_workers_for_lane"]([workers[0]], lane_job)
    if worker_ids(lane_missing_no_fallback) != []:
        raise SystemExit(
            "FAIL: lane_missing_no_fallback_blocked expected no eligible workers, "
            f"got {worker_ids(lane_missing_no_fallback)!r}"
        )
    print("PASS: lane_missing_no_fallback_blocked")

    os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    disabled_rollback = ns["_phase14j_filter_workers_for_lane"](workers, lane_job)
    if disabled_rollback != workers:
        raise SystemExit(f"FAIL: disabled_rollback expected original worker list, got {disabled_rollback!r}")
    print("PASS: disabled_rollback")

finally:
    if old_env is None:
        os.environ.pop("EDGE_PERSISTENT_LANE_WORKERS_ENABLED", None)
    else:
        os.environ["EDGE_PERSISTENT_LANE_WORKERS_ENABLED"] = old_env

print("PASS: pure/in-process synthetic fallback and rollback helper tests complete")
APC_BD_HELPER_TEST

echo
echo "=== source remains smoke-only for BD ==="
if git diff --name-only | grep -q '^edge_controller.py$'; then
  echo "FAIL: edge_controller.py changed during BD"
  fail=1
else
  echo "PASS: edge_controller.py unchanged in BD"
fi

echo
echo "=== default-off DB state ==="
sqlite3 "file:$PWD/$DB?mode=ro" "PRAGMA quick_check;" || fail=1

worker_count="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers;")"
target_columns="$(sqlite3 "file:$PWD/$DB?mode=ro" "
SELECT COUNT(*)
FROM pragma_table_info('workers')
WHERE name IN (
  'worker_role',
  'worker_lane',
  'accepts_lane_jobs',
  'capabilities',
  'disabled',
  'current_running_jobs',
  'state',
  'computed_health'
);
")"
lane_enabled="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers WHERE COALESCE(CAST(accepts_lane_jobs AS INTEGER), 0) != 0;")"
non_default_lane="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers WHERE COALESCE(worker_lane, '') != '';" )"
non_primary_role="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers WHERE COALESCE(worker_role, 'primary') != 'primary';" )"

echo "worker_count=$worker_count"
echo "target_columns_present=$target_columns"
echo "lane_enabled_worker_count=$lane_enabled"
echo "non_default_worker_lane_count=$non_default_lane"
echo "non_primary_worker_role_count=$non_primary_role"

if [ "$target_columns" = "8" ]; then echo "PASS: target metadata columns present"; else echo "FAIL: target metadata column count not 8"; fail=1; fi
if [ "$lane_enabled" = "0" ]; then echo "PASS: no lane-enabled workers"; else echo "FAIL: lane-enabled workers detected"; fail=1; fi
if [ "$non_default_lane" = "0" ]; then echo "PASS: no non-empty worker_lane"; else echo "FAIL: non-empty worker_lane detected"; fail=1; fi
if [ "$non_primary_role" = "0" ]; then echo "PASS: no non-primary worker_role"; else echo "FAIL: non-primary worker_role detected"; fail=1; fi

echo
echo "=== persistent lane worker flag remains disabled ==="
echo "shell_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-<unset>}"

case "${EDGE_PERSISTENT_LANE_WORKERS_ENABLED-}" in
  1|true|TRUE)
    echo "FAIL: shell persistent lane workers flag appears enabled"
    fail=1
    ;;
  *)
    echo "PASS: shell persistent lane workers flag absent/disabled"
    ;;
esac

service_env="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null || true)"
printf '%s\n' "$service_env" | tr ' ' '\n' | grep -q '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=\(1\|true\|TRUE\)$' \
  && { echo "FAIL: service persistent lane workers flag appears enabled"; fail=1; } \
  || echo "PASS: service persistent lane workers flag absent/disabled"

echo
echo "=== controller service read-only health check ==="
service_active="$(systemctl is-active edge-queue-controller 2>/dev/null || true)"
echo "service_active=${service_active:-unknown}"

if [ "$service_active" = "active" ]; then
  echo "PASS: edge-queue-controller active"
else
  echo "FAIL: edge-queue-controller not active"
  fail=1
fi

health_code="$(
  curl -sS --max-time 5 -o /tmp/phase14j-bd-local-health.json \
    -w "%{http_code}" \
    http://127.0.0.1:7070/system/local-health 2>/tmp/phase14j-bd-local-health.err || true
)"
echo "local_health_http_code=${health_code:-curl_failed}"

if [ "$health_code" = "200" ]; then
  echo "PASS: controller-only local health returned 200"
else
  echo "FAIL: controller-only local health did not return 200"
  fail=1
fi

echo
echo "=== static guard: BD smoke must not execute forbidden runtime actions ==="
forbidden_runtime_lines="$(grep -nE '^[[:space:]]*(sudo[[:space:]]+systemctl[[:space:]]+(restart|reload)|systemctl[[:space:]]+(restart|reload)|pct[[:space:]]+exec|ssh[[:space:]]+root@|curl[[:space:]].*127\.0\.0\.1:(11434|8088))' "$0" || true)"
if [ -n "$forbidden_runtime_lines" ]; then
  echo "FAIL: BD smoke contains executable forbidden runtime lines"
  echo "$forbidden_runtime_lines"
  fail=1
else
  echo "PASS: BD smoke contains no executable forbidden runtime lines"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 14J-BD smoke complete"
else
  echo "FAIL: Phase 14J-BD smoke failed"
fi

exit "$fail"
