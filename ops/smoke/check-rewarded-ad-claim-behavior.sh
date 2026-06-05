#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import asyncio
import os
import sqlite3
import tempfile
from pathlib import Path
from types import SimpleNamespace

from fastapi import HTTPException

import edge_controller


class FakeRequest:
    def __init__(self, payload):
        self._payload = payload
        self.headers = {
            "user-agent": "reward-claim-smoke-test",
            "x-forwarded-for": "127.0.0.1",
        }
        self.client = SimpleNamespace(host="127.0.0.1")

    async def json(self):
        return self._payload


def insert_test_user(conn, user_id=1, email="reward-claim-smoke@example.local"):
    table_info = conn.execute("PRAGMA table_info(app_users)").fetchall()
    columns = []
    values = []

    now = "2026-06-05T12:00:00+00:00"

    for col in table_info:
        name = col["name"]
        col_type = str(col["type"] or "").upper()
        pk = int(col["pk"] or 0)
        default = col["dflt_value"]
        notnull = int(col["notnull"] or 0)

        # Include explicit id so the monkeypatched auth row points to a real user.
        if pk and name == "id":
            columns.append(name)
            values.append(user_id)
            continue

        # Omit nullable/defaulted columns unless we want explicit known balances.
        explicit = {
            "email": email,
            "password_hash": "not-used",
            "display_name": None,
            "status": "active",
            "role": "admin",
            "is_admin": 1,
            "plan": "pro",
            "billing_status": "active",
            "credit_balance": 0,
            "free_credit_balance": 0,
            "paid_credit_balance": 9,
            "monthly_credit_allowance": 0,
            "monthly_free_allowance": 0,
            "monthly_paid_allowance": 0,
            "storage_quota_mb": 0,
            "created_at": now,
            "updated_at": now,
            "last_login_at": now,
        }

        if name in explicit:
            columns.append(name)
            values.append(explicit[name])
            continue

        if default is not None and not notnull:
            continue

        if notnull and default is None:
            columns.append(name)
            if "INT" in col_type or "REAL" in col_type or "NUM" in col_type:
                values.append(0)
            else:
                values.append(now)

    placeholders = ", ".join(["?"] * len(columns))
    column_sql = ", ".join(columns)

    conn.execute(
        f"INSERT INTO app_users ({column_sql}) VALUES ({placeholders})",
        values,
    )
    conn.commit()


def user_balances(conn, user_id=1):
    row = conn.execute(
        "SELECT free_credit_balance, paid_credit_balance FROM app_users WHERE id = ?",
        (user_id,),
    ).fetchone()
    return int(row["free_credit_balance"]), int(row["paid_credit_balance"])


async def run_claim(payload):
    return await edge_controller.system_ads_reward_claim(FakeRequest(payload))


async def expect_http(status_code, payload):
    try:
        await run_claim(payload)
    except HTTPException as e:
        assert e.status_code == status_code, (e.status_code, e.detail)
        return str(e.detail)
    raise AssertionError(f"Expected HTTPException {status_code}")


async def scenario_mock_disabled_blocks():
    with tempfile.TemporaryDirectory() as tmp:
        edge_controller.DB_PATH = Path(tmp) / "reward-claim.sqlite3"
        edge_controller._auth_now_iso = lambda: "2026-06-05T12:00:00+00:00"

        edge_controller.init_db()
        edge_controller._ad_reward_init_tables()

        with sqlite3.connect(edge_controller.DB_PATH) as conn:
            conn.row_factory = sqlite3.Row
            insert_test_user(conn)

        edge_controller._credit_pool_user_row = lambda request: {"id": 1}

        os.environ["AD_REWARD_MOCK_ENABLED"] = "false"
        os.environ["AD_REWARD_FREE_CREDITS"] = "5"
        os.environ["AD_REWARD_DAILY_LIMIT"] = "5"
        os.environ["AD_REWARD_MONTHLY_LIMIT"] = "100"
        os.environ["AD_REWARD_COOLDOWN_SECONDS"] = "30"

        detail = await expect_http(
            403,
            {"provider": "mock_rewarded_ad", "reward_event_id": "disabled-1"},
        )
        assert "Mock rewarded ads are disabled" in detail


