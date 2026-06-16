#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cn-post-patch-gate-b0-result-checkpoint"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CN smoke: post-patch Gate B0 result checkpoint ==="

test -f "$DOC"
echo "PASS: CN doc exists"

for marker in \
  "PHASE_14J_CN_POST_PATCH_GATE_B0_RESULT_CHECKPOINT" \
  "MUTATION_SCOPE=docs_smoke_only_post_patch_checkpoint_and_historical_smoke_compatibility" \
  "GATE_B0_PATCH_RESULT=accepts_lane_jobs_and_no_lane_filter_contract_patched" \
  "PATCHED_ACCEPTS_LANE_JOBS_ENFORCEMENT=yes" \
  "PATCHED_NO_LANE_FILTER_PASSTHROUGH=yes" \
  "DEFAULT_OFF_FILTER_PASSTHROUGH=verified" \
  "ACCEPTS_LANE_JOBS_FALSE_REJECTED=verified" \
  "NO_LANE_JOB_DEFAULT_PATH_PASSTHROUGH=verified" \
  "SYNTHETIC_LANE_WORKER_ACCEPTED=verified" \
  "LANE_REQUIRED_WITH_NO_LANE_WORKER_FAILS_SAFE=verified" \
  "CK_HISTORICAL_GAP_SMOKE_MARKER_ONLY_AFTER_CM=yes" \
  "EDGE_CONTROLLER_MUTATION=not_performed_by_cn" \
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
  "POST_PATCH_GATE_B0_RESULT=patched_and_checkpointed" \
  "NEXT_SAFE_PHASE=gate_b1_worker_availability_metadata_plan_or_rotate_exposed_smtp_credential"; do
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
echo "PASS: Phase 14J-CN post-patch checkpoint smoke passed"
