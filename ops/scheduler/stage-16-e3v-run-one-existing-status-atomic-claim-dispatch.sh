#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-16-e3v-run-one-existing-status-atomic-claim-dispatch"
DRY_RUN_APPROVAL_NOTE="dry-run-does-not-require-approval"
RUNTIME_APPROVAL="APPROVE_STAGE_16_E3V_Q_RUN_JOB_29_OPTION_B_ATOMIC_CLAIM_DISPATCH_ONLY"
PASS_MARKER="E3V_Q_OPTION_B_ATOMIC_CLAIM_DISPATCH_JOB_29_OK"

MODE="${1:-}"
EXPECTED_HEAD="${EXPECTED_HEAD:-}"
EXPECTED_MODEL="${EXPECTED_MODEL:-qwen2.5:32b-instruct-q4_K_M}"
FRESH_JOB_ID="${FRESH_JOB_ID:-29}"
EXPECTED_SELECTED_JOB_ID="${EXPECTED_SELECTED_JOB_ID:-29}"
CTID="${CTID:-203}"
CT203_DB_PATH="${CT203_DB_PATH:-/var/lib/edge-queue-controller/edge_queue.sqlite3}"
PVEW_SSH="${PVEW_SSH:-pvew}"
RUN_ROOT="${RUN_ROOT:-/tmp}"
MODEL_TIMEOUT_SECONDS="${MODEL_TIMEOUT_SECONDS:-900}"
RUN_DIR="${RUN_DIR:-$RUN_ROOT/apc-e3v-option-b-job-29-$(date -u +%Y%m%dT%H%M%SZ)}"

EXPECTED_JOB_TYPE="stage16_e3v_option_b_atomic_claim_fresh_model_smoke"
MODEL_PROMPT="Stage 16 E3V fresh eligible Option B atomic-claim smoke. Reply with a short deterministic confirmation."
FORBIDDEN_JOB_IDS="23 24 27 28"

sanitize_stream() {
  sed -E \
    -e 's#https://login\.tailscale\.com/a/[A-Za-z0-9]+#<redacted-auth-url>#g' \
    -e 's/100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-tailscale-ip>/g' \
    -e 's/10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/192\.168\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/<redacted-mac>/g'
}

write_recovery_hint() {
  mkdir -p "$RUN_DIR"
  cat > "$RUN_DIR/recovery_hint.txt" <<EOF
DO_NOT_RERUN
RUN_READ_ONLY_RECOVERY_FIRST
stage=$STAGE
mode=$MODE
run_dir=$RUN_DIR
fresh_job_id=$FRESH_JOB_ID
expected_model=$EXPECTED_MODEL
runtime_approval=$RUNTIME_APPROVAL
timeout_recovery_classifications:
completed_with_one_result_do_not_rerun
running_zero_results_runner_active_do_not_rerun
running_zero_results_no_runner_manual_recovery_required
queued_zero_results_no_claim_new_approval_required
failed_zero_results_do_not_rerun_without_review
duplicate_result_failure_do_not_rerun
ambiguous_preserve_artifacts_do_not_rerun
EOF
}

repo_preflight() {
  repo_head="$(git rev-parse --short HEAD)"
  repo_dirty="$(git status --short)"
  {
    echo "repo_head=$repo_head"
    echo "expected_head=${EXPECTED_HEAD:-unset}"
    echo "repo_dirty=${repo_dirty:-<clean>}"
  } | tee "$RUN_DIR/repo_preflight.txt"

  if [ -n "$EXPECTED_HEAD" ] && [ "$repo_head" != "$EXPECTED_HEAD" ]; then
    echo "REFUSE_REPO_CHECKPOINT_MISMATCH"
    exit 2
  fi

  if [ -n "$repo_dirty" ]; then
    echo "REFUSE_REPO_DIRTY"
    exit 2
  fi

  echo "REPO_PREFLIGHT_OK"
}

scheduler_worker_preflight() {
  scheduler_env="$(env | grep -E '^EDGE_(SCHEDULER|PERSISTENT|LANE|WORKER)' || true)"
  {
    echo "SCHEDULER_ENV_START"
    printf "%s\n" "$scheduler_env"
    echo "SCHEDULER_ENV_END"
    if env | grep -q '^EDGE_PERSISTENT_LANE_WORKERS_ENABLED=true$'; then
      echo "REFUSE_PERSISTENT_WORKERS_ACTIVE"
      exit 2
    fi
    echo "SCHEDULER_WORKER_DISABLED_PREFLIGHT_OK"
  } | tee "$RUN_DIR/scheduler_worker_disabled_preflight.txt"
}

