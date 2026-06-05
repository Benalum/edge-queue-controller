#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import sqlite3

from fastapi import HTTPException

from edge_modules.credit_helpers import (
    credit_json_dumps,
    parse_payload_amount,
    credit_pool_debit_plan,
)
from edge_modules.rewarded_ads import ad_reward_counts


assert credit_json_dumps(None) is None
assert credit_json_dumps({"b": 2, "a": 1}) == '{"a": 1, "b": 2}'

try:
    parse_payload_amount({"amount": "abc"})
    raise SystemExit("parse_payload_amount invalid integer did not raise")
except HTTPException as e:
    assert e.status_code == 400
    assert "integer" in e.detail

try:
    parse_payload_amount({"amount": 0})
    raise SystemExit("parse_payload_amount too-small value did not raise")
except HTTPException as e:
    assert e.status_code == 400
    assert "at least" in e.detail

assert credit_pool_debit_plan(10, 5, 12, "local") == (10, 2)
assert credit_pool_debit_plan(10, 5, 5, "external_paid") == (0, 5)

try:
    credit_pool_debit_plan(10, 1, 12, "local")
    raise SystemExit("insufficient local credits did not raise")
except HTTPException as e:
    assert e.status_code == 402

try:
    credit_pool_debit_plan(0, 1, 2, "external_paid")
    raise SystemExit("insufficient paid credits did not raise")
except HTTPException as e:
    assert e.status_code == 402


conn = sqlite3.connect(":memory:")
conn.row_factory = sqlite3.Row
conn.execute("""
CREATE TABLE ad_reward_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL
)
""")

rows = [
    (1, "granted", "2026-06-05T10:00:00+00:00"),
    (1, "rejected", "2026-06-05T11:00:00+00:00"),
    (1, "granted", "2026-06-04T10:00:00+00:00"),
    (1, "granted", "2026-05-31T10:00:00+00:00"),
    (2, "granted", "2026-06-05T10:00:00+00:00"),
]

for user_id, status, created_at in rows:
    conn.execute(
        "INSERT INTO ad_reward_events (user_id, status, created_at) VALUES (?, ?, ?)",
        (user_id, status, created_at),
    )

daily, monthly, last = ad_reward_counts(conn, 1, "2026-06-05T12:00:00+00:00")

assert daily == 1, daily
assert monthly == 2, monthly

# Preserve original behavior: last claim is ORDER BY id DESC, not newest created_at.
assert last == "2026-05-31T10:00:00+00:00", last

print("PASS: extracted helper behavior matches expected legacy behavior")
PY
