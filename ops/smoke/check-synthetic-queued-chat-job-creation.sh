#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== synthetic queued chat job creation smoke ==="

export PAGER=cat
export PSQL_PAGER=cat

source .venv/bin/activate 2>/dev/null || true

python3 -m py_compile edge_modules/chat_queue_creation.py

python3 - <<'PY'
import os
import time

from edge_modules.chat_queue_creation import (
    ChatQueueCreationError,
    cleanup_synthetic_chat_queue_creation_rows,
    create_synthetic_queued_chat_job,
    setup_synthetic_chat_queue_creation_rows,
)
from edge_modules.chat_queue_persistence import _psql_at

suffix = f"{int(time.time())}-{os.getpid()}"

try:
    ids = setup_synthetic_chat_queue_creation_rows(suffix=suffix)

    created = create_synthetic_queued_chat_job(
        authenticated_user_id=ids["user_id"],
        message="Stage 5F-8 new chat message",
        requested_model="stage-5f8-synthetic-model",
    )

    assert created.status == "queued", created
    assert created.chat_id.startswith("s5f8-chat-"), created
    assert created.user_message_id.startswith("s5f8-msg-user-"), created
    assert created.payload_json["chat_id"] == created.chat_id, created
    assert created.payload_json["user_message_id"] == created.user_message_id, created
    assert created.payload_json["prompt"] == "Stage 5F-8 new chat message", created
    assert created.payload_json["messages"][0]["content"] == "Stage 5F-8 new chat message", created
    assert created.payload_json["mode"] == "chat", created
    assert created.payload_json["route_source"] == "stage_5f8_synthetic_helper", created
    assert created.payload_json["synthetic"] is True, created
    print("OK: created queued chat job for new chat")

    user_msg_count = _psql_at(
        f"SELECT COUNT(*) FROM app_messages WHERE id = '{created.user_message_id}' AND role = 'user' AND chat_id = '{created.chat_id}';"
    )
    assert user_msg_count == "1", user_msg_count
    print("OK: user message persisted before queued job")

    existing = create_synthetic_queued_chat_job(
        authenticated_user_id=ids["user_id"],
        chat_id=ids["existing_chat_id"],
        message="Stage 5F-8 existing chat message",
        requested_model="stage-5f8-synthetic-model",
    )

    assert existing.status == "queued", existing
    assert existing.chat_id == ids["existing_chat_id"], existing
    assert existing.payload_json["chat_id"] == ids["existing_chat_id"], existing
    print("OK: created queued chat job for existing owned chat")

    refused_user = False
    try:
        create_synthetic_queued_chat_job(
            authenticated_user_id="not-synthetic-user",
            message="should fail",
        )
    except ChatQueueCreationError:
        refused_user = True

    assert refused_user, "non-synthetic user was not refused"
    print("OK: non-synthetic user refused")

finally:
    cleanup_synthetic_chat_queue_creation_rows(suffix=suffix)

leftover = _psql_at(
    "SELECT COUNT(*) FROM app_users WHERE id LIKE 's5f8-user-%';"
)
assert leftover == "0", leftover

print("PASS: synthetic queued chat job creation smoke passed and cleaned up")
PY
