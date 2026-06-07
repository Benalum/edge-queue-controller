#!/usr/bin/env bash
set -euo pipefail

export PAGER=cat
export PSQL_PAGER=cat

cd "$(dirname "$0")/../.."

ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"
SCHEMA_FILE="ops/db/laptop-app-schema-v1.sql"

if [ ! -f "$ENV_FILE" ]; then
  echo "FAIL: missing DB env file: $ENV_FILE"
  exit 1
fi

if [ ! -f "$SCHEMA_FILE" ]; then
  echo "FAIL: missing schema file: $SCHEMA_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "${DATABASE_URL:-}" ]; then
  echo "FAIL: DATABASE_URL is not set in $ENV_FILE"
  exit 1
fi

echo "=== pre-schema backup ==="
bash ops/db/backup-laptop-postgres.sh

echo
echo "=== applying laptop app schema ==="
psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -f "$SCHEMA_FILE"

echo
echo "=== schema tables ==="
psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "
SELECT tablename
FROM pg_tables
WHERE schemaname='public'
  AND tablename LIKE 'app_%'
ORDER BY tablename;
"

echo
echo "PASS: laptop app schema applied"
