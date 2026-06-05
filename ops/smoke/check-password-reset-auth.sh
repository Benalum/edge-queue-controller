#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import asyncio
import os
import sqlite3
import tempfile
from pathlib import Path
from types import SimpleNamespace
from urllib.parse import parse_qs, urlparse

from fastapi import HTTPException

import edge_controller


class FakeRequest:
    def __init__(self, payload=None, api_key=None):
        self._payload = payload or {}
        self.headers = {
            "user-agent": "password-reset-smoke",
        }
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
    original_env = {k: os.environ.get(k) for k in [
        "EMAIL_VERIFICATION_DEBUG_RETURN_URL",
        "EMAIL_VERIFICATION_SMTP_ENABLED",
        "PUBLIC_BASE_URL",
        "PASSWORD_RESET_TOKEN_HOURS",
        "EDGE_PUBLIC_API_KEY",
    ]}

    try:
        with tempfile.TemporaryDirectory() as tmp:
            edge_controller.DB_PATH = Path(tmp) / "password-reset.sqlite3"

            os.environ["EMAIL_VERIFICATION_DEBUG_RETURN_URL"] = "true"
            os.environ["EMAIL_VERIFICATION_SMTP_ENABLED"] = "false"
            os.environ["PUBLIC_BASE_URL"] = "https://example.test"
            os.environ["PASSWORD_RESET_TOKEN_HOURS"] = "1"
            os.environ["EDGE_PUBLIC_API_KEY"] = "password-reset-smoke-key"

            edge_controller.init_db()
            edge_controller._auth_init_tables()

            email = "password-reset-smoke@example.local"
            old_password = "old-password-123"
            new_password = "new-password-456"

            insert_user(email, old_password)

            missing = await edge_controller.public_auth_forgot_password(
                FakeRequest(
                    {"email": "missing-reset-smoke@example.local"},
                    api_key="password-reset-smoke-key",
                )
            )
            assert missing["ok"] is True
            assert missing["email_delivery"] == "no_account_noop"

            requested = await edge_controller.public_auth_forgot_password(
                FakeRequest(
                    {"email": email},
                    api_key="password-reset-smoke-key",
                )
            )

            assert requested["ok"] is True
            assert requested["debug_reset_url"].startswith("https://example.test/reset-password?token=")
            token = parse_qs(urlparse(requested["debug_reset_url"]).query)["token"][0]

            bad = await expect_http(
                400,
                edge_controller.public_auth_reset_password(
                    FakeRequest(
                        {
                            "token": "bad-token",
                            "new_password": new_password,
                        },
                        api_key="password-reset-smoke-key",
                    )
                ),
            )
            assert "Invalid" in bad

            short = await expect_http(
                400,
                edge_controller.public_auth_reset_password(
                    FakeRequest(
                        {
                            "token": token,
                            "new_password": "short",
                        },
                        api_key="password-reset-smoke-key",
                    )
                ),
            )
            assert "at least 8" in short

            reset = await edge_controller.public_auth_reset_password(
                FakeRequest(
                    {
                        "token": token,
                        "new_password": new_password,
                    },
                    api_key="password-reset-smoke-key",
                )
            )

            assert reset["ok"] is True
            assert reset["user"]["email"] == email

            await expect_http(401, login(email, old_password))

            logged_in = await login(email, new_password)
            assert logged_in["ok"] is True
            assert logged_in["user"]["email"] == email

            reused = await expect_http(
                400,
                edge_controller.public_auth_reset_password(
                    FakeRequest(
                        {
                            "token": token,
                            "new_password": "another-password-789",
                        },
                        api_key="password-reset-smoke-key",
                    )
                ),
            )
            assert "Invalid or already used" in reused

    finally:
        edge_controller.DB_PATH = original_db_path

        for key, value in original_env.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value

    print("PASS: password reset auth flow works")


asyncio.run(main())
PY
