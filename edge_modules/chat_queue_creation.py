"""
Synthetic queued-chat job creation helper.

Stage 5F-8.

This helper is intentionally not wired into production chat routes yet.
It proves the database-side creation of chat-shaped queued jobs.

Safety:
- synthetic/test-only for now
- refuses non-synthetic user ids
- no production route imports this helper yet
"""

from __future__ import annotations

import json
import secrets
from dataclasses import dataclass
from typing import Any

from edge_modules.chat_queue_persistence import (
    _jsonb_literal,
    _psql_at,
    _psql_run,
    _sql_literal,
)


class ChatQueueCreationError(RuntimeError):
    pass


@dataclass(frozen=True)
class QueuedChatJob:
    chat_id: str
    user_message_id: str
    job_id: str
    status: str
    payload_json: dict[str, Any]


def _require_synthetic_user(user_id: str) -> None:
    if not user_id.startswith("s5f8-user-"):
        raise ChatQueueCreationError(
            "Stage 5F-8 helper refuses non-synthetic user ids"
        )


def setup_synthetic_chat_queue_creation_rows(*, suffix: str) -> dict[str, str]:
    user_id = f"s5f8-user-{suffix}"
    existing_chat_id = f"s5f8-chat-existing-{suffix}"

    _psql_run(
        f"""
        BEGIN;

        DELETE FROM app_messages
        WHERE chat_id LIKE 's5f8-chat-%'
           OR source_job_id LIKE 's5f8-job-%';

        DELETE FROM app_jobs WHERE id LIKE 's5f8-job-%';
        DELETE FROM app_chats WHERE id LIKE 's5f8-chat-%';
        DELETE FROM app_users WHERE id = {_sql_literal(user_id)};

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
          {_sql_literal(user_id)},
          {_sql_literal(user_id + '@example.invalid')},
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
          {_sql_literal(existing_chat_id)},
          {_sql_literal(user_id)},
          'chat',
          'Stage 5F-8 Existing Chat',
          'synthetic',
          now(),
          now()
        );

        COMMIT;
        """
    )

    return {
        "user_id": user_id,
        "existing_chat_id": existing_chat_id,
    }


def cleanup_synthetic_chat_queue_creation_rows(*, suffix: str) -> None:
    user_id = f"s5f8-user-{suffix}"

    _psql_run(
        f"""
        BEGIN;

        DELETE FROM app_messages
        WHERE chat_id LIKE 's5f8-chat-%'
           OR source_job_id LIKE 's5f8-job-%';

        DELETE FROM app_jobs WHERE id LIKE 's5f8-job-%';
        DELETE FROM app_chats WHERE id LIKE 's5f8-chat-%';
        DELETE FROM app_users WHERE id = {_sql_literal(user_id)};

        COMMIT;
        """
    )


def create_synthetic_queued_chat_job(
    *,
    authenticated_user_id: str,
    message: str,
    chat_id: str | None = None,
    requested_model: str = "synthetic",
) -> QueuedChatJob:
    """
    Create a synthetic queued chat job.

    This creates:
    - app_chats row if chat_id is not provided
    - user app_messages row
    - queued app_jobs row

    It does not call CT101.
    It does not create assistant messages.
    """
    _require_synthetic_user(authenticated_user_id)

    clean_message = message.strip()
    if not clean_message:
        raise ChatQueueCreationError("message is required")

    if requested_model is None or not requested_model.strip():
        requested_model = "synthetic"

    if chat_id is not None and not chat_id.startswith("s5f8-chat-"):
        raise ChatQueueCreationError(
            "Stage 5F-8 helper refuses non-synthetic chat ids"
        )

    created_chat_id = chat_id or f"s5f8-chat-{secrets.token_hex(8)}"
    user_message_id = f"s5f8-msg-user-{secrets.token_hex(8)}"
    job_id = f"s5f8-job-{secrets.token_hex(8)}"

    existing_user = _psql_at(
        f"""
        SELECT COALESCE(
          (
            SELECT '1'
            FROM app_users
            WHERE id = {_sql_literal(authenticated_user_id)}
              AND is_active = TRUE
          ),
          ''
        );
        """
    )

    if existing_user != "1":
        raise ChatQueueCreationError("authenticated synthetic user does not exist")

    if chat_id is None:
        _psql_run(
            f"""
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
              {_sql_literal(created_chat_id)},
              {_sql_literal(authenticated_user_id)},
              'chat',
              'Stage 5F-8 Queued Chat',
              {_sql_literal(requested_model)},
              now(),
              now()
            );
            """
        )
    else:
        owned = _psql_at(
            f"""
            SELECT COALESCE(
              (
                SELECT '1'
                FROM app_chats
                WHERE id = {_sql_literal(created_chat_id)}
                  AND user_id = {_sql_literal(authenticated_user_id)}
              ),
              ''
            );
            """
        )

        if owned != "1":
            raise ChatQueueCreationError("chat does not belong to authenticated user")

    payload = {
        "chat_id": created_chat_id,
        "user_message_id": user_message_id,
        "prompt": clean_message,
        "messages": [{"role": "user", "content": clean_message}],
        "mode": "chat",
        "route_source": "stage_5f8_synthetic_helper",
        "synthetic": True,
        "requested_model": requested_model,
    }

    _psql_run(
        f"""
        BEGIN;

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
          {_sql_literal(user_message_id)},
          {_sql_literal(created_chat_id)},
          'user',
          {_sql_literal(clean_message)},
          0,
          NULL,
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
        VALUES (
          {_sql_literal(job_id)},
          {_sql_literal(authenticated_user_id)},
          'ollama_chat',
          'queued',
          {_sql_literal(requested_model)},
          NULL,
          {_jsonb_literal(payload)},
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

    raw = _psql_at(
        f"""
        SELECT row_to_json(j)::text
        FROM (
          SELECT
            id AS job_id,
            status,
            payload_json
          FROM app_jobs
          WHERE id = {_sql_literal(job_id)}
        ) j;
        """
    )

    if not raw:
        raise ChatQueueCreationError("created queued job could not be read back")

    parsed = json.loads(raw)

    return QueuedChatJob(
        chat_id=created_chat_id,
        user_message_id=user_message_id,
        job_id=parsed["job_id"],
        status=parsed["status"],
        payload_json=parsed["payload_json"],
    )
