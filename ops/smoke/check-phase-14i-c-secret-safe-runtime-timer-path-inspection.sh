#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-c-secret-safe-runtime-timer-path-inspection"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-C secret-safe runtime/timer path inspection ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
echo "PASS: required docs/smoke files exist"

echo
echo "=== checkpoint ==="
git status --short
git log --oneline --decorate -5
git tag --points-at HEAD || true

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== active edge timers/services ==="
systemctl --no-pager --type=service --state=running | grep -E 'edge-queue|cloudflared' || true
systemctl --no-pager --type=timer | grep -E 'edge-queue|power|scheduler|remediation' || true

echo
echo "=== timer unit properties, no raw controller unit dump ==="
for unit in \
  edge-queue-power-auto-tick.timer \
  edge-queue-power-auto-tick.service \
  edge-queue-remediation-tick.timer \
  edge-queue-remediation-tick.service
do
  echo
  echo "--- $unit ---"
  systemctl show "$unit" \
    -p Id \
    -p LoadState \
    -p ActiveState \
    -p SubState \
    -p UnitFileState \
    -p FragmentPath \
    -p DropInPaths \
    -p ExecStart \
    --no-pager 2>/dev/null || true
done

echo
echo "=== redacted timer service text only ==="
for unit in \
  edge-queue-power-auto-tick.service \
  edge-queue-remediation-tick.service
do
  echo
  echo "--- redacted systemctl cat $unit ---"
  systemctl cat "$unit" 2>/dev/null \
    | sed -E 's/(SECRET|TOKEN|PASSWORD|KEY|SMTP|EMAIL|TRUSTED|AUTH|COOKIE)([A-Z0-9_]*=)[^[:space:]]+/\1\2REDACTED/g' \
    | sed -n '1,120p' || true
done

echo
echo "=== secret-safe controller environment flags ==="
systemctl show edge-queue-controller -p Environment --value 2>/dev/null \
  | tr ' ' '\n' \
  | grep -E '^EDGE_TICK_|^EDGE_POWER_AUTO_|^EDGE_POWER_EXECUTE_|^EDGE_PROXMOX_|^EDGE_ROUTER_|^EDGE_MODEL_|^WORKER_|^LANE_|^TINY_|^SMALL_' \
  | grep -v -Ei 'SECRET|TOKEN|PASSWORD|KEY=|SMTP|EMAIL|TRUSTED|AUTH|COOKIE' \
  | sort || true

echo
echo "=== read-only worker registry ==="
curl -sS --max-time 5 http://127.0.0.1:7070/workers/registry || echo "WARN: worker registry unavailable"
echo

echo
echo "=== read-only scheduler preview ==="
curl -sS --max-time 5 http://127.0.0.1:7070/scheduler/preview || echo "WARN: scheduler preview unavailable"
echo

echo
echo "=== read-only worker events ==="
curl -sS --max-time 5 "http://127.0.0.1:7070/workers/events?limit=30" || echo "WARN: worker events unavailable"
echo

echo
echo "=== documentation markers ==="
grep -Fq "EDGE_POWER_AUTO_START_WORKERS=1" "$DOC"
grep -Fq "EDGE_POWER_EXECUTE_START_WORKERS=1" "$DOC"
grep -Fq "EDGE_TICK_AUTO_READY_WORKER=1" "$DOC"
grep -Fq "EDGE_TICK_USE_DIRECT_OLLAMA=1" "$DOC"
grep -Fq "Worker registry total: 0" "$DOC"
grep -Fq "Queued job observed: job_id 23" "$DOC"
grep -Fq "Do not activate workers yet" "$DOC"
echo "PASS: required documentation markers found"

echo
echo "=== read-only guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)|/api/(generate|chat)|systemctl[[:space:]]+cat[[:space:]]+edge-queue-controller' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
if [ -n "$danger" ]; then
  echo "$danger"
  echo "FAIL: smoke script contains mutation, model execution, or unsafe raw controller unit dump pattern"
  exit 1
fi
echo "PASS: read-only guard passed"

echo
echo "=== done: Phase 14I-C runtime/timer inspection smoke complete ==="
