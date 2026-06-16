#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-AY smoke: lane worker activation evidence result checkpoint ==="

DOC="docs/phase-14j-ay-lane-worker-activation-evidence-result-checkpoint.md"
DB="edge_queue.sqlite3"
fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-aw-lane-worker-activation-preconditions-matrix.md" \
  "ops/smoke/check-phase-14j-aw-lane-worker-activation-preconditions-matrix.sh" \
  "docs/phase-14j-av-worker-registration-compatibility-closeout-and-next-lane-readiness-plan.md" \
  "docs/phase-14j-au-post-reload-compatibility-result-checkpoint.md" \
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
python3 - <<'APC_AY_DOC_CHECK'
from pathlib import Path

text = Path("docs/phase-14j-ay-lane-worker-activation-evidence-result-checkpoint.md").read_text()

required = [
    "This phase is documentation and smoke only.",
    "Phase 14J-AX status: complete, read-only, no repository changes",
    "controller-only local health returned `200`",
    "`EDGE_PERSISTENT_LANE_WORKERS_ENABLED` remains absent or disabled",
    "worker registry lane metadata remains default-off",
    "no lane-enabled workers were detected",
    "no non-empty `worker_lane` values were detected",
    "no non-primary `worker_role` values were detected",
    "worker payload lane metadata remains blocked",
    "Evidence collection is not runtime activation.",
    "`persistent_lane_workers_not_active`",
    "`primary_worker_unfiltered`",
    "`scheduler_lane_dispatch_not_active`",
    "`fallback_worker_contract_pending`",
    "`rollback_smoke_pending`",
    "`synthetic_enabled_lane_smoke_pending`",
    "`activation_approval_required`",
    "Phase 14J-AZ: no-lane fallback and rollback plan, docs/smoke only",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
APC_AY_DOC_CHECK

echo
echo "=== compile check ==="
python3 - <<'APC_AY_COMPILE'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
APC_AY_COMPILE

echo
echo "=== static source safety markers ==="
python3 - <<'APC_AY_SOURCE'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "def _phase14j_default_off_worker_registration_metadata(",
    "def _phase14j_lane_workers_enabled(",
    "def _phase14j_filter_workers_for_lane(",
    "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()",
    "if phase14j_lane_scheduler_gate_enabled:",
    "_phase14j_filter_workers_for_lane(workers, job)",
    "worker_role = COALESCE(worker_role, ?)",
    "worker_lane = COALESCE(worker_lane, ?)",
    "accepts_lane_jobs = COALESCE(accepts_lane_jobs, ?)",
    "def _stage5p12o_persistent_lane_cutover_readiness(",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing static source markers: " + ", ".join(missing))

for forbidden in [
    "payload.worker_role",
    "payload.worker_lane",
    "payload.accepts_lane_jobs",
    "payload.disabled",
    "payload.current_running_jobs",
    "payload.computed_health",
]:
    if forbidden in text:
        raise SystemExit(f"FAIL: worker payload lane metadata unexpectedly consumed: {forbidden}")

print("PASS: source activation gates remain present and worker payload lane metadata remains blocked")
APC_AY_SOURCE

echo
echo "=== source remains docs/smoke only for AY ==="
if git diff --name-only | grep -q '^edge_controller.py$'; then
  echo "FAIL: edge_controller.py changed during AY"
  fail=1
else
  echo "PASS: edge_controller.py unchanged in AY"
fi

echo
echo "=== default-off DB state ==="
sqlite3 "file:$PWD/$DB?mode=ro" "PRAGMA quick_check;" || fail=1

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

worker_count="$(sqlite3 "file:$PWD/$DB?mode=ro" "SELECT COUNT(*) FROM workers;")"
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
  curl -sS --max-time 5 -o /tmp/phase14j-ay-local-health.json \
    -w "%{http_code}" \
    http://127.0.0.1:7070/system/local-health 2>/tmp/phase14j-ay-local-health.err || true
)"
echo "local_health_http_code=${health_code:-curl_failed}"

if [ "$health_code" = "200" ]; then
  echo "PASS: controller-only local health returned 200"
else
  echo "FAIL: controller-only local health did not return 200"
  fail=1
fi

echo
echo "=== recent service error scan ==="
recent_errors="$(
  journalctl -u edge-queue-controller --since "30 minutes ago" --no-pager \
    | grep -Ei 'Traceback|Exception in ASGI|sqlite3\.|OperationalError|ProgrammingError|IntegrityError|HTTP/1\.1" 500|Internal Server Error' \
    | tail -40 || true
)"
if [ -n "$recent_errors" ]; then
  echo "FAIL: recent service log errors detected"
  echo "$recent_errors"
  fail=1
else
  echo "PASS: no recent traceback/sqlite/500 errors detected"
fi

echo
echo "=== static guard: AY smoke must not execute forbidden runtime actions ==="
forbidden_runtime_lines="$(grep -nE '^[[:space:]]*(sudo[[:space:]]+systemctl[[:space:]]+(restart|reload)|systemctl[[:space:]]+(restart|reload)|pct[[:space:]]+exec|ssh[[:space:]]+root@|curl[[:space:]].*127\.0\.0\.1:(11434|8088))' "$0" || true)"
if [ -n "$forbidden_runtime_lines" ]; then
  echo "FAIL: AY smoke contains executable forbidden runtime lines"
  echo "$forbidden_runtime_lines"
  fail=1
else
  echo "PASS: AY smoke contains no executable forbidden runtime lines"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 14J-AY smoke complete"
else
  echo "FAIL: Phase 14J-AY smoke failed"
fi

exit "$fail"
