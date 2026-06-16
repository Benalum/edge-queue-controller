#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cr-gate-b1-worker-availability-metadata-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== ${PHASE} historical compatibility smoke after Phase 14J-CV ==="
echo "HISTORICAL_PRE_CV_ZERO_WORKER_SMOKE_COMPATIBILITY_AFTER_CV=yes"

test -f "$DOC"
echo "PASS: historical doc exists"

grep -F "PHASE_14J_CR_GATE_B1_WORKER_AVAILABILITY_METADATA_PLAN" "$DOC" >/dev/null
echo "PASS: historical phase marker found: PHASE_14J_CR_GATE_B1_WORKER_AVAILABILITY_METADATA_PLAN"

if grep -F "NO_SECRETS_PRINTED=yes" "$DOC" >/dev/null; then
  echo "PASS: historical no-secrets marker retained"
fi

echo
echo "=== post-CV runtime/default-off seeded metadata guard ==="
service_active="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"
service_enabled="$(systemctl is-enabled "$SERVICE" 2>/dev/null || true)"
service_flag="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null | tr ' ' '\n' | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
quick_check="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;")"
worker_facts="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT
  COUNT(*),
  COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_lane,'') NOT IN ('','primary') THEN 1 ELSE 0 END),0),
  COALESCE(SUM(CASE WHEN COALESCE(worker_role,'primary') <> 'primary' THEN 1 ELSE 0 END),0)
FROM workers;
")"
seeded_count="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COUNT(*) FROM workers WHERE worker_id IN ('primary-default-metadata','study-lane-metadata-default-off');")"
safe_seeded_count="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "
SELECT COUNT(*)
FROM workers
WHERE worker_id IN ('primary-default-metadata','study-lane-metadata-default-off')
  AND (
    COALESCE(disabled,0) NOT IN (0,'0','false','False','')
    OR LOWER(COALESCE(state,'')) IN ('offline','disabled','unhealthy')
    OR LOWER(COALESCE(computed_health,'')) IN ('offline','disabled','unhealthy')
  );
")"

echo "service_active=${service_active}"
echo "service_enabled=${service_enabled}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
echo "sqlite_quick_check=${quick_check}"
echo "worker_facts=${worker_facts}"
echo "seeded_count=${seeded_count}"
echo "safe_seeded_count=${safe_seeded_count}"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$worker_facts" = "2,1,1,1"
test "$seeded_count" = "2"
test "$safe_seeded_count" = "2"

echo "PASS: historical smoke compatible with post-CV seeded metadata"
