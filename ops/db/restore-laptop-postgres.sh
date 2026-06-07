#!/usr/bin/env bash
set -euo pipefail

export PAGER=cat
export PSQL_PAGER=cat

ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"
BACKUP_FILE="${1:-}"
CONFIRM="${2:-}"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 /path/to/backup.dump RESTORE_AI_PLATFORM_CONTROLLER_DB"
  exit 1
fi

if [ "$CONFIRM" != "RESTORE_AI_PLATFORM_CONTROLLER_DB" ]; then
  echo "FAIL: missing confirmation phrase."
  echo "Usage: $0 /path/to/backup.dump RESTORE_AI_PLATFORM_CONTROLLER_DB"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "FAIL: backup file not found: $BACKUP_FILE"
  exit 1
fi

if [ ! -s "$BACKUP_FILE" ]; then
  echo "FAIL: backup file is empty: $BACKUP_FILE"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "FAIL: missing DB env file: $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "${DATABASE_URL:-}" ]; then
  echo "FAIL: DATABASE_URL is not set in $ENV_FILE"
  exit 1
fi

echo "=== restore safety check ==="
echo "target_database=${PGDATABASE:-ai_platform_controller}"
echo "target_host=${PGHOST:-127.0.0.1}"
echo "backup_file=$BACKUP_FILE"

pg_restore -l "$BACKUP_FILE" >/dev/null

echo
echo "This will restore into the configured laptop/controller Postgres database."
echo "The restore uses --clean --if-exists and can replace existing objects."
read -r -p "Type RESTORE to continue: " answer

if [ "$answer" != "RESTORE" ]; then
  echo "Cancelled."
  exit 1
fi

pg_restore "$BACKUP_FILE" \
  --dbname="$DATABASE_URL" \
  --clean \
  --if-exists \
  --no-owner \
  --no-acl

echo "PASS: restore completed"
