#!/usr/bin/env bash
set -euo pipefail

# E3X_E_APPROVAL_COMPAT_SHIM_BEGIN
# Allow phase-specific runtime approval without weakening the existing E3W-F approval gate.
# The existing wrapper still enforces its original approval internally; this shim maps
# a whitelisted phase-specific approval to that original internal approval only when
# E3W_REQUIRED_APPROVAL exactly matches E3W_APPROVAL.
if [ -n "${E3W_REQUIRED_APPROVAL:-}" ]; then
  case "$E3W_REQUIRED_APPROVAL" in
    "APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY"|"APPROVE_STAGE_16_E3X_E_RUN_ONE_SMALL_MODEL_TIMEOUT_SAFE_JOB_ONLY")
      echo "RUNTIME_REQUIRED_APPROVAL=$E3W_REQUIRED_APPROVAL"
      if [ "${E3W_APPROVAL:-}" = "$E3W_REQUIRED_APPROVAL" ]; then
        E3W_APPROVAL="APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY"
        export E3W_APPROVAL
        echo "RUNTIME_APPROVAL_OVERRIDE_ACCEPTED=true"
      fi
      ;;
    *)
      echo "REFUSE_E3W_TIMEOUT_SAFE_WRAPPER: unsupported runtime required approval"
      exit 2
      ;;
  esac
fi
# E3X_E_APPROVAL_COMPAT_SHIM_END


MODE="${1:---dry-run}"

REQUIRED_APPROVAL="APPROVE_STAGE_16_E3W_F_RUN_ONE_TIMEOUT_SAFE_JOB_ONLY"
APPROVAL="${E3W_APPROVAL:-}"
JOB_ID="${E3W_EXPECTED_JOB_ID:-}"
EXPECTED_MODEL="${E3W_EXPECTED_MODEL:-}"
EXPECTED_JOB_TYPE="${E3W_EXPECTED_JOB_TYPE:-stage16_e3w_timeout_safe_one_job_model_smoke}"
DB="${E3W_CT203_DB:-/var/lib/edge-queue-controller/edge_queue.sqlite3}"

MODEL_TIMEOUT_SECONDS="${E3W_MODEL_TIMEOUT_SECONDS:-45}"
WRAPPER_TOTAL_SECONDS="${E3W_WRAPPER_TOTAL_SECONDS:-120}"
NUM_PREDICT="${E3W_NUM_PREDICT:-8}"
TEMPERATURE="${E3W_TEMPERATURE:-0}"

RUN_DIR="${E3W_RUN_DIR:-/tmp/apc-e3w-timeout-safe-one-job-${JOB_ID:-unset}-$(date -u +%Y%m%dT%H%M%SZ)}"
mkdir -p "$RUN_DIR"

echo "=== Stage 16 E3W timeout-safe one-job dispatch wrapper ==="
echo "MODE=$MODE"
echo "RUN_DIR=$RUN_DIR"
echo "EXPECTED_JOB_ID=${JOB_ID:-unset}"
echo "EXPECTED_MODEL=${EXPECTED_MODEL:-unset}"
echo "EXPECTED_JOB_TYPE=$EXPECTED_JOB_TYPE"
echo "MODEL_TIMEOUT_SECONDS=$MODEL_TIMEOUT_SECONDS"
echo "WRAPPER_TOTAL_SECONDS=$WRAPPER_TOTAL_SECONDS"
echo "NUM_PREDICT=$NUM_PREDICT"
echo "TEMPERATURE=$TEMPERATURE"
echo "DO_NOT_RERUN_E3V_Q"
echo "DO_NOT_RETRY_JOB_29"

refuse() {
  echo "REFUSE_E3W_TIMEOUT_SAFE_WRAPPER: $*"
  exit 2
}

case "$MODE" in
  --dry-run|--run) ;;
  *) refuse "mode must be --dry-run or --run" ;;
