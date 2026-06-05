#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import os
import sqlite3
import tempfile
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from fastapi.testclient import TestClient

import edge_controller


original_db_path = edge_controller.DB_PATH
original_env = {k: os.environ.get(k) for k in [
    "EMAIL_VERIFICATION_DEBUG_RETURN_URL",
    "EMAIL_VERIFICATION_SMTP_ENABLED",
    "PUBLIC_BASE_URL",
    "EMAIL_VERIFICATION_TOKEN_HOURS",
]}

try:
    with tempfile.TemporaryDirectory() as tmp:
        edge_controller.DB_PATH = Path(tmp) / "email-verification-api-aliases.sqlite3"

        os.environ["EMAIL_VERIFICATION_DEBUG_RETURN_URL"] = "true"
        os.environ["EMAIL_VERIFICATION_SMTP_ENABLED"] = "false"
        os.environ["PUBLIC_BASE_URL"] = "https://example.test"
        os.environ["EMAIL_VERIFICATION_TOKEN_HOURS"] = "24"

        edge_controller.init_db()
        edge_controller._auth_init_tables()

        client = TestClient(edge_controller.app)

        email = "alias-verify-smoke@example.local"

        registered = client.post(
            "/api/auth/register",
            json={
                "email": email,
                "password": "good-password-123",
            },
        )

        # If /api/auth/register is not a direct controller alias in this app,
        # fall back to the public route. The alias under test is verify/resend.
        if registered.status_code == 404:
            registered = client.post(
                "/public/auth/register",
                json={
                    "email": email,
                    "password": "good-password-123",
                },
            )

        assert registered.status_code == 200, registered.text
        data = registered.json()
        assert data["verification_required"] is True
        token = parse_qs(urlparse(data["debug_verify_url"]).query)["token"][0]

        bad = client.get("/api/auth/verify-email", params={"token": "bad-token"})
        assert bad.status_code == 400, bad.text

        verified = client.get("/api/auth/verify-email", params={"token": token})
        assert verified.status_code == 200, verified.text
        verified_data = verified.json()
        assert verified_data["ok"] is True
        assert verified_data["verified"] is True
        assert verified_data["user"]["email"] == email
        assert verified_data["access_token"]

        reused = client.get("/api/auth/verify-email", params={"token": token})
        assert reused.status_code == 400, reused.text

        resend = client.post(
            "/api/auth/resend-verification",
            json={"email": "not-pending@example.local"},
        )
        assert resend.status_code == 200, resend.text
        assert resend.json()["verification_required"] is True

finally:
    edge_controller.DB_PATH = original_db_path

    for key, value in original_env.items():
        if value is None:
            os.environ.pop(key, None)
        else:
            os.environ[key] = value

print("PASS: email verification /api/auth aliases work")
PY
