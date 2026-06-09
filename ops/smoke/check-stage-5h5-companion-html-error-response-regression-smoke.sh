#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-5h5-companion-html-error-response-regression-smoke.md"
WRAPPER="frontend/wrapper-ui/dev_server.py"
CONFIG="frontend/wrapper-ui/queued_chat_config.js"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

[[ -f "$DOC" ]] || fail "missing $DOC"
[[ -f "$WRAPPER" ]] || fail "missing $WRAPPER"
[[ -f "$CONFIG" ]] || fail "missing $CONFIG"

grep -Fq "Stage 5H-5" "$DOC" || fail "doc missing Stage 5H-5 title"
grep -Fq "smoke-only stage" "$DOC" || fail "doc missing smoke-only statement"
grep -Fq "does not change runtime behavior" "$DOC" || fail "doc missing no-runtime-change invariant"
grep -Fq "does not make queued chat globally default-on" "$DOC" || fail "doc missing default-off invariant"
grep -Fq "does not increase worker concurrency" "$DOC" || fail "doc missing concurrency invariant"
grep -Fq 'does not accept client-provided `user_id`' "$DOC" || fail "doc missing user_id invariant"

grep -Fq "enabled: false" "$CONFIG" || fail "queued chat browser config no longer default-off"
grep -Fq "AI_PLATFORM_QUEUED_CHAT_ENABLED = false" "$CONFIG" || fail "global queued chat flag no longer default-off"

grep -Fq "assistant_message" "$WRAPPER" || fail "wrapper missing assistant_message transform"
grep -Fq "STAGE_5G9_CT101_QUEUED_CHAT_BRIDGE_V1" "$WRAPPER" || fail "wrapper missing queued bridge marker"
grep -Fq "/api/backend/chats/([^/]+)/messages/jobs/([^/]+)" "$WRAPPER" || fail "wrapper missing queued status bridge regex"
grep -Fq "/api/chat/queued/{job_id}" "$WRAPPER" || fail "wrapper missing controller queued status mapping"

# Verify the real CT101 frontend source remotely.
ssh root@100.88.194.19 'pct exec 101 -- bash -s' <<'REMOTE'
set -euo pipefail

cd /opt/ai-platform

FILE="frontend/components/ChatPage.tsx"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$FILE" ]] || fail "missing CT101 $FILE"

grep -Fq "STAGE_5H4_COMPANION_BROWSER_QUEUED_SUBMIT_V1" "$FILE" || fail "CT101 ChatPage missing Stage 5H-4 marker"
grep -Fq "const queuedChatEnabled = useQueuedChat;" "$FILE" || fail "CT101 ChatPage queuedChatEnabled does not use useQueuedChat directly"
grep -Fq "messages/queued" "$FILE" || fail "CT101 ChatPage missing queued create route"
grep -Fq "messages/jobs" "$FILE" || fail "CT101 ChatPage missing queued status route"
grep -Fq "assistant_message" "$FILE" || fail "CT101 ChatPage missing assistant_message handling"
grep -Fq "JSON.parse" "$FILE" || fail "CT101 ChatPage missing JSON parse handling"
grep -Fq "responseText" "$FILE" || fail "CT101 ChatPage missing response text handling"

if grep -Fq "const queuedChatEnabled = !isCompanion && useQueuedChat;" "$FILE"; then
  fail "CT101 ChatPage still blocks companion queued submit"
fi

if grep -nE "user_id\s*:|userId\s*:" "$FILE" | grep -E "queued|message|payload|body" >/dev/null 2>&1; then
  fail "CT101 ChatPage appears to send client-provided user_id/userId near queued payload"
fi

echo "PASS: CT101 ChatPage companion queued HTML/error regression markers verified"
REMOTE

# Live structured JSON regression: create/status companion queued job through wrapper.
python3 - <<'PY'
from __future__ import annotations

import json
import os
import secrets
import time
import urllib.error
import urllib.request

from edge_modules.chat_queue_persistence import _psql_run, _sql_literal
from edge_modules.chat_queue_session_auth import hash_session_token

WRAPPER_BASE = os.getenv("STAGE_5H5_WRAPPER_BASE", "http://127.0.0.1:8787").rstrip("/")
TIMEOUT_SECONDS = int(os.getenv("STAGE_5H5_TIMEOUT_SECONDS", "180"))

