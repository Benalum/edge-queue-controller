#!/usr/bin/env bash
set -euo pipefail
set +H

usage() {
  cat >&2 <<'USAGE'
Usage:
  apc-companion-submit-and-read.sh --base-url URL --bearer TOKEN --message TEXT [--api-key KEY]

Submits one authenticated Companion queued chat request and polls the returned job.
This uses the existing /api/chat/queued and /api/chat/queued/{job_id} routes.
It does not run a worker and does not call Ollama.
USAGE
}

BASE="${APC_PUBLIC_BASE_URL:-}"
BEARER="${APC_PUBLIC_BEARER_TOKEN:-}"
API_KEY="${APC_PUBLIC_API_KEY:-}"
MESSAGE=""
POLL_COUNT="${APC_POLL_COUNT:-20}"
POLL_SLEEP="${APC_POLL_SLEEP:-3}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base-url) BASE="${2:-}"; shift 2 ;;
    --bearer) BEARER="${2:-}"; shift 2 ;;
    --api-key) API_KEY="${2:-}"; shift 2 ;;
    --message) MESSAGE="${2:-}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "REFUSE_UNKNOWN_ARGUMENT: $1" >&2; usage; exit 2 ;;
  esac
done

if [ -z "$BASE" ] || [ -z "$BEARER" ] || [ -z "$MESSAGE" ]; then
  echo "REFUSE_BASE_BEARER_MESSAGE_REQUIRED" >&2
  usage
  exit 2
fi
BASE="${BASE%/}"
TMP="$(mktemp)"
trap 'rm -f "$TMP" "$TMP.headers"' EXIT

headers=(-H "Content-Type: application/json" -H "Authorization: Bearer $BEARER" -H "X-Queued-Chat-Session-Token: $BEARER")
if [ -n "$API_KEY" ]; then
  headers+=( -H "X-Edge-API-Key: $API_KEY" )
fi

json_payload="$(python3 - <<'PY' "$MESSAGE"
import json, sys
print(json.dumps({"message": sys.argv[1], "metadata": {"source": "apc-companion-submit-and-read"}}, ensure_ascii=False))
PY
)"

code="$(curl -k -sS -D "$TMP.headers" -o "$TMP" -w '%{http_code}' \
  "${headers[@]}" \
  --data "$json_payload" \
  "$BASE/api/chat/queued" || true)"

echo "submit_http=$code"
python3 -m json.tool "$TMP" || cat "$TMP"
echo

if [ "$code" != "200" ]; then
  echo "REFUSE_SUBMIT_NOT_200" >&2
  exit 2
fi

JOB_ID="$(python3 - <<'PY' "$TMP"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data=json.load(f)
print(data.get('job_id') or '')
PY
)"
if ! [[ "$JOB_ID" =~ ^[0-9]+$ ]]; then
  echo "REFUSE_JOB_ID_NOT_RETURNED" >&2
  exit 2
fi

echo "submitted_job_id=$JOB_ID"
for i in $(seq 1 "$POLL_COUNT"); do
  code="$(curl -k -sS -o "$TMP" -w '%{http_code}' \
    "${headers[@]}" \
    "$BASE/api/chat/queued/$JOB_ID" || true)"
  status="$(python3 - <<'PY' "$TMP"
import json, sys
try:
    data=json.load(open(sys.argv[1], encoding='utf-8'))
    print(data.get('status') or data.get('job',{}).get('status') or '')
except Exception:
    print('')
PY
)"
  echo "poll=$i http=$code status=$status"
  if [ "$code" = "200" ]; then
    python3 -m json.tool "$TMP" || cat "$TMP"
  fi
  case "${status,,}" in
    completed|complete|failed|error|cancelled|canceled) break ;;
  esac
  sleep "$POLL_SLEEP"
done