async def scenario_grant_duplicate_and_cooldown():
    with tempfile.TemporaryDirectory() as tmp:
        edge_controller.DB_PATH = Path(tmp) / "reward-claim.sqlite3"
        now = ["2026-06-05T12:00:00+00:00"]
        edge_controller._auth_now_iso = lambda: now[0]

        edge_controller.init_db()
        edge_controller._ad_reward_init_tables()

        with sqlite3.connect(edge_controller.DB_PATH) as conn:
            conn.row_factory = sqlite3.Row
            insert_test_user(conn)

        edge_controller._credit_pool_user_row = lambda request: {"id": 1}

        os.environ["AD_REWARD_MOCK_ENABLED"] = "true"
        os.environ["AD_REWARD_FREE_CREDITS"] = "5"
        os.environ["AD_REWARD_DAILY_LIMIT"] = "5"
        os.environ["AD_REWARD_MONTHLY_LIMIT"] = "100"
        os.environ["AD_REWARD_COOLDOWN_SECONDS"] = "30"

        result = await run_claim(
            {
                "provider": "mock_rewarded_ad",
                "reward_event_id": "grant-1",
                "metadata": {"smoke": True},
            }
        )

        assert result["ad_reward"]["ok"] is True
        assert result["ad_reward"]["credits_granted"] == 5
        assert result["ad_reward"]["credit_pool"] == "free"

        with sqlite3.connect(edge_controller.DB_PATH) as conn:
            conn.row_factory = sqlite3.Row
            free, paid = user_balances(conn)
            assert free == 5, free
            assert paid == 9, paid

        duplicate = await run_claim(
            {
                "provider": "mock_rewarded_ad",
                "reward_event_id": "grant-1",
            }
        )

        assert duplicate["ad_reward"]["duplicate"] is True
        assert duplicate["ad_reward"]["credits_granted"] == 0

        with sqlite3.connect(edge_controller.DB_PATH) as conn:
            conn.row_factory = sqlite3.Row
            free, paid = user_balances(conn)
            assert free == 5, free
            assert paid == 9, paid

        detail = await expect_http(
            429,
            {
                "provider": "mock_rewarded_ad",
                "reward_event_id": "grant-2",
            },
        )
        assert "Reward cooldown active" in detail


async def scenario_daily_limit_blocks():
    with tempfile.TemporaryDirectory() as tmp:
        edge_controller.DB_PATH = Path(tmp) / "reward-claim.sqlite3"
        now = ["2026-06-05T12:00:00+00:00"]
        edge_controller._auth_now_iso = lambda: now[0]

        edge_controller.init_db()
        edge_controller._ad_reward_init_tables()

        with sqlite3.connect(edge_controller.DB_PATH) as conn:
            conn.row_factory = sqlite3.Row
            insert_test_user(conn)

        edge_controller._credit_pool_user_row = lambda request: {"id": 1}

        os.environ["AD_REWARD_MOCK_ENABLED"] = "true"
        os.environ["AD_REWARD_FREE_CREDITS"] = "5"
        os.environ["AD_REWARD_DAILY_LIMIT"] = "1"
        os.environ["AD_REWARD_MONTHLY_LIMIT"] = "100"
        os.environ["AD_REWARD_COOLDOWN_SECONDS"] = "0"

        await run_claim(
            {
                "provider": "mock_rewarded_ad",
                "reward_event_id": "daily-1",
            }
        )

        detail = await expect_http(
            429,
            {
                "provider": "mock_rewarded_ad",
                "reward_event_id": "daily-2",
            },
        )
        assert detail == "Daily rewarded-ad limit reached."


async def main():
    original_db_path = edge_controller.DB_PATH
    original_now_iso = edge_controller._auth_now_iso
    original_credit_pool_user_row = edge_controller._credit_pool_user_row
    original_env = {k: os.environ.get(k) for k in [
        "AD_REWARD_MOCK_ENABLED",
        "AD_REWARD_FREE_CREDITS",
        "AD_REWARD_DAILY_LIMIT",
        "AD_REWARD_MONTHLY_LIMIT",
        "AD_REWARD_COOLDOWN_SECONDS",
    ]}

    try:
        await scenario_mock_disabled_blocks()
        await scenario_grant_duplicate_and_cooldown()
        await scenario_daily_limit_blocks()
    finally:
        edge_controller.DB_PATH = original_db_path
        edge_controller._auth_now_iso = original_now_iso
        edge_controller._credit_pool_user_row = original_credit_pool_user_row

        for key, value in original_env.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value

    print("PASS: rewarded ad claim behavior matches expected credit rules")


asyncio.run(main())
PY
