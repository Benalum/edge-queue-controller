#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-B smoke: primary worker lane filter strategy inspection ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-b-primary-worker-lane-filter-strategy-inspection.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-B Primary Worker Lane Filter Strategy Inspection" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "Strategy A: Keep primary unfiltered temporarily" "$DOC" && echo "PASS: strategy A documented" || fail=1
grep -Fq "Strategy B: Convert primary worker to a specific lane" "$DOC" && echo "PASS: strategy B documented" || fail=1
grep -Fq "Strategy C: Use dedicated persistent lane workers plus no-lane fallback" "$DOC" && echo "PASS: strategy C documented" || fail=1
grep -Fq "Strategy D: Adjust readiness gate only after runtime proof" "$DOC" && echo "PASS: strategy D documented" || fail=1
grep -Fq "Phase 12R-B is documentation and smoke only" "$DOC" && echo "PASS: inspection-only marker documented" || fail=1
grep -Fq "The safest next implementation path is not to convert the primary worker immediately" "$DOC" && echo "PASS: recommendation documented" || fail=1

echo
echo "=== source marker checks ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
checks = {
    "primary queue lane source exists": 'primary_queue_lane = capabilities.get("queue_lane")',
    "primary_worker_unfiltered reason exists": 'add_reason("primary_worker_unfiltered")',
    "persistent lane worker inactive blocker exists": 'add_reason("persistent_lane_workers_not_active")',
    "lane dispatch readiness exists": "_stage5p12f_lane_dispatch_readiness",
    "persistent cutover readiness exists": "_stage5p12o_persistent_lane_cutover_readiness",
}
for label, needle in checks.items():
    if needle in text:
        print(f"PASS: {label}")
    else:
        print(f"FAIL: {label}")
        raise SystemExit(1)
PY

echo
echo "=== python syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12rb-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12rb-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12rb-health.json >/tmp/phase12rb-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12rb-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live persistent cutover gate remains blocked safely ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12rb-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12rb-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
evidence = gate.get("evidence") or {}
warnings = gate.get("warnings") or []

summary = {
    "worker_state": worker.get("state"),
    "gate_source": gate.get("source"),
    "ready": gate.get("ready"),
    "dry_run_only": gate.get("dry_run_only"),
    "reasons": sorted(reasons),
    "warnings": warnings,
    "primary_worker_queue_lane": evidence.get("primary_worker_queue_lane"),
    "no_lane_fallback_worker_required": evidence.get("no_lane_fallback_worker_required"),
    "no_lane_fallback_requirement_source": evidence.get("no_lane_fallback_requirement_source"),
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("source") == "stage_5p12o_read_only_persistent_lane_cutover_gate", gate
assert gate.get("ready") is False, gate
assert gate.get("dry_run_only") is True, gate
assert "primary_worker_unfiltered" in reasons, gate
assert "persistent_lane_workers_not_active" in reasons, gate
assert evidence.get("primary_worker_queue_lane") in (None, ""), evidence
assert "no_no_lane_fallback_worker" not in reasons, gate
assert evidence.get("no_lane_fallback_worker_required") is False, evidence
assert evidence.get("no_lane_fallback_requirement_source") == "not_required_without_current_no_lane_risk", evidence
assert "no_no_lane_fallback_worker_absent_but_no_current_no_lane_risk" in warnings, warnings

print("PASS: live gate remains safely blocked for strategy inspection")
PY

echo
echo "=== CT101 primary/lane service safety state ==="
ssh "$CT101" 'pct exec 101 -- bash -lc '"'"'
set -u
fail=0

systemctl is-active ai-platform-laptop-queue-worker.service >/tmp/phase12rb-primary-active.txt 2>/dev/null
if grep -Fq "active" /tmp/phase12rb-primary-active.txt; then
  echo "PASS: primary worker active"
else
  echo "FAIL: primary worker not active"
  cat /tmp/phase12rb-primary-active.txt || true
  fail=1
fi

for u in \
  ai-platform-laptop-queue-worker@model-tiny.service \
  ai-platform-laptop-queue-worker@model-small.service
do
  if systemctl is-active --quiet "$u" 2>/dev/null; then
    echo "FAIL: lane worker active unexpectedly: $u"
    fail=1
  else
    echo "PASS: lane worker inactive: $u"
  fi
done

for f in \
  /etc/ai-platform/laptop-queue-worker.env \
  /etc/ai-platform/laptop-queue-worker-model-tiny.env \
  /etc/ai-platform/laptop-queue-worker-model-small.env
do
  if [ -f "$f" ]; then
    echo "PASS: env file exists: $f"
  else
    echo "FAIL: env file missing: $f"
    fail=1
  fi
done

if grep -Fq "LAPTOP_QUEUE_QUEUE_LANE=model-tiny" /etc/ai-platform/laptop-queue-worker-model-tiny.env 2>/dev/null; then
  echo "PASS: model-tiny env has queue lane"
else
  echo "FAIL: model-tiny env missing queue lane"
  fail=1
fi

if grep -Fq "LAPTOP_QUEUE_QUEUE_LANE=model-small" /etc/ai-platform/laptop-queue-worker-model-small.env 2>/dev/null; then
  echo "PASS: model-small env has queue lane"
else
  echo "FAIL: model-small env missing queue lane"
  fail=1
fi

if grep -Fq "LAPTOP_QUEUE_QUEUE_LANE=" /etc/ai-platform/laptop-queue-worker.env 2>/dev/null; then
  echo "CHECK: primary env has an explicit queue lane setting"
  grep -nF "LAPTOP_QUEUE_QUEUE_LANE=" /etc/ai-platform/laptop-queue-worker.env || true
else
  echo "PASS: primary env has no explicit queue lane setting"
fi

if [ "$fail" = "0" ]; then
  true
else
  false
fi
'"'"'' || fail=1

echo
echo "=== router rollout parked guard ==="
if systemctl show edge-queue-controller -p Environment --value \
  | tr " " "\n" \
  | grep -E "ROUTER.*DRY_RUN|PERSISTENT.*ROLLOUT.*ENABLED=1"; then
  echo "FAIL: unexpected router rollout env found"
  fail=1
else
  echo "PASS: no active router rollout env found"
fi

echo
echo "=== changed files guard ==="
git status --short

bad_status="$(git status --short \
  | grep -vF '?? docs/phase-12r-b-primary-worker-lane-filter-strategy-inspection.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-b-primary-worker-lane-filter-strategy-inspection.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-B doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-B primary worker lane filter strategy inspection smoke passed"
else
  echo "FAIL: Phase 12R-B primary worker lane filter strategy inspection smoke failed"
fi

[ "$fail" = "0" ]
