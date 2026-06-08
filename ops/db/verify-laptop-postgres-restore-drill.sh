#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"
BACKUP_DIR="${AI_PLATFORM_CONTROLLER_BACKUP_DIR:-$HOME/Desktop/ai-platform-controller-backups/postgres}"

if [ -n "${1:-}" ]; then
  BACKUP_FILE="$1"
elif [ -f "$BACKUP_DIR/latest.dump" ]; then
  BACKUP_FILE="$BACKUP_DIR/latest.dump"
else
  BACKUP_FILE="$(ls -1t "$BACKUP_DIR"/*.dump 2>/dev/null | head -n 1 || true)"
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "missing env file: $ENV_FILE" >&2
  exit 1
fi

source "$ENV_FILE"

if [ -z "${DATABASE_URL:-}" ]; then
  echo "DATABASE_URL is not set" >&2
  exit 1
fi

if [ -z "${BACKUP_FILE:-}" ] || [ ! -f "$BACKUP_FILE" ]; then
  echo "missing backup file. Run ops/db/backup-laptop-postgres.sh first." >&2
  exit 1
fi

TMP_DB="ai_platform_restore_drill_$(date +%Y%m%d_%H%M%S)_$$"

ADMIN_URL="$(python3 - "$DATABASE_URL" <<'PYURL'
from urllib.parse import urlsplit, urlunsplit
import sys
u = urlsplit(sys.argv[1])
print(urlunsplit((u.scheme, u.netloc, "/postgres", "", "")))
PYURL
)"

TMP_URL="$(python3 - "$DATABASE_URL" "$TMP_DB" <<'PYURL'
from urllib.parse import urlsplit, urlunsplit
import sys
u = urlsplit(sys.argv[1])
print(urlunsplit((u.scheme, u.netloc, "/" + sys.argv[2], "", "")))
PYURL
)"

cleanup() {
  sudo -u postgres psql -v ON_ERROR_STOP=0 -qAtc "DROP DATABASE IF EXISTS \"$TMP_DB\" WITH (FORCE);" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "=== restore drill backup ==="
echo "$BACKUP_FILE"

echo "=== validate dump ==="
pg_restore -l "$BACKUP_FILE" >/dev/null

echo "=== create temporary restore database ==="
DB_USER="$(python3 -c 'from urllib.parse import urlsplit, unquote; import sys; print(unquote(urlsplit(sys.argv[1]).username or ""))' "$DATABASE_URL")"
if [ -z "$DB_USER" ]; then
  echo "could not parse database user from DATABASE_URL" >&2
  exit 1
fi
sudo -u postgres psql -v ON_ERROR_STOP=1 -qAtc "CREATE DATABASE \"$TMP_DB\" OWNER \"$DB_USER\";" >/dev/null

echo "=== restore backup into temporary database ==="
pg_restore --dbname="$TMP_URL" --no-owner --no-acl "$BACKUP_FILE"

echo "=== list restored public tables ==="
psql "$TMP_URL" -v ON_ERROR_STOP=1 -Atc "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;"

echo "=== verify core restored tables ==="
for table in app_schema_migrations app_users app_sessions app_chats app_messages app_jobs; do
  exists="$(psql "$TMP_URL" -v ON_ERROR_STOP=1 -Atc "SELECT to_regclass('public.${table}') IS NOT NULL;")"
  if [ "$exists" != "t" ]; then
    echo "missing restored table: $table" >&2
    exit 1
  fi
  echo "ok: $table"
done

echo "restore drill passed"
