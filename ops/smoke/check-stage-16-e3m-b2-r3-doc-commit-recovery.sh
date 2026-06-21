#!/usr/bin/env bash
set -u
set -o pipefail
set +H

DOMAIN="${DOMAIN:-https://alexhartel.com}"
PVEW_SSH="${PVEW_SSH:-pvew}"
JOB_ID="${JOB_ID:-26}"
MODEL_NAME="qwen2.5:32b-instruct-q4_K_M"
E3M_B1_MARKER="APC_STAGE16_E3M_B1_SYNTHETIC_QUEUED_JOB_FOR_HELPER_ONLY"
RESULT_MARKER="APC_STAGE16_E3M_B2_MANUAL_HELPER_COMPLETION_RESULT"
EXPECTED_RESPONSE="APC_E3M_B2_OK"

sanitize_stream() {
  sed -E \
    -e 's#https://login\.tailscale\.com/a/[A-Za-z0-9]+#<redacted-auth-url>#g' \
    -e 's/100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-tailscale-ip>/g' \
    -e 's/10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/192\.168\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/<redacted-mac>/g'
}

ct203_guard() {
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$PVEW_SSH" \
    "pct exec 203 -- env JOB_ID='$JOB_ID' E3M_B1_MARKER='$E3M_B1_MARKER' RESULT_MARKER='$RESULT_MARKER' MODEL_NAME='$MODEL_NAME' EXPECTED_RESPONSE='$EXPECTED_RESPONSE' python3 -" 2>&1 <<'PY'
import os
import sqlite3
import subprocess

DB = "/var/lib/edge-queue-controller/edge_queue.sqlite3"
JOB_ID = int(os.environ["JOB_ID"])
E3M_B1_MARKER = os.environ["E3M_B1_MARKER"]
RESULT_MARKER = os.environ["RESULT_MARKER"]
MODEL_NAME = os.environ["MODEL_NAME"]
EXPECTED_RESPONSE = os.environ["EXPECTED_RESPONSE"]

def active(unit):
    try:
        return subprocess.check_output(["systemctl", "is-active", unit], text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return "unknown"

def listener_count():
    try:
        out = subprocess.check_output(["ss", "-ltnp"], text=True, stderr=subprocess.DEVNULL)
        return sum(1 for line in out.splitlines() if ":7070" in line)
    except Exception:
        return -1

print("edge_queue_controller_active=" + active("edge-queue-controller.service"))
print("listener_7070=" + str(listener_count()))

conn = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
conn.row_factory = sqlite3.Row
try:
    print("db_integrity=" + str(conn.execute("pragma integrity_check").fetchone()[0]))
    for table in ["user_sessions", "jobs", "job_results", "router_logs", "router_resolution_steps", "router_feedback", "workers", "worker_events"]:
        print(f"{table}=" + str(conn.execute(f"select count(*) from {table}").fetchone()[0]))

    job = conn.execute(
        """
        select id, status, job_type, requested_model, attempts
          from jobs
         where id = ?
           and job_type = ?
           and requested_model = ?
           and coalesce(prompt,'') like ?
        """,
        (JOB_ID, "stage16_e3m_b1_helper_synthetic_model_smoke", MODEL_NAME, f"%{E3M_B1_MARKER}%"),
    ).fetchone()

    if job:
        print("job_26_present=1")
        print("job_26_status=" + str(job["status"]))
        print("job_26_attempts=" + str(job["attempts"]))
        print("job_26_requested_model=" + str(job["requested_model"]))
    else:
        print("job_26_present=0")

    print("job_results_for_job_26=" + str(conn.execute("select count(*) from job_results where job_id = ?", (JOB_ID,)).fetchone()[0]))
    print("job_results_marker_matches_for_job_26=" + str(conn.execute(
        "select count(*) from job_results where job_id = ? and coalesce(response_json,'') like ?",
        (JOB_ID, f"%{RESULT_MARKER}%"),
    ).fetchone()[0]))
    print("job_results_response_matches_for_job_26=" + str(conn.execute(
        "select count(*) from job_results where job_id = ? and response_text = ?",
        (JOB_ID, EXPECTED_RESPONSE),
    ).fetchone()[0]))

    job25 = conn.execute("select status, attempts from jobs where id = 25").fetchone()
    if job25:
        print("job_25_status=" + str(job25["status"]))
        print("job_25_attempts=" + str(job25["attempts"]))
        print("job_results_for_job_25=" + str(conn.execute("select count(*) from job_results where job_id = 25").fetchone()[0]))
finally:
    conn.close()
PY
}

{
echo "=== Stage 16 E3M-B2-R3 smoke: doc/commit recovery ==="
echo "NO DB write"
echo "NO helper run"
echo "NO model call"
echo "NO approved adapter execution"
echo "NO prompt/completion/generate/chat/embed calls"
echo "NO worker/scheduler activation"
echo "NO public model endpoint exposure"

fail=0
mark_fail() { echo "FAIL: $*"; fail=1; }

echo
echo "--- public routes ---"
for spec in "/:200" "/login:200" "/api/me:401" "/api/system/status:200" "/system/status:200"; do
  path="${spec%:*}"
  expect="${spec##*:}"
  code="$(curl -sS -o /tmp/apc_e3m_b2_r3_smoke_public_body.txt -w '%{http_code}' --max-time 20 "${DOMAIN}${path}" 2>/tmp/apc_e3m_b2_r3_smoke_public_err.txt || true)"
  echo "public_path=$path http=${code:-<curl_failed>} expect=$expect"
  [ "$code" = "$expect" ] || mark_fail "public route mismatch: $path"
done
rm -f /tmp/apc_e3m_b2_r3_smoke_public_body.txt /tmp/apc_e3m_b2_r3_smoke_public_err.txt

echo
echo "--- CT203 DB guard read-only via Python ---"
ct203_out="$(ct203_guard || true)"
echo "$ct203_out"

for expected in \
  "edge_queue_controller_active=active" \
  "listener_7070=1" \
  "db_integrity=ok" \
  "user_sessions=236" \
  "jobs=25" \
  "job_results=8" \
  "router_logs=0" \
  "router_resolution_steps=0" \
  "router_feedback=0" \
  "workers=2" \
  "worker_events=3" \
  "job_26_present=1" \
  "job_26_status=completed" \
  "job_26_attempts=1" \
  "job_26_requested_model=qwen2.5:32b-instruct-q4_K_M" \
  "job_results_for_job_26=1" \
  "job_results_marker_matches_for_job_26=1" \
  "job_results_response_matches_for_job_26=1" \
  "job_25_status=completed" \
  "job_25_attempts=1" \
  "job_results_for_job_25=1"
do
  echo "$ct203_out" | grep -q "^${expected}$" || mark_fail "CT203 guard mismatch: $expected"
done

echo
if [ "$fail" -eq 0 ]; then
  echo "SMOKE_RESULT=PASS"
else
  echo "SMOKE_RESULT=FAIL"
fi

exit "$fail"
} 2>&1 | sanitize_stream
