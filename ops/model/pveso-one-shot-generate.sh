#!/usr/bin/env bash
set -euo pipefail
set +H

REQUIRED_APPROVAL="APPROVE_STAGE_16_E3I_RUN_ONE_SHOT_MODEL_ADAPTER_NO_DB_WRITE_NO_WORKER_ACTIVATION_NO_SCHEDULER_ACTIVATION_NO_MODEL_PULL_NO_PUBLIC_EXPOSURE_KEEP_CT101_STOPPED"
APPROVAL="${APC_ONE_SHOT_MODEL_APPROVAL:-}"
MODEL_NAME="${MODEL_NAME:-qwen2.5:32b-instruct-q4_K_M}"
PROMPT_TEXT="${PROMPT_TEXT:-Reply with exactly this token and no extra words: APC_E3I_OK}"
NUM_PREDICT="${NUM_PREDICT:-4}"
NUM_CTX="${NUM_CTX:-512}"
TEMPERATURE="${TEMPERATURE:-0}"
SEED="${SEED:-16}"
CURL_TIMEOUT="${CURL_TIMEOUT:-240}"
TARGET_OLLAMA_HOST="127.0.0.1:11434"

usage() {
  cat <<USAGE
PVESO one-shot Ollama generate adapter.

This script is intentionally gated. It will not run a model call unless:
  APC_ONE_SHOT_MODEL_APPROVAL=$REQUIRED_APPROVAL

Environment knobs:
  MODEL_NAME       default: $MODEL_NAME
  PROMPT_TEXT      default: tiny deterministic smoke prompt
  NUM_PREDICT      default: $NUM_PREDICT
  NUM_CTX          default: $NUM_CTX
  TEMPERATURE      default: $TEMPERATURE
  SEED             default: $SEED
  CURL_TIMEOUT     default: $CURL_TIMEOUT

Safety posture:
  - PVESO discovered through tailscale status.
  - SSHes to PVESO.
  - Calls PVESO-local http://127.0.0.1:11434/api/generate only.
  - Requires CT101 stopped/onboot=0.
  - Requires Ollama localhost-only listener.
  - No DB writes.
  - No worker/scheduler activation.
  - No model pull/download.
  - No service start/stop/restart/reload.
USAGE
}

sanitize_stream() {
  sed -E \
    -e 's#https://login\.tailscale\.com/a/[A-Za-z0-9]+#<redacted-auth-url>#g' \
    -e 's/100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-tailscale-ip>/g' \
    -e 's/10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/192\.168\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}/<redacted-private-ip>/g' \
    -e 's/([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}/<redacted-mac>/g' \
    -e 's/(token|secret|password|passwd|bearer|authorization)=([^[:space:]]+)/\1=<redacted>/Ig'
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

if [ "$APPROVAL" != "$REQUIRED_APPROVAL" ]; then
  echo "approval_gate=FAIL"
  echo "required=$REQUIRED_APPROVAL"
  echo "Set APC_ONE_SHOT_MODEL_APPROVAL to the required approval string to run."
  exit 64
fi

if ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale_command=missing"
  exit 65
fi

PVESO_TS_IP="$(
  tailscale status 2>/dev/null \
    | awk 'tolower($2)=="pveso" {print $1; exit}'
)"

if [ -z "$PVESO_TS_IP" ]; then
  echo "pveso_tailscale_ip=<not_found>"
  exit 66
fi

{
echo "=== PVESO one-shot model adapter ==="
echo "approval_gate=PASS"
echo "model_name=$MODEL_NAME"
echo "target_ollama_host=$TARGET_OLLAMA_HOST"
echo "num_predict=$NUM_PREDICT"
echo "num_ctx=$NUM_CTX"
echo "temperature=$TEMPERATURE"
echo "seed=$SEED"
echo "pveso_tailscale_ip=found"
echo

ssh \
  -o BatchMode=yes \
  -o ConnectTimeout=10 \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "root@$PVESO_TS_IP" \
  "MODEL_NAME='$MODEL_NAME' PROMPT_TEXT='$PROMPT_TEXT' NUM_PREDICT='$NUM_PREDICT' NUM_CTX='$NUM_CTX' TEMPERATURE='$TEMPERATURE' SEED='$SEED' CURL_TIMEOUT='$CURL_TIMEOUT' bash -s" <<'REMOTE'
set -euo pipefail

TARGET_OLLAMA_HOST="127.0.0.1:11434"
MODEL_NAME="${MODEL_NAME:?MODEL_NAME required}"
PROMPT_TEXT="${PROMPT_TEXT:?PROMPT_TEXT required}"
NUM_PREDICT="${NUM_PREDICT:?NUM_PREDICT required}"
NUM_CTX="${NUM_CTX:?NUM_CTX required}"
TEMPERATURE="${TEMPERATURE:?TEMPERATURE required}"
SEED="${SEED:?SEED required}"
CURL_TIMEOUT="${CURL_TIMEOUT:?CURL_TIMEOUT required}"
RUN_DIR="/root/apc-one-shot-model-adapter-$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "$RUN_DIR"
chmod 700 "$RUN_DIR"

echo "host=$(hostname)"
echo "run_dir=$RUN_DIR"

if command -v pct >/dev/null 2>&1 && pct status 101 >/dev/null 2>&1; then
  ct101_status="$(pct status 101 | tr -s " ")"
  ct101_onboot="$(pct config 101 2>/dev/null | awk -F": " "/^onboot:/ {print \$2}" | head -1)"
  echo "ct_101_status=$ct101_status"
  echo "ct_101_onboot=$ct101_onboot"
  [ "$ct101_status" = "status: stopped" ] || exit 70
  [ "$ct101_onboot" = "0" ] || exit 71
else
  echo "ct_101_status=<missing_or_pct_unavailable>"
  exit 72
fi

echo "ollama_active=$(systemctl is-active ollama.service 2>/dev/null || true)"
systemctl is-active --quiet ollama.service || exit 73

systemctl show ollama.service -p Environment --value 2>/dev/null \
  | tr " " "\n" \
  | grep -E "^OLLAMA_(HOST|MODELS|NUM_THREADS|NUM_PARALLEL)=" || true

if ! systemctl show ollama.service -p Environment --value 2>/dev/null | tr " " "\n" | grep -qx "OLLAMA_HOST=127.0.0.1:11434"; then
  echo "ollama_host_guard=FAIL"
  exit 74
fi

bad_listener_count="$(
  ss -ltnH 2>/dev/null \
    | awk '$4 ~ /:11434$/ && $4 !~ /127[.]0[.]0[.]1:11434$/ && $4 !~ /\[::1\]:11434$/ {c++} END{print c+0}'
)"
echo "non_localhost_11434_listener_count=$bad_listener_count"
[ "$bad_listener_count" = "0" ] || exit 75

