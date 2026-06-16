#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cl-accepts-lane-jobs-and-no-lane-filter-contract-patch-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CL smoke: accepts_lane_jobs and no-lane contract patch plan ==="

test -f "$DOC"
echo "PASS: CL doc exists"

for marker in \
  "PHASE_14J_CL_ACCEPTS_LANE_JOBS_AND_NO_LANE_FILTER_CONTRACT_PATCH_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_contract_patch_plan" \
  "GATE_B0_RESULT=blocked_by_accepts_lane_jobs_gap_and_no_lane_contract_clarification" \
  "ACCEPTS_LANE_JOBS_FALSE_REJECTION_GAP=observed" \
  "NO_LANE_ENABLED_GATE_ELIGIBILITY_PRUNING=observed" \
  "NO_LANE_FULL_LIST_PASSTHROUGH_NOT_VERIFIED=observed" \
  "PATCH_DECISION_ENFORCE_ACCEPTS_LANE_JOBS=yes" \
  "PATCH_DECISION_NO_LANE_DEFAULT_PATH_PASSTHROUGH=yes" \
  "CK_SMOKE_AFTER_PATCH_SHOULD_BE_HISTORICAL_OR_FOCUSED_ONLY=yes" \
  "DEFAULT_OFF_FILTER_PASSTHROUGH=verified" \
  "NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified" \
  "ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified" \
  "SOURCE_MUTATION=not_performed" \
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
  "NEXT_SAFE_PHASE=source_patch_accepts_lane_jobs_and_no_lane_filter_contract"; do
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

echo "PASS: Phase 14J-CL contract patch plan smoke passed"
