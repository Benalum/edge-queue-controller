#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-a-new-chat-read-only-baseline-repository-rule"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-A New Chat read-only baseline repository rule ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
echo "PASS: required docs/smoke files exist"

echo
echo "=== repository status ==="
git status --short

echo
echo "=== git checkpoint ==="
git log --oneline --decorate -8
git tag --points-at HEAD || true
git branch -vv

echo
echo "=== origin/main summary ==="
if [ "${EDGE_BASELINE_ALLOW_FETCH:-0}" = "1" ]; then
  git fetch origin main --quiet || true
  echo "fetch_attempted=1"
else
  echo "fetch_skipped=1"
  echo "reason=EDGE_BASELINE_ALLOW_FETCH is not 1; default smoke remains local read-only"
fi
echo "HEAD=$(git rev-parse --short HEAD)"
echo "origin/main=$(git rev-parse --short origin/main || true)"

echo
echo "=== compile baseline ==="
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== smoke scripts present ==="
find ops/smoke -maxdepth 1 -type f -name 'check-*.sh' | sort | tail -80 || true

echo
echo "=== controller health, if running ==="
curl -sS --max-time 5 http://127.0.0.1:7070/health || echo "WARN: controller health unavailable"
echo

echo
echo "=== read-only scheduler preview, if available ==="
curl -sS --max-time 5 http://127.0.0.1:7070/scheduler/preview || echo "WARN: scheduler preview unavailable"
echo

echo
echo "=== read-only worker registry, if available ==="
curl -sS --max-time 5 http://127.0.0.1:7070/workers/registry || echo "WARN: worker registry unavailable"
echo

echo
echo "=== systemd timers/services read-only summary ==="
systemctl --no-pager --type=service --state=running | grep -E 'edge-queue|cloudflared' || true
systemctl --no-pager --type=timer | grep -E 'edge-queue|power|scheduler' || true

echo
echo "=== power environment summary, if service exists ==="
systemctl show edge-queue-controller -p Environment --value 2>/dev/null \
  | tr ' ' '\n' \
  | grep -E '^EDGE_POWER_AUTO_|^EDGE_POWER_EXECUTE_|^EDGE_PROXMOX_|^EDGE_MODEL_|^EDGE_ROUTER_' \
  | sort || true

echo
echo "=== safety marker grep ==="
grep -RIn -E 'warmup|router|lane|worker|authHeaders|profile/preferences' \
  edge_controller.py docs ops 2>/dev/null | head -180 || true

echo
echo "=== read-only guard for this phase smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|systemctl[[:space:]]+(start|restart|enable|disable)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)|/api/(generate|chat)' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
if [ -n "$danger" ]; then
  echo "$danger"
  echo "FAIL: smoke script contains a dangerous runtime mutation or model execution pattern"
  exit 1
fi
echo "PASS: no dangerous mutation/model execution command patterns found in this smoke script"

echo
echo "=== done: Phase 14I-A read-only baseline smoke complete ==="
