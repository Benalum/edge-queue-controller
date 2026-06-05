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
    def __init__(self, payload=None):
        self._payload = payload or {}
        self.headers = {
            "user-agent": "email-verification-smoke",
            "X-Edge-Api-Key": "email-verification-smoke-key",
            "x-edge-api-key": "email-verification-smoke-key",
        }
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


def count_users(db_path, email):
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        return conn.execute(
            "SELECT COUNT(*) AS c FROM app_users WHERE email = ?",
            (email,),
        ).fetchone()["c"]


def pending_for(db_path, email):
    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        return conn.execute(
            "SELECT * FROM pending_email_signups WHERE email = ?",
            (email,),
        ).fetchone()



def access_token_from_response(data):
    if data.get("access_token"):
        return data["access_token"]

    session = data.get("session")
    if isinstance(session, dict) and session.get("access_token"):
        return session["access_token"]

    raise AssertionError(f"Response did not include access token: {data}")


async def main():
    original_db_path = edge_controller.DB_PATH
    original_env = {k: os.environ.get(k) for k in [
        "EMAIL_VERIFICATION_DEBUG_RETURN_URL",
        "EMAIL_VERIFICATION_SMTP_ENABLED",
        "PUBLIC_BASE_URL",
        "EMAIL_VERIFICATION_TOKEN_HOURS",
        "EDGE_PUBLIC_API_KEY",
    ]}

    try:
        with tempfile.TemporaryDirectory() as tmp:
            db_path = Path(tmp) / "email-verification.sqlite3"
            edge_controller.DB_PATH = db_path

            os.environ["EMAIL_VERIFICATION_DEBUG_RETURN_URL"] = "true"
            os.environ["EMAIL_VERIFICATION_SMTP_ENABLED"] = "false"
            os.environ["PUBLIC_BASE_URL"] = "https://example.test"
            os.environ["EMAIL_VERIFICATION_TOKEN_HOURS"] = "24"
            os.environ["EDGE_PUBLIC_API_KEY"] = "email-verification-smoke-key"

            edge_controller.init_db()
            edge_controller._auth_init_tables()

            email = "verify-smoke@example.local"
            password = "good-password-123"

            registered = await edge_controller.public_auth_register(
                FakeRequest({
                    "email": email,
                    "password": password,
                    "display_name": "Verify Smoke",
                })
            )

            assert registered["ok"] is True
            assert registered["verification_required"] is True
            assert registered["email"] == email
            assert registered["debug_verify_url"].startswith("https://example.test/api/auth/verify-email?token=")
            assert count_users(db_path, email) == 0
            assert pending_for(db_path, email) is not None

            detail = await expect_http(
                403,
                edge_controller.public_auth_login(
                    FakeRequest({"email": email, "password": password})
                ),
            )
            assert "Email verification required" in detail

            token = parse_qs(urlparse(registered["debug_verify_url"]).query)["token"][0]

            bad_detail = await expect_http(
                400,
                edge_controller.public_auth_verify_email("bad-token", FakeRequest()),
            )
            assert "Invalid" in bad_detail

            verified = await edge_controller.public_auth_verify_email(token, FakeRequest())

            assert verified["ok"] is True
            assert verified["verified"] is True
            assert verified["created"] is True
            assert verified["user"]["email"] == email
            assert access_token_from_response(verified)
            assert count_users(db_path, email) == 1

            reused_detail = await expect_http(
                400,
                edge_controller.public_auth_verify_email(token, FakeRequest()),
            )
            assert "Invalid or already used" in reused_detail

            logged_in = await edge_controller.public_auth_login(
                FakeRequest({"email": email, "password": password})
            )

            assert logged_in["ok"] is True
            assert logged_in["user"]["email"] == email
            assert access_token_from_response(logged_in)

            second = await edge_controller.public_auth_register(
                FakeRequest({
                    "email": "system-verify-smoke@example.local",
                    "password": password,
                })
            )

            assert second["verification_required"] is True
            assert count_users(db_path, "system-verify-smoke@example.local") == 0

            system_second = await edge_controller.system_session_register(
                FakeRequest({
                    "email": "system-route-verify-smoke@example.local",
                    "password": password,
                })
            )

            assert system_second["verification_required"] is True
            assert count_users(db_path, "system-route-verify-smoke@example.local") == 0

    finally:
        edge_controller.DB_PATH = original_db_path

        for key, value in original_env.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value

    print("PASS: email verification auth flow blocks account creation until verification")


asyncio.run(main())
PY