esac

if [ -z "$JOB_ID" ]; then
  refuse "E3W_EXPECTED_JOB_ID is required"
fi
if [ "$JOB_ID" = "29" ]; then
  refuse "job 29 is closed failed and must not be retried"
fi
if [ -z "$EXPECTED_MODEL" ]; then
  refuse "E3W_EXPECTED_MODEL is required"
fi

case "$MODEL_TIMEOUT_SECONDS" in
  ''|*[!0-9]*) refuse "E3W_MODEL_TIMEOUT_SECONDS must be numeric" ;;
esac
case "$WRAPPER_TOTAL_SECONDS" in
  ''|*[!0-9]*) refuse "E3W_WRAPPER_TOTAL_SECONDS must be numeric" ;;
esac
case "$NUM_PREDICT" in
  ''|*[!0-9]*) refuse "E3W_NUM_PREDICT must be numeric" ;;
esac

if [ "$MODEL_TIMEOUT_SECONDS" -ge "$WRAPPER_TOTAL_SECONDS" ]; then
  refuse "model timeout must be lower than wrapper total timeout"
fi

if [ "$MODE" = "--run" ]; then
  if [ "$APPROVAL" != "$REQUIRED_APPROVAL" ]; then
    refuse "runtime approval missing or wrong"
  fi
else
  echo "E3W_TIMEOUT_SAFE_WRAPPER_DRY_RUN_ONLY"
fi

if [ "$(git status --short)" != "" ]; then
  refuse "repo dirty"
fi

pveso_ip="$(
  tailscale status 2>/dev/null \
    | awk 'tolower($2)=="pveso" {print $1; exit}'
)"
if [ -z "$pveso_ip" ]; then
  refuse "PVESO tailscale lookup missing"
fi
printf "%s\n" "$pveso_ip" > "$RUN_DIR/pveso_ip.txt"

echo
echo "=== scheduler/persistent worker disabled preflight ==="
{
  if systemctl list-unit-files 2>/dev/null | grep -E 'edge.*scheduler|queue.*scheduler|lane.*worker|persistent.*worker' >/dev/null; then
    echo "SCHEDULER_OR_WORKER_UNIT_FILES_PRESENT=review_required"
  else
    echo "SCHEDULER_OR_WORKER_UNIT_FILES_PRESENT=none_detected"
  fi
  echo "E3W_SCHEDULER_PERSISTENT_WORKER_PREFLIGHT_REVIEWED"
} | tee "$RUN_DIR/scheduler_worker_preflight.txt"

echo
echo "=== CT203 read-only candidate preflight ==="
ssh pvew "pct exec 203 -- env JOB_ID='$JOB_ID' EXPECTED_MODEL='$EXPECTED_MODEL' EXPECTED_JOB_TYPE='$EXPECTED_JOB_TYPE' DB='$DB' python3 -" <<'PY' | tee "$RUN_DIR/ct203_readonly_candidate_preflight.txt"
import os, sqlite3, sys

DB=os.environ["DB"]
JOB_ID=int(os.environ["JOB_ID"])
EXPECTED_MODEL=os.environ["EXPECTED_MODEL"]
EXPECTED_JOB_TYPE=os.environ["EXPECTED_JOB_TYPE"]

conn=sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
conn.row_factory=sqlite3.Row
conn.execute("PRAGMA query_only=ON")

print("E3W_READONLY_CANDIDATE_PREFLIGHT=begin")
integrity=conn.execute("PRAGMA integrity_check").fetchone()[0]
print(f"DB_INTEGRITY={integrity}")
if integrity != "ok":
    print("REFUSE_DB_INTEGRITY_NOT_OK")
    sys.exit(2)

dup=conn.execute("SELECT job_id, COUNT(*) AS c FROM job_results GROUP BY job_id HAVING COUNT(*) > 1").fetchall()
if dup:
    for row in dup:
        print(f"DUPLICATE_JOB_RESULTS job_id={row['job_id']} count={row['c']}")
    print("REFUSE_DUPLICATE_JOB_RESULTS")
    sys.exit(2)
