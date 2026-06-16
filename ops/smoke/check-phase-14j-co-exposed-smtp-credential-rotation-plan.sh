#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-co-exposed-smtp-credential-rotation-plan"
DOC="docs/${PHASE}.md"
DB="edge_queue.sqlite3"
SERVICE="edge-queue-controller.service"

echo "=== Phase 14J-CO smoke: exposed SMTP credential rotation plan ==="

test -f "$DOC"
echo "PASS: CO doc exists"

for marker in \
  "PHASE_14J_CO_EXPOSED_SMTP_CREDENTIAL_ROTATION_PLAN" \
  "MUTATION_SCOPE=docs_smoke_only_security_rotation_plan" \
  "SECURITY_FOLLOWUP_REQUIRED=rotate_exposed_smtp_credential" \
  "DO_NOT_PRINT_SECRETS=yes" \
  "DO_NOT_PASTE_SECRET_IN_CHAT=yes" \
  "DO_NOT_PASTE_SECRET_IN_PPB_BLOCK=yes" \
  "DO_NOT_RUN_FULL_SYSTEMCTL_CAT=yes" \
  "DO_NOT_PRINT_FULL_SYSTEMD_ENVIRONMENT=yes" \
  "ROTATION_MUST_BE_INTERACTIVE_OR_LOCAL_ONLY=yes" \
  "ROTATION_SCRIPT_MUST_USE_SILENT_INPUT=yes" \
  "ROTATION_SCRIPT_MUST_NOT_ECHO_SECRET=yes" \
  "ROTATION_SCRIPT_MUST_NOT_TEE_SECRET_TO_STDOUT=yes" \
  "SECRET_ROTATION=not_performed" \
  "SOURCE_MUTATION=not_performed" \
  "DB_MUTATION=not_performed" \
  "JOB_MUTATION=not_performed" \
  "SERVICE_RESTART_RELOAD=not_performed" \
  "CT101_CALL=not_performed" \
  "MODEL_OLLAMA_CALL=not_performed" \
  "SCHEDULER_LANE_DISPATCH_ACTIVATION=not_performed" \
  "PRIMARY_WORKER_FILTERING_ACTIVATION=not_performed" \
  "PERSISTENT_LANE_WORKER_STARTUP=not_performed" \
  "RUNTIME_ACTIVATION=not_performed" \
  "NO_SECRETS_PRINTED=yes" \
  "NEXT_SAFE_PHASE=interactive_rotate_exposed_smtp_credential_or_gate_b1_worker_availability_metadata_plan"; do
  grep -F "$marker" "$DOC" >/dev/null
  echo "PASS: marker found: $marker"
done

echo
echo "=== runtime/default-off guard, read-only and secret-safe ==="
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
echo "PASS: Phase 14J-CO security rotation plan smoke passed"