ct203_db_stat() {
  ssh "$PVEW_SSH" "pct exec $CTID -- stat -c '%s %Y %n' '$CT203_DB_PATH'"
}

ct203_readonly_candidate_check() {
  ct203_py="$RUN_DIR/ct203_readonly_candidate_check.py"
  cat > "$ct203_py" <<'PY'
#!/usr/bin/env python3
import sqlite3
import sys

DB = "/var/lib/edge-queue-controller/edge_queue.sqlite3"
EXPECTED_MODEL = "qwen2.5:32b-instruct-q4_K_M"
EXPECTED_JOB_ID = 29
EXPECTED_JOB_TYPE = "stage16_e3v_option_b_atomic_claim_fresh_model_smoke"
FORBIDDEN = {23, 24, 27, 28}

conn = sqlite3.connect(f"file:{DB}?mode=ro&immutable=1", uri=True)
conn.row_factory = sqlite3.Row
conn.execute("PRAGMA query_only=ON")

print("CT203_READONLY_CANDIDATE_CHECK=begin")
print("DB_OPEN_MODE=sqlite_uri_mode_ro_immutable")
integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
print(f"DB_INTEGRITY={integrity}")
if integrity != "ok":
    print("REFUSE_DB_INTEGRITY_NOT_OK")
    raise SystemExit(2)

jobs_total = conn.execute("SELECT COUNT(*) FROM jobs").fetchone()[0]
results_total = conn.execute("SELECT COUNT(*) FROM job_results").fetchone()[0]
print(f"JOBS_TOTAL={jobs_total}")
print(f"JOB_RESULTS_TOTAL={results_total}")

dup_rows = conn.execute(
    "SELECT job_id, COUNT(*) AS c FROM job_results GROUP BY job_id HAVING COUNT(*) > 1 ORDER BY job_id"
).fetchall()
if dup_rows:
    for row in dup_rows:
        print(f"DUPLICATE_JOB_RESULTS job_id={row['job_id']} count={row['c']}")
    print("REFUSE_DUPLICATE_JOB_RESULTS")
    raise SystemExit(2)
print("DUPLICATE_JOB_RESULTS none")

job = conn.execute(
    "SELECT id, status, attempts, requested_model, job_type, prompt, created_at, updated_at FROM jobs WHERE id=?",
    (EXPECTED_JOB_ID,),
).fetchone()
result_rows = conn.execute("SELECT COUNT(*) FROM job_results WHERE job_id=?", (EXPECTED_JOB_ID,)).fetchone()[0]
if job is None:
    print("REFUSE_SELECTED_JOB_MISSING")
    raise SystemExit(2)

print(
    f"JOB29_PREFLIGHT id={job['id']} status={job['status']} attempts={job['attempts']} "
    f"model={job['requested_model']} job_type={job['job_type']} result_rows={result_rows}"
)

if int(job["id"]) in FORBIDDEN:
    print("REFUSE_FORBIDDEN_JOB_ID")
    raise SystemExit(2)
if int(job["id"]) != EXPECTED_JOB_ID:
    print("REFUSE_SELECTED_JOB_ID_NOT_29")
    raise SystemExit(2)
if job["status"] != "queued":
    print("REFUSE_SELECTED_JOB_NOT_QUEUED")
    raise SystemExit(2)
if int(job["attempts"]) != 0:
    print("REFUSE_SELECTED_JOB_ATTEMPTS_NOT_ZERO")
    raise SystemExit(2)
if job["requested_model"] != EXPECTED_MODEL:
    print("REFUSE_SELECTED_JOB_MODEL_MISMATCH")
    raise SystemExit(2)
if job["job_type"] != EXPECTED_JOB_TYPE:
    print("REFUSE_SELECTED_JOB_TYPE_MISMATCH")
    raise SystemExit(2)
if result_rows != 0:
    print("REFUSE_SELECTED_JOB_HAS_RESULT")
    raise SystemExit(2)

candidates = conn.execute(
    """
    SELECT
      j.id,
      j.job_type,
      j.requested_model,
      j.status,
      j.attempts,
      j.created_at,
      j.updated_at,
      COALESCE(r.result_rows, 0) AS result_rows
    FROM jobs j
    LEFT JOIN (
      SELECT job_id, COUNT(*) AS result_rows
      FROM job_results
      GROUP BY job_id
    ) r ON r.job_id = j.id
    WHERE j.status='queued'
      AND COALESCE(r.result_rows, 0)=0
      AND j.requested_model=?
    ORDER BY j.created_at, j.id
    """,
    (EXPECTED_MODEL,),
).fetchall()

eligible = [row for row in candidates if int(row["id"]) not in FORBIDDEN]
for row in candidates:
    marker = "ELIGIBLE_CANDIDATE" if int(row["id"]) not in FORBIDDEN else "REFUSE_FORBIDDEN_JOB_ID"
    print(
        f"{marker} job_id={row['id']} status={row['status']} attempts={row['attempts']} "
        f"model={row['requested_model']} result_rows={row['result_rows']} created={row['created_at']} updated={row['updated_at']}"
    )

print(f"E3V_DRY_RUN_ELIGIBLE_JOB_COUNT={len(eligible)}")

if len(eligible) != 1:
    print("REFUSE_MULTIPLE_ELIGIBLE_JOBS" if len(eligible) > 1 else "REFUSE_NO_ELIGIBLE_JOB")
    raise SystemExit(2)

selected = eligible[0]
if int(selected["id"]) != EXPECTED_JOB_ID:
    print("REFUSE_SELECTED_JOB_ID_NOT_29")
    raise SystemExit(2)

print(f"WOULD_ATOMIC_CLAIM job_id={selected['id']} model={selected['requested_model']} result_rows={selected['result_rows']}")
print("E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME")
print("CT203_READONLY_CANDIDATE_CHECK_OK")
PY

  ssh "$PVEW_SSH" "pct exec $CTID -- python3 -" < "$ct203_py" | tee "$RUN_DIR/ct203_readonly_candidate_check.txt"

  grep -F "DB_OPEN_MODE=sqlite_uri_mode_ro_immutable" "$RUN_DIR/ct203_readonly_candidate_check.txt"
  grep -F "DB_INTEGRITY=ok" "$RUN_DIR/ct203_readonly_candidate_check.txt"
  grep -F "DUPLICATE_JOB_RESULTS none" "$RUN_DIR/ct203_readonly_candidate_check.txt"
  grep -F "E3V_DRY_RUN_ELIGIBLE_JOB_COUNT=1" "$RUN_DIR/ct203_readonly_candidate_check.txt"
  grep -F "WOULD_ATOMIC_CLAIM job_id=29 " "$RUN_DIR/ct203_readonly_candidate_check.txt"
}

