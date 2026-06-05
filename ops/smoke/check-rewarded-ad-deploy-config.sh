#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import os

from fastapi.testclient import TestClient

from edge_modules.rewarded_ads import ad_reward_provider_config
import public_gateway


PENDING_VALUES = {
    "AD_REWARD_FREE_CREDITS": "5",
    "AD_REWARD_DAILY_LIMIT": "25",
    "AD_REWARD_MONTHLY_LIMIT": "750",
    "AD_REWARD_COOLDOWN_SECONDS": "120",
    "AD_REWARD_PROVIDER": "none",
    "AD_REWARD_GOOGLE_GPT_ENABLED": "false",
    "AD_REWARD_GOOGLE_GPT_AD_UNIT_PATH": "",
    "AD_REWARD_CLIENT_CLAIM_ENABLED": "false",
    "AD_REWARD_PROVIDER_VERIFICATION_ENABLED": "false",
    "ENABLE_PUBLIC_AD_REWARD_ROUTES": "false",
    "AD_REWARD_MOCK_ENABLED": "false",
}

original_env = {k: os.environ.get(k) for k in PENDING_VALUES}
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

    if path == "/system/ads/reward/status" and method == "GET":
        return 200, {
            "ok": True,
            "can_claim": False,
            "provider": ad_reward_provider_config(),
        }

    if path == "/system/ads/reward/claim" and method == "POST":
        return 200, {"ok": True, "unexpected": "claim proxied"}

    return 500, {"ok": False, "detail": f"unexpected {method} {path}"}


try:
    for key, value in PENDING_VALUES.items():
        os.environ[key] = value

    provider = ad_reward_provider_config()

    assert os.environ["AD_REWARD_FREE_CREDITS"] == "5"
    assert os.environ["AD_REWARD_DAILY_LIMIT"] == "25"
    assert os.environ["AD_REWARD_MONTHLY_LIMIT"] == "750"
    assert os.environ["AD_REWARD_COOLDOWN_SECONDS"] == "120"

    assert provider["provider"] == "none", provider
    assert provider["ready"] is False, provider
    assert provider["client_claim_enabled"] is False, provider
    assert provider["provider_verification_enabled"] is False, provider
    assert provider["google_gpt"]["enabled"] is False, provider
    assert provider["google_gpt"]["ad_unit_path"] == "", provider

    public_gateway._system_v2_fetch_json = fake_fetch_json
    client = TestClient(public_gateway.app)

    status = client.get("/system/ads/reward/status")
    assert status.status_code == 200, status.text
    assert status.json()["provider"]["provider"] == "none"

    claim = client.post(
        "/system/ads/reward/claim",
        json={"provider": "google_gpt", "reward_event_id": "should-not-proxy"},
    )

    assert claim.status_code == 404, claim.text
    assert claim.json()["detail"] == "Rewarded ads are not enabled on the public gateway yet."

    # The blocked claim must not proxy to the controller.
    assert not any(call["path"] == "/system/ads/reward/claim" for call in calls), calls

finally:
    public_gateway._system_v2_fetch_json = original_fetch_json

    for key, value in original_env.items():
        if value is None:
            os.environ.pop(key, None)
        else:
            os.environ[key] = value

print("PASS: rewarded-ad deployment config is safe for pending approval")
PY
