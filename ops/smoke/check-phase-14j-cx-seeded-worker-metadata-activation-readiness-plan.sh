#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cx-seeded-worker-metadata-activation-readiness-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CX smoke: seeded worker metadata activation readiness plan ==="

test -f "$DOC"
echo "PASS: CX doc exists"

for marker in \
  "PHASE_14J_CX_SEEDED_WORKER_METADATA_ACTIVATION_READINESS_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_seeded_worker_metadata_activation_readiness_plan" \
  "GATE_B2_SEED_RESULT_CHECKPOINT=completed" \
  "GATE_B2_PRODUCTION_WORKER_METADATA_SEED_RESULT=passed_backup_first_default_off_seed" \
  "WORKER_FACTS_AFTER_CV=2,1,1,1" \
  "SEEDED_WORKER_ROWS=2" \
  "SEEDED_WORKER_IDS=primary-default-metadata,study-lane-metadata-default-off" \
  "SEEDED_ROWS_DISABLED_OR_OFFLINE=verified" \
  "DEFAULT_OFF_ENV_REMAINED_UNSET=verified" \
  "PRE_SEED_ZERO_WORKER_SMOKES_ARE_HISTORICAL_AFTER_CV=yes" \
  "HISTORICAL_PRE_CV_ZERO_WORKER_SMOKE_COMPATIBILITY_AFTER_CV=yes" \
  "GATE_B3_READINESS_DECISION=ready_for_default_off_seeded_metadata_readiness_smoke" \
  "NEXT_PHASE_NAME=phase-14j-cy-seeded-worker-metadata-default-off-readiness-smoke" \
  "ENVIRONMENT_OVERRIDE_SCOPE=in_process_test_only" \
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
  "DO_NOT_RERUN_14J_AG_APPLY_WRAPPER=preserved" \
  "NO_SECRETS_PRINTED=yes" \
  "GATE_B3_SEEDED_WORKER_METADATA_ACTIVATION_READINESS_PLAN_RESULT=ready_for_default_off_readiness_smoke" \
  "NEXT_SAFE_PHASE=seeded_worker_metadata_default_off_readiness_smoke"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo
echo "=== runtime/default-off seeded metadata guard, read-only ==="
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
study_summary="$(sqlite3 -csv "file:${PWD}/${DB}?mode=ro" "
SELECT worker_role, worker_lane, accepts_lane_jobs, disabled, state, computed_health
FROM workers
WHERE worker_id='study-lane-metadata-default-off';
")"

echo "service_active=${service_active}"
echo "service_enabled=${service_enabled}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
echo "sqlite_quick_check=${quick_check}"
echo "worker_facts=${worker_facts}"
echo "seeded_count=${seeded_count}"
echo "safe_seeded_count=${safe_seeded_count}"
echo "study_summary=${study_summary}"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$worker_facts" = "2,1,1,1"
test "$seeded_count" = "2"
test "$safe_seeded_count" = "2"
test "$study_summary" = "lane,study,1,1,offline,offline"

echo "PASS: seeded worker metadata remains default-off safe"
echo "PASS: Phase 14J-CX activation readiness plan smoke passed"