pveso_preflight() {
  pveso_ip="$(
    tailscale status 2>/dev/null \
      | awk 'tolower($2)=="pveso" {print $1; exit}'
  )"

  if [ -z "$pveso_ip" ]; then
    echo "REFUSE_PVESO_UNAVAILABLE"
    exit 2
  fi

  echo "PVESO_TAILSCALE_STATUS_LOOKUP=OK" | tee "$RUN_DIR/pveso_preflight.txt"

  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    -o LogLevel=ERROR \
    "root@$pveso_ip" '
set -euo pipefail
echo "PVESO_PREFLIGHT=begin"

ollama_state="$(systemctl is-active ollama 2>/dev/null || true)"
echo "OLLAMA_SERVICE_STATE=$ollama_state"
test "$ollama_state" = "active"

listener_lines="$(
  ss -H -ltnp 2>/dev/null \
    | grep ":11434" \
    | tr -s " " \
    | cut -d " " -f4 \
    || true
)"

localhost_count=0
nonlocal_count=0
while IFS= read -r addr; do
  [ -z "$addr" ] && continue
  case "$addr" in
    127.0.0.1:11434|\[::1\]:11434)
      localhost_count=$((localhost_count + 1))
      ;;
    *)
      nonlocal_count=$((nonlocal_count + 1))
      ;;
  esac
done <<EOF
$listener_lines
EOF

echo "OLLAMA_LOCALHOST_11434_LISTENER_COUNT=$localhost_count"
echo "OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=$nonlocal_count"
test "$localhost_count" -ge 1
test "$nonlocal_count" = "0"