print("DUPLICATE_JOB_RESULTS none")

job=conn.execute("""
SELECT id,status,attempts,requested_model,job_type,last_error,updated_at
FROM jobs
WHERE id=?
""", (JOB_ID,)).fetchone()
if not job:
    print("REFUSE_EXPECTED_JOB_MISSING")
    sys.exit(2)

result_rows=conn.execute("SELECT COUNT(*) FROM job_results WHERE job_id=?", (JOB_ID,)).fetchone()[0]
eligible_count=conn.execute("""
SELECT COUNT(*)
FROM jobs j
LEFT JOIN (SELECT job_id, COUNT(*) AS c FROM job_results GROUP BY job_id) r
  ON r.job_id=j.id
WHERE j.id=?
  AND j.status='queued'
  AND COALESCE(j.attempts,0)=0
  AND j.requested_model=?
  AND j.job_type=?
  AND COALESCE(r.c,0)=0
""", (JOB_ID, EXPECTED_MODEL, EXPECTED_JOB_TYPE)).fetchone()[0]

print(
    f"E3W_CANDIDATE_JOB id={job['id']} status={job['status']} attempts={job['attempts']} "
    f"model={job['requested_model']} job_type={job['job_type']} result_rows={result_rows} "
    f"last_error={job['last_error']} updated_at={job['updated_at']}"
)
print(f"E3W_EXPECTED_ELIGIBLE_JOB_COUNT={eligible_count}")

if job["status"] != "queued":
    print("REFUSE_EXPECTED_JOB_NOT_QUEUED")
    sys.exit(2)
if int(job["attempts"] or 0) != 0:
    print("REFUSE_EXPECTED_JOB_ATTEMPTS_NOT_ZERO")
    sys.exit(2)
if job["requested_model"] != EXPECTED_MODEL:
    print("REFUSE_EXPECTED_JOB_MODEL_MISMATCH")
    sys.exit(2)
if job["job_type"] != EXPECTED_JOB_TYPE:
    print("REFUSE_EXPECTED_JOB_TYPE_MISMATCH")
    sys.exit(2)
if result_rows != 0:
    print("REFUSE_EXPECTED_JOB_HAS_RESULT")
    sys.exit(2)
if eligible_count != 1:
    print("REFUSE_E3W_ELIGIBLE_COUNT_NOT_ONE")
    sys.exit(2)

print("E3W_READONLY_CANDIDATE_PREFLIGHT_OK")
PY

grep -F "E3W_READONLY_CANDIDATE_PREFLIGHT_OK" "$RUN_DIR/ct203_readonly_candidate_preflight.txt"

echo
echo "=== PVESO read-only runtime preflight ==="
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

localhost_count="$(ss -H -ltnp 2>/dev/null | grep -E "(127\.0\.0\.1|\[::1\]):11434" | grep -c . || true)"
nonlocal_count="$(ss -H -ltnp 2>/dev/null | grep ":11434" | grep -Ev "(127\.0\.0\.1|\[::1\]):11434" | grep -c . || true)"
echo "OLLAMA_LOCALHOST_11434_LISTENER_COUNT=$localhost_count"
echo "OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=$nonlocal_count"

active_lines="$(ps -eo pid,ppid,etime,stat,args \
  | grep -E "apc-one-shot-model-adapter|pveso_ollama_generate|urllib.request|api/generate|ollama runner|ollama_llama_server" \
  | grep -v grep \
  || true)"