suffix = secrets.token_hex(8)
source_user_id = f"s5h5-user-{suffix}"
source_session_id = f"s5h5-session-{suffix}"
chat_id = f"s5h5-companion-chat-{suffix}"
email = f"s5h5-{suffix}@example.invalid"
session_token = secrets.token_urlsafe(32)
job_id = None
terminal = False

def request_json(method: str, url: str, *, body: dict | None = None, cookie_token: str | None = None):
    data = None
    headers = {"Accept": "application/json"}

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
            content_type = resp.headers.get("Content-Type", "")
    except urllib.error.HTTPError as exc:
        raw = exc.read()
        status = exc.code
        content_type = exc.headers.get("Content-Type", "")

    text = raw.decode("utf-8", "replace")

    if "<html" in text.lower() or "<!doctype html" in text.lower():
        raise SystemExit(f"HTML response detected from {url} status={status} content_type={content_type!r}")

    try:
        parsed = json.loads(text or "{}")
    except Exception:
        raise SystemExit(f"non-JSON response detected from {url} status={status} content_type={content_type!r}")

    return status, parsed

def cleanup():
    _psql_run(
        f"""
        BEGIN;

        DELETE FROM app_messages
        WHERE chat_id = {_sql_literal(chat_id)}
           OR source_job_id IN (
             SELECT id FROM app_jobs
             WHERE payload_json->>'chat_id' = {_sql_literal(chat_id)}
           );

        DELETE FROM app_jobs
        WHERE payload_json->>'chat_id' = {_sql_literal(chat_id)}
           OR id = {_sql_literal(job_id or '')};

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
    cleanup()

    _psql_run(
        f"""
        BEGIN;

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
          'Stage 5H-5 Smoke User',
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
          {_sql_literal(hash_session_token(session_token))},
          now(),
          now() + interval '30 minutes',
          NULL
        );

        COMMIT;
        """
    )

    create_status, create_data = request_json(
        "POST",
        f"{WRAPPER_BASE}/api/backend/chats/{chat_id}/messages/queued",
        body={
            "content": "Stage 5H-5 companion HTML error regression smoke. Reply briefly.",
            "mode": "companion",
        },
        cookie_token=session_token,
    )

    if create_status >= 400:
        raise SystemExit(f"queued companion create failed status={create_status} error={create_data.get('error') or create_data.get('detail')}")

    job_id = str(create_data.get("job_id") or "").strip()
    if not job_id:
        raise SystemExit("queued companion create did not return job_id")

    deadline = time.time() + TIMEOUT_SECONDS
    last_status = None

    while time.time() < deadline:
        poll_status, poll_data = request_json(
            "GET",
            f"{WRAPPER_BASE}/api/backend/chats/{chat_id}/messages/jobs/{job_id}",
            cookie_token=session_token,
        )

        if poll_status >= 400:
            raise SystemExit(f"queued companion status failed status={poll_status} error={poll_data.get('error') or poll_data.get('detail')}")

        status = str(poll_data.get("status") or "").strip().lower()
        last_status = status

        if status == "complete":
            terminal = True
            assistant = poll_data.get("assistant_message")
            if not isinstance(assistant, dict):
                raise SystemExit("complete status missing assistant_message object")
            if assistant.get("role") != "assistant":
                raise SystemExit("assistant_message role was not assistant")
            content = str(assistant.get("content") or "")
            if not content.strip():
                raise SystemExit("assistant_message content was empty")
            if "<html" in content.lower() or "<!doctype html" in content.lower():
                raise SystemExit("assistant_message content looked like raw HTML")
            print("ok: companion queued status completed with structured assistant_message and no raw HTML")
            break

        if status in {"failed", "cancelled"}:
            terminal = True
            raise SystemExit(f"queued companion job reached terminal failure status={status}")

        time.sleep(3)

    if not terminal:
        raise SystemExit(f"queued companion job did not complete before timeout; last_status={last_status}; job_id={job_id}")

finally:
    if terminal:
        cleanup()
        print("ok: cleaned Stage 5H-5 temporary rows")
    else:
        print("note: leaving Stage 5H-5 rows for inspection because job may still be processing")

PY

if grep -RInE "LAPTOP_QUEUE_INTERNAL_TOKEN=.*|EDGE_TRUSTED_PROXY_SECRET=.*|EDGE_PUBLIC_API_KEY=.*|Authorization: Bearer|X-Worker-Token:|X-Edge-Auth-Secret: [^<]" "$DOC" >/dev/null 2>&1; then
  fail "doc appears to contain raw secret/token/header value"
fi

pass "Stage 5H-5 companion HTML/error response regression smoke passed"
