#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import os

from fastapi.testclient import TestClient

import public_gateway


original_env = {
    "ENABLE_PUBLIC_AD_REWARD_ROUTES": os.environ.get("ENABLE_PUBLIC_AD_REWARD_ROUTES"),
}

original_fetch_json = public_gateway._system_v2_fetch_json

calls = []


def fake_fetch_json(path, method="GET", body=None, headers=None, timeout=None):
    calls.append(
        {
            "path": path,
            "method": method,
            "body": body,
            "headers": headers or {},
            "timeout": timeout,
        }
    )

    if path == "/system/ads/reward/status" and method == "GET":
        return 200, {
            "ok": True,
            "can_claim": False,
            "provider": {
                "provider": "none",
                "ready": False,
                "detail": "No rewarded-ad provider is configured.",
            },
        }

    if path == "/system/ads/reward/claim" and method == "POST":
        return 200, {
            "ok": True,
            "proxied": True,
            "body": body,
        }

    return 500, {
        "ok": False,
        "detail": f"Unexpected proxy call: {method} {path}",
    }


try:
    public_gateway._system_v2_fetch_json = fake_fetch_json
    client = TestClient(public_gateway.app)

    os.environ["ENABLE_PUBLIC_AD_REWARD_ROUTES"] = "false"

    status = client.get(
        "/system/ads/reward/status",
        headers={"Authorization": "Bearer test-token"},
    )

    assert status.status_code == 200, status.text
    assert status.json()["ok"] is True
    assert calls[-1]["path"] == "/system/ads/reward/status"
    assert calls[-1]["method"] == "GET"
    assert calls[-1]["headers"]["Authorization"] == "Bearer test-token"

    blocked = client.post(
        "/system/ads/reward/claim",
        headers={"Authorization": "Bearer test-token"},
        json={
            "provider": "google_gpt",
            "reward_event_id": "blocked-test",
        },
    )

    assert blocked.status_code == 404, blocked.text
    assert blocked.json()["detail"] == "Rewarded ads are not enabled on the public gateway yet."

    # No new backend call should have happened for the blocked claim.
    assert calls[-1]["path"] == "/system/ads/reward/status"

    os.environ["ENABLE_PUBLIC_AD_REWARD_ROUTES"] = "true"

    claimed = client.post(
        "/system/ads/reward/claim",
        headers={"Authorization": "Bearer test-token"},
        json={
            "provider": "google_gpt",
            "reward_event_id": "allowed-test",
            "metadata": {"smoke": True},
        },
    )

    assert claimed.status_code == 200, claimed.text
    assert claimed.json()["ok"] is True
    assert calls[-1]["path"] == "/system/ads/reward/claim"
    assert calls[-1]["method"] == "POST"
    assert calls[-1]["headers"]["Authorization"] == "Bearer test-token"
    assert calls[-1]["body"]["provider"] == "google_gpt"
    assert calls[-1]["body"]["reward_event_id"] == "allowed-test"

finally:
    public_gateway._system_v2_fetch_json = original_fetch_json

    for key, value in original_env.items():
        if value is None:
            os.environ.pop(key, None)
        else:
            os.environ[key] = value

print("PASS: public gateway rewarded-ad route gating works")
PY
