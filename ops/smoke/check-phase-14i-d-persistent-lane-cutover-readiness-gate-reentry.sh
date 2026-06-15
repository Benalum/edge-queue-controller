#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-d-persistent-lane-cutover-readiness-gate-reentry"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-D persistent lane cutover readiness gate re-entry inspection ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
echo "PASS: required docs/smoke files exist"

echo
echo "=== checkpoint ==="
git status --short
git log --oneline --decorate -6
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
echo "=== route/code markers ==="
grep -nF "_stage5p12o_persistent_lane_cutover_readiness" edge_controller.py
grep -nF "persistent_lane_cutover_readiness" edge_controller.py docs/phase-12o-b-read-only-persistent-cutover-readiness-gate.md docs/phase-12q-b-conditional-no-lane-fallback-blocker-refinement.md docs/phase-12r-a-primary-worker-unfiltered-blocker-inspection.md 2>/dev/null || true

echo
echo "=== documentation markers ==="
grep -Fq "All tested controller paths returned 404" "$DOC"
grep -Fq "persistent_lane_cutover_readiness_route_exposure_unclear" "$DOC"
grep -Fq "Do not enable workers yet" "$DOC"
grep -Fq "Worker registry total: 0" "$DOC"
grep -Fq "Queued job observed: job_id 23" "$DOC"
grep -Fq "_stage5p12o_persistent_lane_cutover_readiness" "$DOC"
echo "PASS: required documentation markers found"

echo
echo "=== read-only guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)|/api/(generate|chat)|/api/chat|/admin/model-warmup' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
if [ -n "$danger" ]; then
  echo "$danger"
  echo "FAIL: smoke script contains mutation or model execution pattern"
  exit 1
fi
echo "PASS: read-only guard passed"

echo
echo "=== done: Phase 14I-D readiness gate re-entry smoke complete ==="
