#!/usr/bin/env bash
set -euo pipefail
set +H

PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"
PVEW_SSH="${PVEW_SSH:-root@pvew}"

echo "=== smoke: stage-16-login-r10d-vm200-nginx-ct203-upstream-hotfix ==="
echo "MUTATION_SCOPE=read_only_smoke"
echo "PUBLIC_BASE=$PUBLIC_BASE"
echo "NO live infra mutation"
echo "NO service restart/reload/start/stop"
echo "NO CT/VM start/stop/restart"
echo "NO DB write"
echo

remote_counts() {
  ssh -o BatchMode=yes -o ConnectTimeout=8 "$PVEW_SSH" 'bash -s' <<'REMOTE'
set -euo pipefail
pct exec 203 -- bash -lc '
set -euo pipefail
DB="/var/lib/edge-queue-controller/edge_queue.sqlite3"
tables="user_sessions jobs job_results router_logs router_resolution_steps router_feedback workers worker_events"
for t in $tables; do
  c="$(sqlite3 "$DB" "SELECT COUNT(*) FROM \"$t\";" 2>/dev/null || echo ERR)"
  echo "${t}:${c}"
done
'
REMOTE
}

echo "--- db counts before public route smoke ---"
counts_before="$(remote_counts)"
printf '%s\n' "$counts_before"

probe_expect() {
  path="$1"
  expect="$2"
  tmp="$(mktemp)"
  set +e
  out="$(curl -sS --connect-timeout 6 --max-time 15 -o "$tmp" -w "%{http_code} %{time_total} %{size_download}" "$PUBLIC_BASE$path" 2>/dev/null)"
  rc=$?
  set -e
  code="$(printf "%s" "$out" | awk '{print $1}')"
  time_total="$(printf "%s" "$out" | awk '{print $2}')"
  bytes="$(printf "%s" "$out" | awk '{print $3}')"
  echo "public_path=${path} rc=${rc} http=${code} expect=${expect} time=${time_total} bytes=${bytes}"
  rm -f "$tmp"
  test "$rc" = "0"
  test "$code" = "$expect"
}

probe_expect / 200
probe_expect /login 200
probe_expect /api/me 401
probe_expect /api/auth/login 405
probe_expect /system/status 200
probe_expect /api/system/status 200

echo "--- db counts after public route smoke ---"
counts_after="$(remote_counts)"
printf '%s\n' "$counts_after"

if [ "$counts_before" != "$counts_after" ]; then
  echo "FAIL: DB counts changed during read-only smoke"
  diff -u <(printf '%s\n' "$counts_before") <(printf '%s\n' "$counts_after") || true
  exit 1
fi

ssh -o BatchMode=yes -o ConnectTimeout=8 "$PVEW_SSH" 'bash -s' <<'REMOTE'
set -euo pipefail
qm status 200
pct status 203
pct status 204
findmnt /srv/apc-private-data >/dev/null 2>&1 && { echo "private_storage=mounted_UNEXPECTED"; exit 1; } || echo "private_storage=not-mounted"

pct exec 203 -- bash -lc '
set -euo pipefail
echo "ct203_controller_active=$(systemctl is-active edge-queue-controller.service 2>/dev/null || true)"
curl -sS -o /dev/null -w "ct203_health_http=%{http_code}\n" --connect-timeout 3 --max-time 8 http://127.0.0.1:7070/health
curl -sS -o /dev/null -w "ct203_system_status_http=%{http_code}\n" --connect-timeout 3 --max-time 8 http://127.0.0.1:7070/system/status
'
REMOTE

echo "PASS: login hotfix public/API smoke passed"
