#!/usr/bin/env bash

stage5p11g_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-11G Study Answer Reveal Actions Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P11G_STUDY_ANSWER_REVEAL_ACTIONS_BEGIN" \
    "STAGE_5P11G_STUDY_ANSWER_REVEAL_HELPER_BEGIN" \
    "data-stage5p8c-command=\"read-answer\"" \
    "data-stage5p8c-command=\"correct\"" \
    "data-stage5p8c-command=\"wrong\"" \
    "data-stage5p8c-command=\"skip\"" \
    "data-stage5p11g-answer-panel" \
    "reviewing_answer" \
    "waiting_for_mark" \
    "STAGE_5P11F_STUDY_CURRENT_CARD_QUESTION_FRONTEND_BEGIN"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css docs/stage-5p11g-study-answer-reveal-actions.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== lower action buttons present and duplicate refresh still removed ==="
  if grep -Fq 'data-stage5p8c-command="refresh"' frontend/wrapper-ui/app.js; then
    echo "FAIL duplicate lower Refresh returned"
    ok=0
  else
    echo "OK duplicate lower Refresh still removed"
  fi

  echo
  echo "=== backend command flow smoke ==="
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

    email = f"stage5p11g-smoke-{stamp}@example.test"
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
            values["display_name"] = "Stage 5P-11G Smoke User"
        if "password_hash" in user_columns:
            values["password_hash"] = ec._auth_hash_password(f"Stage5P11G-{stamp}-password")
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
            (user_id, ec._auth_hash_token(raw_token), now.isoformat(), expires.isoformat(), now.isoformat(), "stage5p11g-smoke"),
        )

        deck_cur = conn.execute(
            "INSERT INTO study_decks (user_id, title, description, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, NULL)",
            (user_id, f"Stage 5P-11G Deck {stamp}", "answer reveal actions", now.isoformat(), now.isoformat()),
        )
        deck_id = int(deck_cur.lastrowid)

        for i in range(2):
            conn.execute(
                "INSERT INTO study_cards (user_id, deck_id, question, answer, explanation, difficulty, tags_json, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)",
                (user_id, deck_id, f"Question {i+1}", f"Answer {i+1}", f"Explanation {i+1}", "easy", "[]", now.isoformat(), now.isoformat()),
            )

        conn.commit()

    return raw_token, deck_id

stamp = int(time.time())
token, deck_id = create_user_deck_cards(stamp)

status, data = request_json("POST", "/api/study/session/start", token=token, payload={"deck_id": deck_id})
assert status == 200 and data.get("ok") is True, (status, data)
assert data.get("session", {}).get("status") == "active", data

status, data = request_json("POST", "/api/study/session/command", token=token, payload={"message": "Read the answer"})
assert status == 200 and data.get("ok") is True, (status, data)
assert data.get("session", {}).get("status") in {"reviewing_answer", "waiting_for_mark"}, data

status, data = request_json("GET", "/api/study/session/status", token=token)
assert status == 200 and data.get("ok") is True, (status, data)
current = data.get("session", {}).get("current_card") or {}
assert current.get("answer"), data

status, data = request_json("POST", "/api/study/session/command", token=token, payload={"message": "Correct"})
assert status == 200 and data.get("ok") is True, (status, data)
assert data.get("session", {}).get("status") in {"active", "completed"}, data

status, data = request_json("POST", "/api/study/session/command", token=token, payload={"message": "Skip"})
assert status == 200 and data.get("ok") is True, (status, data)
assert data.get("session", {}).get("status") in {"active", "completed"}, data

print("OK command flow read-answer/correct/skip works")
PY

  if [ "$?" = "0" ]; then
    echo "OK backend command flow"
  else
    echo "FAIL backend command flow"
    ok=0
  fi

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p11g-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p11g-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p11g-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker checks ==="
  curl -fsS "$base/app.js" >/tmp/stage5p11g-app.js || ok=0
  curl -fsS "$base/styles.css" >/tmp/stage5p11g-styles.css || ok=0

  if grep -Fq "STAGE_5P11G_STUDY_ANSWER_REVEAL_ACTIONS_BEGIN" /tmp/stage5p11g-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  if grep -Fq "STAGE_5P11G_STUDY_ANSWER_REVEAL_ACTIONS_BEGIN" /tmp/stage5p11g-styles.css; then
    echo "OK live css marker"
  else
    echo "FAIL live css marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P11G_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P11G_SMOKE_FAIL"
  return 1
}

if stage5p11g_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
