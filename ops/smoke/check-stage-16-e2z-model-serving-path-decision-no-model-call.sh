#!/usr/bin/env bash
set -euo pipefail
set +H

PUBLIC_BASE="${PUBLIC_BASE:-https://alexhartel.com}"
PVEW_SSH="${PVEW_SSH:-root@pvew}"
PVESO_SSH="${PVESO_SSH:-root@pveso}"

echo "=== smoke: stage-16-e2z-model-serving-path-decision-no-model-call ==="
echo "MUTATION_SCOPE=read_only_smoke"
echo "NO live infra mutation"
echo "NO service restart/reload/start/stop"
echo "NO CT/VM start/stop/restart"
echo "NO pct mount/unmount"
echo "NO DB write"
echo "NO model endpoint calls"
echo

DOC="docs/stage-16-e2z-model-serving-path-decision-no-model-call.md"
test -f "$DOC"

require_doc_text() {
  pattern="$1"
  grep -F "$pattern" "$DOC" >/dev/null
  echo "doc_contains=$pattern"
}

require_doc_text "No Ollama/model endpoint calls"
require_doc_text "Do not make CT101 the canonical model-serving path yet"
require_doc_text "Suggested approval phrase"
require_doc_text "APPROVE_STAGE_16_E3A_FIRST_MODEL_ENDPOINT_HEALTH_AND_LIST_CALL_ONLY_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_DB_WRITE"

probe_expect() {
  path="$1"
  expect="$2"
  tmp="$(mktemp)"
  set +e
  out="$(curl -sS --connect-timeout 6 --max-time 15 -o "$tmp" -w "%{http_code} %{time_total} %{size_download}" "$PUBLIC_BASE$path" 2>/dev/null)"
  rc=$?
  set -e
  code="$(printf "%s" "$out" | awk '{print $1}')"
  echo "public_path=${path} rc=${rc} http=${code} expect=${expect}"
  rm -f "$tmp"
  test "$rc" = "0"
  test "$code" = "$expect"
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
echo "NO_MODEL_ENDPOINT_CALL=true"
REMOTE

echo "PASS: E2Z model serving path decision smoke passed"
