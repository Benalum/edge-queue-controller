#!/usr/bin/env bash

stage5p11o_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-11O Cumulative Study Totals Smoke ==="

  echo
  echo "=== syntax checks ==="
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P11O_CUMULATIVE_STUDY_TOTALS_BEGIN" \
    "CREATE TABLE IF NOT EXISTS study_user_totals" \
    "CREATE TABLE IF NOT EXISTS study_deck_totals" \
    "_study_rebuild_cumulative_totals" \
    "_study_get_cumulative_totals_for_user" \
    "/system/study/totals/rebuild" \
    "/api/study/totals" \
    "total_skipped" \
    "total_study_seconds"
  do
    if grep -R -Fq "$marker" edge_controller.py docs/stage-5p11o-cumulative-study-totals.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== cumulative totals backend smoke ==="
  "$PYBIN" - "$base" <<'PY'
import json
import secrets
import sqlite3
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

import edge_controller as ec

base = sys.argv[1].rstrip("/")

def request_json(method, path, token=None, payload=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
        headers["X-Queued-Chat-Session-Token"] = token
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = urllib.request.Request(base + path, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = {"raw": body}
        return exc.code, parsed

def create_user_deck_cards(stamp):
    ec._auth_init_tables()
    ec._study_init_tables()
    ec._study_init_session_tables()

    email = f"stage5p11o-smoke-{stamp}@example.test"
    raw_token = secrets.token_urlsafe(48)
    now = datetime.now(timezone.utc)
    expires = now + timedelta(days=1)

    with sqlite3.connect(ec.DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        user_columns = [row[1] for row in conn.execute("PRAGMA table_info(app_users)").fetchall()]
        values = {}

        if "email" in user_columns:
            values["email"] = email
        if "display_name" in user_columns:
            values["display_name"] = "Stage 5P-11O Smoke User"
        if "password_hash" in user_columns:
            values["password_hash"] = ec._auth_hash_password(f"Stage5P11O-{stamp}-password")
        if "status" in user_columns:
            values["status"] = "active"
        if "role" in user_columns:
            values["role"] = "user"
        if "plan" in user_columns:
            values["plan"] = "free"
        if "billing_status" in user_columns:
            values["billing_status"] = "inactive"
        if "storage_quota_mb" in user_columns:
            values["storage_quota_mb"] = 1024
        if "created_at" in user_columns:
            values["created_at"] = now.isoformat()
        if "updated_at" in user_columns:
            values["updated_at"] = now.isoformat()
        if "last_login_at" in user_columns:
            values["last_login_at"] = now.isoformat()

        cols = list(values)
        cur = conn.execute(
            f"INSERT INTO app_users ({','.join(cols)}) VALUES ({','.join('?' for _ in cols)})",
            [values[c] for c in cols],
        )
        user_id = int(cur.lastrowid)

        conn.execute(
            "INSERT INTO user_sessions (user_id, token_hash, created_at, expires_at, revoked_at, last_seen_at, user_agent) VALUES (?, ?, ?, ?, NULL, ?, ?)",
            (user_id, ec._auth_hash_token(raw_token), now.isoformat(), expires.isoformat(), now.isoformat(), "stage5p11o-smoke"),
        )

        deck_cur = conn.execute(
            "INSERT INTO study_decks (user_id, title, description, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, NULL)",
            (user_id, f"Stage 5P-11O Deck {stamp}", "cumulative totals", now.isoformat(), now.isoformat()),
        )
        deck_id = int(deck_cur.lastrowid)

        for q, a in [("1 + 1", "2"), ("2 + 3", "5"), ("5 + 5", "10")]:
            conn.execute(
                "INSERT INTO study_cards (user_id, deck_id, question, answer, explanation, difficulty, tags_json, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)",
                (user_id, deck_id, q, a, f"{q} = {a}", "easy", "[]", now.isoformat(), now.isoformat()),
            )

        conn.commit()

    return raw_token, user_id, deck_id

stamp = int(time.time())
token, user_id, deck_id = create_user_deck_cards(stamp)

for message in [
    "Study session start",
    "Correct",
    "Wrong",
    "Skip",
]:
    payload = {"message": message}
    if message == "Study session start":
        payload["deck_id"] = deck_id

    status, data = request_json("POST", "/api/study/session/command", token=token, payload=payload)
    assert status == 200 and data.get("ok") is True, (message, status, data)

rebuild = ec._study_rebuild_cumulative_totals(user_id=user_id)
assert rebuild["ok"] is True, rebuild
assert rebuild["user_total_rows"] == 1, rebuild
assert rebuild["deck_total_rows"] == 1, rebuild

totals = ec._study_get_cumulative_totals_for_user(user_id)
user_total = totals["user_total"]
deck_total = totals["deck_totals"][0]

for row in [user_total, deck_total]:
    assert row["total_cards_reviewed"] == 3, row
    assert row["total_answered"] == 2, row
    assert row["total_correct"] == 1, row
    assert row["total_wrong"] == 1, row
    assert row["total_skipped"] == 1, row
    assert row["total_study_seconds"] >= 0, row

status, data = request_json("GET", "/api/study/totals", token=token)
assert status == 200 and data.get("ok") is True, (status, data)
api_total = data["totals"]["user_total"]
assert api_total["total_cards_reviewed"] == 3, api_total
assert api_total["total_correct"] == 1, api_total
assert api_total["total_wrong"] == 1, api_total
assert api_total["total_skipped"] == 1, api_total

print("OK cumulative study totals", json.dumps(api_total, sort_keys=True))
PY

  if [ "$?" = "0" ]; then
    echo "OK cumulative totals backend"
  else
    echo "FAIL cumulative totals backend"
    ok=0
  fi

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p11o-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /profile /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p11o-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p11o-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P11O_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P11O_SMOKE_FAIL"
  return 1
}

if stage5p11o_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
