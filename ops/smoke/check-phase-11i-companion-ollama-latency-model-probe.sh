#!/usr/bin/env bash

echo "=== Phase 11I smoke: Companion Ollama latency and model availability probe ==="

fail=0

DOC="docs/phase-11i-companion-ollama-latency-model-probe.md"

OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-}"
OLLAMA_MODEL="${OLLAMA_MODEL:-}"

if [ -z "$OLLAMA_BASE_URL" ]; then
  OLLAMA_BASE_URL="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null | tr ' ' '\n' | awk -F= '$1=="EDGE_OLLAMA_BASE_URL"{print $2; exit}')"
fi

if [ -z "$OLLAMA_MODEL" ]; then
  OLLAMA_MODEL="$(systemctl show edge-queue-controller -p Environment --value 2>/dev/null | tr ' ' '\n' | awk -F= '$1=="LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK"{print $2; exit}')"
fi

if [ -z "$OLLAMA_BASE_URL" ]; then
  OLLAMA_BASE_URL="http://100.88.245.33:11434"
fi

if [ -z "$OLLAMA_MODEL" ]; then
  OLLAMA_MODEL="gemma4:e4b"
fi

echo "OLLAMA_BASE_URL=$OLLAMA_BASE_URL"
echo "OLLAMA_MODEL=$OLLAMA_MODEL"

echo
echo "=== verify stage files exist ==="
for path in \
  "$DOC" \
  ops/smoke/check-phase-11i-companion-ollama-latency-model-probe.sh
do
  if [ -f "$path" ]; then
    echo "PASS: found $path"
  else
    echo "FAIL: missing $path"
    fail=1
  fi
done

echo
echo "=== verify Phase 11H tag remains present ==="
if git rev-parse --verify controller-phase-11h-companion-queued-ollama-timeout-inspection-2026-06-13 >/dev/null 2>&1; then
  echo "PASS: Phase 11H tag exists"
else
  echo "FAIL: Phase 11H tag missing"
  fail=1
fi

echo
echo "=== Ollama version check ==="
version_code="$(curl -sS --max-time 8 -o /tmp/phase11i-ollama-version.json -w "%{http_code}" "$OLLAMA_BASE_URL/api/version" 2>/tmp/phase11i-ollama-version.err || true)"
echo "version_http_code=$version_code"
sed -n '1,80p' /tmp/phase11i-ollama-version.json 2>/dev/null || true

if [ "$version_code" = "200" ]; then
  echo "PASS: Ollama /api/version reachable"
else
  echo "CHECK: Ollama /api/version was not reachable with HTTP 200"
fi

echo
echo "=== Ollama tags check ==="
tags_code="$(curl -sS --max-time 12 -o /tmp/phase11i-ollama-tags.json -w "%{http_code}" "$OLLAMA_BASE_URL/api/tags" 2>/tmp/phase11i-ollama-tags.err || true)"
echo "tags_http_code=$tags_code"

python3 - <<'PY'
import json
from pathlib import Path

path = Path("/tmp/phase11i-ollama-tags.json")
if not path.exists() or not path.read_text().strip():
    print("CHECK: no tags JSON body")
    raise SystemExit(0)

try:
    data = json.loads(path.read_text())
except Exception as exc:
    print(f"CHECK: could not parse tags JSON: {exc}")
    raise SystemExit(0)

models = data.get("models", [])
print("models:")
for model in models:
    print(" -", model.get("name", "unknown"))
PY

if [ "$tags_code" = "200" ]; then
  if grep -q "\"name\".*${OLLAMA_MODEL}" /tmp/phase11i-ollama-tags.json 2>/dev/null; then
    echo "PASS: configured fallback model appears in Ollama tags"
  else
    echo "CHECK: configured fallback model was not found exactly in Ollama tags"
  fi
else
  echo "CHECK: Ollama /api/tags was not reachable with HTTP 200"
fi

echo
echo "=== tiny direct Ollama model latency probe ==="
echo "This is not a Companion queue job. It sends one tiny direct prompt to the configured Ollama endpoint."

python3 - <<'PY'
import json
import os
import sys
import time
import urllib.request
import urllib.error

base = os.environ.get("OLLAMA_BASE_URL", "http://100.88.245.33:11434").rstrip("/")
model = os.environ.get("OLLAMA_MODEL", "gemma4:e4b")
url = f"{base}/api/generate"

payload = {
    "model": model,
    "prompt": "Reply with exactly: ok",
    "stream": False,
    "options": {
        "num_predict": 8,
        "temperature": 0
    }
}

