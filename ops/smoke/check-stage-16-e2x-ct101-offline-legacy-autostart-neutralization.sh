#!/usr/bin/env bash
set -euo pipefail
set +H

PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"
PVEW_SSH="${PVEW_SSH:-root@pvew}"
PVESO_SSH="${PVESO_SSH:-root@pveso}"

echo "=== smoke: stage-16-e2x-ct101-offline-legacy-autostart-neutralization ==="
echo "MUTATION_SCOPE=read_only_smoke"
echo "NO live infra mutation"
echo "NO service restart/reload/start/stop"
echo "NO CT/VM start/stop/restart"
echo "NO pct mount/unmount"
echo "NO DB write"
echo

require_doc_text() {
  file="$1"
  pattern="$2"
  grep -F "$pattern" "$file" >/dev/null
  echo "doc_contains=$pattern"
}

DOC="docs/stage-16-e2x-ct101-offline-legacy-autostart-neutralization.md"
test -f "$DOC"
require_doc_text "$DOC" "Masked unit count: 11"
require_doc_text "$DOC" "docker.service"
require_doc_text "$DOC" "docker.socket"
require_doc_text "$DOC" "containerd.service"
require_doc_text "$DOC" "ollama.service"
require_doc_text "$DOC" "ollama.socket"
require_doc_text "$DOC" "ai-platform-queue-controller.service"
require_doc_text "$DOC" "llm-stack-compose.service"
require_doc_text "$DOC" "CT101 remained stopped"
require_doc_text "$DOC" "CT101 remained `onboot=0`"

echo "--- public login/API guard ---"
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
probe_expect /api/system/status 200

echo "--- PVEW/CT203 DB guard ---"
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
DB="/var/lib/edge-queue-controller/edge_queue.sqlite3"
expected="user_sessions:236 jobs:23 job_results:6 router_logs:0 router_resolution_steps:0 router_feedback:0 workers:2 worker_events:3"
for pair in $expected; do
  t="${pair%%:*}"
  e="${pair##*:}"
  c="$(sqlite3 "$DB" "SELECT COUNT(*) FROM \"$t\";" 2>/dev/null || echo ERR)"
  echo "count=${t}:${c}"
  test "$c" = "$e"
done
'
REMOTE

echo "--- PVESO CT posture guard, no mount ---"
tailscale ssh "$PVESO_SSH" 'bash -s' <<'REMOTE'
set -euo pipefail
pct status 101
pct status 201 || true
pct status 202 || true
pct status 101 | grep -q "status: stopped"
pct config 101 | grep -q "^onboot: 0"
echo "ct101_stopped=true"
echo "ct101_onboot_0=true"
REMOTE

echo "PASS: E2X docs and stopped-posture smoke passed"
