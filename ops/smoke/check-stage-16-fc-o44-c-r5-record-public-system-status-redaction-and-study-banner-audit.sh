#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o44-c-r5-record-public-system-status-redaction-and-study-banner-audit.md"
CONTRACT_SMOKE="ops/smoke/check-stage-16-fc-o44-c-public-status-redaction-contract.py"
SOURCE="edge_controller.py"
FORBIDDEN_STATUS_REGEX='127\.0\.0\.1|localhost|local-health|/system/local-health|http://[^"]*:[0-9]+|https://[^"]*:[0-9]+|CT203|ct-203|CT204|ct-204|CT101|ct-101|VM200|vm-200|PVEW|PVESO|Proxmox|nginx|cloudflared|/srv/|admin_model_warmup|model_memory_status|warmup|Ollama|qwen|llama|edge-queue-controller|controller/API|queue/API|worker dispatch|manual-unlock|mountpoint|private_storage|private_storage_status'

test -f "$DOC"
test -x "$CONTRACT_SMOKE"
python3 -m py_compile "$SOURCE"
"$CONTRACT_SMOKE"

grep -Fq "public System status redaction is live" "$DOC"
grep -Fq "Signed-out users can see Study session scaffolding" "$DOC"
grep -Fq "Under Construction: Some features do not work yet." "$DOC"
grep -Fq "FC-O44-D should patch the public Study signed-out view and banner copy" "$DOC"

for url in \
  "https://alexhartel.com/api/system/status?fc_o44_c_r5_repo_smoke=$(date -u +%s)" \
  "https://alexhartel.com/system/status?fc_o44_c_r5_repo_smoke=$(date -u +%s)"
do
  tmp="$(mktemp)"
  code="$(curl -k -L -sS -H 'cache-control: no-cache' -o "$tmp" -w '%{http_code}' "$url")"
  test "$code" = "200"
  python3 -m json.tool "$tmp" >/dev/null
  if grep -Eiq "$FORBIDDEN_STATUS_REGEX" "$tmp"; then
    echo "forbidden public infrastructure term found in $url"
    grep -Ein "$FORBIDDEN_STATUS_REGEX" "$tmp" || true
    rm -f "$tmp"
    exit 1
  fi
  python3 - <<'PY' "$tmp"
import json, sys
data=json.load(open(sys.argv[1]))
assert "nodes" not in data
assert "private_storage_status" not in data
assert "model_memory_status" not in data
PY
  rm -f "$tmp"
done

echo "stage-16-fc-o44-c-r5 checkpoint smoke passed"
