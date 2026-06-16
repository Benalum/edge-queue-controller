#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-BG smoke: lane missing fallback contract checkpoint and activation-blocker review ==="

DOC="docs/phase-14j-bg-lane-missing-fallback-contract-checkpoint-and-activation-blocker-review.md"
DB="edge_queue.sqlite3"
fail=0

echo
echo "=== required artifacts ==="
for p in \
  "$DOC" \
  "docs/phase-14j-bf-lane-missing-fallback-contract-decision.md" \
  "ops/smoke/check-phase-14j-bf-lane-missing-fallback-contract-decision.sh" \
  "docs/phase-14j-be-synthetic-fallback-and-rollback-smoke-result-checkpoint.md" \
  "docs/phase-14j-bd-synthetic-fallback-and-rollback-smoke-artifact.md" \
  "docs/phase-14j-bc-synthetic-fallback-and-rollback-smoke-design.md" \
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
python3 - <<'APC_BG_DOC_CHECK'
from pathlib import Path

text = Path("docs/phase-14j-bg-lane-missing-fallback-contract-checkpoint-and-activation-blocker-review.md").read_text()

required = [
    "This phase is documentation and smoke only.",
    "No-lane jobs keep the primary/default worker path.",
    "Lane-tagged jobs that require a lane worker do not silently fall back to primary workers.",
    "Lane-tagged jobs with no eligible matching lane worker remain blocked/deferred.",
    "`allow_primary_fallback=true` does not change production behavior yet.",
    "Activation blocker review",
    "`persistent_lane_workers_not_active`",
    "`primary_worker_unfiltered`",
    "`scheduler_lane_dispatch_not_active`",
    "`ct101_runtime_protected`",
    "`router_rollout_parked`",
    "`warmup_execution_disabled`",
    "`rollback_smoke_pending`",
    "`activation_approval_required`",
    "Blocker review is not runtime activation.",
    "Contract checkpointing is not scheduler activation.",
    "Activation remains blocked.",
    "Phase 14J-BH: lane worker activation remains blocked closeout and source-update decision, docs/smoke only",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing doc markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
APC_BG_DOC_CHECK

echo
echo "=== compile check ==="
python3 - <<'APC_BG_COMPILE'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py compiles via in-memory compile")
APC_BG_COMPILE

echo
echo "=== source contract markers ==="
python3 - <<'APC_BG_SOURCE'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "def _phase14j_lane_workers_enabled(",
    "def _phase14j_job_lane_metadata(",
    "def _phase14j_worker_lane_metadata(",
    "def _phase14j_worker_eligible_for_job(",
    "def _phase14j_filter_workers_for_lane(",
    "if not _phase14j_lane_workers_enabled():",
    "return list(workers)",
    "allow_primary_fallback",
    "primary_fallback_not_allowed",
    "lane_mismatch",
    "capacity_reached",
    "phase14j_lane_scheduler_gate_enabled = _phase14j_lane_workers_enabled()",
    "if phase14j_lane_scheduler_gate_enabled:",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("FAIL: missing source contract markers: " + ", ".join(missing))

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

print("PASS: source contract markers remain present and worker payload lane metadata remains blocked")
APC_BG_SOURCE

echo
echo "=== source remains docs/smoke only for BG ==="
if git diff --name-only | grep -q '^edge_controller.py$'; then
  echo "FAIL: edge_controller.py changed during BG"
  fail=1
else
  echo "PASS: edge_controller.py unchanged in BG"
fi

echo
echo "=== run BF smoke as blocker-review evidence ==="
bash ops/smoke/check-phase-14j-bf-lane-missing-fallback-contract-decision.sh || fail=1

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
  curl -sS --max-time 5 -o /tmp/phase14j-bg-local-health.json \
    -w "%{http_code}" \
    http://127.0.0.1:7070/system/local-health 2>/tmp/phase14j-bg-local-health.err || true
)"
echo "local_health_http_code=${health_code:-curl_failed}"

if [ "$health_code" = "200" ]; then
  echo "PASS: controller-only local health returned 200"
else
  echo "FAIL: controller-only local health did not return 200"
  fail=1
fi

echo
echo "=== static guard: BG smoke must not execute forbidden runtime actions ==="
forbidden_runtime_lines="$(grep -nE '^[[:space:]]*(sudo[[:space:]]+systemctl[[:space:]]+(restart|reload)|systemctl[[:space:]]+(restart|reload)|pct[[:space:]]+exec|ssh[[:space:]]+root@|curl[[:space:]].*127\.0\.0\.1:(11434|8088))' "$0" || true)"
if [ -n "$forbidden_runtime_lines" ]; then
  echo "FAIL: BG smoke contains executable forbidden runtime lines"
  echo "$forbidden_runtime_lines"
  fail=1
else
  echo "PASS: BG smoke contains no executable forbidden runtime lines"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 14J-BG smoke complete"
else
  echo "FAIL: Phase 14J-BG smoke failed"
fi

exit "$fail"
