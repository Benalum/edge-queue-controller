#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== laptop app schema v2 chat source_job_id smoke ==="

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

require_sql() {
  local sql="$1"
  local label="$2"

  if psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -Atc "$sql" | grep -qx "1"; then
    echo "OK: $label"
  else
    echo "FAIL: $label"
    exit 1
  fi
}

require_file() {
  if [ ! -f "$1" ]; then
    echo "FAIL: missing file $1"
    exit 1
  fi
  echo "OK: file $1"
}

require_file ops/db/laptop-app-schema-v2-chat-source-job-id.sql
require_file ops/db/apply-laptop-app-schema-v2-chat-source-job-id.sh
require_file docs/laptop-app-schema-v2-chat-source-job-id.md

bash ops/db/apply-laptop-app-schema-v2-chat-source-job-id.sh

require_sql "SELECT 1 FROM information_schema.columns WHERE table_name='app_messages' AND column_name='source_job_id';" "app_messages.source_job_id column"
require_sql "SELECT 1 FROM pg_indexes WHERE tablename='app_messages' AND indexname='idx_app_messages_source_job_id_unique';" "source_job_id unique partial index"
require_sql "SELECT 1 FROM app_schema_migrations WHERE version='stage-5f4-chat-source-job-id';" "schema migration marker"

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
BEGIN;

DELETE FROM app_messages WHERE id LIKE 's5f4-msg-%';
DELETE FROM app_chats WHERE id = 's5f4-chat';
DELETE FROM app_users WHERE id = 's5f4-user';

INSERT INTO app_users (
  id,
  email,
  password_hash,
  is_active,
  is_admin,
  created_at,
  updated_at
)
VALUES (
  's5f4-user',
  's5f4-user@example.invalid',
  'synthetic-smoke-password-hash',
  TRUE,
  FALSE,
  now(),
  now()
);

INSERT INTO app_chats (
  id,
  user_id,
  mode,
  title,
  model,
  created_at,
  updated_at
)
VALUES (
  's5f4-chat',
  's5f4-user',
  'chat',
  'Stage 5F-4 Smoke',
  'synthetic',
  now(),
  now()
);

INSERT INTO app_messages (
  id,
  chat_id,
  role,
  content,
  risk_level,
  source_job_id,
  created_at
)
VALUES (
  's5f4-msg-1',
  's5f4-chat',
  'assistant',
  'first assistant message',
  0,
  's5f4-job-1',
  now()
);

DO $$
BEGIN
  BEGIN
    INSERT INTO app_messages (
      id,
      chat_id,
      role,
      content,
      risk_level,
      source_job_id,
      created_at
    )
    VALUES (
      's5f4-msg-duplicate',
      's5f4-chat',
      'assistant',
      'duplicate assistant message',
      0,
      's5f4-job-1',
      now()
    );

    RAISE EXCEPTION 'duplicate non-null source_job_id was allowed';
  EXCEPTION WHEN unique_violation THEN
    NULL;
  END;
END $$;

INSERT INTO app_messages (
  id,
  chat_id,
  role,
  content,
  risk_level,
  source_job_id,
  created_at
)
VALUES
  (
    's5f4-msg-null-1',
    's5f4-chat',
    'assistant',
    'null source job one',
    0,
    NULL,
    now()
  ),
  (
    's5f4-msg-null-2',
    's5f4-chat',
    'assistant',
    'null source job two',
    0,
    NULL,
    now()
  );

DELETE FROM app_messages WHERE id LIKE 's5f4-msg-%';
DELETE FROM app_chats WHERE id = 's5f4-chat';
DELETE FROM app_users WHERE id = 's5f4-user';

COMMIT;
SQL

echo "PASS: laptop app schema v2 chat source_job_id smoke passed and cleaned up"
