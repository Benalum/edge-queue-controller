#!/usr/bin/env bash
set -u
set -o pipefail
set +H

DOMAIN="${DOMAIN:-https://alexhartel.com}"
PVEW_SSH="${PVEW_SSH:-pvew}"
ADAPTER="${ADAPTER:-ops/model/pveso-one-shot-generate.sh}"

sanitize_stream() {
  sed -E \
    -e 's#https://login\.tailscale\.com/a/[A-Za-z0-9]+#<redacted-auth-url>#g' \
    -e 's/100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-tailscale-ip>/g' \
    -e 's/10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/192\.168\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/<redacted-mac>/g'
}

{
echo "=== Stage 16 E3H smoke: adapter script no-run / approval-gate-only ==="
echo "NO approved adapter execution"
echo "NO prompt/completion/generate/chat/embed calls"
echo "NO DB write"
echo "NO worker/scheduler activation"
echo "NO model pull/download"
echo "NO public model endpoint exposure"

fail=0
mark_fail() { echo "FAIL: $*"; fail=1; }

echo
echo "--- adapter static and approval-gate checks ---"
[ -f "$ADAPTER" ] || mark_fail "adapter missing"
[ -x "$ADAPTER" ] || mark_fail "adapter not executable"
bash -n "$ADAPTER" || mark_fail "adapter bash syntax failed"

help_out="$("$ADAPTER" --help 2>&1)"
help_rc="$?"
echo "adapter_help_rc=$help_rc"
echo "adapter_help_preview_start"
printf '%s\n' "$help_out" | head -60
echo "adapter_help_preview_end"
[ "$help_rc" = "0" ] || mark_fail "adapter help failed"

grep -q "APC_ONE_SHOT_MODEL_APPROVAL" "$ADAPTER" || mark_fail "approval env gate missing"
grep -q "APPROVE_STAGE_16_E3I_RUN_ONE_SHOT_MODEL_ADAPTER" "$ADAPTER" || mark_fail "E3I approval string missing"
grep -q "127.0.0.1:11434" "$ADAPTER" || mark_fail "localhost endpoint guard missing"
grep -q "/api/generate" "$ADAPTER" || mark_fail "generate endpoint missing"
grep -q "ct_101_status" "$ADAPTER" || mark_fail "CT101 guard missing"
grep -q "non_localhost_11434_listener_count" "$ADAPTER" || mark_fail "listener guard missing"

echo
echo "--- adapter negative gate test: no approval, should exit before any model call ---"
set +e
gate_out="$("$ADAPTER" 2>&1)"
gate_rc="$?"
set -u
echo "adapter_no_approval_rc=$gate_rc"
printf '%s\n' "$gate_out" | head -40
[ "$gate_rc" = "64" ] || mark_fail "adapter did not stop at approval gate rc=64"
printf '%s\n' "$gate_out" | grep -q "approval_gate=FAIL" || mark_fail "approval gate failure text missing"

echo
echo "--- public routes ---"
for spec in "/:200" "/login:200" "/api/me:401" "/api/system/status:200" "/system/status:200"; do
  path="${spec%:*}"
  expect="${spec##*:}"
  code="$(curl -sS -o /tmp/apc_e3h_smoke_public_body.txt -w '%{http_code}' --max-time 20 "${DOMAIN}${path}" 2>/tmp/apc_e3h_smoke_public_err.txt || true)"
  echo "public_path=$path http=${code:-<curl_failed>} expect=$expect"
  [ "$code" = "$expect" ] || mark_fail "public route mismatch: $path"
done
rm -f /tmp/apc_e3h_smoke_public_body.txt /tmp/apc_e3h_smoke_public_err.txt

echo
echo "--- CT203 DB guard read-only ---"
ct203_out="$(
ssh -o BatchMode=yes -o ConnectTimeout=10 "$PVEW_SSH" 'bash -s' 2>&1 <<'PVEW_REMOTE'
set -u
pct exec 203 -- bash -lc '
set -u
DB="/var/lib/edge-queue-controller/edge_queue.sqlite3"
echo "edge_queue_controller_active=$(systemctl is-active edge-queue-controller.service 2>/dev/null || true)"
echo "listener_7070=$(ss -ltnp 2>/dev/null | grep -c ":7070" || true)"
sqlite3 "file:$DB?mode=ro" "pragma integrity_check;" 2>/dev/null | sed "s/^/db_integrity=/"
for t in user_sessions jobs job_results router_logs router_resolution_steps router_feedback workers worker_events; do
  c="$(sqlite3 "file:$DB?mode=ro" "select count(*) from $t;" 2>/dev/null || echo "<query_failed>")"
  echo "$t=$c"
done
'
PVEW_REMOTE
)" || true
echo "$ct203_out"

for expected in \
  "edge_queue_controller_active=active" \
  "listener_7070=1" \
  "db_integrity=ok" \
  "user_sessions=236" \
  "jobs=23" \
  "job_results=6" \
  "router_logs=0" \
  "router_resolution_steps=0" \
  "router_feedback=0" \
  "workers=2" \
  "worker_events=3"
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
