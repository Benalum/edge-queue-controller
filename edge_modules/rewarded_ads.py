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