runner_lines="$(ps -eo pid,ppid,etime,args | grep -E "ollama.*runner|ollama_llama_server|llama.*runner|api/generate|apc-one-shot-model-adapter" | grep -v grep || true)"
runner_count="$(printf "%s\n" "$runner_lines" | grep -c . || true)"
echo "PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT=$runner_count"
test "$runner_count" = "0"

if ollama list 2>/dev/null | awk "{print \$1}" | grep -Fx "qwen2.5:32b-instruct-q4_K_M" >/dev/null; then
  echo "TARGET_MODEL_PRESENT=true"
else
  echo "REFUSE_MODEL_MISSING"
  exit 2
fi

ct101_status="$(pct status 101 2>/dev/null | cut -d " " -f2 || true)"
ct101_onboot="$(pct config 101 2>/dev/null | grep "^onboot:" | cut -d " " -f2 || true)"
echo "CT101_STATUS=$ct101_status"
echo "CT101_ONBOOT=$ct101_onboot"
test "$ct101_status" = "stopped"
test "$ct101_onboot" = "0"

echo "PVESO_PREFLIGHT_OK"
' | sanitize_stream | tee -a "$RUN_DIR/pveso_preflight.txt"

  grep -F "PVESO_PREFLIGHT_OK" "$RUN_DIR/pveso_preflight.txt"
  grep -F "OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0" "$RUN_DIR/pveso_preflight.txt"
  grep -F "PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT=0" "$RUN_DIR/pveso_preflight.txt"
  grep -F "TARGET_MODEL_PRESENT=true" "$RUN_DIR/pveso_preflight.txt"
  grep -F "CT101_STATUS=stopped" "$RUN_DIR/pveso_preflight.txt"
  grep -F "CT101_ONBOOT=0" "$RUN_DIR/pveso_preflight.txt"

  printf "%s" "$pveso_ip" > "$RUN_DIR/pveso_ip.txt"
}

