"""
Disabled-by-default queued chat session-auth resolver helper.

Stage 5F-16.

This helper is intentionally not wired into production routes yet.
It centralizes the future real-user queued chat rule:

- derive authenticated_user_id server-side from a session token
- never trust client-provided user_id
- reject missing, expired, revoked, unknown, or inactive-user sessions

Safety:
- disabled unless LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED=1
- does not create jobs
- does not persist messages
- does not call CT101
- does not call Ollama
"""

from __future__ import annotations

import hashlib
import os
from dataclasses import dataclass

from edge_modules.chat_queue_persistence import _psql_at, _sql_literal


class QueuedChatSessionAuthError(RuntimeError):
    pass


@dataclass(frozen=True)
class QueuedChatAuthenticatedUser:
    user_id: str
    session_id: str
    email: str | None = None


def queued_chat_session_auth_resolver_enabled() -> bool:
    return os.environ.get("LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED", "").strip() == "1"


def hash_session_token(session_token: str) -> str:
    return hashlib.sha256(session_token.encode("utf-8")).hexdigest()


def resolve_authenticated_user_from_session_token(
    *,
    session_token: str | None,
) -> QueuedChatAuthenticatedUser:
    """
    Resolve authenticated user from a session token.

    This helper does not create jobs.
    This helper does not persist messages.
    This helper is not wired into production routes yet.
    """
    if not queued_chat_session_auth_resolver_enabled():
        raise QueuedChatSessionAuthError("queued chat session auth resolver is disabled")

    clean_token = str(session_token or "").strip()
    if not clean_token:
        raise QueuedChatSessionAuthError("session token is required")

    token_hash = hash_session_token(clean_token)

    raw = _psql_at(
        f"""
        SELECT COALESCE(
          (
            SELECT row_to_json(x)::text
            FROM (
              SELECT
                s.id AS session_id,
                s.user_id AS user_id,
                u.email AS email
              FROM app_sessions s
              JOIN app_users u
                ON u.id = s.user_id
              WHERE s.token_hash = {_sql_literal(token_hash)}
                AND s.revoked_at IS NULL
                AND s.expires_at > now()
                AND u.is_active = TRUE
              LIMIT 1
            ) x
          ),
          ''
        );
        """
    )

    if not raw:
        raise QueuedChatSessionAuthError(
            "session is missing, expired, revoked, unknown, or user is inactive"
        )

    import json

    parsed = json.loads(raw)

    return QueuedChatAuthenticatedUser(
        user_id=parsed["user_id"],
        session_id=parsed["session_id"],
        email=parsed.get("email"),
    )


def reject_client_provided_user_id(payload: dict) -> None:
    """
    Refuse client-provided user ids for future real-user queued chat routes.
    """
    if "user_id" in payload or "authenticated_user_id" in payload:
        raise QueuedChatSessionAuthError("client-provided user_id is refused")
