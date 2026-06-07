"""
Disabled-by-default real-user queued chat guard helper.

Stage 5F-13.

This helper is intentionally not wired into production routes yet.
It defines the guardrails required before real authenticated users can enter
the laptop-owned queued chat path.

Safety:
- real-user queued chat is disabled unless LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED=1
- client-provided user_id is refused
- chat ownership must be verified before reuse
- this helper does not create jobs
- this helper does not persist messages
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Any

from edge_modules.chat_queue_persistence import _psql_at, _sql_literal


class RealUserQueuedChatGuardError(RuntimeError):
    pass


@dataclass(frozen=True)
class RealUserQueuedChatGuardResult:
    authenticated_user_id: str
    chat_id: str | None
    requested_model: str | None
    message: str


def real_user_queued_chat_enabled() -> bool:
    return os.environ.get("LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED", "").strip() == "1"


def _client_user_id_present(payload: dict[str, Any]) -> bool:
    return "user_id" in payload or "authenticated_user_id" in payload


def validate_real_user_queued_chat_request(
    *,
    authenticated_user_id: str | None,
    payload: dict[str, Any],
) -> RealUserQueuedChatGuardResult:
    """
    Validate a future real-user queued chat request.

    This helper does not create jobs.
    This helper does not persist messages.
    This helper only validates guard rules.
    """
    if not real_user_queued_chat_enabled():
        raise RealUserQueuedChatGuardError("real-user queued chat is disabled")

    if not authenticated_user_id:
        raise RealUserQueuedChatGuardError("authenticated user is required")

    if _client_user_id_present(payload):
        raise RealUserQueuedChatGuardError("client-provided user_id is refused")

    message = str(payload.get("message") or "").strip()
    if not message:
        raise RealUserQueuedChatGuardError("message is required")

    chat_id_raw = payload.get("chat_id")
    chat_id = str(chat_id_raw).strip() if chat_id_raw else None

    if chat_id:
        owned = _psql_at(
            f"""
            SELECT COALESCE(
              (
                SELECT '1'
                FROM app_chats
                WHERE id = {_sql_literal(chat_id)}
                  AND user_id = {_sql_literal(authenticated_user_id)}
              ),
              ''
            );
            """
        )

        if owned != "1":
            raise RealUserQueuedChatGuardError("chat does not belong to authenticated user")

    requested_model_raw = payload.get("requested_model")
    requested_model = str(requested_model_raw).strip() if requested_model_raw else None

    return RealUserQueuedChatGuardResult(
        authenticated_user_id=authenticated_user_id,
        chat_id=chat_id,
        requested_model=requested_model,
        message=message,
    )


def validate_real_user_queued_chat_status_request(
    *,
    authenticated_user_id: str | None,
    job_id: str,
) -> str:
    """
    Validate ownership for a future real-user queued chat status request.

    Returns the job id when valid.
    """
    if not real_user_queued_chat_enabled():
        raise RealUserQueuedChatGuardError("real-user queued chat is disabled")

    if not authenticated_user_id:
        raise RealUserQueuedChatGuardError("authenticated user is required")

    clean_job_id = str(job_id or "").strip()
    if not clean_job_id:
        raise RealUserQueuedChatGuardError("job_id is required")

    owned = _psql_at(
        f"""
        SELECT COALESCE(
          (
            SELECT '1'
            FROM app_jobs
            WHERE id = {_sql_literal(clean_job_id)}
              AND user_id = {_sql_literal(authenticated_user_id)}
          ),
          ''
        );
        """
    )

    if owned != "1":
        raise RealUserQueuedChatGuardError("job does not belong to authenticated user")

    return clean_job_id
