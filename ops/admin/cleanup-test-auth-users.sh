#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

python3 - <<'PY'
import os
import sqlite3
import edge_controller

TARGET_EMAILS = [
    "you@example.com",
    "alexhartel179+verify1780690690@gmail.com",
    "alexhartel179+verify1780690895@gmail.com",
]

# Also clean any temporary verification aliases after recovery flow testing.
TARGET_LIKE_PATTERNS = [
    "alexhartel179+verify%@gmail.com",
]

CONFIRM = os.getenv("CONFIRM_DELETE_TEST_AUTH_USERS", "")
DRY_RUN = CONFIRM != "DELETE_TEST_AUTH_USERS"

with sqlite3.connect(edge_controller.DB_PATH) as conn:
    conn.row_factory = sqlite3.Row

    users = []
    pending = []

    for email in TARGET_EMAILS:
        users.extend(conn.execute(
            """
            SELECT id, email, created_at, last_login_at
            FROM app_users
            WHERE email = ?
            """,
            (email,),
        ).fetchall())

        pending.extend(conn.execute(
            """
            SELECT id, email, expires_at, consumed_at, sent_count, last_sent_at
            FROM pending_email_signups
            WHERE email = ?
            """,
            (email,),
        ).fetchall())

    for pattern in TARGET_LIKE_PATTERNS:
        users.extend(conn.execute(
            """
            SELECT id, email, created_at, last_login_at
            FROM app_users
            WHERE email LIKE ?
            """,
            (pattern,),
        ).fetchall())

        pending.extend(conn.execute(
            """
            SELECT id, email, expires_at, consumed_at, sent_count, last_sent_at
            FROM pending_email_signups
            WHERE email LIKE ?
            """,
            (pattern,),
        ).fetchall())

    # Deduplicate by id/email
    users_by_id = {int(r["id"]): r for r in users}
    pending_by_id = {int(r["id"]): r for r in pending}

    print("=== cleanup mode ===")
    print("DRY RUN" if DRY_RUN else "DELETE MODE")

    print("\n=== app_users matched ===")
    for r in users_by_id.values():
        print(dict(r))

    print("\n=== pending_email_signups matched ===")
    for r in pending_by_id.values():
        print(dict(r))

    if DRY_RUN:
        print("\nNo rows deleted.")
        print("To delete later, run:")
        print("CONFIRM_DELETE_TEST_AUTH_USERS=DELETE_TEST_AUTH_USERS ops/admin/cleanup-test-auth-users.sh")
        raise SystemExit(0)

    user_ids = sorted(users_by_id)

    conn.execute("BEGIN")

    if user_ids:
        placeholders = ",".join("?" for _ in user_ids)

        conn.execute(
            f"DELETE FROM user_sessions WHERE user_id IN ({placeholders})",
            user_ids,
        )

        conn.execute(
            f"DELETE FROM app_users WHERE id IN ({placeholders})",
            user_ids,
        )

    for email in TARGET_EMAILS:
        conn.execute(
            "DELETE FROM pending_email_signups WHERE email = ?",
            (email,),
        )

    for pattern in TARGET_LIKE_PATTERNS:
        conn.execute(
            "DELETE FROM pending_email_signups WHERE email LIKE ?",
            (pattern,),
        )

    conn.commit()

    print("\nDeleted matched test auth users, sessions, and pending signups.")
PY
