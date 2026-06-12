#!/usr/bin/env bash

stage5p6c_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  controller="${STAGE5P6C_CONTROLLER:-http://127.0.0.1:7070}"
  base="${STAGE5P6C_BASE:-http://127.0.0.1:8787}"
  PYBIN="${STAGE5P6C_PYTHON:-$HOME/Desktop/edge-queue-controller/.venv/bin/python}"
  [ -x "$PYBIN" ] || PYBIN="python3"
  tmpdir="/tmp/stage5p6c-mark-card"
  mkdir -p "$tmpdir"

  echo "=== Stage 5P-6C Study Session Mark Card Integration Smoke ==="
  echo "controller=$controller"
  echo "base=$base"
  echo "python=$PYBIN"

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P6B_STUDY_MARK_CARD_BEGIN" \
    "_study_mark_current_card_for_session" \
    "study_mark_correct" \
    "study_mark_incorrect" \
    "INSERT INTO study_reviews" \
    "STAGE_5P6A_STUDY_READ_ANSWER_BEGIN" \
    "STAGE_5P5A_STUDY_SESSION_COMMAND_LIFECYCLE_BEGIN" \
    '@app.post("/api/study/session/command")'
  do
    if grep -Fq "$marker" edge_controller.py; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== wrapper route smoke ==="
  if curl -fsS "$base/api/system/public-status" > "$tmpdir/public-status.json"; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /study /companion /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o "$tmpdir/route.html" -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < "$tmpdir/route.html" 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== mark-card live integration ==="
  "$PYBIN" - "$controller" "$tmpdir" <<'PY'
import json
import secrets
import sqlite3
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

import edge_controller as ec

controller = sys.argv[1].rstrip("/")
tmpdir = Path(sys.argv[2])

def read_public_api_key():
    for line in Path(".env").read_text(errors="replace").splitlines():
        line = line.strip()
        if line.startswith("EDGE_PUBLIC_API_KEY="):
            return line.split("=", 1)[1].strip().strip("'").strip('"')
    raise RuntimeError("EDGE_PUBLIC_API_KEY missing from .env")

PUBLIC_API_KEY = read_public_api_key()
ACCESS_TOKEN = None
SMOKE_USER_ID = None

def request_json(method, path, payload=None):
    data = None
    headers = {
        "Content-Type": "application/json",
        "x-edge-api-key": PUBLIC_API_KEY,
    }

    if ACCESS_TOKEN:
        headers["Authorization"] = f"Bearer {ACCESS_TOKEN}"

    if payload is not None:
        data = json.dumps(payload).encode("utf-8")

    req = urllib.request.Request(
        controller + path,
        data=data,
        method=method,
        headers=headers,
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body)
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = {"raw": body}
        return exc.code, parsed

def create_smoke_user_and_token(stamp):
    global ACCESS_TOKEN, SMOKE_USER_ID

    ec._auth_init_tables()

    email = f"stage5p6c-smoke-{stamp}@example.test"
    now = datetime.now(timezone.utc)
    expires = now + timedelta(days=1)

    raw_token = secrets.token_urlsafe(48)
    token_hash = ec._auth_hash_token(raw_token)

    with sqlite3.connect(ec.DB_PATH) as conn:
        conn.row_factory = sqlite3.Row
        columns = [row[1] for row in conn.execute("PRAGMA table_info(app_users)").fetchall()]
        values = {}

        if "email" in columns:
            values["email"] = email
        if "display_name" in columns:
            values["display_name"] = "Stage 5P-6C Smoke User"
        if "password_hash" in columns:
            values["password_hash"] = ec._auth_hash_password(f"Stage5P6C-{stamp}-password")
        if "status" in columns:
            values["status"] = "active"
        if "role" in columns:
            values["role"] = "user"
        if "plan" in columns:
            values["plan"] = "free"
        if "billing_status" in columns:
            values["billing_status"] = "inactive"
        if "storage_quota_mb" in columns:
            values["storage_quota_mb"] = 1024
        if "created_at" in columns:
            values["created_at"] = now.isoformat()
        if "updated_at" in columns:
            values["updated_at"] = now.isoformat()
        if "last_login_at" in columns:
            values["last_login_at"] = now.isoformat()

        insert_columns = list(values.keys())
        placeholders = ",".join("?" for _ in insert_columns)

        cur = conn.execute(
            f"INSERT INTO app_users ({','.join(insert_columns)}) VALUES ({placeholders})",
            [values[c] for c in insert_columns],
        )
        SMOKE_USER_ID = int(cur.lastrowid)

        conn.execute(
            "INSERT INTO user_sessions ("
            "user_id, token_hash, created_at, expires_at, revoked_at, last_seen_at, user_agent"
            ") VALUES (?, ?, ?, ?, NULL, ?, ?)",
            (
                SMOKE_USER_ID,
                token_hash,
                now.isoformat(),
                expires.isoformat(),
                now.isoformat(),
                "stage5p6c-smoke",
            ),
        )
        conn.commit()

    ACCESS_TOKEN = raw_token
    print("OK created local smoke user/session", email)

