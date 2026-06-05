from __future__ import annotations

import os


def ad_reward_settings():
    return {
        "reward_credits": int(os.getenv("AD_REWARD_FREE_CREDITS", "5")),
        "daily_limit": int(os.getenv("AD_REWARD_DAILY_LIMIT", "5")),
        "monthly_limit": int(os.getenv("AD_REWARD_MONTHLY_LIMIT", "100")),
        "cooldown_seconds": int(os.getenv("AD_REWARD_COOLDOWN_SECONDS", "300")),
    }


def ad_request_ip(request):
    forwarded = request.headers.get("x-forwarded-for", "")
    if forwarded:
        return forwarded.split(",")[0].strip()
    client = getattr(request, "client", None)
    return getattr(client, "host", "") or ""
