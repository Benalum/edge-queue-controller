#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import os
import sqlite3
import tempfile
from pathlib import Path

import edge_controller


def insert_ad_event(conn, *, user_id, status, created_at, reward_event_id):
    columns = []
    values = []

    table_info = conn.execute("PRAGMA table_info(ad_reward_events)").fetchall()

    for col in table_info:
        name = col["name"]
        pk = int(col["pk"] or 0)
        default = col["dflt_value"]
        notnull = int(col["notnull"] or 0)

        if pk and name == "id":
            continue

        if name == "user_id":
            value = user_id
        elif name == "provider":
            value = "test_provider"
        elif name == "reward_event_id":
            value = reward_event_id
        elif name == "status":
            value = status
        elif name == "reward_credits":
            value = 5
        elif name == "credit_pool":
            value = "free"
        elif name == "ip_hash":
            value = "ip_hash_test"
        elif name == "user_agent_hash":
            value = "ua_hash_test"
        elif name == "created_at":
            value = created_at
        elif name == "updated_at":
            value = created_at
        elif name == "metadata_json":
            value = "{}"
        elif notnull and default is None:
            value = ""
        else:
            continue

        columns.append(name)
        values.append(value)

    placeholders = ", ".join(["?"] * len(columns))
    sql = f"INSERT INTO ad_reward_events ({', '.join(columns)}) VALUES ({placeholders})"
    conn.execute(sql, values)


with tempfile.TemporaryDirectory() as tmp:
    db_path = str(Path(tmp) / "reward-status-test.sqlite3")

    old_db_path = edge_controller.DB_PATH
    old_auth_now = edge_controller._auth_now_iso

    old_env = {
        key: os.environ.get(key)
        for key in [
            "AD_REWARD_FREE_CREDITS",
            "AD_REWARD_DAILY_LIMIT",
            "AD_REWARD_MONTHLY_LIMIT",
            "AD_REWARD_COOLDOWN_SECONDS",
            "AD_REWARD_MOCK_ENABLED",
            "AD_REWARD_PROVIDER_VERIFICATION_ENABLED",
        ]
    }

    try:
        edge_controller.DB_PATH = db_path
        edge_controller._auth_now_iso = lambda: "2026-06-05T12:00:00+00:00"

        # Build the base controller schema first. _ad_reward_init_tables()
        # depends on account/auth init, and auth init expects the jobs table
        # created by init_db().
        edge_controller.init_db()

        os.environ["AD_REWARD_FREE_CREDITS"] = "5"
        os.environ["AD_REWARD_DAILY_LIMIT"] = "5"
        os.environ["AD_REWARD_MONTHLY_LIMIT"] = "100"
        os.environ["AD_REWARD_COOLDOWN_SECONDS"] = "300"
        os.environ["AD_REWARD_MOCK_ENABLED"] = "true"
        os.environ["AD_REWARD_PROVIDER_VERIFICATION_ENABLED"] = "false"

        edge_controller._ad_reward_init_tables()

        def reward_status(user_id: int):
            return edge_controller._ad_reward_status_for_user(
                user_id,
                db_path=edge_controller.DB_PATH,
                init_tables=edge_controller._ad_reward_init_tables,
                now_iso=edge_controller._auth_now_iso,
            )

        # No prior claims: should be available.
        status = reward_status(1)

        assert status["ok"] is True
        assert status["can_claim"] is True
        assert status["blocked_reason"] is None
        assert status["reward_credits"] == 5
        assert status["credit_pool"] == "free"
        assert status["credit_rule"] == "Ad rewards grant free/local credits only."
        assert status["mock_enabled"] is True
        assert status["provider_verification_enabled"] is False
        assert status["daily"] == {"used": 0, "limit": 5}
        assert status["monthly"] == {"used": 0, "limit": 100}
        assert status["cooldown"]["seconds"] == 300
        assert status["cooldown"]["remaining_seconds"] == 0
        assert status["cooldown"]["last_claim_at"] is None

        # Rejected event should not count.
        with sqlite3.connect(db_path) as conn:
            conn.row_factory = sqlite3.Row
            insert_ad_event(
                conn,
                user_id=1,
                status="rejected",
                created_at="2026-06-05T11:00:00+00:00",
                reward_event_id="rejected-1",
            )
            conn.commit()

        status = reward_status(1)
        assert status["can_claim"] is True
        assert status["daily"]["used"] == 0
        assert status["monthly"]["used"] == 0

        # Granted event inside cooldown should block.
        with sqlite3.connect(db_path) as conn:
            conn.row_factory = sqlite3.Row
            insert_ad_event(
                conn,
                user_id=1,
                status="granted",
                created_at="2026-06-05T11:59:30+00:00",
                reward_event_id="granted-1",
            )
            conn.commit()

        status = reward_status(1)
        assert status["can_claim"] is False
        assert status["daily"]["used"] == 1
        assert status["monthly"]["used"] == 1
        assert status["cooldown"]["last_claim_at"] == "2026-06-05T11:59:30+00:00"
        assert status["cooldown"]["remaining_seconds"] == 270
        assert status["blocked_reason"] == "Reward cooldown active. Try again in 270 seconds."

        # With cooldown disabled and daily limit reached, should show daily limit.
        os.environ["AD_REWARD_COOLDOWN_SECONDS"] = "0"
        os.environ["AD_REWARD_DAILY_LIMIT"] = "1"

        status = reward_status(1)
        assert status["can_claim"] is False
        assert status["daily"] == {"used": 1, "limit": 1}
        assert status["blocked_reason"] == "Daily rewarded-ad limit reached."

        print("PASS: rewarded ad status behavior matches expected output")

    finally:
        edge_controller.DB_PATH = old_db_path
        edge_controller._auth_now_iso = old_auth_now

        for key, value in old_env.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
PY
