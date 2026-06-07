#!/usr/bin/env bash
set -euo pipefail

echo "=== laptop Postgres foundation smoke ==="

ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "FAIL: missing local DB env file: $ENV_FILE"
  exit 1
fi

if [ "$(stat -c '%a' "$ENV_FILE")" != "600" ]; then
  echo "FAIL: DB env file must be chmod 600: $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "${DATABASE_URL:-}" ]; then
  echo "FAIL: DATABASE_URL is not set in $ENV_FILE"
  exit 1
fi

if ! systemctl is-active --quiet postgresql; then
  echo "FAIL: postgresql service is not active"
  exit 1
fi

psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "SELECT current_database();" | grep -Fx "ai_platform_controller" >/dev/null
psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "SELECT current_user;" | grep -Fx "ai_platform_controller" >/dev/null
psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "SELECT 1;" | grep -Fx "1" >/dev/null

echo "PASS: laptop Postgres foundation is reachable"
