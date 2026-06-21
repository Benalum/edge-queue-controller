#!/usr/bin/env bash
set -euo pipefail

STAGE="stage-16-e3v-run-one-existing-status-atomic-claim-dispatch"
REQUIRED_APPROVAL="APPROVE_STAGE_16_E3V_RUN_ONE_EXISTING_STATUS_ATOMIC_CLAIM_DISPATCH_ONLY"
PASS_MARKER="E3V_OPTION_B_ATOMIC_CLAIM_ONE_SHOT_DISPATCH_OK"

MODE="${1:-}"
EXPECTED_MODEL="${EXPECTED_MODEL:-qwen2.5:32b-instruct-q4_K_M}"
EXPECTED_HEAD="${EXPECTED_HEAD:-}"
EXPECTED_SELECTED_JOB_ID="${EXPECTED_SELECTED_JOB_ID:-}"
CTID="${CTID:-203}"
CT203_DB_PATH="${CT203_DB_PATH:-/var/lib/edge-queue-controller/edge_queue.sqlite3}"
PVEW_SSH="${PVEW_SSH:-pvew}"
RUN_ROOT="${RUN_ROOT:-/tmp}"
MAX_RUNTIME_SECONDS="${MAX_RUNTIME_SECONDS:-7200}"

FORBIDDEN_JOB_IDS="23 24 27 28"

now_utc() {
  date -u +%Y%m%dT%H%M%SZ
}

run_dir="${RUN_DIR:-$RUN_ROOT/apc-e3v-option-b-dry-run-$(now_utc)}"

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
  mkdir -p "$run_dir"
  cat > "$run_dir/recovery_hint.txt" <<EOF
DO_NOT_RERUN
RUN_READ_ONLY_RECOVERY_FIRST
stage=$STAGE
mode=$MODE
run_dir=$run_dir
no_db_write_expected=true
no_db_claim_expected=true
no_adapter_call_expected=true
no_model_call_expected=true
EOF
}

refuse_execute_not_enabled() {
  echo "REFUSE_E3V_EXECUTE_NOT_ENABLED"
  echo "NO_DB_WRITE"
  echo "NO_DB_CLAIM"
  echo "NO_ADAPTER_CALL"
  echo "NO_MODEL_CALL"
  exit 2
}

echo "STAGE=$STAGE"

case "$MODE" in
  --dry-run)
    echo "MODE=dry-run"
    ;;
  --execute-approved)
    echo "MODE=execute-approved"
    if [ "${APPROVAL:-}" != "$REQUIRED_APPROVAL" ]; then
      echo "REFUSE_APPROVAL_MISSING"
      exit 2
    fi
    echo "APPROVAL_CAPTURED=$REQUIRED_APPROVAL"
    refuse_execute_not_enabled
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

write_recovery_hint

echo "RUN_DIR=$run_dir"
echo "NO_DB_WRITE"
echo "NO_SCHEMA_MIGRATION"
echo "NO_DB_CLAIM"
echo "NO_HELPER_CALL"
echo "NO_ADAPTER_CALL"
echo "NO_MODEL_CALL"
echo "SCHEDULER_ACTIVATION=not_performed"
echo "PERSISTENT_WORKER_ACTIVATION=not_performed"

repo_head="$(git rev-parse --short HEAD)"
repo_dirty="$(git status --short)"
{
  echo "repo_head=$repo_head"
  echo "expected_head=${EXPECTED_HEAD:-unset}"
  echo "repo_dirty=${repo_dirty:-<clean>}"
} | tee "$run_dir/repo_preflight.txt"

if [ -n "$EXPECTED_HEAD" ] && [ "$repo_head" != "$EXPECTED_HEAD" ]; then
  echo "REFUSE_REPO_CHECKPOINT_MISMATCH"
  exit 2
fi

if [ -n "$repo_dirty" ]; then
  echo "REFUSE_REPO_DIRTY"
  exit 2
fi

echo "REPO_PREFLIGHT_OK"

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
} | tee "$run_dir/scheduler_worker_disabled_preflight.txt"

before_stat="$(ssh "$PVEW_SSH" "pct exec $CTID -- stat -c '%s %Y %n' '$CT203_DB_PATH'")"
echo "$before_stat" | tee "$run_dir/ct203_db_stat_before.txt"

ct203_py="$run_dir/ct203_readonly_candidate_check.py"
cat > "$ct203_py" <<'PY'
#!/usr/bin/env python3
import sqlite3
import sys

DB = "/var/lib/edge-queue-controller/edge_queue.sqlite3"
EXPECTED_MODEL = "qwen2.5:32b-instruct-q4_K_M"
FORBIDDEN = {23, 24, 27, 28}

conn = sqlite3.connect(f"file:{DB}?mode=ro&immutable=1", uri=True)
conn.row_factory = sqlite3.Row
conn.execute("PRAGMA query_only=ON")

print("CT203_READONLY_CANDIDATE_CHECK=begin")
print("DB_OPEN_MODE=sqlite_uri_mode_ro_immutable")
integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
print(f"DB_INTEGRITY={integrity}")

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
else:
    print("DUPLICATE_JOB_RESULTS none")