atomic_claim_job_29() {
  claim_py="$RUN_DIR/atomic_claim_job_29.py"
  cat > "$claim_py" <<'PY'
#!/usr/bin/env python3
import sqlite3
from datetime import datetime, timezone

DB = "/var/lib/edge-queue-controller/edge_queue.sqlite3"
JOB_ID = 29
EXPECTED_MODEL = "qwen2.5:32b-instruct-q4_K_M"

def now():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

conn = sqlite3.connect(DB, isolation_level=None)
conn.row_factory = sqlite3.Row
conn.execute("PRAGMA busy_timeout=5000")

print("E3V_Q_ATOMIC_CLAIM=begin")
integrity_before = conn.execute("PRAGMA integrity_check").fetchone()[0]
print(f"DB_INTEGRITY_BEFORE_CLAIM={integrity_before}")
if integrity_before != "ok":
    print("REFUSE_DB_INTEGRITY_NOT_OK")
    raise SystemExit(2)

before = conn.execute(
    """
    SELECT j.id, j.status, j.attempts, j.requested_model, COUNT(r.job_id) AS result_rows
    FROM jobs j
    LEFT JOIN job_results r ON r.job_id = j.id
    WHERE j.id=?
    GROUP BY j.id
    """,
    (JOB_ID,),
).fetchone()
if before is None:
    print("REFUSE_SELECTED_JOB_MISSING")
    raise SystemExit(2)

print(
    f"E3V_Q_JOB_BEFORE_CLAIM id={before['id']} status={before['status']} "
    f"attempts={before['attempts']} model={before['requested_model']} result_rows={before['result_rows']}"
)

if before["status"] != "queued":
    print("REFUSE_SELECTED_JOB_NOT_QUEUED")
    raise SystemExit(2)
if int(before["attempts"]) != 0:
    print("REFUSE_SELECTED_JOB_ATTEMPTS_NOT_ZERO")
    raise SystemExit(2)
if before["requested_model"] != EXPECTED_MODEL:
    print("REFUSE_SELECTED_JOB_MODEL_MISMATCH")
    raise SystemExit(2)
if int(before["result_rows"]) != 0:
    print("REFUSE_SELECTED_JOB_HAS_RESULT")
    raise SystemExit(2)

try:
    conn.execute("BEGIN IMMEDIATE")
    cur = conn.execute(
        """
        UPDATE jobs
        SET status='running',
            attempts=attempts+1,
            updated_at=?
        WHERE id=?
          AND id=29
          AND status='queued'
          AND attempts=0
          AND requested_model=?
          AND NOT EXISTS (
            SELECT 1 FROM job_results WHERE job_id=?
          )
        """,
        (now(), JOB_ID, EXPECTED_MODEL, JOB_ID),
    )
    changes = cur.rowcount
    print(f"E3V_Q_ATOMIC_CLAIM_CHANGES={changes}")

    if changes != 1:
        conn.execute("ROLLBACK")
        print("REFUSE_ATOMIC_CLAIM_NOT_ONE")
        raise SystemExit(2)

    after = conn.execute(
        """
        SELECT j.id, j.status, j.attempts, j.requested_model, COUNT(r.job_id) AS result_rows
        FROM jobs j
        LEFT JOIN job_results r ON r.job_id = j.id
        WHERE j.id=?
        GROUP BY j.id
        """,
        (JOB_ID,),
    ).fetchone()

    print(f"E3V_Q_JOB_STATUS_AFTER_CLAIM={after['status']}")
    print(f"E3V_Q_JOB_ATTEMPTS_AFTER_CLAIM={after['attempts']}")
    print(f"E3V_Q_JOB_RESULT_ROWS_AFTER_CLAIM={after['result_rows']}")

    if after["status"] != "running":
        print("REFUSE_ATOMIC_CLAIM_NOT_ONE")
        conn.execute("ROLLBACK")
        raise SystemExit(2)
    if int(after["attempts"]) != 1:
        print("REFUSE_ATOMIC_CLAIM_NOT_ONE")
        conn.execute("ROLLBACK")
        raise SystemExit(2)
    if int(after["result_rows"]) != 0:
        print("REFUSE_SELECTED_JOB_HAS_RESULT")
        conn.execute("ROLLBACK")
        raise SystemExit(2)

    conn.execute("COMMIT")
except Exception:
    try:
        conn.execute("ROLLBACK")
    except Exception:
        pass
    raise

print("E3V_Q_ATOMIC_CLAIM_OK")
PY

  ssh "$PVEW_SSH" "pct exec $CTID -- python3 -" < "$claim_py" | tee "$RUN_DIR/atomic_claim_result.txt"

  grep -F "E3V_Q_ATOMIC_CLAIM_CHANGES=1" "$RUN_DIR/atomic_claim_result.txt"
  grep -F "E3V_Q_JOB_STATUS_AFTER_CLAIM=running" "$RUN_DIR/atomic_claim_result.txt"
  grep -F "E3V_Q_JOB_ATTEMPTS_AFTER_CLAIM=1" "$RUN_DIR/atomic_claim_result.txt"
  grep -F "E3V_Q_JOB_RESULT_ROWS_AFTER_CLAIM=0" "$RUN_DIR/atomic_claim_result.txt"
  grep -F "E3V_Q_ATOMIC_CLAIM_OK" "$RUN_DIR/atomic_claim_result.txt"
}

