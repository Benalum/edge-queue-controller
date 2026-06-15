#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-b-persistent-lane-worker-blocker-reentry-inspection"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-B persistent lane worker blocker re-entry inspection ==="

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
echo "=== read-only worker registry ==="
curl -sS --max-time 5 http://127.0.0.1:7070/workers/registry || echo "WARN: worker registry unavailable"
echo

echo
echo "=== read-only scheduler preview ==="
curl -sS --max-time 5 http://127.0.0.1:7070/scheduler/preview || echo "WARN: scheduler preview unavailable"
echo

echo
echo "=== read-only recent worker events ==="
curl -sS --max-time 5 "http://127.0.0.1:7070/workers/events?limit=30" || echo "WARN: worker events unavailable"
echo

echo
echo "=== secret-safe runtime flag summary ==="
systemctl show edge-queue-controller -p Environment --value 2>/dev/null \
  | tr ' ' '\n' \
  | grep -E '^EDGE_TICK_|^EDGE_POWER_AUTO_|^EDGE_POWER_EXECUTE_|^EDGE_PROXMOX_|^EDGE_ROUTER_|^EDGE_MODEL_|^WORKER_|^LANE_|^TINY_|^SMALL_' \
  | grep -v -Ei 'SECRET|TOKEN|PASSWORD|KEY=|SMTP|EMAIL|TRUSTED' \
  | sort || true

echo
echo "=== timers/services summary ==="
systemctl --no-pager --type=service --state=running | grep -E 'edge-queue|cloudflared' || true
systemctl --no-pager --type=timer | grep -E 'edge-queue|power|scheduler|remediation' || true

echo
echo "=== repo blocker references ==="
grep -RInE 'persistent_lane_workers_not_active|primary_worker_unfiltered|worker_registry_empty|router_rollout_parked|warmup_execution_disabled|ct101_runtime_protected|model-tiny|model-small' \
  docs ops edge_controller.py 2>/dev/null | head -220 || true

echo
echo "=== read-only guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)|/api/(generate|chat)|systemctl[[:space:]]+cat[[:space:]]+edge-queue-controller' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
if [ -n "$danger" ]; then
  echo "$danger"
  echo "FAIL: smoke script contains mutation, model execution, or unsafe raw unit dump pattern"
  exit 1
fi
echo "PASS: read-only guard passed"

echo
echo "=== done: Phase 14I-B inspection smoke complete ==="
