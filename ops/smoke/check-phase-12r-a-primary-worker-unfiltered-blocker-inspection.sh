#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12R-A smoke: primary worker unfiltered blocker inspection ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

DOC="docs/phase-12r-a-primary-worker-unfiltered-blocker-inspection.md"

echo
echo "=== repo state ==="
git status --short
git log --oneline -8
git tag --points-at HEAD || true

echo
echo "=== doc checks ==="
grep -Fq "Phase 12R-A Primary Worker Unfiltered Blocker Inspection" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "primary_worker_unfiltered" "$DOC" && echo "PASS: primary_worker_unfiltered documented" || fail=1
grep -Fq 'capabilities not advertising a `queue_lane`' "$DOC" && echo "PASS: queue_lane cause documented" || fail=1
grep -Fq "Phase 12R-A is documentation and smoke only" "$DOC" && echo "PASS: inspection-only marker documented" || fail=1
grep -Fq 'no_no_lane_fallback_worker` is not a reason' "$DOC" && echo "PASS: Phase 12Q-B behavior preserved marker documented" || fail=1
grep -Fq "does not need to expose a matching evidence.primary_worker_unfiltered field" "$DOC" && echo "PASS: live exposure clarification documented" || fail=1

echo
echo "=== source marker checks ==="
python3 - <<'PY' || fail=1
from pathlib import Path

text = Path("edge_controller.py").read_text()
checks = {
    'primary queue_lane source exists': 'primary_queue_lane = capabilities.get("queue_lane")',
    'primary_worker_unfiltered bool source exists': '"primary_worker_unfiltered": not bool(primary_queue_lane)',
    'primary_worker_unfiltered reason source exists': 'add_reason("primary_worker_unfiltered")',
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
curl -sS --max-time 8 -o /tmp/phase12ra-health.json \
  -w "health_code=%{http_code} time=%{time_total}\n" \
  http://127.0.0.1:7070/health | tee /tmp/phase12ra-health-code.txt || fail=1

python3 -m json.tool /tmp/phase12ra-health.json >/tmp/phase12ra-health.pretty \
  && grep -Fq '"ok": true' /tmp/phase12ra-health.pretty \
  && echo "PASS: controller health ok" || fail=1

echo
echo "=== live /system/status gate check ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status \
  | python3 -m json.tool >/tmp/phase12ra-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12ra-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
blockers = gate.get("blockers") or {}
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
    "primary_worker_unfiltered_reason_present": "primary_worker_unfiltered" in reasons,
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

assert blockers.get("active_unsupported_jobs") == [], blockers
assert blockers.get("recent_no_lane_jobs_after_lane_contract") == [], blockers

assert "no_no_lane_fallback_worker" not in reasons, gate
assert evidence.get("no_lane_fallback_worker_required") is False, evidence
assert evidence.get("no_lane_fallback_requirement_source") == "not_required_without_current_no_lane_risk", evidence
assert "no_no_lane_fallback_worker_absent_but_no_current_no_lane_risk" in warnings, warnings

print("PASS: primary_worker_unfiltered is verified as a live readiness reason")
print("PASS: primary worker queue_lane is absent/null as expected")
print("PASS: Phase 12Q-B warning-only no-lane fallback behavior preserved")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12ra-primary-active.txt \
  && grep -Fq "active" /tmp/phase12ra-primary-active.txt \
  && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12ra-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12ra-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12ra-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12ra-small-active.txt
  fail=1
else
  echo "PASS: small lane service inactive"
fi

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
  | grep -vF '?? docs/phase-12r-a-primary-worker-unfiltered-blocker-inspection.md' \
  | grep -vF '?? ops/smoke/check-phase-12r-a-primary-worker-unfiltered-blocker-inspection.sh' || true)"

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12R-A doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12R-A primary worker unfiltered blocker inspection smoke passed"
else
  echo "FAIL: Phase 12R-A primary worker unfiltered blocker inspection smoke failed"
fi

[ "$fail" = "0" ]
