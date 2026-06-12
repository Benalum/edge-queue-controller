#!/usr/bin/env bash

stage5p10b_smoke_main() {
  cd "$HOME/Desktop/edge-queue-controller" || return 1

  ok=1
  controller="http://127.0.0.1:7070"
  base="http://127.0.0.1:8787"
  PYBIN="$HOME/Desktop/edge-queue-controller/.venv/bin/python"
  [ -x "$PYBIN" ] || PYBIN="python3"

  echo "=== Stage 5P-10B Companion Queue Status Endpoint Smoke ==="

  echo
  echo "=== syntax checks ==="
  node --check frontend/wrapper-ui/app.js || ok=0
  [ ! -f frontend/study-ui/app.js ] || node --check frontend/study-ui/app.js || ok=0
  "$PYBIN" -m py_compile edge_controller.py || ok=0

  echo
  echo "=== source marker checks ==="
  for marker in \
    "STAGE_5P10B_COMPANION_QUEUE_STATUS_BEGIN" \
    '@app.get("/api/chat/queue/status")' \
    '@app.get("/public/chat/queue/status")' \
    "waiting_count" \
    "running_count" \
    "ahead_count" \
    "position" \
    "/api/chat/queued"
  do
    if grep -Fq "$marker" edge_controller.py docs/stage-5p10b-companion-queue-status-endpoint.md; then
      echo "OK marker $marker"
    else
      echo "FAIL missing marker $marker"
      ok=0
    fi
  done

  echo
  echo "=== route smoke before restart ==="
  if curl -fsS "$base/api/system/public-status" >/tmp/stage5p10b-public-status.json; then
    echo "OK public-status"
  else
    echo "FAIL public-status"
    ok=0
  fi

  for route in /companion /study /chat /profile /support /credits /admin /system; do
    code="$(curl -sS -L -o /tmp/stage5p10b-route.html -w "%{http_code}" "$base$route" || true)"
    bytes="$(wc -c < /tmp/stage5p10b-route.html 2>/dev/null || printf 0)"
    if [ "$code" = "200" ] && [ "$bytes" -gt 100 ]; then
      echo "OK $route code=$code bytes=$bytes"
    else
      echo "FAIL $route code=$code bytes=$bytes"
      ok=0
    fi
  done

  echo
  echo "=== live endpoint integration ==="
  "$PYBIN" - "$controller" <<'PY'
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

def request_json(method, path, token=None, payload=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    req = urllib.request.Request(controller + path, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode("utf-8")
            return resp.status, json.loads(body) if body else {}
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", "replace")
        try:
            parsed = json.loads(body)
        except Exception:
            parsed = {"raw": body}
        return exc.code, parsed

def create_smoke_user_and_token(stamp):
    ec._auth_init_tables()
    email = f"stage5p10b-smoke-{stamp}@example.test"
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
            values["display_name"] = "Stage 5P-10B Smoke User"
        if "password_hash" in columns:
            values["password_hash"] = ec._auth_hash_password(f"Stage5P10B-{stamp}-password")
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

        cols = list(values)
        placeholders = ",".join("?" for _ in cols)
        cur = conn.execute(
            f"INSERT INTO app_users ({','.join(cols)}) VALUES ({placeholders})",
            [values[c] for c in cols],
        )
        user_id = int(cur.lastrowid)
        conn.execute(
            "INSERT INTO user_sessions (user_id, token_hash, created_at, expires_at, revoked_at, last_seen_at, user_agent) VALUES (?, ?, ?, ?, NULL, ?, ?)",
            (user_id, token_hash, now.isoformat(), expires.isoformat(), now.isoformat(), "stage5p10b-smoke"),
        )
        conn.commit()
    return raw_token, user_id

stamp = int(time.time())
token, user_id = create_smoke_user_and_token(stamp)

status, unauthorized = request_json("GET", "/api/chat/queue/status")
assert status == 401, (status, unauthorized)
print("OK endpoint requires bearer token")

status, baseline = request_json("GET", "/api/chat/queue/status", token=token)
assert status == 200, (status, baseline)
assert baseline.get("ok") is True, baseline
assert "queue" in baseline, baseline
print("OK queue status baseline", baseline.get("queue"))

with sqlite3.connect(ec.DB_PATH) as conn:
    conn.row_factory = sqlite3.Row
    cols = [row["name"] for row in conn.execute("PRAGMA table_info(jobs)").fetchall()]
    assert "status" in cols, cols
    now = datetime.now(timezone.utc).isoformat()

    table_info = conn.execute("PRAGMA table_info(jobs)").fetchall()
    info_by_col = {row["name"]: row for row in table_info}
    values = {}

    def value_for_column(col, col_type, required):
        lower = col.lower()
        type_text = str(col_type or "").upper()

        if lower in ("job_id", "public_id", "external_id", "request_id"):
            return f"stage5p10b-job-{stamp}"
        if lower in ("job_type", "type", "kind"):
            return "ollama_chat"
        if lower == "status" or lower.endswith("_status"):
            return "queued"
        if lower in ("prompt", "message", "input", "query", "text"):
            return "Stage 5P-10B smoke prompt"
        if "payload" in lower or lower.endswith("_json") or "request" in lower:
            return json.dumps({"message": "stage5p10b smoke", "prompt": "Stage 5P-10B smoke prompt"})
        if "result" in lower or "response" in lower:
            return None
        if "error" in lower:
            return None
        if lower in ("attempts", "retry_count", "priority", "queue_position"):
            return 0
        if lower in ("user_id", "owner_user_id", "account_id"):
            return user_id
        if lower in ("model", "requested_model", "model_name"):
            return "stage5p10b-smoke-model"
        if lower in ("worker_id", "claimed_by", "target_name"):
            return None
        if lower in ("created_at", "updated_at", "submitted_at", "queued_at"):
            return now
        if lower.endswith("_at"):
            return None
        if "INT" in type_text:
            return 0 if required else None
        if "REAL" in type_text or "FLOA" in type_text or "DOUB" in type_text:
            return 0.0 if required else None
        if "BLOB" in type_text:
            return b"" if required else None
        return "stage5p10b-smoke" if required else None

    for row in table_info:
        col = row["name"]
        if col == "id" or int(row["pk"] or 0):
            continue

        has_default = row["dflt_value"] is not None
        required = bool(row["notnull"]) and not has_default
        val = value_for_column(col, row["type"], required)

        if val is not None or required:
            values[col] = val

    # Ensure known useful columns are present even when nullable.
    for col in cols:
        if col not in values and col in ("job_id", "job_type", "status", "prompt", "payload_json", "user_id", "created_at", "updated_at"):
            row = info_by_col[col]
            values[col] = value_for_column(col, row["type"], True)

    insert_cols = list(values)
    placeholders = ",".join("?" for _ in insert_cols)
    cur = conn.execute(
        f"INSERT INTO jobs ({','.join(insert_cols)}) VALUES ({placeholders})",
        [values[c] for c in insert_cols],
    )
    inserted_id = cur.lastrowid
    conn.commit()

job_id = values.get("job_id") or str(inserted_id)
print("OK inserted queued smoke job", job_id)

status, after = request_json("GET", f"/api/chat/queue/status?job_id={job_id}", token=token)
assert status == 200, (status, after)
assert after.get("ok") is True, after
queue = after.get("queue") or {}
job = after.get("job") or {}
assert int(queue.get("waiting_count", 0)) >= 1, after
assert job.get("status") in ("queued", "pending"), after
assert job.get("position") is not None, after
assert job.get("ahead_count") is not None, after
print("OK queue status with job position", json.dumps(after, indent=2))
PY

  live_status="$?"
  if [ "$live_status" = "0" ]; then
    echo "OK live queue endpoint integration"
  else
    echo "FAIL live queue endpoint integration"
    ok=0
  fi

  echo
  if [ "$ok" = "1" ]; then
    echo "STAGE_5P10B_SMOKE_OK"
    return 0
  fi

  echo "STAGE_5P10B_SMOKE_FAIL"
  return 1
}

if stage5p10b_smoke_main "$@"; then
  return 0 2>/dev/null || true
else
  return 1 2>/dev/null || false
fi
