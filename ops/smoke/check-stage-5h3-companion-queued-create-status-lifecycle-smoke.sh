#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-5h3-companion-queued-create-status-lifecycle-smoke.md"
WRAPPER="frontend/wrapper-ui/dev_server.py"
CONTROLLER="edge_controller.py"
GUARD="edge_modules/chat_queue_real_user_guard.py"
CREATION="edge_modules/chat_queue_real_user_creation.py"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

[[ -f "$DOC" ]] || fail "missing $DOC"
[[ -f "$WRAPPER" ]] || fail "missing $WRAPPER"
[[ -f "$CONTROLLER" ]] || fail "missing $CONTROLLER"
[[ -f "$GUARD" ]] || fail "missing $GUARD"
[[ -f "$CREATION" ]] || fail "missing $CREATION"

grep -Fq "Stage 5H-3" "$DOC" || fail "doc missing Stage 5H-3 title"
grep -Fq "does not enable companion queued browser submit globally" "$DOC" || fail "doc missing no-browser-enable invariant"
grep -Fq "does not make queued chat globally default-on" "$DOC" || fail "doc missing default-off invariant"
grep -Fq "does not increase worker concurrency" "$DOC" || fail "doc missing concurrency invariant"
grep -Fq 'does not accept client-provided `user_id`' "$DOC" || fail "doc missing user_id invariant"
grep -Fq "never prints the raw session token" "$DOC" || fail "doc missing token safety statement"
grep -Fq "never prints the assistant reply content" "$DOC" || fail "doc missing reply safety statement"

grep -Fq "STAGE_5H2_COMPANION_MODE_OWNERSHIP_V1" "$WRAPPER" || fail "wrapper missing Stage 5H-2 marker"
grep -Fq "STAGE_5H2_COMPANION_MODE_OWNERSHIP_V1" "$CONTROLLER" || fail "controller missing Stage 5H-2 marker"
grep -Fq 'declared_mode in {"chat", "companion"}' "$WRAPPER" || fail "wrapper missing mode allowlist"
grep -Fq 'clean_mode not in {"chat", "companion"}' "$CONTROLLER" || fail "controller missing mode allowlist"
grep -Fq "mode must be chat or companion" "$GUARD" || fail "guard missing mode validation"
grep -Fq '"mode": validated.mode' "$CREATION" || fail "creation helper missing mode preservation"

if grep -RInE "LAPTOP_QUEUE_INTERNAL_TOKEN=.*|EDGE_TRUSTED_PROXY_SECRET=.*|EDGE_PUBLIC_API_KEY=.*|Authorization: Bearer|X-Worker-Token:|X-Edge-Auth-Secret: [^<]" "$DOC" >/dev/null 2>&1; then
  fail "doc appears to contain raw secret/token/header value"
fi

python3 - <<'PY'
from __future__ import annotations

import json
import os
import secrets
import time
import urllib.error
import urllib.request
from pathlib import Path

from edge_modules.chat_queue_persistence import _psql_at, _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

WRAPPER_BASE = os.getenv("STAGE_5H3_WRAPPER_BASE", "http://127.0.0.1:8787").rstrip("/")
CONTROLLER_BASE = os.getenv("STAGE_5H3_CONTROLLER_BASE", "http://127.0.0.1:7070").rstrip("/")
TIMEOUT_SECONDS = int(os.getenv("STAGE_5H3_TIMEOUT_SECONDS", "180"))

suffix = secrets.token_hex(8)
source_user_id = f"s5h3-user-{suffix}"
source_session_id = f"s5h3-session-{suffix}"
chat_id = f"s5h3-companion-chat-{suffix}"
email = f"s5h3-{suffix}@example.invalid"
session_token = secrets.token_urlsafe(32)
job_id = None
terminal = False
created_rows = False

def request_json(method: str, url: str, *, body: dict | None = None, cookie_token: str | None = None) -> tuple[int, dict]:
    data = None
    headers = {
        "Accept": "application/json",
    }

    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    if cookie_token:
        headers["Cookie"] = f"edgeStudyToken={cookie_token}"

    req = urllib.request.Request(url, data=data, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req, timeout=45) as resp:
            raw = resp.read()
            status = resp.status
    except urllib.error.HTTPError as exc:
        raw = exc.read()
        status = exc.code

    try:
        parsed = json.loads(raw.decode("utf-8") or "{}")
    except Exception:
        parsed = {"ok": False, "error": "non_json_response", "status": status}

    return status, parsed

def cleanup() -> None:
    _psql_run(
        f"""
        BEGIN;

        DELETE FROM app_messages
        WHERE chat_id = {_sql_literal(chat_id)}
           OR source_job_id = {_sql_literal(job_id or '')};

        DELETE FROM app_jobs
        WHERE id = {_sql_literal(job_id or '')}
           OR payload_json->>'chat_id' = {_sql_literal(chat_id)};

        DELETE FROM app_chats
        WHERE id = {_sql_literal(chat_id)};

        DELETE FROM app_sessions
        WHERE id IN (
          {_sql_literal(source_session_id)},
          {_sql_literal('ct101-edge-session-' + source_user_id)}
        );

        DELETE FROM app_users
        WHERE id IN (
          {_sql_literal(source_user_id)},
          {_sql_literal('ct101:' + source_user_id)}
        );

        COMMIT;
        """
    )

