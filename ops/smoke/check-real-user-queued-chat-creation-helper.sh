#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== real-user queued chat creation helper smoke ==="

export PAGER=cat
export PSQL_PAGER=cat

source .venv/bin/activate 2>/dev/null || true

python3 -m py_compile \
  edge_modules/chat_queue_real_user_creation.py \
  edge_modules/chat_queue_real_user_guard.py \
  edge_modules/chat_queue_persistence.py

python3 - <<'PY'
import os
import time

from edge_modules.chat_queue_persistence import _psql_at, _psql_run, _sql_literal
from edge_modules.chat_queue_real_user_creation import (
    RealUserQueuedChatCreationError,
    create_real_user_queued_chat_job,
)

suffix = f"s5f18-{int(time.time())}-{os.getpid()}"
user_id = f"{suffix}-user"
other_user_id = f"{suffix}-other-user"
existing_chat_id = f"{suffix}-chat"
other_chat_id = f"{suffix}-other-chat"

def cleanup():
    _psql_run(
        f"""
        BEGIN;
        DELETE FROM app_messages WHERE chat_id IN ({_sql_literal(existing_chat_id)}, {_sql_literal(other_chat_id)})
           OR chat_id LIKE 's5f18-chat-%';
        DELETE FROM app_jobs WHERE id LIKE 's5f18-job-%';
        DELETE FROM app_chats WHERE id IN ({_sql_literal(existing_chat_id)}, {_sql_literal(other_chat_id)})
           OR id LIKE 's5f18-chat-%';
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
            {_sql_literal(existing_chat_id)},
            {_sql_literal(user_id)},
            'chat',
            'Stage 5F-18 Existing Chat',
            'synthetic',
            now(),
            now()
          ),
          (
            {_sql_literal(other_chat_id)},
            {_sql_literal(other_user_id)},
            'chat',
            'Stage 5F-18 Other Chat',
            'synthetic',
            now(),
            now()
          );

        COMMIT;
        """
    )

    os.environ.pop("LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED", None)
    os.environ.pop("LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED", None)

    disabled_raised = False
    try:
        create_real_user_queued_chat_job(
            authenticated_user_id=user_id,
            payload={"message": "disabled should fail"},
        )
    except RealUserQueuedChatCreationError:
        disabled_raised = True

    assert disabled_raised, "disabled helper did not refuse"
    print("OK: helper disabled by default")

    os.environ["LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED"] = "1"
    os.environ["LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED"] = "1"

    client_user_raised = False
    try:
        create_real_user_queued_chat_job(
            authenticated_user_id=user_id,
            payload={"message": "client user should fail", "user_id": other_user_id},
        )
    except RealUserQueuedChatCreationError:
        client_user_raised = True

    assert client_user_raised, "client-provided user_id was not refused"
    print("OK: client-provided user_id refused")

    wrong_chat_raised = False
    try:
        create_real_user_queued_chat_job(
            authenticated_user_id=user_id,
            payload={"message": "wrong chat should fail", "chat_id": other_chat_id},
        )
    except RealUserQueuedChatCreationError:
        wrong_chat_raised = True

    assert wrong_chat_raised, "wrong-user chat reuse was not refused"
    print("OK: wrong-user chat reuse refused")

    new_chat_job = create_real_user_queued_chat_job(
        authenticated_user_id=user_id,
        payload={
            "message": "Stage 5F-18 new real-user-shaped chat",
            "requested_model": "stage-5f18-model",
        },
    )

    assert new_chat_job.status == "queued", new_chat_job
    assert new_chat_job.chat_id.startswith("s5f18-chat-"), new_chat_job
    assert new_chat_job.payload_json["synthetic"] is False, new_chat_job
    assert new_chat_job.payload_json["route_source"] == "stage_5f18_real_user_creation_helper", new_chat_job
    print("OK: new chat real-user-shaped queued job created")

    existing_chat_job = create_real_user_queued_chat_job(
        authenticated_user_id=user_id,
        payload={
            "message": "Stage 5F-18 existing chat real-user-shaped message",
            "chat_id": existing_chat_id,
            "requested_model": "stage-5f18-model",
        },
    )

    assert existing_chat_job.status == "queued", existing_chat_job
    assert existing_chat_job.chat_id == existing_chat_id, existing_chat_job
    print("OK: existing owned chat real-user-shaped queued job created")

    user_msg_count = _psql_at(
        f"""
        SELECT COUNT(*)
        FROM app_messages
        WHERE id IN ({_sql_literal(new_chat_job.user_message_id)}, {_sql_literal(existing_chat_job.user_message_id)})
          AND role = 'user';
        """
    )

    assert user_msg_count == "2", user_msg_count
    print("OK: user messages persisted before queued jobs")

    job_count = _psql_at(
        f"""
        SELECT COUNT(*)
        FROM app_jobs
        WHERE id IN ({_sql_literal(new_chat_job.job_id)}, {_sql_literal(existing_chat_job.job_id)})
          AND user_id = {_sql_literal(user_id)}
          AND status = 'queued'
          AND job_type = 'ollama_chat';
        """
    )

    assert job_count == "2", job_count
    print("OK: queued app_jobs rows created for authenticated user")

finally:
    cleanup()

leftover = _psql_at(
    f"SELECT COUNT(*) FROM app_users WHERE id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});"
)
assert leftover == "0", leftover

print("PASS: real-user queued chat creation helper smoke passed and cleaned up")
PY
