"""
Synthetic queued-chat assistant message persistence helper.

Stage 5F-5.

This helper is intentionally not wired into production chat routes yet.
It proves the persistence rules needed before opt-in queued chat behavior.

Safety:
- synthetic/test-only for now
- no production route imports this helper yet
- uses app_messages.source_job_id uniqueness from Stage 5F-4
"""

from __future__ import annotations

import json
import os
import secrets
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any


class ChatPersistenceError(RuntimeError):
    pass


def _load_database_url() -> str:
    if os.environ.get("DATABASE_URL"):
        return os.environ["DATABASE_URL"]

    env_file = Path(
        os.environ.get(
            "AI_PLATFORM_CONTROLLER_DB_ENV",
            str(Path.home() / ".config/ai-platform-controller/postgres.env"),
        )
    )

    if not env_file.exists():
        raise ChatPersistenceError(f"missing DB env file: {env_file}")

    for line in env_file.read_text().splitlines():
        if line.startswith("DATABASE_URL="):
            value = line.split("=", 1)[1].strip()
            if value:
                return value

    raise ChatPersistenceError(f"DATABASE_URL missing from {env_file}")


def _psql_at(sql: str) -> str:
    database_url = _load_database_url()
    proc = subprocess.run(
        ["psql", database_url, "-v", "ON_ERROR_STOP=1", "-Atc", sql],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return proc.stdout.strip()


def _psql_run(sql: str) -> None:
    database_url = _load_database_url()
    subprocess.run(
        ["psql", database_url, "-v", "ON_ERROR_STOP=1", "-c", sql],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def _sql_literal(value: Any) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def _jsonb_literal(value: Any) -> str:
    return _sql_literal(json.dumps(value, separators=(",", ":"), sort_keys=True)) + "::jsonb"


@dataclass(frozen=True)
class PersistedAssistantMessage:
    id: str
    chat_id: str
    role: str
    content: str
    source_job_id: str


def persist_assistant_message_for_completed_job(
    *,
    job_id: str,
    authenticated_user_id: str,
) -> PersistedAssistantMessage:
    """
    Persist exactly one assistant message for a completed queued chat job.
    """
    message_id = "msg-" + secrets.token_hex(16)

    raw = _psql_at(
        f"""
        WITH target_job AS (
          SELECT
            j.id AS job_id,
            j.user_id,
            j.status,
            j.payload_json,
            j.result_json,
            j.result_json->>'reply' AS reply,
            j.payload_json->>'chat_id' AS chat_id
          FROM app_jobs j
          WHERE j.id = {_sql_literal(job_id)}
        ),
        validated AS (
          SELECT tj.*
          FROM target_job tj
          JOIN app_chats c
            ON c.id = tj.chat_id
           AND c.user_id = tj.user_id
          WHERE tj.user_id = {_sql_literal(authenticated_user_id)}
            AND tj.status = 'complete'
            AND COALESCE(tj.reply, '') <> ''
            AND COALESCE(tj.chat_id, '') <> ''
        ),
        inserted AS (
          INSERT INTO app_messages (
            id,
            chat_id,
            role,
            content,
            risk_level,
            source_job_id,
            created_at
          )
          SELECT
            {_sql_literal(message_id)},
            v.chat_id,
            'assistant',
            v.reply,
            0,
            v.job_id,
            now()
          FROM validated v
          ON CONFLICT (source_job_id) WHERE source_job_id IS NOT NULL
          DO NOTHING
          RETURNING
            id,
            chat_id,
            role,
            content,
            source_job_id
        ),
        existing AS (
          SELECT
            m.id,
            m.chat_id,
            m.role,
            m.content,
            m.source_job_id
          FROM app_messages m
          WHERE m.source_job_id = {_sql_literal(job_id)}
        )
        SELECT COALESCE(
          (SELECT row_to_json(inserted)::text FROM inserted LIMIT 1),
          (SELECT row_to_json(existing)::text FROM existing LIMIT 1),
          ''
        );
        """
    )

    if not raw:
        raise ChatPersistenceError(
            f"could not persist assistant message for job {job_id}: "
            "job missing, incomplete, failed, wrong user, missing reply, or chat ownership mismatch"
        )

    parsed = json.loads(raw)

    return PersistedAssistantMessage(
        id=parsed["id"],
        chat_id=parsed["chat_id"],
        role=parsed["role"],
        content=parsed["content"],
        source_job_id=parsed["source_job_id"],
    )


def setup_synthetic_chat_persistence_rows(*, suffix: str) -> dict[str, str]:
    user_id = f"s5f5-user-{suffix}"
    other_user_id = f"s5f5-other-user-{suffix}"
    chat_id = f"s5f5-chat-{suffix}"
    complete_job_id = f"s5f5-job-complete-{suffix}"
    failed_job_id = f"s5f5-job-failed-{suffix}"
    wrong_user_job_id = f"s5f5-job-wrong-user-{suffix}"

    _psql_run(
        f"""
        BEGIN;

        DELETE FROM app_messages WHERE source_job_id LIKE 's5f5-job-%';
        DELETE FROM app_jobs WHERE id IN (
          {_sql_literal(complete_job_id)},
          {_sql_literal(failed_job_id)},
          {_sql_literal(wrong_user_job_id)}
        );
        DELETE FROM app_chats WHERE id = {_sql_literal(chat_id)};
        DELETE FROM app_users WHERE id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});

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
        VALUES (
          {_sql_literal(chat_id)},
          {_sql_literal(user_id)},
          'chat',
          'Stage 5F-5 Smoke',
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
            {_sql_literal(complete_job_id)},
            {_sql_literal(user_id)},
            'ollama_chat',
            'complete',
            'synthetic',
            's5f5-worker',
            {_jsonb_literal({'chat_id': chat_id, 'mode': 'chat', 'synthetic': True})},
            {_jsonb_literal({'reply': 'Stage 5F-5 assistant reply', 'model': 'synthetic'})},
            NULL,
            now(),
            now(),
            now(),
            now()
          ),
          (
            {_sql_literal(failed_job_id)},
            {_sql_literal(user_id)},
            'ollama_chat',
            'failed',
            'synthetic',
            's5f5-worker',
            {_jsonb_literal({'chat_id': chat_id, 'mode': 'chat', 'synthetic': True})},
            NULL,
            'synthetic failure',
            now(),
            now(),
            now(),
            now()
          ),
          (
            {_sql_literal(wrong_user_job_id)},
            {_sql_literal(other_user_id)},
            'ollama_chat',
            'complete',
            'synthetic',
            's5f5-worker',
            {_jsonb_literal({'chat_id': chat_id, 'mode': 'chat', 'synthetic': True})},
            {_jsonb_literal({'reply': 'Wrong user reply', 'model': 'synthetic'})},
            NULL,
            now(),
            now(),
            now(),
            now()
          );

        COMMIT;
        """
    )

    return {
        "user_id": user_id,
        "other_user_id": other_user_id,
        "chat_id": chat_id,
        "complete_job_id": complete_job_id,
        "failed_job_id": failed_job_id,
        "wrong_user_job_id": wrong_user_job_id,
    }


def cleanup_synthetic_chat_persistence_rows(*, suffix: str) -> None:
    user_id = f"s5f5-user-{suffix}"
    other_user_id = f"s5f5-other-user-{suffix}"
    chat_id = f"s5f5-chat-{suffix}"

    _psql_run(
        f"""
        BEGIN;
        DELETE FROM app_messages WHERE source_job_id LIKE 's5f5-job-%';
        DELETE FROM app_jobs WHERE id LIKE 's5f5-job-%';
        DELETE FROM app_chats WHERE id = {_sql_literal(chat_id)};
        DELETE FROM app_users WHERE id IN ({_sql_literal(user_id)}, {_sql_literal(other_user_id)});
        COMMIT;
        """
    )
