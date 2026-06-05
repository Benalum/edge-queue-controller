#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import asyncio
import os
import sqlite3
import tempfile
from pathlib import Path
from types import SimpleNamespace

from fastapi import HTTPException

import edge_controller


class FakeRequest:
    def __init__(self, payload=None, token=None, api_key=None):
        self._payload = payload or {}
        self.headers = {
            "user-agent": "change-password-smoke",
        }
        if token:
            self.headers["authorization"] = f"Bearer {token}"
            self.headers["Authorization"] = f"Bearer {token}"
        if api_key:
            self.headers["x-edge-api-key"] = api_key
            self.headers["X-Edge-Api-Key"] = api_key
        self.client = SimpleNamespace(host="127.0.0.1")

    async def json(self):
        return self._payload


async def expect_http(status_code, coro):
    try:
        await coro
    except HTTPException as e:
        assert e.status_code == status_code, (e.status_code, e.detail)
        return str(e.detail)
    raise AssertionError(f"Expected HTTPException {status_code}")


def insert_user(email, password):
    now = edge_controller._auth_now_iso()
    with sqlite3.connect(edge_controller.DB_PATH) as conn:
        conn.execute(
            """
            INSERT INTO app_users (
                email,
                display_name,
                password_hash,
                status,
                created_at,
                updated_at,
                last_login_at
            )
            VALUES (?, NULL, ?, 'active', ?, ?, NULL)
            """,
            (
                email,
                edge_controller._auth_hash_password(password),
                now,
                now,
            ),
        )
        conn.commit()


async def login(email, password):
    return await edge_controller.system_session_login(
        FakeRequest({
            "email": email,
            "password": password,
        })
    )


async def main():
    original_db_path = edge_controller.DB_PATH
    original_api_key = os.environ.get("EDGE_PUBLIC_API_KEY")

    try:
        with tempfile.TemporaryDirectory() as tmp:
            edge_controller.DB_PATH = Path(tmp) / "change-password.sqlite3"
            os.environ["EDGE_PUBLIC_API_KEY"] = "change-password-smoke-key"

            edge_controller.init_db()
            edge_controller._auth_init_tables()

            email = "change-password-smoke@example.local"
            old_password = "old-password-123"
            mid_password = "mid-password-456"
            new_password = "new-password-789"

            insert_user(email, old_password)

            first_login = await login(email, old_password)
            assert first_login["ok"] is True
            token = first_login["session"]["access_token"]

            detail = await expect_http(
                401,
                edge_controller.system_session_change_password(
                    FakeRequest(
                        {
                            "current_password": "wrong-password",
                            "new_password": mid_password,
                        },
                        token=token,
                    )
                ),
            )
            assert "Current password is incorrect" in detail

            detail = await expect_http(
                400,
                edge_controller.system_session_change_password(
                    FakeRequest(
                        {
                            "current_password": old_password,
                            "new_password": "short",
                        },
                        token=token,
                    )
                ),
            )
            assert "at least 8" in detail

            changed = await edge_controller.system_session_change_password(
                FakeRequest(
                    {
                        "current_password": old_password,
                        "new_password": mid_password,
                    },
                    token=token,
                )
            )
            assert changed["ok"] is True
            assert changed["user"]["email"] == email

            await expect_http(401, login(email, old_password))

            second_login = await login(email, mid_password)
            assert second_login["ok"] is True
            second_token = second_login["session"]["access_token"]

            public_changed = await edge_controller.public_auth_change_password(
                FakeRequest(
                    {
                        "current_password": mid_password,
                        "new_password": new_password,
                    },
                    token=second_token,
                    api_key="change-password-smoke-key",
                )
            )
            assert public_changed["ok"] is True
            assert public_changed["user"]["email"] == email

            await expect_http(401, login(email, mid_password))

            final_login = await login(email, new_password)
            assert final_login["ok"] is True
            assert final_login["user"]["email"] == email

    finally:
        edge_controller.DB_PATH = original_db_path
        if original_api_key is None:
            os.environ.pop("EDGE_PUBLIC_API_KEY", None)
        else:
            os.environ["EDGE_PUBLIC_API_KEY"] = original_api_key

    print("PASS: change password auth flow works")


asyncio.run(main())
PY
