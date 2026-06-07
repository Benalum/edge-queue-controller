#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

export PAGER=cat
export PSQL_PAGER=cat

echo "=== laptop app schema smoke ==="

ENV_FILE="${AI_PLATFORM_CONTROLLER_DB_ENV:-$HOME/.config/ai-platform-controller/postgres.env}"

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

require_table() {
  local table="$1"
  local found
  found="$(psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "SELECT to_regclass('public.${table}') IS NOT NULL;")"
  if [ "$found" != "t" ]; then
    echo "FAIL: missing table $table"
    exit 1
  fi
  echo "OK: table $table"
}

require_column() {
  local table="$1"
  local column="$2"
  local found
  found="$(psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema='public'
      AND table_name='${table}'
      AND column_name='${column}';
  ")"
  if [ "$found" != "1" ]; then
    echo "FAIL: missing column ${table}.${column}"
    exit 1
  fi
  echo "OK: column ${table}.${column}"
}

for table in \
  app_schema_migrations \
  app_users \
  app_sessions \
  app_chats \
  app_messages \
  app_jobs \
  app_workers \
  app_worker_nodes
do
  require_table "$table"
done

for spec in \
  "app_users:id,email,password_hash,is_active,is_admin,created_at,updated_at,last_login_at" \
  "app_sessions:id,user_id,token_hash,created_at,expires_at,revoked_at" \
  "app_chats:id,user_id,mode,title,model,created_at,updated_at,deleted_at" \
  "app_messages:id,chat_id,role,content,risk_level,created_at" \
  "app_jobs:id,user_id,job_type,status,requested_model,assigned_worker_id,payload_json,result_json,error_text,created_at,updated_at,started_at,finished_at" \
  "app_workers:id,name,status,capabilities_json,current_job_id,worker_node_id,last_heartbeat_at,idle_shutdown_seconds,created_at,updated_at" \
  "app_worker_nodes:id,name,node_type,host_machine,tailscale_ip,lan_ip,compose_path,start_command,stop_command,wake_method,wake_target,enabled,status,capabilities,notes,last_seen_at,created_at,updated_at"
do
  table="${spec%%:*}"
  cols="${spec#*:}"
  IFS=',' read -ra columns <<< "$cols"
  for column in "${columns[@]}"; do
    require_column "$table" "$column"
  done
done

migration_found="$(psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "
  SELECT 1
  FROM app_schema_migrations
  WHERE version='2026-06-07-stage-5d4-app-foundation-v1';
")"

if [ "$migration_found" != "1" ]; then
  echo "FAIL: schema migration marker missing"
  exit 1
fi

echo "OK: schema migration marker"

echo "PASS: laptop app schema smoke passed"