body = json.dumps(payload).encode("utf-8")
req = urllib.request.Request(
    url,
    data=body,
    headers={"Content-Type": "application/json"},
    method="POST",
)

start = time.perf_counter()
try:
    with urllib.request.urlopen(req, timeout=75) as response:
        raw = response.read()
        code = response.getcode()
    elapsed = time.perf_counter() - start
    print(f"ollama_generate_http_code={code}")
    print(f"ollama_generate_elapsed_seconds={elapsed:.3f}")

    try:
        data = json.loads(raw.decode("utf-8"))
        response_text = str(data.get("response", "")).strip()
        print(f"ollama_generate_response_preview={response_text[:200]}")
    except Exception as exc:
        print(f"CHECK: could not parse generate JSON: {exc}")
        print(raw[:500])

    if code == 200 and elapsed <= 45:
        print("PASS: tiny direct model probe completed within 45 seconds")
    elif code == 200:
        print("CHECK: tiny direct model probe completed but was slow")
    else:
        print("CHECK: tiny direct model probe returned non-200")

except Exception as exc:
    elapsed = time.perf_counter() - start
    print(f"CHECK: tiny direct model probe failed or timed out after {elapsed:.3f}s: {exc}")
PY

echo
echo "=== recent controller/wrapper evidence around Ollama/queue ==="
journalctl -u edge-queue-controller -n 160 --no-pager 2>/dev/null \
  | grep -Ei 'ollama|timeout|timed out|laptop-queue|jobs/claim|jobs/.*/complete|workers/heartbeat|gemma4' \
  | tail -n 120 || true

echo
echo "=== append Phase 11I evidence to doc ==="
{
  echo
  echo "## Phase 11I Smoke Evidence"
  echo
  echo "Generated: $(date -Is)"
  echo
  echo "### Git"
  echo
  echo '```text'
  git log --oneline -12
  git tag --points-at HEAD
  echo '```'
  echo
  echo "### Ollama target"
  echo
  echo '```text'
  echo "OLLAMA_BASE_URL=$OLLAMA_BASE_URL"
  echo "OLLAMA_MODEL=$OLLAMA_MODEL"
  echo "version_http_code=$version_code"
  echo "tags_http_code=$tags_code"
  echo '```'
  echo
  echo "### Interpretation"
  echo
  echo "If the tiny direct model probe is slow or times out, Phase 11J should either use a faster fallback model, increase the bounded worker timeout, or add a warmup/preflight path."
} >> "$DOC"

echo
echo "=== verify this inspection changed only docs/smoke ==="
git status --short

unexpected_files="$(git status --short | awk '{print $2}' | grep -vE '^(docs/phase-11i-companion-ollama-latency-model-probe\.md|ops/smoke/check-phase-11i-companion-ollama-latency-model-probe\.sh)$' || true)"
if [ -n "$unexpected_files" ]; then
  echo "FAIL: unexpected changed files:"
  printf '%s\n' "$unexpected_files"
  fail=1
else
  echo "PASS: only expected Phase 11I docs/smoke files changed"
fi

echo
echo "=== verify router rollout remains parked ==="
if systemctl show edge-queue-controller -p Environment --value 2>/dev/null | tr ' ' '\n' | grep -E 'ROUTER.*DRY.*RUN|DRY.*RUN.*ROUTER' ; then
  echo "FAIL: router dry-run environment appears present"
  fail=1
else
  echo "PASS: router dry-run environment remains absent"
fi

runtime_files="$(find . \
  -type f \( -name '*.py' -o -name '*.js' -o -name '*.html' \) \
  -not -path './.git/*' \
  -not -path './.venv/*' \
  -not -path './node_modules/*' \
  -not -path './docs/*' \
  -not -path './ops/smoke/*' \
  -not -path './ops/stage/*' \
  -print)"

echo
echo "=== check for frontend router network traffic references ==="
if printf '%s\n' "$runtime_files" | xargs grep -nE 'fetch\([^)]*/api/router|XMLHttpRequest.*api/router' 2>/dev/null; then
  echo "FAIL: frontend router network call reference found"
  fail=1
else
  echo "PASS: no frontend router network call reference found"
fi

echo
echo "=== check for obvious persistent rollout mutation routes ==="
if printf '%s\n' "$runtime_files" | xargs grep -nE '@app\.(post|put|patch|delete).*rollout|router\.(post|put|patch|delete).*rollout' 2>/dev/null; then
  echo "FAIL: possible persistent rollout mutation route found"
  fail=1
else
  echo "PASS: no obvious persistent rollout mutation route found"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 11I smoke passed"
else
  echo "FAIL: Phase 11I smoke failed"
fi

[ "$fail" = "0" ]
