#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-cp-post-rotation-sanitized-smtp-checkpoint"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CP smoke: post-rotation sanitized SMTP checkpoint ==="

test -f "$DOC"
echo "PASS: CP doc exists"

for marker in \
  "PHASE_14J_CP_POST_ROTATION_SANITIZED_SMTP_CHECKPOINT" \
  "MUTATION_SCOPE=docs_smoke_only_post_rotation_sanitized_checkpoint" \
  "SECRET_ROTATION=performed_interactively" \
  "PPB_USED_FOR_SECRET_ENTRY=no" \
  "SECRET_PRINTED=no" \
  "SECRET_VALUE_RECORDED=no" \
  "ACTIVE_SERVICE_LOADED_SMTP_PASSWORD=verified_by_local_terminal" \
  "SMTP_PROVIDER_ACCEPTED_ACTIVE_CREDENTIAL=verified_by_local_terminal" \
  "SMTP_HOST_VERIFIED=smtp.resend.com" \
  "SMTP_USERNAME_VERIFIED=resend" \
  "POST_ROTATION_SERVICE_ACTIVE=verified" \
  "POST_ROTATION_DB_QUICK_CHECK=ok" \
  "POST_ROTATION_LANE_FLAG_DEFAULT_OFF=verified" \
  "OLD_SMTP_CREDENTIAL_REVOCATION_REQUIRED=manual_provider_dashboard" \
  "SECRET_ROTATION_PERFORMED_BY_THIS_PHASE=not_performed" \
  "SOURCE_MUTATION=not_performed" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed_by_this_phase" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=not_performed" \
  "NO_SECRETS_PRINTED=yes" \
  "SMTP_ROTATION_RESULT=rotated_loaded_and_provider_verified" \
  "NEXT_SAFE_PHASE=revoke_old_smtp_credential_or_gate_b1_worker_availability_metadata_plan"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo
echo "=== runtime/default-off guard, read-only and secret-safe ==="
service_active="$(systemctl is-active "$SERVICE" 2>/dev/null || true)"
service_enabled="$(systemctl is-enabled "$SERVICE" 2>/dev/null || true)"
service_flag="$(systemctl show "$SERVICE" -p Environment --value 2>/dev/null | tr ' ' '\n' | grep '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=' || true)"
quick_check="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "PRAGMA quick_check;")"
lane_enabled="$(sqlite3 "file:${PWD}/${DB}?mode=ro" "SELECT COALESCE(SUM(CASE WHEN COALESCE(accepts_lane_jobs,0) NOT IN (0,'0','false','False','') THEN 1 ELSE 0 END),0) FROM workers;")"

echo "service_active=${service_active}"
echo "service_enabled=${service_enabled}"
echo "service_EDGE_PERSISTENT_LANE_WORKERS_ENABLED=${service_flag:-<unset>}"
echo "sqlite_quick_check=${quick_check}"
echo "lane_enabled_worker_count=${lane_enabled}"

test "$service_active" = "active"
test "$service_enabled" = "enabled"
test -z "$service_flag"
test "$quick_check" = "ok"
test "$lane_enabled" = "0"

echo "PASS: production runtime remains default-off"
echo "PASS: Phase 14J-CP post-rotation sanitized checkpoint smoke passed"
