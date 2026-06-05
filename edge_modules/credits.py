from __future__ import annotations

import sqlite3

from fastapi import HTTPException


def credit_pool_active_reserved_totals(conn, user_id: int):
    row = conn.execute(
        """
        SELECT
            COALESCE(SUM(free_amount), 0) AS free_reserved,
            COALESCE(SUM(paid_amount), 0) AS paid_reserved
        FROM credit_reservations
        WHERE user_id = ?
          AND status = 'reserved'
        """,
        (user_id,),
    ).fetchone()

    if not row:
        return 0, 0

    return int(row["free_reserved"] or 0), int(row["paid_reserved"] or 0)


def credit_pool_sync_legacy_total(conn, user_id: int, now_iso):
    row = conn.execute(
        """
        SELECT free_credit_balance, paid_credit_balance
        FROM app_users
        WHERE id = ?
        """,
        (user_id,),
    ).fetchone()

    if not row:
        return

    total = int(row["free_credit_balance"] or 0) + int(row["paid_credit_balance"] or 0)

    conn.execute(
        """
        UPDATE app_users
        SET credit_balance = ?,
            updated_at = ?
        WHERE id = ?
        """,
        (total, now_iso(), user_id),
    )


def credit_pool_add_ledger(
    conn,
    user_id: int,
    free_delta: int,
    paid_delta: int,
    reason: str,
    service_class: str,
    metadata,
    now_iso,
    credit_json_dumps,
):
    total_delta = int(free_delta) + int(paid_delta)
    now = now_iso()

    conn.execute(
        """
        INSERT INTO user_credit_ledger (
            user_id,
            delta,
            free_delta,
            paid_delta,
            reason,
            service_class,
            metadata_json,
            created_at
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            user_id,
            total_delta,
            int(free_delta),
            int(paid_delta),
            str(reason),
            str(service_class),
            credit_json_dumps(metadata),
            now,
        ),
    )


def credit_pool_find_reservation(conn, user_id: int, payload):
    reservation_id = payload.get("reservation_id")
    reservation_token = payload.get("reservation_token")

    if reservation_id:
        row = conn.execute(
            """
            SELECT *
            FROM credit_reservations
            WHERE id = ?
              AND user_id = ?
            """,
            (int(reservation_id), user_id),
        ).fetchone()
    elif reservation_token:
        row = conn.execute(
            """
            SELECT *
            FROM credit_reservations
            WHERE reservation_token = ?
              AND user_id = ?
            """,
            (str(reservation_token), user_id),
        ).fetchone()
    else:
        raise HTTPException(status_code=400, detail="reservation_id or reservation_token is required.")

    if not row:
        raise HTTPException(status_code=404, detail="Reservation not found.")

    return row




def credit_pool_grant_free_to_user_on_conn(
    conn,
    *,
    user_id: int,
    amount: int,
    reason: str,
    metadata,
    now_iso,
    credit_json_dumps,
):
    now = now_iso()

    conn.execute(
        """
        UPDATE app_users
        SET free_credit_balance = free_credit_balance + ?,
            updated_at = ?
        WHERE id = ?
        """,
        (int(amount), now, int(user_id)),
    )

    credit_pool_add_ledger(
        conn,
        int(user_id),
        int(amount),
        0,
        str(reason),
        "local",
        metadata,
        now_iso=now_iso,
        credit_json_dumps=credit_json_dumps,
    )

    credit_pool_sync_legacy_total(conn, int(user_id), now_iso=now_iso)


def credit_pool_grant_free_to_email(
    *,
    db_path,
    email: str,
    amount: int,
    reason: str,
    admin_user_id: int,
    admin_email: str,
    metadata,
    now_iso,
    credit_json_dumps,
):
    now = now_iso()

    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        target = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE email = ?
            """,
            (email,),
        ).fetchone()

        if not target:
            raise HTTPException(status_code=404, detail="Target user not found.")

        target_id = int(target["id"])

        conn.execute(
            """
            UPDATE app_users
            SET free_credit_balance = free_credit_balance + ?,
                updated_at = ?
            WHERE id = ?
            """,
            (amount, now, target_id),
        )

        credit_pool_add_ledger(
            conn,
            target_id,
            amount,
            0,
            f"grant_free:{reason}",
            "local",
            {
                "admin_user_id": admin_user_id,
                "admin_email": admin_email,
                "metadata": metadata,
            },
            now_iso=now_iso,
            credit_json_dumps=credit_json_dumps,
        )

        credit_pool_sync_legacy_total(conn, target_id, now_iso=now_iso)
        conn.commit()

    return target_id


def credit_pool_grant_paid_to_email(
    *,
    db_path,
    email: str,
    amount: int,
    reason: str,
    admin_user_id: int,
    admin_email: str,
    metadata,
    now_iso,
    credit_json_dumps,
):
    now = now_iso()

    with sqlite3.connect(db_path) as conn:
        conn.row_factory = sqlite3.Row
        conn.execute("BEGIN IMMEDIATE")

        target = conn.execute(
            """
            SELECT *
            FROM app_users
            WHERE email = ?
            """,
            (email,),
        ).fetchone()

        if not target:
            raise HTTPException(status_code=404, detail="Target user not found.")

        target_id = int(target["id"])

        conn.execute(
            """
            UPDATE app_users
            SET paid_credit_balance = paid_credit_balance + ?,
                updated_at = ?
            WHERE id = ?
            """,
            (amount, now, target_id),
        )

        credit_pool_add_ledger(
            conn,
            target_id,
            0,
            amount,
            f"grant_paid:{reason}",
            "external_paid",
            {
                "admin_user_id": admin_user_id,
                "admin_email": admin_email,
                "metadata": metadata,
            },
            now_iso=now_iso,
            credit_json_dumps=credit_json_dumps,
        )

        credit_pool_sync_legacy_total(conn, target_id, now_iso=now_iso)
        conn.commit()

    return target_id

