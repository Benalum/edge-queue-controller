#!/usr/bin/env bash
set -euo pipefail

export PAGER=cat
export PSQL_PAGER=cat

cd "$(dirname "$0")/../.."

CONFIRM="${1:-${APC_CONFIRM_APPLY_ROUTER_SHADOW_EVIDENCE_SCHEMA:-}}"
REQUIRED_CONFIRM="APPLY_ROUTER_SHADOW_EVIDENCE_SCHEMA"

if [ "$CONFIRM" != "$REQUIRED_CONFIRM" ]; then
  echo "FAIL: confirmation required to apply router shadow evidence schema"
  echo "Run only after backup/rollback readiness is approved."
  echo "Required confirmation: $REQUIRED_CONFIRM"
  exit 1
fi

ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"
SCHEMA_FILE="ops/db/laptop-app-schema-v3-router-shadow-evidence.sql"
BACKUP_SCRIPT="ops/db/backup-laptop-postgres.sh"
RESTORE_SCRIPT="ops/db/restore-laptop-postgres.sh"
RESTORE_DRILL_SCRIPT="ops/db/verify-laptop-postgres-restore-drill.sh"

for f in "$SCHEMA_FILE" "$BACKUP_SCRIPT" "$RESTORE_SCRIPT" "$RESTORE_DRILL_SCRIPT"; do
  if [ ! -f "$f" ]; then
    echo "FAIL: missing required file: $f"
    exit 1
  fi
done

if [ ! -f "$ENV_FILE" ]; then
  echo "FAIL: missing DB env file"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "${DATABASE_URL:-}" ]; then
  echo "FAIL: DATABASE_URL is not set"
  exit 1
fi

echo "=== Phase 14I-AU future apply wrapper ==="
echo "SQL artifact: $SCHEMA_FILE"
echo "Target: controller-owned database from configured env"
echo "Secrets: not printed"

echo
echo "=== pre-apply backup ==="
bash "$BACKUP_SCRIPT"

echo
echo "=== applying router shadow evidence schema artifact ==="
psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -f "$SCHEMA_FILE"

echo
echo "=== verify table exists ==="
psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "
SELECT CASE WHEN EXISTS (
  SELECT 1
  FROM information_schema.tables
  WHERE table_schema = 'public'
    AND table_name = 'queued_chat_router_shadow_evidence'
) THEN 'table_exists' ELSE 'table_missing' END;
"

echo
echo "=== verify migration marker exists ==="
psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "
SELECT CASE WHEN EXISTS (
  SELECT 1
  FROM app_schema_migrations
  WHERE version = 'stage-14i-router-shadow-evidence'
) THEN 'marker_exists' ELSE 'marker_missing' END;
"

echo
echo "=== verify safe count-only row state ==="
psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "
SELECT count(*)::text
FROM queued_chat_router_shadow_evidence;
"

echo
echo "PASS: router shadow evidence schema artifact applied and verified"
