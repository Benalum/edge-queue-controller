#!/usr/bin/env bash
set -euo pipefail

export PAGER=cat
export PSQL_PAGER=cat

ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"
BACKUP_ROOT="${AI_PLATFORM_CONTROLLER_BACKUP_DIR:-$HOME/Desktop/ai-platform-controller-backups/postgres}"
RETENTION_DAYS="${AI_PLATFORM_CONTROLLER_BACKUP_RETENTION_DAYS:-14}"

if [ ! -f "$ENV_FILE" ]; then
  echo "FAIL: missing DB env file: $ENV_FILE" >&2
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "${DATABASE_URL:-}" ]; then
  echo "FAIL: DATABASE_URL is not set in $ENV_FILE" >&2
  exit 1
fi

mkdir -p "$BACKUP_ROOT"
chmod 700 "$BACKUP_ROOT"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$BACKUP_ROOT/ai-platform-controller-$TS.dump"
MANIFEST_FILE="$BACKUP_ROOT/ai-platform-controller-$TS.txt"
LATEST_LINK="$BACKUP_ROOT/latest.dump"

echo "=== laptop Postgres backup ==="
echo "backup_root=$BACKUP_ROOT"

pg_dump "$DATABASE_URL" \
  --format=custom \
  --no-owner \
  --no-acl \
  --file="$BACKUP_FILE"

chmod 600 "$BACKUP_FILE"

{
  echo "AI Platform Controller Postgres Backup"
  echo "created_at=$TS"
  echo "database=${PGDATABASE:-ai_platform_controller}"
  echo "host=${PGHOST:-127.0.0.1}"
  echo "port=${PGPORT:-5432}"
  echo "backup_file=$BACKUP_FILE"
  echo
  echo "pg_restore list check:"
  pg_restore -l "$BACKUP_FILE" | sed -n '1,80p'
} > "$MANIFEST_FILE"

chmod 600 "$MANIFEST_FILE"

ln -sfn "$BACKUP_FILE" "$LATEST_LINK"

# Retention cleanup for old generated backups/manifests only.
find "$BACKUP_ROOT" -maxdepth 1 -type f -name 'ai-platform-controller-*.dump' -mtime +"$RETENTION_DAYS" -delete
find "$BACKUP_ROOT" -maxdepth 1 -type f -name 'ai-platform-controller-*.txt' -mtime +"$RETENTION_DAYS" -delete

if [ ! -s "$BACKUP_FILE" ]; then
  echo "FAIL: backup file is empty: $BACKUP_FILE" >&2
  exit 1
fi

pg_restore -l "$BACKUP_FILE" >/dev/null

echo "PASS: laptop Postgres backup created"
echo "BACKUP_FILE=$BACKUP_FILE"
echo "MANIFEST_FILE=$MANIFEST_FILE"
