#!/usr/bin/env bash

stage5p5b_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  controller="${STAGE5P5B_CONTROLLER:-http://127.0.0.1:7070}"
  base="${STAGE5P5B_BASE:-http://127.0.0.1:8787}"
  PYBIN="${STAGE5P5B_PYTHON:-$HOME/Desktop/edge-queue-controller/.venv/bin/python}"
  [ -x "$PYBIN" ] || PYBIN="python3"
  tmpdir="/tmp/stage5p5b-command-lifecycle"
  mkdir -p "$tmpdir"

  echo "=== Stage 5P-5B Study Session Command Lifecycle Integration Smoke ==="
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
    "STAGE_5P5A_STUDY_SESSION_COMMAND_LIFECYCLE_BEGIN" \
    '@app.post("/api/study/session/command")' \
    "STAGE_5P4_STUDY_INTENT_PARSER_BEGIN" \
    "STAGE_5P3B_STUDY_SESSION_LIFECYCLE_BEGIN" \
    "STAGE_5P3A_STUDY_SESSION_START_BEGIN" \
    "STAGE_5P2_STUDY_SESSION_STATUS_BEGIN"
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
  echo "=== command endpoint live integration ==="
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
    path = Path(".env")
    if not path.exists():
        raise RuntimeError(".env missing; cannot read EDGE_PUBLIC_API_KEY")

    for line in path.read_text(errors="replace").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        if key.strip() == "EDGE_PUBLIC_API_KEY":
            value = value.strip().strip("'").strip('"')
            if value:
                return value

    raise RuntimeError("EDGE_PUBLIC_API_KEY missing from .env")


PUBLIC_API_KEY = read_public_api_key()
ACCESS_TOKEN = None


def request_json(method, path, payload=None, bearer=True, public_key=True):
    data = None
    headers = {"Content-Type": "application/json"}

    if public_key:
        headers["x-edge-api-key"] = PUBLIC_API_KEY

    if bearer:
        if not ACCESS_TOKEN:
            raise RuntimeError("ACCESS_TOKEN missing")
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

    email = f"stage5p5b-smoke-{stamp}@example.test"
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
            values["display_name"] = "Stage 5P-5B Smoke User"
        if "password_hash" in columns:
            values["password_hash"] = ec._auth_hash_password(f"Stage5P5B-{stamp}-password")
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
                "stage5p5b-smoke",
            ),
        )
        conn.commit()

    ACCESS_TOKEN = raw_token
    print("OK created local smoke user/session", email)


stamp = int(time.time())
create_smoke_user_and_token(stamp)

deck_name = f"Stage 5P-5B command smoke {stamp}"

status, deck_data = request_json("POST", "/api/study/decks", {
    "title": deck_name,
    "description": "Temporary deck created by Stage 5P-5B smoke."
})
assert status in (200, 201), (status, deck_data)

deck = deck_data.get("deck") or {}
deck_id = deck.get("id")
assert deck_id, deck_data
print("OK created deck", deck_id)

status, card_data = request_json("POST", f"/api/study/decks/{deck_id}/cards", {
    "question": "Stage 5P-5B smoke question?",
    "answer": "Stage 5P-5B smoke answer.",
    "hint": "smoke",
    "tags": ["smoke", "stage5p5b"]
})
assert status in (200, 201), (status, card_data)

card = card_data.get("card") or {}
card_id = card.get("id")
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

status, status_data = request_json("POST", "/api/study/session/command", {
    "message": "Study Session Status"
})
assert status == 200, (status, status_data)
assert (status_data.get("session") or {}).get("status") == "active", status_data
print("OK command status active")

status, pause_data = request_json("POST", "/api/study/session/command", {
    "message": "Study Session Pause"
})
assert status == 200, (status, pause_data)
assert pause_data.get("intent") == "study_session_pause", pause_data
assert (pause_data.get("session") or {}).get("status") == "paused", pause_data
print("OK command pause")

status, resume_data = request_json("POST", "/api/study/session/command", {
    "message": "Study Session Resume"
})
assert status == 200, (status, resume_data)
assert resume_data.get("intent") == "study_session_resume", resume_data
assert (resume_data.get("session") or {}).get("status") == "active", resume_data
print("OK command resume")

status, stop_data = request_json("POST", "/api/study/session/command", {
    "message": "Study Session Stop"
})
assert status == 200, (status, stop_data)
assert stop_data.get("intent") == "study_session_stop", stop_data
assert (stop_data.get("session") or {}).get("status") == "stopped", stop_data
print("OK command stop")

status, final_data = request_json("GET", "/api/study/session/status")
assert status == 200, (status, final_data)
assert (final_data.get("session") or {}).get("status") == "none", final_data
print("OK final status none")

(tmpdir / "stage5p5b-result.json").write_text(json.dumps({
    "deck_id": deck_id,
    "card_id": card_id,
    "final_status": final_data,
}, indent=2))
PY

  lifecycle_status="$?"
  if [ "$lifecycle_status" = "0" ]; then
    echo "OK command lifecycle integration"
  else
    echo "FAIL command lifecycle integration"
    ok=0
  fi

  echo
  echo "=== recent journal signals ==="
  journalctl --user -n 120 --no-pager 2>/dev/null | grep -Ei "traceback|exception|failed|error" | tail -40 || true

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P5B_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P5B_SMOKE_FAIL"
  return 1
}

if stage5p5b_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
