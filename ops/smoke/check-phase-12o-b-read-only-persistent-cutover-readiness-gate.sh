#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12O-B smoke: read-only persistent cutover readiness gate ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12o-b-read-only-persistent-cutover-readiness-gate.md"
grep -Fq "Phase 12O-B Read-Only Persistent Cutover Readiness Gate" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "persistent_lane_cutover_readiness" "$DOC" && echo "PASS: status field documented" || fail=1
grep -Fq "stage_5p12o_read_only_persistent_lane_cutover_gate" "$DOC" && echo "PASS: source documented" || fail=1
grep -Fq "ready=false" "$DOC" && echo "PASS: expected not-ready state documented" || fail=1
grep -Fq "router rollout should remain parked" "$DOC" && echo "PASS: safety marker documented" || fail=1

echo
echo "=== source checks ==="
grep -Fq "STAGE_5P12O_PERSISTENT_LANE_CUTOVER_READINESS_GATE_BEGIN" edge_controller.py && echo "PASS: Phase 12O-B helper marker exists" || fail=1
grep -Fq "def _stage5p12o_persistent_lane_cutover_readiness" edge_controller.py && echo "PASS: Phase 12O-B helper exists" || fail=1
grep -Fq '"persistent_lane_cutover_readiness": _stage5p12o_persistent_lane_cutover_readiness(registered_capacity)' edge_controller.py && echo "PASS: CT101 status attaches persistent cutover gate" || fail=1
grep -Fq "No service changes are performed by this helper." edge_controller.py && echo "PASS: helper read-only note exists" || fail=1

echo
echo "=== python syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12ob-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12ob-smoke-health.json >/tmp/phase12ob-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12ob-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== live persistent cutover gate check ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12ob-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12ob-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

registered = worker.get("registered_capacity") or {}
caps = registered.get("capabilities") or {}
lane_plan = worker.get("lane_dispatch_readiness") or {}
gate = worker.get("persistent_lane_cutover_readiness") or {}

summary = {
    "worker_state": worker.get("state"),
    "worker_id": registered.get("worker_id"),
    "worker_node_id": registered.get("worker_node_id"),
    "primary_queue_lane": caps.get("queue_lane"),
    "lane_dispatch_dry_run_only": lane_plan.get("dry_run_only"),
    "gate": gate,
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert registered.get("worker_id") == "ct101-stage5g21-managed-browser", summary
assert registered.get("worker_node_id") == "ct101-stage5g21-managed-browser-node", summary
assert caps.get("queue_lane") is None, summary

assert gate.get("source") == "stage_5p12o_read_only_persistent_lane_cutover_gate", gate
assert gate.get("dry_run_only") is True, gate
assert gate.get("ready") is False, gate

reasons = set(gate.get("reasons") or [])
expected = {
    "primary_worker_unfiltered",
    "historical_no_lane_jobs_detected",
    "no_no_lane_fallback_worker",
    "persistent_lane_workers_not_active",
}
missing = expected - reasons
assert not missing, {"missing_reasons": sorted(missing), "reasons": sorted(reasons), "gate": gate}

blockers = gate.get("blockers") or {}
assert blockers.get("primary_worker_unfiltered") is True, blockers
assert blockers.get("fallback_worker_present") is False, blockers
assert blockers.get("historical_no_lane_jobs"), blockers

print("PASS: live persistent cutover gate is present and safely not ready")
PY

echo
echo "=== no active queued/running jobs check ==="
python3 - <<'PY' || fail=1
import json
import subprocess

sql = r"""
SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
FROM (
  SELECT
    id,
    status,
    COALESCE(payload_json->>'queue_lane', '(none)') AS queue_lane,
    COALESCE(requested_model, '(none)') AS requested_model,
    assigned_worker_id
  FROM app_jobs
  WHERE job_type = 'ollama_chat'
    AND status IN ('queued', 'pending', 'running', 'claimed', 'processing', 'in_progress')
  ORDER BY created_at ASC NULLS LAST, id ASC
) t;
"""

cmd = [
    "bash",
    "-lc",
    "python3 - <<'INNER'\n"
    "from edge_modules.chat_queue_persistence import _psql_at\n"
    f"print(_psql_at({sql!r}))\n"
    "INNER"
]

raw = subprocess.check_output(cmd, text=True)
rows = json.loads(raw)
print(json.dumps(rows, indent=2, sort_keys=True))
assert rows == [], rows
print("PASS: no active queued/running ollama_chat jobs")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12ob-primary-active.txt && grep -Fq "active" /tmp/phase12ob-primary-active.txt && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12ob-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12ob-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12ob-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12ob-small-active.txt
  fail=1
else
  echo "PASS: small lane service inactive"
fi

echo
echo "=== lane service enablement remains disabled ==="
ssh "$CT101" 'pct exec 101 -- bash -lc "
systemctl is-enabled ai-platform-laptop-queue-worker.service 2>/dev/null || true
systemctl is-enabled ai-platform-laptop-queue-worker@model-tiny.service 2>/dev/null || true
systemctl is-enabled ai-platform-laptop-queue-worker@model-small.service 2>/dev/null || true
"' >/tmp/phase12ob-enabled-state.txt || fail=1
cat /tmp/phase12ob-enabled-state.txt

grep -Fq "enabled" /tmp/phase12ob-enabled-state.txt && echo "PASS: primary enabled state present" || fail=1
grep -Fq "disabled" /tmp/phase12ob-enabled-state.txt && echo "PASS: lane disabled state present" || fail=1

echo
echo "=== router rollout parked guard ==="
if systemctl show edge-queue-controller -p Environment --value | tr " " "\n" | grep -E "ROUTER.*DRY_RUN|PERSISTENT.*ROLLOUT.*ENABLED=1"; then
  echo "FAIL: unexpected router rollout env found"
  fail=1
else
  echo "PASS: no active router rollout env found"
fi

echo
echo "=== changed files guard ==="
bad_status="$(git status --short \
  | grep -vF ' M edge_controller.py' \
  | grep -vF '?? docs/phase-12o-b-read-only-persistent-cutover-readiness-gate.md' \
  | grep -vF '?? ops/smoke/check-phase-12o-b-read-only-persistent-cutover-readiness-gate.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12O-B code/doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12O-B read-only persistent cutover readiness gate smoke passed"
else
  echo "FAIL: Phase 12O-B read-only persistent cutover readiness gate smoke failed"
fi

[ "$fail" = "0" ]