for job_id in (23, 24, 27, 28):
    job = conn.execute(
        "SELECT id, job_type, requested_model, status, attempts, updated_at FROM jobs WHERE id=?",
        (job_id,),
    ).fetchone()
    result_rows = conn.execute("SELECT COUNT(*) FROM job_results WHERE job_id=?", (job_id,)).fetchone()[0]
    if job is None:
        print(f"JOB_CLASSIFY id={job_id} present=false result_rows={result_rows}")
    else:
        print(
            f"JOB_CLASSIFY id={job_id} present=true status={job['status']} attempts={job['attempts']} "
            f"job_type={job['job_type']!r} requested_model={job['requested_model']!r} result_rows={result_rows} "
            f"updated_at={job['updated_at']}"
        )

candidates = conn.execute(
    """
    SELECT
      j.id,
      j.job_type,
      j.prompt,
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

if len(eligible) == 0:
    print("E3V_DRY_RUN_RESULT=NO_ELIGIBLE_JOB_NO_RUNTIME")
elif len(eligible) == 1:
    row = eligible[0]
    print(f"WOULD_ATOMIC_CLAIM job_id={row['id']} model={row['requested_model']} result_rows={row['result_rows']}")
    print("E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME")
else:
    print("REFUSE_MULTIPLE_ELIGIBLE_JOBS")
    raise SystemExit(2)

print("CT203_READONLY_CANDIDATE_CHECK_OK")
PY

ssh "$PVEW_SSH" "pct exec $CTID -- python3 -" < "$ct203_py" \
  | tee "$run_dir/ct203_readonly_candidate_check.txt"

grep -F "DB_OPEN_MODE=sqlite_uri_mode_ro_immutable" "$run_dir/ct203_readonly_candidate_check.txt"
grep -F "DB_INTEGRITY=ok" "$run_dir/ct203_readonly_candidate_check.txt"
grep -F "DUPLICATE_JOB_RESULTS none" "$run_dir/ct203_readonly_candidate_check.txt"

if grep -F "REFUSE_MULTIPLE_ELIGIBLE_JOBS" "$run_dir/ct203_readonly_candidate_check.txt" >/dev/null; then
  echo "REFUSE_MULTIPLE_ELIGIBLE_JOBS"
  exit 2
fi

if [ -n "$EXPECTED_SELECTED_JOB_ID" ]; then
  if ! grep -F "WOULD_ATOMIC_CLAIM job_id=$EXPECTED_SELECTED_JOB_ID " "$run_dir/ct203_readonly_candidate_check.txt" >/dev/null; then
    echo "REFUSE_EXPECTED_SELECTED_JOB_ID_MISMATCH"
    exit 2
  fi
fi

pveso_ip="$(
  tailscale status 2>/dev/null \
    | awk 'tolower($2)=="pveso" {print $1; exit}'
)"

if [ -z "$pveso_ip" ]; then
  echo "REFUSE_PVESO_UNAVAILABLE"
  exit 2
fi

echo "PVESO_TAILSCALE_STATUS_LOOKUP=OK" | tee "$run_dir/pveso_preflight.txt"

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
' | sanitize_stream | tee -a "$run_dir/pveso_preflight.txt"

grep -F "PVESO_PREFLIGHT_OK" "$run_dir/pveso_preflight.txt"
grep -F "OLLAMA_NONLOCALHOST_11434_LISTENER_COUNT=0" "$run_dir/pveso_preflight.txt"
grep -F "PVESO_RUNNER_OR_ADAPTER_PROCESS_COUNT=0" "$run_dir/pveso_preflight.txt"
grep -F "TARGET_MODEL_PRESENT=true" "$run_dir/pveso_preflight.txt"
grep -F "CT101_STATUS=stopped" "$run_dir/pveso_preflight.txt"
grep -F "CT101_ONBOOT=0" "$run_dir/pveso_preflight.txt"

after_stat="$(ssh "$PVEW_SSH" "pct exec $CTID -- stat -c '%s %Y %n' '$CT203_DB_PATH'")"
echo "$after_stat" | tee "$run_dir/ct203_db_stat_after.txt"

if [ "$before_stat" != "$after_stat" ]; then
  echo "REFUSE_DB_STAT_CHANGED"
  exit 2
fi

echo "CT203_DB_STAT_UNCHANGED=true"

if grep -F "E3V_DRY_RUN_RESULT=NO_ELIGIBLE_JOB_NO_RUNTIME" "$run_dir/ct203_readonly_candidate_check.txt" >/dev/null; then
  final_result="E3V_DRY_RUN_RESULT=NO_ELIGIBLE_JOB_NO_RUNTIME"
elif grep -F "E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME" "$run_dir/ct203_readonly_candidate_check.txt" >/dev/null; then
  final_result="E3V_DRY_RUN_RESULT=WOULD_CLAIM_ONE_JOB_NO_RUNTIME"
else
  final_result="E3V_DRY_RUN_RESULT=UNKNOWN"
fi

{
  echo "$final_result"
  echo "E3V_OPTION_B_DRY_RUN_GUARD_PREFLIGHT_OK"
} | tee "$run_dir/final_status.txt"

cat "$run_dir/final_status.txt"
