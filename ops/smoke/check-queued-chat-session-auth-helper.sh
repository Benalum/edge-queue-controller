#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== queued chat session auth helper smoke ==="

export PAGER=cat
export PSQL_PAGER=cat

source .venv/bin/activate 2>/dev/null || true

python3 -m py_compile edge_modules/chat_queue_session_auth.py

python3 - <<'PY'
import os
import time

from edge_modules.chat_queue_persistence import _psql_at, _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import (
    QueuedChatSessionAuthError,
    hash_session_token,
    reject_client_provided_user_id,
    resolve_authenticated_user_from_session_token,
)

suffix = f"s5f16-{int(time.time())}-{os.getpid()}"
user_id = f"{suffix}-user"
inactive_user_id = f"{suffix}-inactive-user"

valid_session_id = f"{suffix}-session-valid"
expired_session_id = f"{suffix}-session-expired"
revoked_session_id = f"{suffix}-session-revoked"
inactive_session_id = f"{suffix}-session-inactive"

valid_token = f"{suffix}-valid-token"
expired_token = f"{suffix}-expired-token"
revoked_token = f"{suffix}-revoked-token"
inactive_token = f"{suffix}-inactive-token"
unknown_token = f"{suffix}-unknown-token"

def cleanup():
    _psql_run(
        f"""
        BEGIN;
        DELETE FROM app_sessions
        WHERE id IN (
          {_sql_literal(valid_session_id)},
          {_sql_literal(expired_session_id)},
          {_sql_literal(revoked_session_id)},
          {_sql_literal(inactive_session_id)}
        );
        DELETE FROM app_users
        WHERE id IN ({_sql_literal(user_id)}, {_sql_literal(inactive_user_id)});
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
            {_sql_literal(inactive_user_id)},
            {_sql_literal(inactive_user_id + '@example.invalid')},
            'synthetic-smoke-password-hash',
            FALSE,
            FALSE,
            now(),
            now()
          );

        INSERT INTO app_sessions (
          id,
          user_id,
          token_hash,
          created_at,
          expires_at,
          revoked_at
        )
        VALUES
          (
            {_sql_literal(valid_session_id)},
            {_sql_literal(user_id)},
            {_sql_literal(hash_session_token(valid_token))},
            now(),
            now() + interval '1 hour',
            NULL
          ),
          (
            {_sql_literal(expired_session_id)},
            {_sql_literal(user_id)},
            {_sql_literal(hash_session_token(expired_token))},
            now() - interval '2 hours',
            now() - interval '1 hour',
            NULL
          ),
          (
            {_sql_literal(revoked_session_id)},
            {_sql_literal(user_id)},
            {_sql_literal(hash_session_token(revoked_token))},
            now(),
            now() + interval '1 hour',
            now()
          ),
          (
            {_sql_literal(inactive_session_id)},
            {_sql_literal(inactive_user_id)},
            {_sql_literal(hash_session_token(inactive_token))},
            now(),
            now() + interval '1 hour',
            NULL
          );

        COMMIT;
        """
    )

    os.environ.pop("LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED", None)

    disabled_raised = False
    try:
        resolve_authenticated_user_from_session_token(session_token=valid_token)
    except QueuedChatSessionAuthError:
        disabled_raised = True

    assert disabled_raised, "disabled resolver did not refuse"
    print("OK: disabled resolver refused")

    os.environ["LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED"] = "1"

    missing_raised = False
    try:
        resolve_authenticated_user_from_session_token(session_token="")
    except QueuedChatSessionAuthError:
        missing_raised = True

    assert missing_raised, "missing token was not refused"
    print("OK: missing token refused")

    unknown_raised = False
    try:
        resolve_authenticated_user_from_session_token(session_token=unknown_token)
    except QueuedChatSessionAuthError:
        unknown_raised = True

    assert unknown_raised, "unknown token was not refused"
    print("OK: unknown token refused")

    expired_raised = False
    try:
        resolve_authenticated_user_from_session_token(session_token=expired_token)
    except QueuedChatSessionAuthError:
        expired_raised = True

    assert expired_raised, "expired token was not refused"
    print("OK: expired session refused")

    revoked_raised = False
    try:
        resolve_authenticated_user_from_session_token(session_token=revoked_token)
    except QueuedChatSessionAuthError:
        revoked_raised = True

    assert revoked_raised, "revoked token was not refused"
    print("OK: revoked session refused")

    inactive_raised = False
    try:
        resolve_authenticated_user_from_session_token(session_token=inactive_token)
    except QueuedChatSessionAuthError:
        inactive_raised = True

    assert inactive_raised, "inactive user session was not refused"
    print("OK: inactive user session refused")

    user = resolve_authenticated_user_from_session_token(session_token=valid_token)

    assert user.user_id == user_id, user
    assert user.session_id == valid_session_id, user
    assert user.email == user_id + "@example.invalid", user
    print("OK: valid session resolved authenticated_user_id server-side")

    client_user_raised = False
    try:
        reject_client_provided_user_id({"message": "hello", "user_id": "evil"})
    except QueuedChatSessionAuthError:
        client_user_raised = True

    assert client_user_raised, "client-provided user_id was not refused"
    print("OK: client-provided user_id refused")

finally:
    cleanup()

leftover = _psql_at(
    f"SELECT COUNT(*) FROM app_users WHERE id IN ({_sql_literal(user_id)}, {_sql_literal(inactive_user_id)});"
)
assert leftover == "0", leftover

print("PASS: queued chat session auth helper smoke passed and cleaned up")
PY
