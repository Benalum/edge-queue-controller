#!/usr/bin/env bash
set -euo pipefail
set +H

PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"
PVEW_SSH="${PVEW_SSH:-root@pvew}"
PVESO_SSH="${PVESO_SSH:-root@pveso}"

echo "=== smoke: stage-16-e3b-pveso-ollama-service-diagnostic-read-only ==="
echo "MUTATION_SCOPE=read_only_smoke"
echo "NO service mutation"
echo "NO CT/VM mutation"
echo "NO DB write"
echo "NO model endpoint calls"
echo

DOC="docs/stage-16-e3b-pveso-ollama-service-diagnostic-read-only.md"
test -f "$DOC"

require_doc_text() {
  pattern="$1"
  grep -F "$pattern" "$DOC" >/dev/null
  echo "doc_contains=$pattern"
}

require_doc_text "Stage 16 E3B"
require_doc_text "No Ollama/model endpoint calls"
require_doc_text "E3A_BLOCKED_REASON=no_already_running_ollama_11434_listener"
require_doc_text "Ollama binary present:"
require_doc_text "11434 listener present:"
require_doc_text "APPROVE_STAGE_16_E3C_PVESO_OLLAMA_SERVICE_REPAIR_START_HEALTH_LIST_ONLY_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_DB_WRITE_NO_MODEL_PULL"

probe_expect() {
  path="$1"
  expect="$2"
  tmp="$(mktemp)"
  set +e
  out="$(curl -sS --connect-timeout 6 --max-time 15 -o "$tmp" -w "%{http_code}" "$PUBLIC_BASE$path" 2>/dev/null)"
  rc=$?
  set -e
  echo "public_path=${path} rc=${rc} http=${out} expect=${expect}"
  rm -f "$tmp"
  test "$rc" = "0"
  test "$out" = "$expect"
}

probe_expect / 200
probe_expect /login 200
probe_expect /api/me 401
probe_expect /api/system/status 200

ssh -o BatchMode=yes -o ConnectTimeout=8 "$PVEW_SSH" 'bash -s' <<'REMOTE'
set -euo pipefail
qm status 200
pct status 203
pct status 204
findmnt /srv/apc-private-data >/dev/null 2>&1 && { echo "private_storage=mounted_UNEXPECTED"; exit 1; } || echo "private_storage=not-mounted"
pct exec 203 -- bash -lc '
set -euo pipefail
curl -sS -o /dev/null -w "ct203_health_http=%{http_code}\n" --connect-timeout 3 --max-time 8 http://127.0.0.1:7070/health
curl -sS -o /dev/null -w "ct203_system_status_http=%{http_code}\n" --connect-timeout 3 --max-time 8 http://127.0.0.1:7070/system/status
'
REMOTE

tailscale ssh "$PVESO_SSH" 'bash -s' <<'REMOTE'
set -euo pipefail
pct status 101
pct status 101 | grep -q "status: stopped"
pct config 101 | grep -q "^onboot: 0"
echo "ct101_stopped=true"
echo "ct101_onboot_0=true"
echo "host_ollama_binary=$(command -v ollama || true)"
echo "host_ollama_service_active=$(systemctl is-active ollama.service 2>/dev/null || true)"
echo "host_11434_listener_present=$(ss -lnt 2>/dev/null | grep -qE ":(11434)\b" && echo yes || echo no)"
echo "NO_MODEL_ENDPOINT_CALL=true"
REMOTE

echo "PASS: E3B read-only diagnostic smoke passed"
