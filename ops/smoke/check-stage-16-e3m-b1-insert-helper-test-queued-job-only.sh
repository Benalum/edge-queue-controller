#!/usr/bin/env bash
set -u
set -o pipefail
set +H

DOMAIN="${DOMAIN:-https://alexhartel.com}"
PVEW_SSH="${PVEW_SSH:-pvew}"
HELPER="${HELPER:-ops/model/manual-complete-queued-job-via-pveso-adapter.sh}"
ADAPTER="${ADAPTER:-ops/model/pveso-one-shot-generate.sh}"
EXPECTED_JOB_ID="${EXPECTED_JOB_ID:-26}"
MARKER="APC_STAGE16_E3M_B1_SYNTHETIC_QUEUED_JOB_FOR_HELPER_ONLY"
MODEL_NAME="qwen2.5:32b-instruct-q4_K_M"

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
  ssh -o BatchMode=yes -o ConnectTimeout=10 "$PVEW_SSH" "EXPECTED_JOB_ID='$EXPECTED_JOB_ID' MARKER='$MARKER' MODEL_NAME='$MODEL_NAME' pct exec 203 -- python3 -" 2>&1 <<'PY'
import os
import sqlite3
import subprocess

DB = "/var/lib/edge-queue-controller/edge_queue.sqlite3"
JOB_ID = int(os.environ["EXPECTED_JOB_ID"])
MARKER = os.environ["MARKER"]
MODEL_NAME = os.environ["MODEL_NAME"]

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
        select id, status, job_type, requested_model, attempts, length(coalesce(prompt, '')) as prompt_len
          from jobs
         where id = ?
           and job_type = ?
           and status = ?
           and requested_model = ?
           and coalesce(prompt, '') like ?
        """,
        (JOB_ID, "stage16_e3m_b1_helper_synthetic_model_smoke", "queued", MODEL_NAME, f"%{MARKER}%"),
    ).fetchone()

    if job:
        print("synthetic_e3m_b1_present=1")
        print("synthetic_e3m_b1_id=" + str(job["id"]))
        print("synthetic_e3m_b1_status=" + str(job["status"]))
        print("synthetic_e3m_b1_job_type=" + str(job["job_type"]))
        print("synthetic_e3m_b1_requested_model=" + str(job["requested_model"]))
        print("synthetic_e3m_b1_attempts=" + str(job["attempts"]))
        print("synthetic_e3m_b1_prompt_len=" + str(job["prompt_len"]))
        print("job_results_for_synthetic_e3m_b1=" + str(conn.execute("select count(*) from job_results where job_id = ?", (JOB_ID,)).fetchone()[0]))
    else:
        print("synthetic_e3m_b1_present=0")

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
echo "=== Stage 16 E3M-B1 smoke: helper test queued job only ==="
echo "NO DB write"
echo "NO helper execution with approval"
echo "NO model call"
echo "NO approved adapter execution"
echo "NO prompt/completion/generate/chat/embed calls"
echo "NO worker/scheduler activation"
echo "NO public model endpoint exposure"

fail=0
mark_fail() { echo "FAIL: $*"; fail=1; }

echo
echo "--- helper and adapter static/gate checks ---"
[ -f "$HELPER" ] || mark_fail "helper missing"
[ -x "$HELPER" ] || mark_fail "helper not executable"
[ -f "$ADAPTER" ] || mark_fail "adapter missing"
[ -x "$ADAPTER" ] || mark_fail "adapter not executable"
bash -n "$HELPER" || mark_fail "helper bash syntax failed"
bash -n "$ADAPTER" || mark_fail "adapter bash syntax failed"

set +e
helper_gate_out="$(JOB_ID="$EXPECTED_JOB_ID" "$HELPER" 2>&1)"
helper_gate_rc="$?"
adapter_gate_out="$("$ADAPTER" 2>&1)"
adapter_gate_rc="$?"
set -u

echo "helper_no_approval_rc=$helper_gate_rc"
printf '%s\n' "$helper_gate_out" | head -20
[ "$helper_gate_rc" = "64" ] || mark_fail "helper did not stop at approval gate rc=64"
printf '%s\n' "$helper_gate_out" | grep -q "approval_gate=FAIL" || mark_fail "helper approval failure text missing"

echo "adapter_no_approval_rc=$adapter_gate_rc"
printf '%s\n' "$adapter_gate_out" | head -20
[ "$adapter_gate_rc" = "64" ] || mark_fail "adapter did not stop at approval gate rc=64"
printf '%s\n' "$adapter_gate_out" | grep -q "approval_gate=FAIL" || mark_fail "adapter approval failure text missing"

echo
echo "--- public routes ---"
for spec in "/:200" "/login:200" "/api/me:401" "/api/system/status:200" "/system/status:200"; do
  path="${spec%:*}"
  expect="${spec##*:}"
  code="$(curl -sS -o /tmp/apc_e3m_b1_smoke_public_body.txt -w '%{http_code}' --max-time 20 "${DOMAIN}${path}" 2>/tmp/apc_e3m_b1_smoke_public_err.txt || true)"
  echo "public_path=$path http=${code:-<curl_failed>} expect=$expect"
  [ "$code" = "$expect" ] || mark_fail "public route mismatch: $path"
done
rm -f /tmp/apc_e3m_b1_smoke_public_body.txt /tmp/apc_e3m_b1_smoke_public_err.txt

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
  "job_results=7" \
  "router_logs=0" \
  "router_resolution_steps=0" \
  "router_feedback=0" \
  "workers=2" \
  "worker_events=3" \
  "synthetic_e3m_b1_present=1" \
  "synthetic_e3m_b1_id=26" \
  "synthetic_e3m_b1_status=queued" \
  "synthetic_e3m_b1_job_type=stage16_e3m_b1_helper_synthetic_model_smoke" \
  "synthetic_e3m_b1_requested_model=qwen2.5:32b-instruct-q4_K_M" \
  "synthetic_e3m_b1_attempts=0" \
  "job_results_for_synthetic_e3m_b1=0" \
  "job_25_status=completed" \
  "job_25_attempts=1" \
  "job_results_for_job_25=1"
do
  echo "$ct203_out" | grep -q "^${expected}$" || mark_fail "CT203 guard mismatch: $expected"
done

echo
echo "--- PVESO health/list only; no generate call ---"
PVESO_TS_IP="$(tailscale status 2>/dev/null | awk 'tolower($2)=="pveso" {print $1; exit}')"

if [ -z "$PVESO_TS_IP" ]; then
  mark_fail "PVESO Tailscale IP not found"
else
  pveso_out="$(
    ssh \
      -o BatchMode=yes \
      -o ConnectTimeout=10 \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      "root@$PVESO_TS_IP" 'bash -s' 2>&1 <<'PVESO_REMOTE'
set -u
set -o pipefail
TARGET_OLLAMA_HOST="127.0.0.1:11434"
echo "host=$(hostname)"
echo "ollama_active=$(systemctl is-active ollama.service 2>/dev/null || true)"
systemctl show ollama.service -p Environment --value 2>/dev/null \
  | tr " " "\n" \
  | grep -E "^OLLAMA_(HOST|MODELS|NUM_THREADS|NUM_PARALLEL)=" || true
bad_listener_count="$(
  ss -ltnH 2>/dev/null \
    | awk '$4 ~ /:11434$/ && $4 !~ /127[.]0[.]0[.]1:11434$/ && $4 !~ /\[::1\]:11434$/ {c++} END{print c+0}'
)"
echo "non_localhost_11434_listener_count=$bad_listener_count"
curl -fsS --max-time 10 "http://${TARGET_OLLAMA_HOST}/api/version" \
  | python3 -c 'import sys,json; data=json.load(sys.stdin); print("api_version_ok=yes"); print("api_version="+str(data.get("version","<missing>")))'
curl -fsS --max-time 20 "http://${TARGET_OLLAMA_HOST}/api/tags" \
  | python3 -c 'import sys,json; data=json.load(sys.stdin); models=data.get("models",[]); print("api_tags_ok=yes"); print("api_tags_model_count="+str(len(models))); [print("api_tags_model="+str(m.get("name","<missing>"))) for m in models]'
if command -v pct >/dev/null 2>&1 && pct status 101 >/dev/null 2>&1; then
  echo "ct_101_status=$(pct status 101 | tr -s " ")"
  echo "ct_101_onboot=$(pct config 101 2>/dev/null | awk -F": " "/^onboot:/ {print \$2}" | head -1)"
fi
PVESO_REMOTE
  )" || true

  echo "$pveso_out"

  echo "$pveso_out" | grep -q "ollama_active=active" || mark_fail "PVESO Ollama not active"
  echo "$pveso_out" | grep -q "OLLAMA_HOST=127.0.0.1:11434" || mark_fail "PVESO Ollama host not localhost"
  echo "$pveso_out" | grep -q "non_localhost_11434_listener_count=0" || mark_fail "PVESO has non-localhost 11434 listener"
  echo "$pveso_out" | grep -q "api_version_ok=yes" || mark_fail "PVESO /api/version failed"
  echo "$pveso_out" | grep -q "api_tags_ok=yes" || mark_fail "PVESO /api/tags failed"
  echo "$pveso_out" | grep -q "ct_101_status=status: stopped" || mark_fail "CT101 not confirmed stopped"
  echo "$pveso_out" | grep -q "ct_101_onboot=0" || mark_fail "CT101 onboot not confirmed 0"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "SMOKE_RESULT=PASS"
else
  echo "SMOKE_RESULT=FAIL"
fi

exit "$fail"
} 2>&1 | sanitize_stream
