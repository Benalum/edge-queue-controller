from __future__ import annotations

import os

from edge_modules.credit_helpers import ad_iso_to_epoch


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


def ad_reward_counts(conn, user_id: int, now_iso: str):
    day_prefix = now_iso[:10]
    month_prefix = now_iso[:7]

    daily = conn.execute(
        """
        SELECT COUNT(*) AS count
        FROM ad_reward_events
        WHERE user_id = ?
          AND status = 'granted'
          AND created_at LIKE ?
        """,
        (user_id, f"{day_prefix}%"),
    ).fetchone()["count"]

    monthly = conn.execute(
        """
        SELECT COUNT(*) AS count
        FROM ad_reward_events
        WHERE user_id = ?
          AND status = 'granted'
          AND created_at LIKE ?
        """,
        (user_id, f"{month_prefix}%"),
    ).fetchone()["count"]

    last = conn.execute(
        """
        SELECT created_at
        FROM ad_reward_events
        WHERE user_id = ?
          AND status = 'granted'
        ORDER BY id DESC
        LIMIT 1
        """,
        (user_id,),
    ).fetchone()

    return int(daily or 0), int(monthly or 0), last["created_at"] if last else None



def ad_reward_status_for_user(user_id: int, *, db_path: str, init_tables, now_iso):
    import os
    import sqlite3

    init_tables()
    settings = ad_reward_settings()
    now = now_iso()

    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        daily, monthly, last_claim_at = ad_reward_counts(conn, user_id, now_iso())

    cooldown_remaining = 0
    if last_claim_at:
        elapsed = max(0, int(ad_iso_to_epoch(now) - ad_iso_to_epoch(last_claim_at)))
        cooldown_remaining = max(0, settings["cooldown_seconds"] - elapsed)

    can_claim = True
    blocked_reason = None

    if daily >= settings["daily_limit"]:
        can_claim = False
        blocked_reason = "Daily rewarded-ad limit reached."
    elif monthly >= settings["monthly_limit"]:
        can_claim = False
        blocked_reason = "Monthly rewarded-ad limit reached."
    elif cooldown_remaining > 0:
        can_claim = False
        blocked_reason = f"Reward cooldown active. Try again in {cooldown_remaining} seconds."

    return {
        "ok": True,
        "can_claim": can_claim,
        "blocked_reason": blocked_reason,
        "reward_credits": settings["reward_credits"],
        "credit_pool": "free",
        "credit_rule": "Ad rewards grant free/local credits only.",
        "mock_enabled": str(os.getenv("AD_REWARD_MOCK_ENABLED", "false")).strip().lower() in ("1", "true", "yes", "on"),
        "provider_verification_enabled": str(os.getenv("AD_REWARD_PROVIDER_VERIFICATION_ENABLED", "false")).strip().lower() in ("1", "true", "yes", "on"),
        "daily": {
            "used": daily,
            "limit": settings["daily_limit"],
        },
        "monthly": {
            "used": monthly,
            "limit": settings["monthly_limit"],
        },
        "cooldown": {
            "seconds": settings["cooldown_seconds"],
            "remaining_seconds": cooldown_remaining,
            "last_claim_at": last_claim_at,
        },
    }