active_count="$(printf "%s\n" "$active_lines" | grep -c . || true)"
echo "PVESO_ACTIVE_MODEL_CLIENT_OR_RUNNER_COUNT=$active_count"
if [ "$active_count" != "0" ]; then
  echo "PVESO_ACTIVE_MODEL_CLIENT_OR_RUNNER_LINES_BEGIN"
  printf "%s\n" "$active_lines"
  echo "PVESO_ACTIVE_MODEL_CLIENT_OR_RUNNER_LINES_END"
fi

ct101_status="$(pct status 101 2>/dev/null | cut -d " " -f2 || true)"
ct101_onboot="$(pct config 101 2>/dev/null | grep "^onboot:" | cut -d " " -f2 || true)"
echo "CT101_STATUS=$ct101_status"
echo "CT101_ONBOOT=$ct101_onboot"

if [ "$ollama_state" != "active" ]; then echo "REFUSE_OLLAMA_NOT_ACTIVE"; exit 2; fi
if [ "$localhost_count" = "0" ]; then echo "REFUSE_LOCALHOST_LISTENER_MISSING"; exit 2; fi
if [ "$nonlocal_count" != "0" ]; then echo "REFUSE_NONLOCALHOST_LISTENER_PRESENT"; exit 2; fi
if [ "$active_count" != "0" ]; then echo "REFUSE_ACTIVE_MODEL_CLIENT_OR_RUNNER"; exit 2; fi
if [ "$ct101_status" != "stopped" ]; then echo "REFUSE_CT101_NOT_STOPPED"; exit 2; fi
if [ "$ct101_onboot" != "0" ]; then echo "REFUSE_CT101_ONBOOT_NOT_ZERO"; exit 2; fi

echo "E3W_PVESO_PREFLIGHT_OK"
' | sed -E \
    -e 's/100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-tailscale-ip>/g' \
    -e 's/10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/192\.168\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    | tee "$RUN_DIR/pveso_preflight.txt"

grep -F "E3W_PVESO_PREFLIGHT_OK" "$RUN_DIR/pveso_preflight.txt"

if [ "$MODE" = "--dry-run" ]; then
  echo
  echo "WOULD_ATOMIC_CLAIM job_id=$JOB_ID model=$EXPECTED_MODEL"
  echo "WOULD_USE_MODEL_TIMEOUT_SECONDS=$MODEL_TIMEOUT_SECONDS"
  echo "WOULD_USE_WRAPPER_TOTAL_SECONDS=$WRAPPER_TOTAL_SECONDS"
  echo "WOULD_USE_NUM_PREDICT=$NUM_PREDICT"
  echo "WOULD_MARK_FAILED_INTERNALLY_ON_MODEL_TIMEOUT_OR_ERROR"
  echo "E3W_TIMEOUT_SAFE_DRY_RUN_WOULD_CLAIM_ONE_JOB_NO_RUNTIME"
  exit 0
fi

echo
echo "=== atomic claim ==="
ssh pvew "pct exec 203 -- env JOB_ID='$JOB_ID' EXPECTED_MODEL='$EXPECTED_MODEL' EXPECTED_JOB_TYPE='$EXPECTED_JOB_TYPE' DB='$DB' python3 -" <<'PY' | tee "$RUN_DIR/atomic_claim_result.txt"
import os, sqlite3, sys
from datetime import datetime, timezone

DB=os.environ["DB"]
JOB_ID=int(os.environ["JOB_ID"])
EXPECTED_MODEL=os.environ["EXPECTED_MODEL"]
EXPECTED_JOB_TYPE=os.environ["EXPECTED_JOB_TYPE"]

