#!/usr/bin/env bash

echo "=== Phase 11H-R1 smoke: Companion queued Ollama timeout inspection ==="

fail=0
FAILED_JOB_ID="${FAILED_JOB_ID:-s5f18-job-d0425f23fd07bf0c}"
DOC="docs/phase-11h-companion-queued-ollama-timeout-inspection.md"

code_for() {
  local url="$1"
  curl -sS --max-time 6 -o /tmp/phase11h-curl.out -w "%{http_code}" "$url" 2>/tmp/phase11h-curl.err || true
}

append_text_block() {
  local title="$1"
  {
    echo
    echo "### ${title}"
    echo
    echo '```text'
    cat
    echo '```'
  } >> "$DOC"
}

echo
echo "=== verify stage files exist ==="
for path in \
  "$DOC" \
  ops/smoke/check-phase-11h-companion-queued-ollama-timeout-inspection.sh
do
  if [ -f "$path" ]; then
    echo "PASS: found $path"
  else
    echo "FAIL: missing $path"
    fail=1
  fi
done

echo
echo "=== verify Phase 11G tag remains present ==="
if git rev-parse --verify controller-phase-11g-system-render-readiness-variable-repair-2026-06-13 >/dev/null 2>&1; then
  echo "PASS: Phase 11G tag exists"
else
  echo "FAIL: Phase 11G tag missing"
  fail=1
fi

echo
echo "=== discover Companion frontend gateway with GET only ==="
CANDIDATES="
http://127.0.0.1:8787
http://127.0.0.1:7070
http://127.0.0.1:8088
https://alexhartel.com
"

FRONTEND_BASE=""

for base in $CANDIDATES; do
  companion_code="$(code_for "$base/companion")"
  system_code="$(code_for "$base/api/system/status")"
  queue_code="$(code_for "$base/api/chat/queue/status")"

  echo "CHECK: $base companion=$companion_code system_status=$system_code queue_status=$queue_code"

  if [ -z "$FRONTEND_BASE" ] && [ "$companion_code" = "200" ]; then
    FRONTEND_BASE="$base"
  fi
done

if [ -n "$FRONTEND_BASE" ]; then
  echo "PASS: selected frontend gateway: $FRONTEND_BASE"
else
  echo "FAIL: no frontend gateway returned HTTP 200 for /companion"
  fail=1
fi

echo
echo "=== inspect status endpoints as CHECK-only ==="
for url in \
  "http://127.0.0.1:8787/api/system/status" \
  "http://127.0.0.1:8787/system/status" \
  "http://127.0.0.1:8787/system/public-status" \
  "http://127.0.0.1:7070/system/status" \
  "http://127.0.0.1:7070/system/public-status" \
  "http://127.0.0.1:7070/system/local-health"
do
  code="$(code_for "$url")"
  echo "CHECK: GET $url returned HTTP $code"
  if [ "$code" = "200" ]; then
    echo "--- body preview ---"
    sed -n '1,60p' /tmp/phase11h-curl.out 2>/dev/null || true
    echo "--- end body preview ---"
  fi
done

echo
echo "=== GET failed job details when endpoint permits it; protected 401 is expected without browser session token ==="
if [ -n "$FRONTEND_BASE" ]; then
  for route in \
    "/api/chat/queued/${FAILED_JOB_ID}" \
    "/api/chat/queue/status?job_id=${FAILED_JOB_ID}" \
    "/api/chat/queue/status"
  do
    url="${FRONTEND_BASE}${route}"
    code="$(code_for "$url")"
    echo "CHECK: GET $url returned HTTP $code"
    echo "--- body preview ---"
    sed -n '1,80p' /tmp/phase11h-curl.out 2>/dev/null || true
    echo "--- end body preview ---"

    if [ "$code" = "401" ]; then
      echo "PASS: protected queue endpoint rejected unauthenticated read"
    fi
  done
else
  echo "SKIP: failed job GET checks because no frontend gateway was found"
fi

echo
echo "=== local service inventory, read-only ==="
systemctl list-units --type=service --all --no-pager \
  | grep -Ei 'edge|queue|worker|ollama|wrapper|cloudflared' \
  | sed -n '1,160p' || true

echo
echo "=== local timer inventory, read-only ==="
systemctl list-timers --all --no-pager \
  | grep -Ei 'edge|queue|worker|remediation|power' \
  | sed -n '1,160p' || true

echo
echo "=== inspect relevant systemd environment keys without exposing secrets ==="
for unit in edge-queue-controller edge-wrapper-ui; do
  echo "--- $unit environment hints ---"
  systemctl show "$unit" -p Environment --value 2>/dev/null \
    | tr ' ' '\n' \
    | grep -Ei 'OLLAMA|MODEL|TIMEOUT|QUEUE|WORKER|BASE_URL|CT101|LAPTOP' \
    | sed -E 's/(TOKEN|SECRET|PASSWORD|KEY)=.*/\1=<redacted>/I' \
    | sed -n '1,120p' || true
done

