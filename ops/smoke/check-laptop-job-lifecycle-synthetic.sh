#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

export PAGER=cat
export PSQL_PAGER=cat

echo "=== synthetic laptop job lifecycle smoke ==="

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

SUFFIX="$(date +%s)-$$"
USER_ID="s5e2-user-${SUFFIX}"
NODE_ID="s5e2-node-${SUFFIX}"
WORKER_ID="s5e2-worker-${SUFFIX}"
JOB_OK_ID="s5e2-job-ok-${SUFFIX}"
JOB_FAIL_ID="s5e2-job-fail-${SUFFIX}"

psql_at() {
  psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 -Atc "$1"
}

psql_run() {
  psql "$DATABASE_URL" -P pager=off -v ON_ERROR_STOP=1 "$@"
}

cleanup() {
  psql_run >/dev/null <<SQL
DELETE FROM app_jobs
WHERE id IN ('$JOB_OK_ID', '$JOB_FAIL_ID')
   OR user_id = '$USER_ID';

DELETE FROM app_workers
WHERE id = '$WORKER_ID';

DELETE FROM app_worker_nodes
WHERE id = '$NODE_ID';

DELETE FROM app_users
WHERE id = '$USER_ID';
SQL
}

trap cleanup EXIT

# Ensure stale synthetic rows from a previous interrupted run with same IDs cannot exist.
cleanup || true

echo "OK: inserting synthetic user, node, worker, and jobs"

psql_run <<SQL
INSERT INTO app_users (
    id,
    email,
    display_name,
    password_hash,
    is_active,
    is_admin
)
VALUES (
    '$USER_ID',
    '$USER_ID@example.local',
    'Stage 5E-2 Synthetic User',
    'stage-5e2-not-a-real-password',
    TRUE,
    FALSE
);

INSERT INTO app_worker_nodes (
    id,
    name,
    node_type,
    host_machine,
    tailscale_ip,
    enabled,
    status,
    capabilities,
    notes
)
VALUES (
    '$NODE_ID',
    'Stage 5E-2 Synthetic Node',
    'synthetic',
    'laptop-controller',
    '127.0.0.1',
    TRUE,
    'online',
    '{"job_types":["ollama_chat"]}'::jsonb,
    'Synthetic smoke row; safe to delete.'
);

INSERT INTO app_workers (
    id,
    name,
    status,
    capabilities_json,
    current_job_id,
    worker_node_id,
    last_heartbeat_at,
    idle_shutdown_seconds
)
VALUES (
    '$WORKER_ID',
    'Stage 5E-2 Synthetic Worker',
    'idle',
    '{"job_types":["ollama_chat"]}'::jsonb,
    NULL,
    '$NODE_ID',
    now(),
    300
);

INSERT INTO app_jobs (
    id,
    user_id,
    job_type,
    status,
    requested_model,
    assigned_worker_id,
    payload_json
)
VALUES (
    '$JOB_OK_ID',
    '$USER_ID',
    'ollama_chat',
    'queued',
    'stage-5e2-synthetic-model',
    NULL,
    '{"prompt":"synthetic success job"}'::jsonb
);

INSERT INTO app_jobs (
    id,
    user_id,
    job_type,
    status,
    requested_model,
    assigned_worker_id,
    payload_json
)
VALUES (
    '$JOB_FAIL_ID',
    '$USER_ID',
    'ollama_chat',
    'queued',
    'stage-5e2-synthetic-model',
    NULL,
    '{"prompt":"synthetic failed job"}'::jsonb
);
SQL

created_count="$(psql_at "SELECT COUNT(*) FROM app_jobs WHERE id IN ('$JOB_OK_ID', '$JOB_FAIL_ID');")"
if [ "$created_count" != "2" ]; then
  echo "FAIL: expected 2 synthetic jobs, got $created_count"
  exit 1
fi
echo "OK: synthetic queued jobs created"

claimed_status="$(psql_at "
UPDATE app_jobs
SET status='running',
    assigned_worker_id='$WORKER_ID',
    started_at=now(),
    updated_at=now()
WHERE id='$JOB_OK_ID'
  AND status='queued'
RETURNING status;
")"

if [ "$claimed_status" != "running" ]; then
  echo "FAIL: success job did not transition queued -> running"
  exit 1
fi

psql_run >/dev/null <<SQL
UPDATE app_workers
SET status='busy',
    current_job_id='$JOB_OK_ID',
    updated_at=now()