conn=sqlite3.connect(DB, timeout=30)
conn.row_factory=sqlite3.Row
try:
    conn.execute("BEGIN IMMEDIATE")
    now=datetime.now(timezone.utc).isoformat().replace("+00:00","Z")
    conn.execute("""
    UPDATE jobs
    SET status='running',
        attempts=COALESCE(attempts,0)+1,
        updated_at=?
    WHERE id=?
      AND status='queued'
      AND COALESCE(attempts,0)=0
      AND requested_model=?
      AND job_type=?
      AND NOT EXISTS (SELECT 1 FROM job_results WHERE job_id=?)
    """, (now, JOB_ID, EXPECTED_MODEL, EXPECTED_JOB_TYPE, JOB_ID))
    changes=conn.execute("SELECT changes()").fetchone()[0]
    print(f"E3W_RUNTIME_ATOMIC_CLAIM_CHANGES={changes}")
    if changes != 1:
        print("REFUSE_E3W_ATOMIC_CLAIM_NOT_ONE")
        conn.rollback()
        sys.exit(2)
    row=conn.execute("SELECT id,status,attempts,requested_model,job_type FROM jobs WHERE id=?", (JOB_ID,)).fetchone()
    result_rows=conn.execute("SELECT COUNT(*) FROM job_results WHERE job_id=?", (JOB_ID,)).fetchone()[0]
    print(f"E3W_JOB_AFTER_CLAIM id={row['id']} status={row['status']} attempts={row['attempts']} model={row['requested_model']} job_type={row['job_type']} result_rows={result_rows}")
    conn.commit()
    print("E3W_RUNTIME_ATOMIC_CLAIM_OK")
except Exception:
    try: conn.rollback()
    except Exception: pass
    raise
finally:
    conn.close()
PY

grep -F "E3W_RUNTIME_ATOMIC_CLAIM_CHANGES=1" "$RUN_DIR/atomic_claim_result.txt"
grep -F "E3W_RUNTIME_ATOMIC_CLAIM_OK" "$RUN_DIR/atomic_claim_result.txt"

mark_failed() {
  local msg="$1"
  echo "=== guarded internal failure update ==="
  ssh pvew "pct exec 203 -- env JOB_ID='$JOB_ID' EXPECTED_MODEL='$EXPECTED_MODEL' DB='$DB' ERROR_TEXT='$msg' python3 -" <<'PY' | tee "$RUN_DIR/internal_failure_update.txt"
import os, sqlite3, sys
from datetime import datetime, timezone

DB=os.environ["DB"]
JOB_ID=int(os.environ["JOB_ID"])
EXPECTED_MODEL=os.environ["EXPECTED_MODEL"]
ERROR_TEXT=os.environ["ERROR_TEXT"]

conn=sqlite3.connect(DB, timeout=30)
conn.row_factory=sqlite3.Row
try:
    conn.execute("BEGIN IMMEDIATE")
    now=datetime.now(timezone.utc).isoformat().replace("+00:00","Z")
    conn.execute("""
    UPDATE jobs
    SET status='failed',
        last_error=?,
        updated_at=?
    WHERE id=?
      AND status='running'
      AND attempts=1
      AND requested_model=?
      AND NOT EXISTS (SELECT 1 FROM job_results WHERE job_id=?)
    """, (ERROR_TEXT, now, JOB_ID, EXPECTED_MODEL, JOB_ID))
    changes=conn.execute("SELECT changes()").fetchone()[0]
    print(f"E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES={changes}")
    if changes != 1:
        print("REFUSE_E3W_INTERNAL_FAILURE_UPDATE_NOT_ONE")
        conn.rollback()
        sys.exit(2)
    conn.commit()
    print("E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_OK")
except Exception:
    try: conn.rollback()
    except Exception: pass
    raise
finally:
    conn.close()
PY
}

echo
echo "=== one model call with bounded timeout ==="
set +e
ssh \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  -o UserKnownHostsFile=/dev/null \
  -o StrictHostKeyChecking=no \
  -o LogLevel=ERROR \
  "root@$pveso_ip" \
  "env EXPECTED_MODEL='$EXPECTED_MODEL' NUM_PREDICT='$NUM_PREDICT' TEMPERATURE='$TEMPERATURE' MODEL_TIMEOUT_SECONDS='$MODEL_TIMEOUT_SECONDS' python3 -" <<'PY' > "$RUN_DIR/model_call_result.txt" 2>&1
