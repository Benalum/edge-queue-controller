#!/usr/bin/env bash

stage5p11j_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-11J Companion Study Answer Capture Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P11J_COMPANION_STUDY_ANSWER_CAPTURE_BEGIN" \
    "STAGE_5P11J_COMPANION_STUDY_ANSWER_CAPTURE_SUBMIT_HOOK_BEGIN" \
    "stage5p11jRouteCompanionStudyAnswer" \
    "stage5p11jCompareAnswer" \
    "Study answer checked" \
    "Study answer check" \
    "Correct." \
    "Marked wrong. Correct answer was" \
    "Say Correct, Wrong, or Skip" \
    "STAGE_5P11I_COMPANION_STUDY_COMMAND_ROUTING_BEGIN"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js docs/stage-5p11j-companion-study-answer-capture.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== ensure no Companion buttons/debug UI added ==="
  if grep -Fq 'data-stage5p11j-test' frontend/wrapper-ui/app.js; then
    echo "FAIL test UI marker found"
    ok=0
  else
    echo "OK no test UI marker"
  fi

  if grep -Fq 'button type="button" data-stage5p11j' frontend/wrapper-ui/app.js; then
    echo "FAIL Stage 5P-11J added Companion buttons"
    ok=0
  else
    echo "OK no Stage 5P-11J Companion buttons"
  fi

  echo
  echo "=== verify answer hook comes before queued fetch ==="
  "$PYBIN" - <<'PY'
from pathlib import Path
s = Path("frontend/wrapper-ui/app.js").read_text()
hook = s.index("STAGE_5P11J_COMPANION_STUDY_ANSWER_CAPTURE_SUBMIT_HOOK_BEGIN")
queued = s.index('fetch("/api/chat/queued"', hook)
assert hook < queued
print("OK answer hook precedes queued fetch")
PY
  if [ "$?" = "0" ]; then
    echo "OK answer hook order"
  else
    echo "FAIL answer hook order"
    ok=0
  fi

  echo
  echo "=== backend answer command flow smoke ==="
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

    email = f"stage5p11j-smoke-{stamp}@example.test"
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
            values["display_name"] = "Stage 5P-11J Smoke User"
        if "password_hash" in user_columns:
            values["password_hash"] = ec._auth_hash_password(f"Stage5P11J-{stamp}-password")
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
            (user_id, ec._auth_hash_token(raw_token), now.isoformat(), expires.isoformat(), now.isoformat(), "stage5p11j-smoke"),
        )

        deck_cur = conn.execute(
            "INSERT INTO study_decks (user_id, title, description, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, NULL)",
            (user_id, f"Stage 5P-11J Deck {stamp}", "companion answer capture", now.isoformat(), now.isoformat()),
        )
        deck_id = int(deck_cur.lastrowid)

        for q, a in [("1 + 1", "2"), ("2 + 3", "5")]:
            conn.execute(
                "INSERT INTO study_cards (user_id, deck_id, question, answer, explanation, difficulty, tags_json, created_at, updated_at, archived_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)",
                (user_id, deck_id, q, a, f"{q} = {a}", "easy", "[]", now.isoformat(), now.isoformat()),
            )

        conn.commit()

    return raw_token, deck_id

stamp = int(time.time())
token, deck_id = create_user_deck_cards(stamp)

status, data = request_json("POST", "/api/study/session/command", token=token, payload={"message": "Study session start", "deck_id": deck_id})
assert status == 200 and data.get("ok") is True, (status, data)
assert data.get("session", {}).get("status") == "active", data

status, data = request_json("GET", "/api/study/session/status", token=token)
assert status == 200 and data.get("session", {}).get("current_card", {}).get("answer") == "2", data

status, data = request_json("POST", "/api/study/session/command", token=token, payload={"message": "Correct"})
assert status == 200 and data.get("ok") is True, (status, data)
assert data.get("session", {}).get("status") in {"active", "completed"}, data

print("OK backend can mark captured answer correct and advance")
PY

  if [ "$?" = "0" ]; then
    echo "OK backend answer flow"
  else
    echo "FAIL backend answer flow"
    ok=0
  fi

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p11j-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p11j-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p11j-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker check ==="
  curl -fsS "$base/app.js" >/tmp/stage5p11j-app.js || ok=0

  if grep -Fq "STAGE_5P11J_COMPANION_STUDY_ANSWER_CAPTURE_BEGIN" /tmp/stage5p11j-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P11J_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P11J_SMOKE_FAIL"
  return 1
}

if stage5p11j_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