WHERE id='$WORKER_ID';
SQL

worker_state="$(psql_at "SELECT status || '|' || COALESCE(current_job_id, '') FROM app_workers WHERE id='$WORKER_ID';")"
if [ "$worker_state" != "busy|$JOB_OK_ID" ]; then
  echo "FAIL: worker did not enter busy state for success job: $worker_state"
  exit 1
fi
echo "OK: success job claimed and worker busy"

complete_status="$(psql_at "
UPDATE app_jobs
SET status='complete',
    result_json='{\"reply\":\"synthetic complete reply\",\"model\":\"stage-5e2-synthetic-model\"}'::jsonb,
    error_text=NULL,
    finished_at=now(),
    updated_at=now()
WHERE id='$JOB_OK_ID'
  AND status='running'
RETURNING status;
")"

if [ "$complete_status" != "complete" ]; then
  echo "FAIL: success job did not transition running -> complete"
  exit 1
fi

psql_run >/dev/null <<SQL
UPDATE app_workers
SET status='idle',
    current_job_id=NULL,
    updated_at=now()
WHERE id='$WORKER_ID';
SQL

reply="$(psql_at "SELECT result_json->>'reply' FROM app_jobs WHERE id='$JOB_OK_ID';")"
if [ "$reply" != "synthetic complete reply" ]; then
  echo "FAIL: success job result_json reply mismatch: $reply"
  exit 1
fi
echo "OK: success job completed with result_json"

claimed_fail_status="$(psql_at "
UPDATE app_jobs
SET status='running',
    assigned_worker_id='$WORKER_ID',
    started_at=now(),
    updated_at=now()
WHERE id='$JOB_FAIL_ID'
  AND status='queued'
RETURNING status;
")"

if [ "$claimed_fail_status" != "running" ]; then
  echo "FAIL: failure job did not transition queued -> running"
  exit 1
fi

psql_run >/dev/null <<SQL
UPDATE app_workers
SET status='busy',
    current_job_id='$JOB_FAIL_ID',
    updated_at=now()
WHERE id='$WORKER_ID';
SQL

failed_status="$(psql_at "
UPDATE app_jobs
SET status='failed',
    result_json=NULL,
    error_text='synthetic failure from Stage 5E-2 smoke',
    finished_at=now(),
    updated_at=now()
WHERE id='$JOB_FAIL_ID'
  AND status='running'
RETURNING status;
")"

if [ "$failed_status" != "failed" ]; then
  echo "FAIL: failure job did not transition running -> failed"
  exit 1
fi

psql_run >/dev/null <<SQL
UPDATE app_workers
SET status='idle',
    current_job_id=NULL,
    updated_at=now()
WHERE id='$WORKER_ID';
SQL

error_text="$(psql_at "SELECT error_text FROM app_jobs WHERE id='$JOB_FAIL_ID';")"
if [ "$error_text" != "synthetic failure from Stage 5E-2 smoke" ]; then
  echo "FAIL: failure job error_text mismatch: $error_text"
  exit 1
fi

worker_final="$(psql_at "SELECT status || '|' || COALESCE(current_job_id, '') FROM app_workers WHERE id='$WORKER_ID';")"
if [ "$worker_final" != "idle|" ]; then
  echo "FAIL: worker did not return to idle: $worker_final"
  exit 1
fi
echo "OK: failure job failed with error_text and worker returned idle"

cleanup
trap - EXIT

leftover_count="$(psql_at "
SELECT
  (
    SELECT COUNT(*) FROM app_jobs WHERE id IN ('$JOB_OK_ID', '$JOB_FAIL_ID') OR user_id='$USER_ID'
  )
  +
  (
    SELECT COUNT(*) FROM app_workers WHERE id='$WORKER_ID'
  )
  +
  (
    SELECT COUNT(*) FROM app_worker_nodes WHERE id='$NODE_ID'
  )
  +
  (
    SELECT COUNT(*) FROM app_users WHERE id='$USER_ID'
  );
")"

if [ "$leftover_count" != "0" ]; then
  echo "FAIL: cleanup left $leftover_count synthetic row(s)"
  echo "Synthetic ids:"
  echo "  user=$USER_ID"
  echo "  node=$NODE_ID"
  echo "  worker=$WORKER_ID"
  echo "  success_job=$JOB_OK_ID"
  echo "  failed_job=$JOB_FAIL_ID"
  exit 1
fi

echo "PASS: synthetic laptop job lifecycle smoke passed and cleaned up"