try:
    # Verify controller and wrapper are reachable without printing sensitive values.
    c_status, c_data = request_json("GET", f"{CONTROLLER_BASE}/health")
    if c_status >= 400:
        raise SystemExit(f"controller health failed status={c_status}")

    # Create a temporary local controller session that the wrapper can resolve.
    token_hash = hash_session_token(session_token)
    _psql_run(
        f"""
        BEGIN;

        DELETE FROM app_messages WHERE chat_id = {_sql_literal(chat_id)};
        DELETE FROM app_jobs WHERE payload_json->>'chat_id' = {_sql_literal(chat_id)};
        DELETE FROM app_chats WHERE id = {_sql_literal(chat_id)};
        DELETE FROM app_sessions
        WHERE id IN (
          {_sql_literal(source_session_id)},
          {_sql_literal('ct101-edge-session-' + source_user_id)}
        );
        DELETE FROM app_users
        WHERE id IN (
          {_sql_literal(source_user_id)},
          {_sql_literal('ct101:' + source_user_id)}
        );

        INSERT INTO app_users (
          id,
          email,
          display_name,
          password_hash,
          is_active,
          is_admin,
          created_at,
          updated_at
        )
        VALUES (
          {_sql_literal(source_user_id)},
          {_sql_literal(email)},
          'Stage 5H-3 Smoke User',
          NULL,
          TRUE,
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
        VALUES (
          {_sql_literal(source_session_id)},
          {_sql_literal(source_user_id)},
          {_sql_literal(token_hash)},
          now(),
          now() + interval '30 minutes',
          NULL
        );

        COMMIT;
        """
    )
    created_rows = True

    payload = {
        "content": "Stage 5H-3 companion queue lifecycle smoke. Reply briefly.",
        "mode": "companion",
    }

    create_status, create_data = request_json(
        "POST",
        f"{WRAPPER_BASE}/api/backend/chats/{chat_id}/messages/queued",
        body=payload,
        cookie_token=session_token,
    )

    if create_status >= 400:
        detail = create_data.get("detail") or create_data.get("error") or create_data
        raise SystemExit(f"queued companion create failed status={create_status} detail={detail}")

    job_id = str(create_data.get("job_id") or "").strip()
    if not job_id:
        raise SystemExit("queued companion create response did not include job_id")

    if create_data.get("chat_id") != chat_id:
        raise SystemExit("queued companion create response did not preserve chat_id")

    db_shape_raw = _psql_at(
        f"""
        SELECT COALESCE(
          (
            SELECT json_build_object(
              'chat_mode', c.mode,
              'job_mode', j.payload_json->>'mode',
              'job_status', j.status,
              'job_type', j.job_type,
              'job_user_prefix_ok', (j.user_id LIKE 'ct101:%')
            )::text
            FROM app_jobs j
            JOIN app_chats c
              ON c.id = j.payload_json->>'chat_id'
            WHERE j.id = {_sql_literal(job_id)}
          ),
          ''
        );
        """
    )

    if not db_shape_raw:
        raise SystemExit("could not read queued companion DB shape")

    db_shape = json.loads(db_shape_raw)

    if db_shape.get("chat_mode") != "companion":
        raise SystemExit(f"expected app_chats.mode companion, got {db_shape.get('chat_mode')!r}")

    if db_shape.get("job_mode") != "companion":
        raise SystemExit(f"expected app_jobs.payload_json.mode companion, got {db_shape.get('job_mode')!r}")

    if db_shape.get("job_type") != "ollama_chat":
        raise SystemExit(f"expected ollama_chat job type, got {db_shape.get('job_type')!r}")

    if not db_shape.get("job_user_prefix_ok"):
        raise SystemExit("expected mirrored ct101 user ownership for queued companion job")

    print(f"ok: created companion queued job job_id={job_id} chat_id={chat_id}")
    print("ok: DB shape has chat_mode=companion and job_mode=companion")

    deadline = time.time() + TIMEOUT_SECONDS
    last_status = None
    assistant_seen = False

    while time.time() < deadline:
        poll_status, poll_data = request_json(
            "GET",
            f"{WRAPPER_BASE}/api/backend/chats/{chat_id}/messages/jobs/{job_id}",
            cookie_token=session_token,
        )

        if poll_status >= 400:
            detail = poll_data.get("detail") or poll_data.get("error") or poll_data
            raise SystemExit(f"queued companion status failed status={poll_status} detail={detail}")

        status = str(poll_data.get("status") or "").strip().lower()
        last_status = status

        if status == "complete":
            terminal = True
            assistant = poll_data.get("assistant_message")
            if not isinstance(assistant, dict):
                raise SystemExit("complete companion status missing assistant_message object")
            if assistant.get("role") != "assistant":
                raise SystemExit("assistant_message role was not assistant")
            if not str(assistant.get("content") or "").strip():
                raise SystemExit("assistant_message content was empty")
            assistant_seen = True
            break

        if status in {"failed", "cancelled"}:
            terminal = True
            raise SystemExit(f"queued companion job reached terminal failure status={status}")

        time.sleep(3)

    if not terminal:
        print(f"FAIL: queued companion job did not reach terminal state before timeout; last_status={last_status}; job_id={job_id}; chat_id={chat_id}")
        print("Leaving rows in place for inspection because the managed worker may still be processing the job.")
        raise SystemExit(1)

    if not assistant_seen:
        raise SystemExit("assistant_message was not observed")

    print("ok: wrapper status returned complete assistant_message shape without printing reply content")

    cleanup()
    print("ok: cleaned Stage 5H-3 temporary rows after terminal completion")

except Exception:
    if created_rows and job_id and terminal:
        try:
            cleanup()
        except Exception:
            pass
    raise
PY

pass "Stage 5H-3 companion queued create/status lifecycle smoke passed"