call_one_shot_model_adapter() {
  pveso_ip="$(cat "$RUN_DIR/pveso_ip.txt")"
  model_call_py="$RUN_DIR/pveso_ollama_generate_job_29.py"
  cat > "$model_call_py" <<'PY'
#!/usr/bin/env python3
import base64
import json
import sys
import urllib.request

MODEL = "qwen2.5:32b-instruct-q4_K_M"
PROMPT = "Stage 16 E3V fresh eligible Option B atomic-claim smoke. Reply with a short deterministic confirmation."
URL = "http://127.0.0.1:11434/api/generate"

payload = {
    "model": MODEL,
    "prompt": PROMPT,
    "stream": False,
    "options": {
        "temperature": 0,
        "num_predict": 64,
    },
}
data = json.dumps(payload).encode("utf-8")
req = urllib.request.Request(URL, data=data, headers={"Content-Type": "application/json"}, method="POST")

with urllib.request.urlopen(req, timeout=900) as resp:
    raw = resp.read()

obj = json.loads(raw.decode("utf-8"))
response_text = obj.get("response", "")
if not isinstance(response_text, str) or not response_text.strip():
    print("ONE_SHOT_MODEL_ADAPTER_RESULT=error")
    print("REFUSE_RUNTIME_MARKER_MISSING")
    raise SystemExit(2)

print("ONE_SHOT_MODEL_ADAPTER_RESULT=ok")
print(f"ONE_SHOT_MODEL_ADAPTER_MODEL={MODEL}")
print("MODEL_RESPONSE_TEXT_B64=" + base64.b64encode(response_text.encode("utf-8")).decode("ascii"))
print("MODEL_RESPONSE_JSON_B64=" + base64.b64encode(json.dumps(obj, sort_keys=True).encode("utf-8")).decode("ascii"))
PY

  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    -o LogLevel=ERROR \
    "root@$pveso_ip" \
    "python3 -" < "$model_call_py" | sanitize_stream | tee "$RUN_DIR/model_adapter_result.txt"

  grep -F "ONE_SHOT_MODEL_ADAPTER_RESULT=ok" "$RUN_DIR/model_adapter_result.txt"
  grep -F "ONE_SHOT_MODEL_ADAPTER_MODEL=$EXPECTED_MODEL" "$RUN_DIR/model_adapter_result.txt"
  grep -F "MODEL_RESPONSE_TEXT_B64=" "$RUN_DIR/model_adapter_result.txt"
  grep -F "MODEL_RESPONSE_JSON_B64=" "$RUN_DIR/model_adapter_result.txt"
}