curl -fsS --max-time 10 "http://${TARGET_OLLAMA_HOST}/api/version" \
  | tee "$RUN_DIR/api-version.json" \
  | python3 -c 'import sys,json; data=json.load(sys.stdin); print("api_version_ok=yes"); print("api_version="+str(data.get("version","<missing>")))'

curl -fsS --max-time 20 "http://${TARGET_OLLAMA_HOST}/api/tags" > "$RUN_DIR/api-tags.json"

python3 - "$MODEL_NAME" "$RUN_DIR/api-tags.json" <<'PY'
import json, sys
target = sys.argv[1]
path = sys.argv[2]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
models = data.get("models", [])
names = [m.get("name") for m in models]
print("api_tags_ok=yes")
print("api_tags_model_count=" + str(len(models)))
for name in names:
    print("api_tags_model=" + str(name))
if target not in names:
    print("target_model_present=no")
    sys.exit(76)
print("target_model_present=yes")
PY

request_file="$RUN_DIR/generate-request.json"
response_file="$RUN_DIR/generate-response.json"
stderr_file="$RUN_DIR/generate-curl.stderr"

python3 - "$MODEL_NAME" "$PROMPT_TEXT" "$NUM_PREDICT" "$NUM_CTX" "$TEMPERATURE" "$SEED" > "$request_file" <<'PY'
import json, sys
model, prompt, num_predict, num_ctx, temperature, seed = sys.argv[1:]
payload = {
    "model": model,
    "prompt": prompt,
    "stream": False,
    "keep_alive": "0s",
    "options": {
        "temperature": float(temperature),
        "num_predict": int(num_predict),
        "num_ctx": int(num_ctx),
        "seed": int(seed),
    },
}
json.dump(payload, sys.stdout)
PY

start_epoch="$(date +%s)"
curl -fsS \
  --max-time "$CURL_TIMEOUT" \
  -H 'Content-Type: application/json' \
  -d @"$request_file" \
  "http://${TARGET_OLLAMA_HOST}/api/generate" \
  > "$response_file" \
  2> "$stderr_file" &
curl_pid="$!"

for i in $(seq 1 "$CURL_TIMEOUT"); do
  if kill -0 "$curl_pid" 2>/dev/null; then
    if [ $((i % 10)) -eq 0 ]; then
      echo "generate_wait_seconds=$i"
      ps -eo pid,user,stat,etime,%cpu,%mem,rss,args 2>/dev/null \
        | grep -Ei "ollama|runner" \
        | grep -v grep || true
    fi
    sleep 1
  else
    break
  fi
done

wait "$curl_pid"
curl_rc="$?"
end_epoch="$(date +%s)"
echo "generate_curl_rc=$curl_rc"
echo "generate_elapsed_seconds=$((end_epoch - start_epoch))"

if [ "$curl_rc" != "0" ]; then
  echo "generate_curl_stderr_start"
  cat "$stderr_file" 2>/dev/null || true
  echo "generate_curl_stderr_end"
  exit 77
fi

python3 - "$response_file" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
response = str(data.get("response", ""))
clean = response.replace("\n", "\\n")
print("generate_json_ok=yes")
print("generate_done=" + str(data.get("done", "<missing>")))
print("generate_model=" + str(data.get("model", "<missing>")))
print("generate_response_text=" + clean[:200])
print("generate_response_len=" + str(len(response)))
for k in [
    "total_duration",
    "load_duration",
    "prompt_eval_count",
    "prompt_eval_duration",
    "eval_count",
    "eval_duration",
]:
    if k in data:
        print(f"generate_{k}={data[k]}")
if not response.strip():
    print("generate_nonempty_response=no")
    sys.exit(78)
print("generate_nonempty_response=yes")
PY

echo "ollama_active_post=$(systemctl is-active ollama.service 2>/dev/null || true)"
bad_listener_count_post="$(
  ss -ltnH 2>/dev/null \
    | awk '$4 ~ /:11434$/ && $4 !~ /127[.]0[.]0[.]1:11434$/ && $4 !~ /\[::1\]:11434$/ {c++} END{print c+0}'
)"
echo "non_localhost_11434_listener_count_post=$bad_listener_count_post"
[ "$bad_listener_count_post" = "0" ] || exit 79

if command -v pct >/dev/null 2>&1 && pct status 101 >/dev/null 2>&1; then
  echo "ct_101_status_post=$(pct status 101 | tr -s " ")"
  echo "ct_101_onboot_post=$(pct config 101 2>/dev/null | awk -F": " "/^onboot:/ {print \$2}" | head -1)"
fi

echo "ONE_SHOT_MODEL_ADAPTER_RESULT=PASS"
REMOTE

} 2>&1 | sanitize_stream
