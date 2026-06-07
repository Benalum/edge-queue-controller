#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

echo "=== synthetic chat assistant message persistence smoke ==="

export PAGER=cat
export PSQL_PAGER=cat

source .venv/bin/activate 2>/dev/null || true

python3 -m py_compile edge_modules/chat_queue_persistence.py

python3 - <<'PY'
import os
import time

from edge_modules.chat_queue_persistence import (
    ChatPersistenceError,
    _psql_at,
    cleanup_synthetic_chat_persistence_rows,
    persist_assistant_message_for_completed_job,
    setup_synthetic_chat_persistence_rows,
)

suffix = f"{int(time.time())}-{os.getpid()}"

try:
    ids = setup_synthetic_chat_persistence_rows(suffix=suffix)

    first = persist_assistant_message_for_completed_job(
        job_id=ids["complete_job_id"],
        authenticated_user_id=ids["user_id"],
    )

    assert first.role == "assistant", first
    assert first.chat_id == ids["chat_id"], first
    assert first.source_job_id == ids["complete_job_id"], first
    assert first.content == "Stage 5F-5 assistant reply", first
    print("OK: completed queued job created assistant message")

    second = persist_assistant_message_for_completed_job(
        job_id=ids["complete_job_id"],
        authenticated_user_id=ids["user_id"],
    )

    assert second.id == first.id, (first, second)
    assert second.content == first.content, (first, second)
    print("OK: duplicate persistence returned same assistant message")

    count = _psql_at(
        f"SELECT COUNT(*) FROM app_messages WHERE source_job_id = '{ids['complete_job_id']}';"
    )
    assert count == "1", count
    print("OK: duplicate persistence did not create second assistant message")

    failed_raised = False
    try:
        persist_assistant_message_for_completed_job(
            job_id=ids["failed_job_id"],
            authenticated_user_id=ids["user_id"],
        )
    except ChatPersistenceError:
        failed_raised = True

    assert failed_raised, "failed job unexpectedly created assistant message"
    print("OK: failed queued job created no assistant message")

    wrong_user_raised = False
    try:
        persist_assistant_message_for_completed_job(
            job_id=ids["wrong_user_job_id"],
            authenticated_user_id=ids["user_id"],
        )
    except ChatPersistenceError:
        wrong_user_raised = True

    assert wrong_user_raised, "wrong-user job unexpectedly created assistant message"
    print("OK: wrong-user queued job created no assistant message")

finally:
    cleanup_synthetic_chat_persistence_rows(suffix=suffix)

leftover = _psql_at(
    "SELECT COUNT(*) FROM app_users WHERE id LIKE 's5f5-user-%' OR id LIKE 's5f5-other-user-%';"
)
assert leftover == "0", leftover

print("PASS: synthetic chat assistant message persistence smoke passed and cleaned up")
PY