complete_job_29() {
  response_text_b64="$(grep -F "MODEL_RESPONSE_TEXT_B64=" "$RUN_DIR/model_adapter_result.txt" | tail -n1 | cut -d= -f2-)"
  response_json_b64="$(grep -F "MODEL_RESPONSE_JSON_B64=" "$RUN_DIR/model_adapter_result.txt" | tail -n1 | cut -d= -f2-)"

  completion_py="$RUN_DIR/complete_job_29.py"
  cat > "$completion_py" <<'PY'
#!/usr/bin/env python3
import base64
import os
import sqlite3
from datetime import datetime, timezone

DB = "/var/lib/edge-queue-controller/edge_queue.sqlite3"
JOB_ID = 29
EXPECTED_MODEL = "qwen2.5:32b-instruct-q4_K_M"

def now():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")

response_text = base64.b64decode(os.environ["MODEL_RESPONSE_TEXT_B64"]).decode("utf-8")
response_json = base64.b64decode(os.environ["MODEL_RESPONSE_JSON_B64"]).decode("utf-8")

conn = sqlite3.connect(DB, isolation_level=None)
conn.row_factory = sqlite3.Row
conn.execute("PRAGMA busy_timeout=5000")

print("E3V_Q_COMPLETION=begin")

required_result_cols = {"job_id", "model", "response_text", "response_json", "error", "created_at", "updated_at"}
result_cols = {row["name"] for row in conn.execute("PRAGMA table_info(job_results)").fetchall()}
missing = sorted(required_result_cols - result_cols)
if missing:
    print("REFUSE_JOB_RESULTS_SCHEMA_MISSING_REQUIRED_COLUMNS=" + ",".join(missing))
    raise SystemExit(2)

try:
    conn.execute("BEGIN IMMEDIATE")

    before = conn.execute(
        """
        SELECT j.id, j.status, j.attempts, j.requested_model, COUNT(r.job_id) AS result_rows
        FROM jobs j
        LEFT JOIN job_results r ON r.job_id = j.id
        WHERE j.id=?
        GROUP BY j.id
        """,
        (JOB_ID,),
    ).fetchone()

    print(
        f"E3V_Q_JOB_BEFORE_COMPLETION id={before['id']} status={before['status']} "
        f"attempts={before['attempts']} model={before['requested_model']} result_rows={before['result_rows']}"
    )

    cur = conn.execute(
        """
        UPDATE jobs
        SET status='completed',
            last_error=NULL,
            updated_at=?
        WHERE id=?
          AND id=29
          AND status='running'
          AND requested_model=?
          AND NOT EXISTS (
            SELECT 1 FROM job_results WHERE job_id=?
          )
        """,
        (now(), JOB_ID, EXPECTED_MODEL, JOB_ID),
    )
    changes = cur.rowcount
    print(f"E3V_Q_COMPLETION_CHANGES={changes}")

    if changes != 1:
        print("REFUSE_COMPLETION_NOT_ONE")
        conn.execute("ROLLBACK")
        raise SystemExit(2)

    ts = now()
    conn.execute(
        """
        INSERT INTO job_results (
          job_id,
          model,
          response_text,
          response_json,
          error,
          created_at,
          updated_at
        )
        VALUES (?, ?, ?, ?, NULL, ?, ?)
        """,
        (JOB_ID, EXPECTED_MODEL, response_text, response_json, ts, ts),
    )

    after = conn.execute(
        """
        SELECT j.id, j.status, j.attempts, j.requested_model, COUNT(r.job_id) AS result_rows
        FROM jobs j
        LEFT JOIN job_results r ON r.job_id = j.id
        WHERE j.id=?
        GROUP BY j.id
        """,
        (JOB_ID,),
    ).fetchone()

    print(f"E3V_Q_JOB_STATUS_AFTER_COMPLETION={after['status']}")
    print(f"E3V_Q_JOB_ATTEMPTS_AFTER_COMPLETION={after['attempts']}")
    print(f"E3V_Q_JOB_RESULT_ROWS_AFTER_COMPLETION={after['result_rows']}")

    if after["status"] != "completed":
        print("REFUSE_COMPLETION_NOT_ONE")
        conn.execute("ROLLBACK")
        raise SystemExit(2)
    if int(after["attempts"]) != 1:
        print("REFUSE_COMPLETION_NOT_ONE")
        conn.execute("ROLLBACK")
        raise SystemExit(2)
    if int(after["result_rows"]) != 1:
        print("REFUSE_COMPLETION_NOT_ONE")
        conn.execute("ROLLBACK")
        raise SystemExit(2)

    conn.execute("COMMIT")
except Exception:
    try:
        conn.execute("ROLLBACK")
    except Exception:
        pass
    raise

integrity_after = conn.execute("PRAGMA integrity_check").fetchone()[0]
print(f"DB_INTEGRITY_AFTER={integrity_after}")
if integrity_after != "ok":
    print("REFUSE_DB_INTEGRITY_NOT_OK")
    raise SystemExit(2)

dup_rows = conn.execute(
    "SELECT job_id, COUNT(*) AS c FROM job_results GROUP BY job_id HAVING COUNT(*) > 1 ORDER BY job_id"
).fetchall()
if dup_rows:
    for row in dup_rows:
        print(f"DUPLICATE_JOB_RESULTS job_id={row['job_id']} count={row['c']}")
    print("REFUSE_DUPLICATE_JOB_RESULTS")
    raise SystemExit(2)
print("DUPLICATE_JOB_RESULTS none")

print("E3V_Q_COMPLETION_OK")
PY

  ssh "$PVEW_SSH" "pct exec $CTID -- env MODEL_RESPONSE_TEXT_B64='$response_text_b64' MODEL_RESPONSE_JSON_B64='$response_json_b64' python3 -" \
    < "$completion_py" | tee "$RUN_DIR/completion_result.txt"

  grep -F "E3V_Q_COMPLETION_CHANGES=1" "$RUN_DIR/completion_result.txt"
  grep -F "E3V_Q_JOB_STATUS_AFTER_COMPLETION=completed" "$RUN_DIR/completion_result.txt"
  grep -F "E3V_Q_JOB_ATTEMPTS_AFTER_COMPLETION=1" "$RUN_DIR/completion_result.txt"
  grep -F "E3V_Q_JOB_RESULT_ROWS_AFTER_COMPLETION=1" "$RUN_DIR/completion_result.txt"
  grep -F "DB_INTEGRITY_AFTER=ok" "$RUN_DIR/completion_result.txt"
  grep -F "DUPLICATE_JOB_RESULTS none" "$RUN_DIR/completion_result.txt"
  grep -F "E3V_Q_COMPLETION_OK" "$RUN_DIR/completion_result.txt"
}

