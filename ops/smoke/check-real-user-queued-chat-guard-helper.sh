#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== real-user queued chat guard helper smoke ==="

export PAGER=cat
export PSQL_PAGER=cat

source .venv/bin/activate 2>/dev/null || true

python3 -m py_compile edge_modules/chat_queue_real_user_guard.py

python3 - <<'PY'
import os
import time

from edge_modules.chat_queue_persistence import _psql_at, _psql_run, _sql_literal, _jsonb_literal
from edge_modules.chat_queue_real_user_guard import (
    RealUserQueuedChatGuardError,
    validate_real_user_queued_chat_request,
    validate_real_user_queued_chat_status_request,
)

suffix = f"s5f13-{int(time.time())}-{os.getpid()}"
user_id = f"{suffix}-user"
other_user_id = f"{suffix}-other-user"
chat_id = f"{suffix}-chat"
other_chat_id = f"{suffix}-other-chat"
job_id = f"{suffix}-job"
other_job_id = f"{suffix}-other-job"

def cleanup():
    _psql_run(
        f"""
        BEGIN;
        DELETE FROM app_jobs WHERE id IN ({_sql_literal(job_id)}, {_sql_literal(other_job_id)});
        DELETE FROM app_messages WHERE chat_id IN ({_sql_literal(chat_id)}, {_sql_literal(other_chat_id)});
        DELETE FROM app_chats WHERE id IN ({_sql_literal(chat_id)}, {_sql_literal(other_chat_id)});
        DELETE FROM app_users WHERE id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});
        COMMIT;
        """
    )

cleanup()

try:
    _psql_run(
        f"""
        BEGIN;

        INSERT INTO app_users (
          id,
          email,
          password_hash,
          is_active,
          is_admin,
          created_at,
          updated_at
        )
        VALUES
          (
            {_sql_literal(user_id)},
            {_sql_literal(user_id + '@example.invalid')},
            'synthetic-smoke-password-hash',
            TRUE,
            FALSE,
            now(),
            now()
          ),
          (
            {_sql_literal(other_user_id)},
            {_sql_literal(other_user_id + '@example.invalid')},
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
        VALUES
          (
            {_sql_literal(chat_id)},
            {_sql_literal(user_id)},
            'chat',
            'Stage 5F-13 Chat',
            'synthetic',
            now(),
            now()
          ),
          (
            {_sql_literal(other_chat_id)},
            {_sql_literal(other_user_id)},
            'chat',
            'Stage 5F-13 Other Chat',
            'synthetic',
            now(),
            now()
          );

        INSERT INTO app_jobs (
          id,
          user_id,
          job_type,
          status,
          requested_model,
          assigned_worker_id,
          payload_json,
          result_json,
          error_text,
          created_at,
          updated_at,
          started_at,
          finished_at
        )
        VALUES
          (
            {_sql_literal(job_id)},
            {_sql_literal(user_id)},
            'ollama_chat',
            'queued',
            'synthetic',
            NULL,
            {_jsonb_literal({'chat_id': chat_id, 'synthetic': True})},
            NULL,
            NULL,
            now(),
            now(),
            NULL,
            NULL
          ),
          (
            {_sql_literal(other_job_id)},
            {_sql_literal(other_user_id)},
            'ollama_chat',
            'queued',
            'synthetic',
            NULL,
            {_jsonb_literal({'chat_id': other_chat_id, 'synthetic': True})},
            NULL,
            NULL,
            now(),
            now(),
            NULL,
            NULL
          );

        COMMIT;
        """
    )

    os.environ.pop("LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED", None)

    disabled_raised = False
    try:
        validate_real_user_queued_chat_request(
            authenticated_user_id=user_id,
            payload={"message": "hello"},
        )
    except RealUserQueuedChatGuardError:
        disabled_raised = True

    assert disabled_raised, "real-user guard did not refuse disabled mode"
    print("OK: disabled real-user mode refused")

    os.environ["LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED"] = "1"

    anonymous_raised = False
    try:
        validate_real_user_queued_chat_request(
            authenticated_user_id=None,
            payload={"message": "hello"},
        )
    except RealUserQueuedChatGuardError:
        anonymous_raised = True

    assert anonymous_raised, "anonymous request was not refused"
    print("OK: anonymous request refused")

    client_user_raised = False
    try:
        validate_real_user_queued_chat_request(
            authenticated_user_id=user_id,
            payload={"message": "hello", "user_id": other_user_id},
        )
    except RealUserQueuedChatGuardError:
        client_user_raised = True

    assert client_user_raised, "client-provided user_id was not refused"
    print("OK: client-provided user_id refused")

    wrong_chat_raised = False
    try:
        validate_real_user_queued_chat_request(
            authenticated_user_id=user_id,
            payload={"message": "hello", "chat_id": other_chat_id},
        )
    except RealUserQueuedChatGuardError:
        wrong_chat_raised = True

    assert wrong_chat_raised, "wrong-user chat was not refused"
    print("OK: wrong-user chat reuse refused")

    accepted = validate_real_user_queued_chat_request(
        authenticated_user_id=user_id,
        payload={"message": "hello", "chat_id": chat_id, "requested_model": "synthetic"},
    )

    assert accepted.authenticated_user_id == user_id, accepted
    assert accepted.chat_id == chat_id, accepted
    assert accepted.message == "hello", accepted
    print("OK: owned chat request accepted by helper")

    wrong_job_raised = False
    try:
        validate_real_user_queued_chat_status_request(
            authenticated_user_id=user_id,
            job_id=other_job_id,
        )
    except RealUserQueuedChatGuardError:
        wrong_job_raised = True

    assert wrong_job_raised, "wrong-user job status was not refused"
    print("OK: wrong-user job status refused")

    owned_job = validate_real_user_queued_chat_status_request(
        authenticated_user_id=user_id,
        job_id=job_id,
    )

    assert owned_job == job_id, owned_job
    print("OK: owned job status accepted by helper")

finally:
    cleanup()

leftover = _psql_at(
    f"SELECT COUNT(*) FROM app_users WHERE id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});"
)
assert leftover == "0", leftover

print("PASS: real-user queued chat guard helper smoke passed and cleaned up")
PY
