#!/usr/bin/env bash

stage5p8e_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  controller="${STAGE5P8E_CONTROLLER:-http://127.0.0.1:7070}"
  base="${STAGE5P8E_BASE:-http://127.0.0.1:8787}"
  PYBIN="${STAGE5P8E_PYTHON:-$HOME/Desktop/edge-queue-controller/.venv/bin/python}"
  [ -x "$PYBIN" ] || PYBIN="python3"
  tmpdir="/tmp/stage5p8e-study-controls-command"
  mkdir -p "$tmpdir"

  echo "=== Stage 5P-8E Study Controls Live Command Smoke ==="
  echo "controller=$controller"
  echo "base=$base"
  echo "python=$PYBIN"

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== frontend command string checks ==="
  for marker in \
    "STAGE_5P8C_STUDY_SESSION_CONTROL_BUTTONS_BEGIN" \
    "stage5p8c-study-session-controls" \
    "Study Session Pause" \
    "Study Session Resume" \
    "Study Session Stop" \
    "/api/study/session/command" \
    "Start is intentionally not wired yet"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css docs/stage-5p8c-study-session-control-buttons.md; then
      echo "OK frontend marker $marker"
    else
      echo "FAIL missing frontend marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== backend command marker checks ==="
  for marker in \
    '@app.post("/api/study/session/command")' \
    "study_session_pause" \
    "study_session_resume" \
    "study_session_stop" \
    "study_session_start"
  do
    if grep -Fq "$marker" edge_controller.py; then
      echo "OK backend marker $marker"
    else
      echo "FAIL missing backend marker $marker"
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
  echo "=== live command integration with frontend command strings ==="
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
    global ACCESS_TOKEN

    ec._auth_init_tables()

    email = f"stage5p8e-smoke-{stamp}@example.test"
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
            values["display_name"] = "Stage 5P-8E Smoke User"
        if "password_hash" in columns:
            values["password_hash"] = ec._auth_hash_password(f"Stage5P8E-{stamp}-password")
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
        user_id = int(cur.lastrowid)

        conn.execute(
            "INSERT INTO user_sessions ("
            "user_id, token_hash, created_at, expires_at, revoked_at, last_seen_at, user_agent"
            ") VALUES (?, ?, ?, ?, NULL, ?, ?)",
            (
                user_id,
                token_hash,
                now.isoformat(),
                expires.isoformat(),
                now.isoformat(),
                "stage5p8e-smoke",
            ),
        )
        conn.commit()

    ACCESS_TOKEN = raw_token
    print("OK created local smoke user/session", email)

stamp = int(time.time())
create_smoke_user_and_token(stamp)

status, deck_data = request_json("POST", "/api/study/decks", {
    "title": f"Stage 5P-8E controls command smoke {stamp}",
    "description": "Temporary deck created by Stage 5P-8E smoke."
})
assert status in (200, 201), (status, deck_data)
deck_id = (deck_data.get("deck") or {}).get("id")
assert deck_id, deck_data
print("OK created deck", deck_id)

status, card_data = request_json("POST", f"/api/study/decks/{deck_id}/cards", {
    "question": "Stage 5P-8E smoke question?",
    "answer": "Stage 5P-8E smoke answer.",
    "hint": "smoke",
    "tags": ["smoke", "stage5p8e"]
})
assert status in (200, 201), (status, card_data)
card_id = (card_data.get("card") or {}).get("id")
assert card_id, card_data
print("OK created card", card_id)

status, start_data = request_json("POST", "/api/study/session/command", {
    "message": "Study Session Start",
    "deck_id": deck_id
})
assert status == 200, (status, start_data)
assert start_data.get("intent") == "study_session_start", start_data
assert (start_data.get("session") or {}).get("status") == "active", start_data
print("OK command start")

status, pause_data = request_json("POST", "/api/study/session/command", {
    "message": "Study Session Pause"
})
assert status == 200, (status, pause_data)
assert pause_data.get("intent") == "study_session_pause", pause_data
assert (pause_data.get("session") or {}).get("status") == "paused", pause_data
print("OK frontend string pause")

status, resume_data = request_json("POST", "/api/study/session/command", {
    "message": "Study Session Resume"
})
assert status == 200, (status, resume_data)
assert resume_data.get("intent") == "study_session_resume", resume_data
assert (resume_data.get("session") or {}).get("status") == "active", resume_data
print("OK frontend string resume")

status, stop_data = request_json("POST", "/api/study/session/command", {
    "message": "Study Session Stop"
})
assert status == 200, (status, stop_data)
assert stop_data.get("intent") == "study_session_stop", stop_data
assert (stop_data.get("session") or {}).get("status") == "stopped", stop_data
print("OK frontend string stop")

status, final_data = request_json("GET", "/api/study/session/status")
assert status == 200, (status, final_data)
assert (final_data.get("session") or {}).get("status") == "none", final_data
print("OK final status none")

(tmpdir / "stage5p8e-result.json").write_text(json.dumps({
    "deck_id": deck_id,
    "card_id": card_id,
    "final_status": final_data,
}, indent=2))
PY

  live_status="$?"
  if [ "$live_status" = "0" ]; then
    echo "OK frontend command strings live integration"
  else
    echo "FAIL frontend command strings live integration"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P8E_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P8E_SMOKE_FAIL"
  return 1
}

if stage5p8e_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