postflight() {
  pveso_ip="$(cat "$RUN_DIR/pveso_ip.txt")"

  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    -o LogLevel=ERROR \
    "root@$pveso_ip" '
set -euo pipefail
runner_lines="$(ps -eo pid,ppid,etime,args | grep -E "ollama.*runner|ollama_llama_server|llama.*runner|api/generate|apc-one-shot-model-adapter" | grep -v grep || true)"
runner_count="$(printf "%s\n" "$runner_lines" | grep -c . || true)"
echo "PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT_AFTER=$runner_count"

ct101_status="$(pct status 101 2>/dev/null | cut -d " " -f2 || true)"
ct101_onboot="$(pct config 101 2>/dev/null | grep "^onboot:" | cut -d " " -f2 || true)"
echo "CT101_STATUS_AFTER=$ct101_status"
echo "CT101_ONBOOT_AFTER=$ct101_onboot"

test "$runner_count" = "0"
test "$ct101_status" = "stopped"
test "$ct101_onboot" = "0"
' | sanitize_stream | tee "$RUN_DIR/postflight_pveso_ct101.txt"

  grep -F "PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT_AFTER=0" "$RUN_DIR/postflight_pveso_ct101.txt"
  grep -F "CT101_STATUS_AFTER=stopped" "$RUN_DIR/postflight_pveso_ct101.txt"
  grep -F "CT101_ONBOOT_AFTER=0" "$RUN_DIR/postflight_pveso_ct101.txt"
}

echo "STAGE=$STAGE"

case "$MODE" in
  --dry-run)
    echo "MODE=dry-run"
    mkdir -p "$RUN_DIR"
    write_recovery_hint
    echo "RUN_DIR=$RUN_DIR"
    echo "NO_DB_WRITE"
    echo "NO_SCHEMA_MIGRATION"
    echo "NO_DB_CLAIM"
    echo "NO_HELPER_CALL"
    echo "NO_ADAPTER_CALL"
    echo "NO_MODEL_CALL"
    echo "SCHEDULER_ACTIVATION=not_performed"
    echo "PERSISTENT_WORKER_ACTIVATION=not_performed"
    repo_preflight
    scheduler_worker_preflight
    before_stat="$(ct203_db_stat)"
    echo "$before_stat" | tee "$RUN_DIR/ct203_db_stat_before.txt"
    ct203_readonly_candidate_check
    pveso_preflight
    after_stat="$(ct203_db_stat)"
    echo "$after_stat" | tee "$RUN_DIR/ct203_db_stat_after.txt"
    test "$before_stat" = "$after_stat"
    echo "CT203_DB_STAT_UNCHANGED=true"
    echo "E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME" | tee "$RUN_DIR/final_status.txt"
    echo "E3V_OPTION_B_DRY_RUN_GUARD_PREFLIGHT_OK" | tee -a "$RUN_DIR/final_status.txt"
    cat "$RUN_DIR/final_status.txt"
    ;;
  --execute-approved)
    echo "MODE=execute-approved"
    if [ "${APPROVAL:-}" != "$RUNTIME_APPROVAL" ]; then
      echo "REFUSE_APPROVAL_MISSING"
      exit 2
    fi
    if [ "$FRESH_JOB_ID" != "29" ] || [ "$EXPECTED_SELECTED_JOB_ID" != "29" ]; then
      echo "REFUSE_SELECTED_JOB_ID_NOT_29"
      exit 2
    fi
    mkdir -p "$RUN_DIR"
    write_recovery_hint
    echo "RUN_DIR=$RUN_DIR"
    echo "RUNTIME_APPROVAL_CAPTURED=$RUNTIME_APPROVAL"
    echo "RUNTIME_SCOPE=job_id_29_only"
    repo_preflight
    scheduler_worker_preflight
    before_stat="$(ct203_db_stat)"
    echo "$before_stat" | tee "$RUN_DIR/ct203_db_stat_before.txt"
    ct203_readonly_candidate_check
    pveso_preflight
    atomic_claim_job_29
    call_one_shot_model_adapter
    complete_job_29
    postflight
    after_stat="$(ct203_db_stat)"
    echo "$after_stat" | tee "$RUN_DIR/ct203_db_stat_after.txt"
    echo "E3V_Q_OPTION_B_ATOMIC_CLAIM_DISPATCH_JOB_29_OK" | tee "$RUN_DIR/final_status.txt"
    cat "$RUN_DIR/final_status.txt"
    ;;
  "")
    echo "REFUSE_MODE_REQUIRED"
    echo "EXPECTED_MODE=--dry-run or --execute-approved"
    exit 2
    ;;
  *)
    echo "REFUSE_UNKNOWN_MODE"
    echo "mode=$MODE"
    exit 2
    ;;
esac