stamp = int(time.time())
create_smoke_user_and_token(stamp)

answer_one = "Stage 5P-6C answer one."
answer_two = "Stage 5P-6C answer two."

status, deck_data = request_json("POST", "/api/study/decks", {
    "title": f"Stage 5P-6C mark card smoke {stamp}",
    "description": "Temporary deck created by Stage 5P-6C smoke."
})
assert status in (200, 201), (status, deck_data)
deck_id = (deck_data.get("deck") or {}).get("id")
assert deck_id, deck_data
print("OK created deck", deck_id)

status, card_one_data = request_json("POST", f"/api/study/decks/{deck_id}/cards", {
    "question": "Stage 5P-6C first question?",
    "answer": answer_one,
    "hint": "smoke",
    "tags": ["smoke", "stage5p6c"]
})
assert status in (200, 201), (status, card_one_data)
card_one_id = (card_one_data.get("card") or {}).get("id")
assert card_one_id, card_one_data
print("OK created first card", card_one_id)

status, card_two_data = request_json("POST", f"/api/study/decks/{deck_id}/cards", {
    "question": "Stage 5P-6C second question?",
    "answer": answer_two,
    "hint": "smoke",
    "tags": ["smoke", "stage5p6c"]
})
assert status in (200, 201), (status, card_two_data)
card_two_id = (card_two_data.get("card") or {}).get("id")
assert card_two_id, card_two_data
print("OK created second card", card_two_id)

status, start_data = request_json("POST", "/api/study/session/command", {
    "message": "Study Session Start",
    "deck_id": deck_id
})
assert status == 200, (status, start_data)
session = start_data.get("session") or {}
assert session.get("status") == "active", start_data
assert session.get("current_card_id") == card_one_id, start_data
print("OK command start on first card")

status, answer_data = request_json("POST", "/api/study/session/command", {
    "message": "read the answer"
})
assert status == 200, (status, answer_data)
assert answer_data.get("intent") == "study_read_answer", answer_data
assert (answer_data.get("session") or {}).get("status") == "reviewing_answer", answer_data
assert (answer_data.get("card") or {}).get("answer") == answer_one, answer_data
print("OK read first answer")

status, correct_data = request_json("POST", "/api/study/session/command", {
    "message": "correct"
})
assert status == 200, (status, correct_data)
assert correct_data.get("intent") == "study_mark_correct", correct_data
assert correct_data.get("was_correct") is True, correct_data
session = correct_data.get("session") or {}
assert session.get("status") == "active", correct_data
assert session.get("current_card_id") == card_two_id, correct_data
assert session.get("queue_position") == 1, correct_data
print("OK marked first card correct and advanced")

status, answer_two_data = request_json("POST", "/api/study/session/command", {
    "message": "read the answer"
})
assert status == 200, (status, answer_two_data)
assert answer_two_data.get("intent") == "study_read_answer", answer_two_data
assert (answer_two_data.get("card") or {}).get("answer") == answer_two, answer_two_data
assert (answer_two_data.get("session") or {}).get("status") == "reviewing_answer", answer_two_data
print("OK read second answer")

status, incorrect_data = request_json("POST", "/api/study/session/command", {
    "message": "wrong"
})
assert status == 200, (status, incorrect_data)
assert incorrect_data.get("intent") == "study_mark_incorrect", incorrect_data
assert incorrect_data.get("was_correct") is False, incorrect_data
session = incorrect_data.get("session") or {}
assert session.get("status") == "completed", incorrect_data
assert incorrect_data.get("completed") is True, incorrect_data
print("OK marked second card incorrect and completed")

status, final_data = request_json("GET", "/api/study/session/status")
assert status == 200, (status, final_data)
assert (final_data.get("session") or {}).get("status") == "none", final_data
print("OK final status none")

with sqlite3.connect(ec.DB_PATH) as conn:
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        "SELECT was_correct FROM study_reviews WHERE user_id = ? AND deck_id = ? ORDER BY id ASC",
        (SMOKE_USER_ID, deck_id),
    ).fetchall()

review_values = [int(row["was_correct"]) for row in rows]
assert review_values[-2:] == [1, 0], review_values
print("OK review rows correct/incorrect", review_values[-2:])

(tmpdir / "stage5p6c-result.json").write_text(json.dumps({
    "deck_id": deck_id,
    "card_one_id": card_one_id,
    "card_two_id": card_two_id,
    "review_values": review_values[-2:],
    "final_status": final_data,
}, indent=2))
PY

  live_status="$?"
  if [ "$live_status" = "0" ]; then
    echo "OK mark-card integration"
  else
    echo "FAIL mark-card integration"
    ok=0
  fi

  echo
  echo "=== recent journal signals ==="
  journalctl --user -n 120 --no-pager 2>/dev/null | grep -Ei "traceback|exception|failed|error" | tail -40 || true

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P6C_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P6C_SMOKE_FAIL"
  return 1
}

if stage5p6c_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
