from __future__ import annotations

import os
import secrets
import sqlite3

from fastapi import HTTPException

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



def ad_reward_init_tables(db_path: str, credit_pool_init_tables):
    credit_pool_init_tables()

    with sqlite3.connect(db_path) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS ad_reward_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                provider TEXT NOT NULL,
                reward_event_id TEXT,
                status TEXT NOT NULL DEFAULT 'granted',
                credits_granted INTEGER NOT NULL DEFAULT 0,
                credit_pool TEXT NOT NULL DEFAULT 'free',
                ip_hash TEXT,
                user_agent_hash TEXT,
                metadata_json TEXT,
                created_at TEXT NOT NULL,
                UNIQUE(provider, reward_event_id),
                FOREIGN KEY(user_id) REFERENCES app_users(id)
            )
            """
        )
        conn.commit()

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


def parse_reward_claim_payload(payload):
    if not isinstance(payload, dict):
        payload = {}

    provider = str(payload.get("provider") or "mock_rewarded_ad").strip()[:80]
    reward_event_id = str(payload.get("reward_event_id") or secrets.token_urlsafe(24)).strip()
    metadata = payload.get("metadata") or {}

    return provider, reward_event_id, metadata


def ad_reward_claim_for_user(
    *,
    request,
    payload,
    user_id: int,
    db_path,
    now_iso,
    init_tables,
    credit_pool_summary,
    credit_pool_grant_free_to_user,
    ad_hash,
    credit_json_dumps,
):
    provider, reward_event_id, metadata = parse_reward_claim_payload(payload)

    mock_enabled = str(os.getenv("AD_REWARD_MOCK_ENABLED", "false")).strip().lower() in ("1", "true", "yes", "on")
    if provider == "mock_rewarded_ad" and not mock_enabled:
        raise HTTPException(
            status_code=403,
            detail="Mock rewarded ads are disabled. Real provider verification is required.",
        )

    settings = ad_reward_settings()
    credits = int(settings["reward_credits"])
    now = now_iso()

    init_tables()

    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        existing = conn.execute(
            """
            SELECT *
            FROM ad_reward_events
            WHERE provider = ?
              AND reward_event_id = ?
            """,
            (provider, reward_event_id),
        ).fetchone()

        if existing:
            conn.commit()
            summary = credit_pool_summary(user_id)
            summary["ad_reward"] = {
                "ok": True,
                "duplicate": True,
                "credits_granted": 0,
                "detail": "Reward event was already claimed.",
            }
            summary["reward_status"] = ad_reward_status_for_user(
                user_id,
                db_path=db_path,
                init_tables=init_tables,
                now_iso=now_iso,
            )
            return summary

        daily, monthly, last_claim_at = ad_reward_counts(conn, user_id, now_iso())
        now_epoch = ad_iso_to_epoch(now)

        cooldown_remaining = 0
        if last_claim_at:
            elapsed = max(0, now_epoch - ad_iso_to_epoch(last_claim_at))
            cooldown_remaining = max(0, int(settings["cooldown_seconds"] - elapsed))

        if daily >= settings["daily_limit"]:
            raise HTTPException(status_code=429, detail="Daily rewarded-ad limit reached.")

        if monthly >= settings["monthly_limit"]:
            raise HTTPException(status_code=429, detail="Monthly rewarded-ad limit reached.")

        if cooldown_remaining > 0:
            raise HTTPException(
                status_code=429,
                detail=f"Reward cooldown active. Try again in {cooldown_remaining} seconds.",
            )

        conn.execute(
            """
            INSERT INTO ad_reward_events (
                user_id,
                provider,
                reward_event_id,
                status,
                credits_granted,
                credit_pool,
                ip_hash,
                user_agent_hash,
                metadata_json,
                created_at
            )
            VALUES (?, ?, ?, 'granted', ?, 'free', ?, ?, ?, ?)
            """,
            (
                user_id,
                provider,
                reward_event_id,
                credits,
                ad_hash(ad_request_ip(request)),
                ad_hash(request.headers.get("user-agent", "")),
                credit_json_dumps(metadata),
                now,
            ),
        )

        credit_pool_grant_free_to_user(
            conn,
            user_id=user_id,
            amount=credits,
            reason=f"ad_reward:{provider}",
            metadata={
                "provider": provider,
                "reward_event_id": reward_event_id,
                "credit_pool": "free",
                "metadata": metadata,
            },
            now_iso=now_iso,
            credit_json_dumps=credit_json_dumps,
        )

        conn.commit()

    summary = credit_pool_summary(user_id)
    summary["ad_reward"] = {
        "ok": True,
        "duplicate": False,
        "provider": provider,
        "credits_granted": credits,
        "credit_pool": "free",
        "detail": "Reward granted as free/local credits.",
    }
    summary["reward_status"] = ad_reward_status_for_user(
        user_id,
        db_path=db_path,
        init_tables=init_tables,
        now_iso=now_iso,
    )
    return summary