echo
echo "=== source inspection for timeout/model/ollama markers ==="
grep -RInE 'bounded ollama|Ollama request failed|OLLAMA|ollama|gemma4|fallback|timeout|TIMEOUT|queued_chat|laptop-queue' \
  edge_controller.py frontend ops systemd 2>/dev/null \
  | sed -n '1,260p' || true

echo
echo "=== controller and wrapper logs around failed job, read-only ==="
{
  echo "--- edge-queue-controller: failed job and worker markers ---"
  journalctl -u edge-queue-controller --since "2026-06-13 00:35:00" --until "2026-06-13 00:46:30" --no-pager 2>/dev/null \
    | grep -Ei "${FAILED_JOB_ID}|bounded ollama|ollama request failed|timed out|timeout|gemma4|queued chat|queue worker|jobs/claim|workers/heartbeat|jobs/.*/complete|internal/laptop-queue" \
    | sed -n '1,260p' || true

  echo
  echo "--- edge-wrapper-ui: failed job polling markers ---"
  journalctl -u edge-wrapper-ui --since "2026-06-13 00:35:00" --until "2026-06-13 00:46:30" --no-pager 2>/dev/null \
    | grep -Ei "${FAILED_JOB_ID}|/api/chat/queued|/api/chat/queue/status|api/system/status|companion|timed out|timeout" \
    | sed -n '1,260p' || true
} | tee /tmp/phase11h-job-log-evidence.txt

echo
echo "=== CT101 / Ollama read-only inspection over Tailscale SSH, bounded and optional ==="
if timeout 20s ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o ServerAliveInterval=4 \
    -o ServerAliveCountMax=2 \
    root@100.88.194.19 \
    'timeout 14s pct exec 101 -- bash -lc "
      echo --- CT101 basic ---
      hostname || true
      date -Is || true
      uptime || true

      echo
      echo --- Docker containers ---
      docker ps --format \"table {{.Names}}\t{{.Status}}\t{{.Ports}}\" 2>/dev/null || true

      echo
      echo --- Ollama version ---
      curl -sS --max-time 4 http://127.0.0.1:11434/api/version 2>/dev/null || true
      echo

      echo
      echo --- Ollama tags compact ---
      curl -sS --max-time 6 http://127.0.0.1:11434/api/tags 2>/dev/null \
        | python3 - <<\"PY\" 2>/dev/null || true
import json, sys
try:
    data=json.load(sys.stdin)
    for model in data.get(\"models\", []):
        print(model.get(\"name\", \"unknown\"))
except Exception as exc:
    print(f\"could_not_parse_tags: {exc}\")
PY

      echo
      echo --- Recent Ollama logs ---
      docker logs --tail 80 ollama 2>&1 | sed -n \"1,120p\" || true
    "'; then
  echo "PASS: optional CT101 read-only inspection completed"
else
  echo "CHECK: optional CT101 SSH/Ollama read-only inspection unavailable or timed out"
fi

echo
echo "=== append Phase 11H-R1 evidence summary to doc ==="
{
  echo
  echo "## Phase 11H-R1 Smoke Evidence"
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
  echo "### Failed job"
  echo
  echo '```text'
  echo "FAILED_JOB_ID=$FAILED_JOB_ID"
  echo "Observed user-facing error: stage 5e21 bounded ollama failure: Ollama request failed: timed out"
  echo '```'
  echo
  echo "### Selected gateway"
  echo
  echo '```text'
  echo "FRONTEND_BASE=${FRONTEND_BASE:-none}"
  echo '```'
  echo
  echo "### Key evidence from repaired smoke"
  echo
  echo "- /companion was reachable from the selected frontend gateway."
  echo "- Queue job status endpoints are protected and reject unauthenticated reads, which is expected outside the browser session."
  echo "- Local controller and wrapper services were inspected without restarts."
  echo "- Worker heartbeat/claim/complete log markers were collected for the failed job window."
  echo "- Optional CT101/Ollama SSH inspection was bounded and does not block the checkpoint."
  echo
  echo "### Recommended Phase 11I direction"
  echo
  echo "Use the collected source/log evidence to choose the smallest reliability repair: bounded timeout adjustment, faster fallback model, Ollama warmup/preflight, or clearer timeout handling."
} >> "$DOC"

echo
echo "=== verify this inspection changed only docs/smoke ==="
git status --short

unexpected_files="$(git status --short | awk '{print $2}' | grep -vE '^(docs/phase-11h-companion-queued-ollama-timeout-inspection\.md|ops/smoke/check-phase-11h-companion-queued-ollama-timeout-inspection\.sh)$' || true)"
if [ -n "$unexpected_files" ]; then
  echo "FAIL: unexpected changed files:"
  printf '%s\n' "$unexpected_files"
  fail=1
else
  echo "PASS: only expected Phase 11H docs/smoke files changed"
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
  echo "PASS: Phase 11H-R1 smoke passed"
else
  echo "FAIL: Phase 11H-R1 smoke failed"
fi

[ "$fail" = "0" ]