import json, os, sys, urllib.request, urllib.error

model=os.environ["EXPECTED_MODEL"]
num_predict=int(os.environ["NUM_PREDICT"])
temperature=float(os.environ["TEMPERATURE"])
timeout=int(os.environ["MODEL_TIMEOUT_SECONDS"])

payload={
  "model": model,
  "prompt": "Reply with exactly: E3W_TIMEOUT_SAFE_OK",
  "stream": False,
  "options": {
    "temperature": temperature,
    "num_predict": num_predict
  }
}

req=urllib.request.Request(
    "http://127.0.0.1:11434/api/generate",
    data=json.dumps(payload).encode("utf-8"),
    headers={"Content-Type":"application/json"},
    method="POST",
)

try:
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        body=resp.read().decode("utf-8", errors="replace")
    data=json.loads(body)
    response=(data.get("response") or "").strip()
    print("E3W_ONE_SHOT_MODEL_RESULT=ok")
    print("E3W_ONE_SHOT_MODEL_RESPONSE_BEGIN")
    print(response)
    print("E3W_ONE_SHOT_MODEL_RESPONSE_END")
except Exception as e:
    print("E3W_ONE_SHOT_MODEL_RESULT=error")
    print(f"E3W_ONE_SHOT_MODEL_ERROR={type(e).__name__}: {e}")
    sys.exit(2)
PY
model_rc=$?
set -e

cat "$RUN_DIR/model_call_result.txt"

if [ "$model_rc" != "0" ]; then
  mark_failed "E3W timeout-safe wrapper: model call timed out or failed before completion; job was marked failed internally."
  grep -F "E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1" "$RUN_DIR/internal_failure_update.txt"
  echo "E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK"
  exit 0
fi

if ! grep -F "E3W_ONE_SHOT_MODEL_RESULT=ok" "$RUN_DIR/model_call_result.txt" >/dev/null; then
  mark_failed "E3W timeout-safe wrapper: model call did not produce success marker; job was marked failed internally."
  grep -F "E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1" "$RUN_DIR/internal_failure_update.txt"
  echo "E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK"
  exit 0
fi

model_response="$(awk '/E3W_ONE_SHOT_MODEL_RESPONSE_BEGIN/{flag=1;next}/E3W_ONE_SHOT_MODEL_RESPONSE_END/{flag=0}flag' "$RUN_DIR/model_call_result.txt")"

echo
echo "=== completion transaction ==="
set +e
ssh pvew "pct exec 203 -- env JOB_ID='$JOB_ID' EXPECTED_MODEL='$EXPECTED_MODEL' DB='$DB' MODEL_RESPONSE='$model_response' python3 -" <<'PY' | tee "$RUN_DIR/completion_result.txt"
import os, sqlite3, json, sys
from datetime import datetime, timezone

DB=os.environ["DB"]
JOB_ID=int(os.environ["JOB_ID"])
EXPECTED_MODEL=os.environ["EXPECTED_MODEL"]
MODEL_RESPONSE=os.environ["MODEL_RESPONSE"]

def build_insert(table_cols):
    now=datetime.now(timezone.utc).isoformat().replace("+00:00","Z")
    colnames=[c["name"] for c in table_cols]
    values={}
    for c in colnames:
        lc=c.lower()
        if lc=="job_id":
            values[c]=JOB_ID
        elif lc in ("result","output","response","content","text","answer","completion"):
            values[c]=MODEL_RESPONSE
        elif lc in ("status","state"):
            values[c]="completed"
        elif lc in ("model","requested_model"):
            values[c]=EXPECTED_MODEL
        elif lc in ("worker_id","worker","runner"):
            values[c]="stage16-e3w-timeout-safe-wrapper"
        elif lc in ("created_at","updated_at","finished_at","completed_at"):
            values[c]=now
        elif lc in ("metadata","meta","extra"):
            values[c]=json.dumps({"phase":"stage-16-e3w","wrapper":"timeout-safe","num_predict":8})
    insert_cols=[]
    insert_vals=[]
    for c in table_cols:
        name=c["name"]
        lc=name.lower()
        notnull=bool(c["notnull"])
        dflt=c["dflt_value"]
        pk=bool(c["pk"])
        if name in values:
            insert_cols.append(name)
            insert_vals.append(values[name])
        elif notnull and dflt is None and not pk:
            raise RuntimeError(f"unsupported required job_results column without default: {name}")
    return insert_cols, insert_vals

