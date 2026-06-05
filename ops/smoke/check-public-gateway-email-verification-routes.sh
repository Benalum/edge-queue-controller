#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from fastapi.testclient import TestClient

import public_gateway


original_fetch_json = public_gateway._system_v2_fetch_json

calls = []


def fake_fetch_json(path, method="GET", body=None, headers=None, timeout=None):
    calls.append({
        "path": path,
        "method": method,
        "body": body,
        "headers": headers or {},
        "timeout": timeout,
    })

    if path.startswith("/api/auth/verify-email") and method == "GET":
        if "bad-token" in path:
            return 400, {
                "ok": False,
                "detail": "Invalid or already used verification link.",
            }

        return 200, {
            "ok": True,
            "verified": True,
            "created": True,
            "user": {"email": "proxy-smoke@example.local"},
            "access_token": "smoke-token",
        }

    if path == "/api/auth/resend-verification" and method == "POST":
        return 200, {
            "ok": True,
            "verification_required": True,
            "email": body.get("email"),
            "email_delivery": "smtp",
        }

    return 500, {
        "ok": False,
        "detail": f"Unexpected proxy call: {method} {path}",
    }


try:
    public_gateway._system_v2_fetch_json = fake_fetch_json
    client = TestClient(public_gateway.app)

    bad = client.get("/api/auth/verify-email?token=bad-token")
    assert bad.status_code == 400, bad.text
    assert "Invalid" in bad.json()["detail"]
    assert calls[-1]["path"] == "/api/auth/verify-email?token=bad-token"
    assert calls[-1]["method"] == "GET"

    good = client.get("/api/auth/verify-email?token=good-token")
    assert good.status_code == 200, good.text
    assert good.json()["ok"] is True
    assert good.json()["verified"] is True

    resend = client.post(
        "/api/auth/resend-verification",
        json={"email": "proxy-smoke@example.local"},
    )
    assert resend.status_code == 200, resend.text
    assert resend.json()["verification_required"] is True
    assert calls[-1]["path"] == "/api/auth/resend-verification"
    assert calls[-1]["method"] == "POST"
    assert calls[-1]["body"]["email"] == "proxy-smoke@example.local"

finally:
    public_gateway._system_v2_fetch_json = original_fetch_json

print("PASS: public gateway email verification routes proxy correctly")
PY
