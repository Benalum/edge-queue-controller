#!/usr/bin/env bash

stage5p10g_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  base="http://127.0.0.1:8787"
  controller="http://127.0.0.1:7070"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-10G Simplified Companion Queue Display Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P10G_SIMPLIFIED_QUEUE_DISPLAY_BEGIN" \
    "queuedChatQueueSummary" \
    "STAGE_5P10G_SIMPLIFIED_QUEUE_DISPLAY_LOGIC_BEGIN" \
    "position / total" \
    "STAGE_5P10F_REAL_USER_QUEUE_STATUS_BRIDGE_BEGIN" \
    "STAGE_5P10E_NATIVE_QUEUE_SESSION_BRIDGE_BEGIN" \
    "STAGE_5P10D_COMPANION_QUEUE_AUTH_HEADERS_BEGIN"
  do
    if grep -R -Fq "$marker" frontend/wrapper-ui/app.js frontend/wrapper-ui/styles.css edge_controller.py docs/stage-5p10g-simplified-companion-queue-display.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== old detailed rows should be gone ==="
  for old_marker in \
    "queuedChatQueueSize" \
    "queuedChatQueuePosition" \
    "queuedChatJobsAhead" \
    "Queue size" \
    "Your position" \
    "Jobs ahead"
  do
    if grep -R -Fq "$old_marker" frontend/wrapper-ui/app.js; then
      echo "FAIL old marker still present $old_marker"
      ok=0
    else
      echo "OK old marker removed $old_marker"
    fi
  done

  echo
  echo "=== live queue-status endpoint still works ==="
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
    email = f"stage5p10g-smoke-{stamp}@example.test"
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
            values["display_name"] = "Stage 5P-10G Smoke User"
        if "password_hash" in user_columns:
            values["password_hash"] = ec._auth_hash_password(f"Stage5P10G-{stamp}-password")
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
                "stage5p10g-smoke",
            ),
        )
        conn.commit()

    return raw_token

stamp = int(time.time())
token = create_native_smoke_user_and_session(stamp)

status, created = request_json(
    "POST",
    "/api/chat/queued",
    token=token,
    payload={
        "message": "Stage 5P-10G simplified queue display smoke",
        "requested_model": "gemma4:e4b",
        "mode": "chat",
    },
)
assert status == 200, (status, created)
job_id = created.get("job_id")
assert job_id, created
print("OK created queued job", job_id)

status, q = request_json("GET", f"/api/chat/queue/status?job_id={job_id}", token=token)
assert status == 200, (status, q)
assert q.get("ok") is True, q
job = q.get("job") or {}
queue = q.get("queue") or {}
assert job.get("job_id") == job_id, q
assert queue.get("total_active") is not None, q
assert job.get("position") is not None or job.get("status") in {"running", "complete", "completed"}, q
print("OK queue status supports simplified display", json.dumps(q, indent=2)[:1200])
PY

  if [ "$?" = "0" ]; then
    echo "OK live queue status endpoint for simplified UI"
  else
    echo "FAIL live queue status endpoint for simplified UI"
    ok=0
  fi

  echo
  echo "=== route smoke ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p10g-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p10g-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p10g-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live asset marker checks ==="
  curl -fsS "$base/app.js" >/tmp/stage5p10g-app.js || ok=0
  curl -fsS "$base/styles.css" >/tmp/stage5p10g-styles.css || ok=0

  if grep -Fq "STAGE_5P10G_SIMPLIFIED_QUEUE_DISPLAY_BEGIN" /tmp/stage5p10g-app.js; then
    echo "OK live app marker"
  else
    echo "FAIL live app marker"
    ok=0
  fi

  if grep -Fq "STAGE_5P10G_SIMPLIFIED_QUEUE_DISPLAY_BEGIN" /tmp/stage5p10g-styles.css; then
    echo "OK live css marker"
  else
    echo "FAIL live css marker"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P10G_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P10G_SMOKE_FAIL"
  return 1
}

if stage5p10g_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