conn=sqlite3.connect(DB, timeout=30)
conn.row_factory=sqlite3.Row
try:
    conn.execute("BEGIN IMMEDIATE")
    job=conn.execute("SELECT id,status,attempts,requested_model FROM jobs WHERE id=?", (JOB_ID,)).fetchone()
    if not job:
        print("REFUSE_E3W_COMPLETION_JOB_MISSING")
        conn.rollback(); sys.exit(2)
    if job["status"] != "running" or int(job["attempts"] or 0) != 1 or job["requested_model"] != EXPECTED_MODEL:
        print("REFUSE_E3W_COMPLETION_JOB_GUARD_MISMATCH")
        conn.rollback(); sys.exit(2)
    before=conn.execute("SELECT COUNT(*) FROM job_results WHERE job_id=?", (JOB_ID,)).fetchone()[0]
    if before != 0:
        print("REFUSE_E3W_COMPLETION_RESULT_ALREADY_EXISTS")
        conn.rollback(); sys.exit(2)

    table_cols=conn.execute("PRAGMA table_info(job_results)").fetchall()
    cols, vals=build_insert(table_cols)
    placeholders=",".join(["?"]*len(cols))
    quoted=",".join([f'"{c}"' for c in cols])
    conn.execute(f"INSERT INTO job_results ({quoted}) VALUES ({placeholders})", vals)

    conn.execute("""
    UPDATE jobs
    SET status='completed',
        updated_at=?
    WHERE id=?
      AND status='running'
      AND attempts=1
      AND requested_model=?
    """, (datetime.now(timezone.utc).isoformat().replace("+00:00","Z"), JOB_ID, EXPECTED_MODEL))

    job_changes=conn.execute("SELECT changes()").fetchone()[0]
    after=conn.execute("SELECT COUNT(*) FROM job_results WHERE job_id=?", (JOB_ID,)).fetchone()[0]
    print(f"E3W_COMPLETION_JOB_UPDATE_CHANGES={job_changes}")
    print(f"E3W_COMPLETION_RESULT_ROWS_AFTER={after}")
    if job_changes != 1 or after != 1:
        print("REFUSE_E3W_COMPLETION_GUARDS_FAILED")
        conn.rollback(); sys.exit(2)
    conn.commit()
    print("E3W_RUNTIME_COMPLETION_OK")
except Exception as e:
    try: conn.rollback()
    except Exception: pass
    print("E3W_RUNTIME_COMPLETION_ERROR=%s: %s" % (type(e).__name__, e))
    sys.exit(2)
finally:
    conn.close()
PY
completion_rc=$?
set -e

if [ "$completion_rc" != "0" ]; then
  mark_failed "E3W timeout-safe wrapper: model succeeded but completion transaction failed; job was marked failed internally."
  grep -F "E3W_RUNTIME_INTERNAL_FAILURE_UPDATE_CHANGES=1" "$RUN_DIR/internal_failure_update.txt"
  echo "E3W_RUNTIME_INTERNAL_FAILURE_PATH_OK"
  exit 0
fi

grep -F "E3W_RUNTIME_COMPLETION_OK" "$RUN_DIR/completion_result.txt"
echo "E3W_TIMEOUT_SAFE_RUNTIME_DONE"
