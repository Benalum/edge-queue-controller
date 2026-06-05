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


def ad_reward_counts(conn, user_id: int):
    daily = conn.execute(
        """
        SELECT COUNT(*) AS c
        FROM ad_reward_events
        WHERE user_id = ?
          AND created_at >= datetime('now', 'start of day')
        """,
        (user_id,),
    ).fetchone()["c"]

    monthly = conn.execute(
        """
        SELECT COUNT(*) AS c
        FROM ad_reward_events
        WHERE user_id = ?
          AND created_at >= datetime('now', 'start of month')
        """,
        (user_id,),
    ).fetchone()["c"]

    last = conn.execute(
        """
        SELECT created_at
        FROM ad_reward_events
        WHERE user_id = ?
        ORDER BY created_at DESC
        LIMIT 1
        """,
        (user_id,),
    ).fetchone()

    return int(daily or 0), int(monthly or 0), last["created_at"] if last else None
