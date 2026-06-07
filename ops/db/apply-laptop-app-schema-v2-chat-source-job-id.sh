#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

export PAGER=cat
export PSQL_PAGER=cat

ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "FAIL: missing DB env file: $ENV_FILE" >&2
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [ -z "${DATABASE_URL:-}" ]; then
  echo "FAIL: DATABASE_URL missing from $ENV_FILE" >&2
  exit 1
fi

echo "=== applying laptop app schema v2 chat source_job_id migration ==="
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f ops/db/laptop-app-schema-v2-chat-source-job-id.sql

echo "PASS: laptop app schema v2 chat source_job_id migration applied"
