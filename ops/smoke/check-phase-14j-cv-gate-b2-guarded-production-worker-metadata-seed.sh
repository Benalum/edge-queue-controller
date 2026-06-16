#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cv-gate-b2-guarded-production-worker-metadata-seed"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CV smoke: guarded production worker metadata seed ==="

test -f "$DOC"
echo "PASS: CV doc exists"

for marker in \
  "PHASE_14J_CV_GATE_B2_GUARDED_PRODUCTION_WORKER_METADATA_SEED" \
  "MUTATION_SCOPE=guarded_backup_first_production_db_worker_metadata_seed" \
  "APPROVAL_CONFIRMED=yes" \
  "BACKUP_CREATED=yes" \
  "BACKUP_QUICK_CHECK=ok" \
  "ROLLBACK_AVAILABLE=yes" \
  "PRODUCTION_DB_MUTATION=performed_worker_metadata_seed" \
  "SEEDED_WORKER_ROWS=2" \
  "SEEDED_WORKER_IDS=primary-default-metadata,study-lane-metadata-default-off" \
  "PRIMARY_METADATA_ROW=primary_default_worker_metadata_seeded" \
  "STUDY_LANE_METADATA_ROW=study_lane_worker_metadata_default_off_seeded" \
  "STUDY_LANE_ACCEPTS_LANE_JOBS=1" \
  "SEEDED_ROWS_DISABLED_OR_OFFLINE=verified" \
  "JOB_SUMMARY_UNCHANGED=verified" \
  "DEFAULT_OFF_ENV_REMAINED_UNSET=verified" \
  "SOURCE_MUTATION=not_performed" \
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
  "PRE_SEED_ZERO_WORKER_SMOKES_ARE_HISTORICAL_AFTER_CV=yes" \
  "GATE_B2_PRODUCTION_WORKER_METADATA_SEED_RESULT=passed_backup_first_default_off_seed" \
  "NEXT_SAFE_PHASE=gate_b2_production_worker_metadata_seed_result_checkpoint"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

backup_path="$(grep -F "BACKUP_PATH=" "$DOC" | head -n1 | sed 's/^- BACKUP_PATH=//')"
test -n "$backup_path"
test -f "$backup_path"
echo "PASS: backup file exists"

echo
echo "=== runtime/default-off and seeded metadata guard ==="
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
study_summary="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT worker_role, worker_lane, accepts_lane_jobs, disabled, state, computed_health
FROM workers
WHERE worker_id='study-lane-metadata-default-off';
")"
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
echo "study_summary=${study_summary}"
echo "safe_seeded_count=${safe_seeded_count}"

IFS=',' read -r worker_count lane_enabled non_default_lane non_primary_role <<< "$worker_facts"
IFS=',' read -r study_role study_lane study_accepts study_disabled study_state study_health <<< "$study_summary"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$worker_count" = "2"
test "$lane_enabled" = "1"
test "$non_default_lane" = "1"
test "$non_primary_role" = "1"
test "$seeded_count" = "2"
test "$study_role" = "lane"
test "$study_lane" = "study"
test "$study_accepts" = "1"
test "$safe_seeded_count" = "2"

echo "PASS: production runtime remains default-off with seeded metadata"
echo "PASS: Phase 14J-CV guarded production worker metadata seed smoke passed"
