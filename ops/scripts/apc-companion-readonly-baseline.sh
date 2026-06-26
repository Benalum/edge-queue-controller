#!/usr/bin/env bash
set -euo pipefail
set +H

ROOT="${APC_REPO:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

echo "=== repo preflight ==="
git rev-parse --short HEAD 2>/dev/null || true
git status --short 2>/dev/null || true

if git rev-parse --verify HEAD >/dev/null 2>&1; then
  HEAD_SHORT="$(git rev-parse --short HEAD)"
  echo "head_short=$HEAD_SHORT"
  if [ "${APC_EXPECT_HEAD:-937ac4a}" != "" ] && [ "$HEAD_SHORT" != "${APC_EXPECT_HEAD:-937ac4a}" ]; then
    echo "WARN_HEAD_MISMATCH expected=${APC_EXPECT_HEAD:-937ac4a} actual=$HEAD_SHORT"
  fi
fi

echo
echo "=== source markers ==="
grep -nF "_stage16_fc_o45_e_cl_f_companion_study_last_message_mvp" edge_controller.py >/dev/null && echo "last_message_mvp_source=present" || echo "last_message_mvp_source=missing"
grep -nF "@app.post(\"/api/chat/queued\")" edge_controller.py >/dev/null && echo "api_chat_queued_route=present" || echo "api_chat_queued_route=missing"
grep -nF "@app.post(\"/internal/edge-worker/jobs/claim\")" edge_controller.py >/dev/null && echo "internal_worker_claim_route=present" || echo "internal_worker_claim_route=missing"
grep -nF "queuedChatPollJob" frontend/wrapper-ui/app.js >/dev/null && echo "wrapper_polling=present" || echo "wrapper_polling=missing"
grep -nF "/api/study/session/command" frontend/wrapper-ui/app.js >/dev/null && echo "study_command_bridge=present" || echo "study_command_bridge=missing"

echo
echo "=== local DB read-only, if available ==="
DB="${APC_DB_PATH:-/var/lib/edge-queue-controller/edge_queue.sqlite3}"
if [ -f "$DB" ]; then
  python3 - "$DB" <<'PY'
import sqlite3, sys
path = sys.argv[1]
conn = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
conn.row_factory = sqlite3.Row
try:
    integrity = conn.execute("PRAGMA integrity_check").fetchone()[0]
    jobs = conn.execute("SELECT COUNT(*) FROM jobs").fetchone()[0]
    results = conn.execute("SELECT COUNT(*) FROM job_results").fetchone()[0]
    queued_companion = conn.execute("SELECT COUNT(*) FROM jobs WHERE job_type='companion.chat' AND status='queued'").fetchone()[0]
    running = conn.execute("SELECT COUNT(*) FROM jobs WHERE status='running'").fetchone()[0]
    print(f"integrity={integrity}")
    print(f"jobs_total={jobs}")
    print(f"results_total={results}")
    print(f"queued_companion={queued_companion}")
    print(f"running_total={running}")
finally:
    conn.close()
PY
else
  echo "db_not_available_locally=$DB"
fi

echo
echo "=== public route read-only, if APC_PUBLIC_BASE_URL is set ==="
if [ -n "${APC_PUBLIC_BASE_URL:-}" ]; then
  BASE="${APC_PUBLIC_BASE_URL%/}"
  for path in / /api/system/status /api/companion/voice/status; do
    code="$(curl -k -sS -o /tmp/apc_baseline_body.$$ -w '%{http_code}' "$BASE$path" || true)"
    bytes="$(wc -c < /tmp/apc_baseline_body.$$ 2>/dev/null || echo 0)"
    rm -f /tmp/apc_baseline_body.$$
    echo "public_get path=$path http=$code bytes=$bytes"
  done
  code="$(curl -k -sS -o /tmp/apc_baseline_body.$$ -w '%{http_code}' \
    -H 'Content-Type: application/json' \
    --data '{"action":"last_message","message":"signed out guard check"}' \
    "$BASE/api/companion/study/action" || true)"
  rm -f /tmp/apc_baseline_body.$$
  echo "public_unauth_last_message_http=$code expected=401"
else
  echo "public_checks_skipped=set_APC_PUBLIC_BASE_URL_to_enable"
fi

echo
echo "=== systemd read-only, if local systemd is available ==="
for unit in \
  edge-deterministic-companion-once.service \
  edge-deterministic-companion-once@.service \
  edge-queue-worker.service \
  edge-queue-worker.timer \
  edge-ct203-deterministic-companion-once.service \
  edge-ct203-deterministic-companion-once.timer; do
  if command -v systemctl >/dev/null 2>&1; then
    state="$(systemctl is-active "$unit" 2>/dev/null || true)"
    echo "unit=$unit active_state=${state:-unknown}"
  fi
done

echo "baseline_readonly_status=complete"
