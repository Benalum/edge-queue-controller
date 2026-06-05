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
    def __init__(self, payload=None):
        self._payload = payload or {}
        self.headers = {"user-agent": "credit-pool-lifecycle-smoke"}
        self.client = SimpleNamespace(host="127.0.0.1")

    async def json(self):
        return self._payload


def insert_test_user(conn, user_id=1, email="credit-pool-smoke@example.local"):
    table_info = conn.execute("PRAGMA table_info(app_users)").fetchall()
    columns = []
    values = []
    now = "2026-06-05T12:00:00+00:00"

    explicit = {
        "id": user_id,
        "email": email,
        "password_hash": "not-used",
        "display_name": None,
        "status": "active",
        "role": "admin",
        "is_admin": 1,
        "plan": "pro",
        "billing_status": "active",
        "credit_balance": 15,
        "free_credit_balance": 10,
        "paid_credit_balance": 5,
        "monthly_credit_allowance": 0,
        "monthly_free_credit_allowance": 0,
        "monthly_paid_credit_allowance": 0,
        "storage_quota_mb": 0,
        "created_at": now,
        "updated_at": now,
        "last_login_at": now,
    }

    for col in table_info:
        name = col["name"]
        col_type = str(col["type"] or "").upper()
        pk = int(col["pk"] or 0)
        default = col["dflt_value"]
        notnull = int(col["notnull"] or 0)

        if name in explicit:
            columns.append(name)
            values.append(explicit[name])
            continue

        if pk:
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
    conn.execute(
        f"INSERT INTO app_users ({', '.join(columns)}) VALUES ({placeholders})",
        values,
    )
    conn.commit()


def balances(conn, user_id=1):
    row = conn.execute(
        """
        SELECT credit_balance, free_credit_balance, paid_credit_balance
        FROM app_users
        WHERE id = ?
        """,
        (user_id,),
    ).fetchone()
    return (
        int(row["credit_balance"]),
        int(row["free_credit_balance"]),
        int(row["paid_credit_balance"]),
    )


async def expect_http(status_code, coro):
    try:
        await coro
    except HTTPException as e:
        assert e.status_code == status_code, (e.status_code, e.detail)
        return str(e.detail)
    raise AssertionError(f"Expected HTTPException {status_code}")


async def main():
    original_db_path = edge_controller.DB_PATH
    original_now_iso = edge_controller._auth_now_iso
    original_auth_current_user = edge_controller._auth_current_user_from_request

    try:
        with tempfile.TemporaryDirectory() as tmp:
            edge_controller.DB_PATH = Path(tmp) / "credit-pool-lifecycle.sqlite3"
            edge_controller._auth_now_iso = lambda: "2026-06-05T12:00:00+00:00"
            edge_controller._auth_current_user_from_request = lambda request: {"id": 1}

            edge_controller.init_db()
            edge_controller._credit_pool_init_tables()

            with sqlite3.connect(edge_controller.DB_PATH) as conn:
                conn.row_factory = sqlite3.Row
                insert_test_user(conn)

            # Grant free credits.
            grant_free = await edge_controller.system_credits_grant_free(
                FakeRequest({
                    "email": "credit-pool-smoke@example.local",
                    "amount": 3,
                    "reason": "smoke_free",
                    "metadata": {"smoke": True},
                })
            )
            assert grant_free["credits"]["free_available"] == 13
            assert grant_free["credits"]["paid_available"] == 5
            assert grant_free["credits"]["total_available"] == 18

            # Grant paid credits.
            grant_paid = await edge_controller.system_credits_grant_paid(
                FakeRequest({
                    "email": "credit-pool-smoke@example.local",
                    "amount": 7,
                    "reason": "smoke_paid",
                    "metadata": {"smoke": True},
                })
            )
            assert grant_paid["credits"]["free_available"] == 13
            assert grant_paid["credits"]["paid_available"] == 12
            assert grant_paid["credits"]["total_available"] == 25

            with sqlite3.connect(edge_controller.DB_PATH) as conn:
                conn.row_factory = sqlite3.Row
                assert balances(conn) == (25, 13, 12)

            # Local reserve should use free first, then paid if allowed.
            local_reserve = await edge_controller.system_credits_reserve_v2(
                FakeRequest({
                    "amount": 15,
                    "reason": "local_smoke",
                    "service_class": "local",
                    "allow_paid_for_local": True,
                    "metadata": {"kind": "local"},
                })
            )
            local_token = local_reserve["reservation"]["reservation_token"]
            assert local_reserve["reservation"]["free_amount"] == 13
            assert local_reserve["reservation"]["paid_amount"] == 2
            assert local_reserve["credits"]["free_available"] == 0
            assert local_reserve["credits"]["paid_available"] == 10
            assert local_reserve["credits"]["total_available"] == 10

            with sqlite3.connect(edge_controller.DB_PATH) as conn:
                conn.row_factory = sqlite3.Row
                assert balances(conn) == (10, 0, 10)

            # Refund restores both pools.
            refunded = await edge_controller.system_credits_refund_v2(
                FakeRequest({
                    "reservation_token": local_token,
                    "metadata": {"refund": True},
                })
            )
            assert refunded["credits"]["free_available"] == 13
            assert refunded["credits"]["paid_available"] == 12
            assert refunded["credits"]["total_available"] == 25

            with sqlite3.connect(edge_controller.DB_PATH) as conn:
                conn.row_factory = sqlite3.Row
                assert balances(conn) == (25, 13, 12)

            # External paid reserve must use paid only.
            external_reserve = await edge_controller.system_credits_reserve_v2(
                FakeRequest({
                    "amount": 4,
                    "reason": "external_smoke",
                    "service_class": "external_paid",
                    "metadata": {"kind": "external"},
                })
            )
            external_token = external_reserve["reservation"]["reservation_token"]
            assert external_reserve["reservation"]["free_amount"] == 0
            assert external_reserve["reservation"]["paid_amount"] == 4
            assert external_reserve["credits"]["free_available"] == 13
            assert external_reserve["credits"]["paid_available"] == 8
            assert external_reserve["credits"]["total_available"] == 21

            committed = await edge_controller.system_credits_commit_v2(
                FakeRequest({
                    "reservation_token": external_token,
                    "metadata": {"commit": True},
                })
            )
            assert committed["credits"]["free_available"] == 13
            assert committed["credits"]["paid_available"] == 8
            assert committed["credits"]["total_available"] == 21

            with sqlite3.connect(edge_controller.DB_PATH) as conn:
                conn.row_factory = sqlite3.Row
                assert balances(conn) == (21, 13, 8)

            # Local with paid disallowed should fail if free is insufficient.
            detail = await expect_http(
                402,
                edge_controller.system_credits_reserve_v2(
                    FakeRequest({
                        "amount": 14,
                        "reason": "free_only_fail",
                        "service_class": "local",
                        "allow_paid_for_local": False,
                    })
                ),
            )
            assert "Insufficient free/local credits" in detail

            # External paid should fail if paid is insufficient.
            detail = await expect_http(
                402,
                edge_controller.system_credits_reserve_v2(
                    FakeRequest({
                        "amount": 99,
                        "reason": "paid_fail",
                        "service_class": "external_paid",
                    })
                ),
            )
            assert "Insufficient paid credits" in detail

    finally:
        edge_controller.DB_PATH = original_db_path
        edge_controller._auth_now_iso = original_now_iso
        edge_controller._auth_current_user_from_request = original_auth_current_user

    print("PASS: credit pool lifecycle behavior matches expected rules")


asyncio.run(main())
PY
