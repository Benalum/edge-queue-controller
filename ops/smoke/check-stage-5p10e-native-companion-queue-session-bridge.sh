#!/usr/bin/env bash

stage5p10e_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  controller="http://127.0.0.1:7070"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-10E Native Companion Queue Session Bridge Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== env flag checks without values ==="
  for key in \
    LAPTOP_CHAT_QUEUE_ENABLED \
    LAPTOP_CHAT_QUEUE_REAL_USERS_ENABLED \
    LAPTOP_CHAT_QUEUE_SESSION_AUTH_RESOLVER_ENABLED \
    LAPTOP_CHAT_QUEUE_REAL_USER_CREATION_HELPER_ENABLED
  do
    if grep -Eq "^${key}=1$" .env; then
      echo "OK $key enabled"
    else
      echo "FAIL $key not enabled in .env"
      ok=0
    fi
  done

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P10E_NATIVE_QUEUE_SESSION_BRIDGE_BEGIN" \
    "_s5p10e_native_queue_auth_user_from_session_token" \
    "_s5p10e_resolve_queue_auth_user" \
    "native-edge-session-" \
    "STAGE_5P10E_COMPANION_OMIT_CLIENT_CHAT_ID_BEGIN" \
    "STAGE_5P10D_COMPANION_QUEUE_AUTH_HEADERS_BEGIN" \
    "X-Queued-Chat-Session-Token"
  do
    if grep -R -Fq "$marker" edge_controller.py frontend/wrapper-ui/app.js docs/stage-5p10e-native-companion-queue-session-bridge.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== confirm frontend queued body no longer sends client chat_id ==="
  python3 - <<'PY' || ok=0
from pathlib import Path
s = Path("frontend/wrapper-ui/app.js").read_text()
start = s.find("async function queuedChatSubmit")
end = s.find("const text = await res.text()", start)
block = s[start:end]
if "chat_id:" in block:
    raise SystemExit("queuedChatSubmit still sends chat_id")
if "X-Queued-Chat-Session-Token" not in s:
    raise SystemExit("missing queued session token header")
print("OK queuedChatSubmit omits chat_id and sends queue token header")
PY

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p10e-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p10e-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p10e-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live native-session queued-chat integration ==="
  "$PYBIN" - "$controller" <<'PY'
import json
import secrets
import sqlite3
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

import edge_controller as ec

controller = sys.argv[1].rstrip("/")

def request_json(method, path, token=None, payload=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
        headers["X-Queued-Chat-Session-Token"] = token
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = urllib.request.Request(controller + path, data=data, method=method, headers=headers)
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

def create_native_smoke_user_and_session(stamp):
    ec._auth_init_tables()
    email = f"stage5p10e-smoke-{stamp}@example.test"
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
            values["display_name"] = "Stage 5P-10E Smoke User"
        if "password_hash" in user_columns:
            values["password_hash"] = ec._auth_hash_password(f"Stage5P10E-{stamp}-password")
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
        placeholders = ",".join("?" for _ in cols)
        cur = conn.execute(
            f"INSERT INTO app_users ({','.join(cols)}) VALUES ({placeholders})",
            [values[c] for c in cols],
        )
        user_id = int(cur.lastrowid)

        conn.execute(
            "INSERT INTO user_sessions (user_id, token_hash, created_at, expires_at, revoked_at, last_seen_at, user_agent) VALUES (?, ?, ?, ?, NULL, ?, ?)",
            (
                user_id,
                ec._auth_hash_token(raw_token),
                now.isoformat(),
                expires.isoformat(),
                now.isoformat(),
                "stage5p10e-smoke",
            ),
        )
        conn.commit()

    return raw_token, user_id

stamp = int(time.time())
token, native_user_id = create_native_smoke_user_and_session(stamp)

status, data = request_json(
    "POST",
    "/api/chat/queued",
    token=token,
    payload={
        "message": "Stage 5P-10E smoke queued message",
        "requested_model": "gemma4:e4b",
        "mode": "chat",
    },
)

assert status == 200, (status, data)
assert data.get("ok") is True, data
assert data.get("job_id"), data
assert data.get("real_user") is True, data
assert str(data.get("chat_id") or "").strip(), data
print("OK created real-user queued chat job", data.get("job_id"), data.get("chat_id"), data.get("status"))

job_id = data["job_id"]
status, poll = request_json("GET", f"/api/chat/queued/{job_id}", token=token)
assert status == 200, (status, poll)
assert poll.get("ok") is True, poll
print("OK polled real-user queued chat job", json.dumps(poll, indent=2)[:1000])
PY

  live_status="$?"
  if [ "$live_status" = "0" ]; then
    echo "OK live native-session queued-chat bridge"
  else
    echo "FAIL live native-session queued-chat bridge"
    ok=0
  fi

  echo
  echo "=== live asset marker check ==="
  curl -fsS "$base/app.js" >/tmp/stage5p10e-app.js || ok=0
  if grep -Fq "STAGE_5P10E_COMPANION_OMIT_CLIENT_CHAT_ID_BEGIN" /tmp/stage5p10e-app.js; then
    echo "OK live app omit-chat-id marker"
  else
    echo "FAIL live app omit-chat-id marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P10E_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P10E_SMOKE_FAIL"
  return 1
}

if stage5p10e_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
