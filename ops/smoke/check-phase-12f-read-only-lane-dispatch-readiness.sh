#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12F smoke: read-only lane dispatch readiness ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== source checks ==="
git status --short
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py py_compile ok" || fail=1
grep -nF "STAGE_5P12F_LANE_DISPATCH_READINESS_PLAN_BEGIN" edge_controller.py && echo "PASS: Phase 12F begin marker found" || fail=1
grep -nF "STAGE_5P12F_LANE_DISPATCH_READINESS_PLAN_END" edge_controller.py && echo "PASS: Phase 12F end marker found" || fail=1
grep -nF '"lane_dispatch_readiness": _stage5p12f_lane_dispatch_readiness(registered_capacity)' edge_controller.py && echo "PASS: lane_dispatch_readiness field found" || fail=1
grep -nF '"dry_run_only": True' edge_controller.py && echo "PASS: dry-run-only marker found" || fail=1
grep -nF '"dispatch_enabled": False' edge_controller.py && echo "PASS: dispatch disabled marker found" || fail=1

echo
echo "=== doc checks ==="
grep -Fq "Phase 12F Read-Only Lane Dispatch Readiness" docs/phase-12f-read-only-lane-dispatch-readiness.md && echo "PASS: doc title found" || fail=1
grep -Fq "dry_run_only" docs/phase-12f-read-only-lane-dispatch-readiness.md && echo "PASS: doc dry-run marker found" || fail=1
grep -Fq "dispatch_enabled" docs/phase-12f-read-only-lane-dispatch-readiness.md && echo "PASS: doc dispatch marker found" || fail=1
grep -Fq "claim_filter_enabled" docs/phase-12f-read-only-lane-dispatch-readiness.md && echo "PASS: doc claim marker found" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12f-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12f-smoke-health.json >/tmp/phase12f-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12f-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== live /system/status readiness proof ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12f-smoke-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12f-smoke-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker service missing"

registered = worker.get("registered_capacity") or {}
caps = registered.get("capabilities") or {}
plan = worker.get("lane_dispatch_readiness")

assert isinstance(plan, dict), worker

summary = {
    "worker_state": worker.get("state"),
    "registered_capabilities": caps,
    "lane_dispatch_readiness": plan,
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert plan.get("source") == "stage_5p12f_read_only_status_planner", plan
assert plan.get("dry_run_only") is True, plan
assert plan.get("runtime_enabled") is False, plan
assert plan.get("dispatch_enabled") is False, plan
assert plan.get("claim_filter_enabled") is False, plan
assert plan.get("active_queue_lane") is None, plan
assert plan.get("supported_lanes") == ["model-tiny", "model-small"], plan
assert plan.get("supported_model_tiers") == ["tiny", "small"], plan
assert plan.get("allowed_models") == ["qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"], plan
assert plan.get("lane_capacity") == {"model-tiny": {"max": 1}, "model-small": {"max": 1}}, plan
assert plan.get("max_jobs_per_run") == 1, plan
assert plan.get("node_max_concurrent_jobs") == 1, plan
assert plan.get("ollama_num_parallel") is None, plan

lanes = plan.get("lanes") or []
by_lane = {row.get("queue_lane"): row for row in lanes}
assert "model-tiny" in by_lane, lanes
assert "model-small" in by_lane, lanes
assert by_lane["model-tiny"].get("capacity_max") == 1, lanes
assert by_lane["model-small"].get("capacity_max") == 1, lanes
assert by_lane["model-tiny"].get("claim_active") is False, lanes
assert by_lane["model-small"].get("claim_active") is False, lanes

warnings = plan.get("warnings") or []
assert any("queue_lane is unset" in item for item in warnings), warnings

print("PASS: /system/status exposes read-only lane dispatch readiness safely")
PY

echo
echo "=== CT101 safety checks ==="
ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_MAX_JOBS_PER_RUN|LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS|LAPTOP_QUEUE_SUPPORTED_LANES|LAPTOP_QUEUE_SUPPORTED_MODEL_TIERS|LAPTOP_QUEUE_ALLOWED_MODELS)=" /etc/ai-platform/laptop-queue-worker.env' >/tmp/phase12f-env.txt && echo "PASS: CT101 metadata env captured" || fail=1
cat /tmp/phase12f-env.txt

grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" /tmp/phase12f-env.txt && echo "PASS: max jobs remains 1" || fail=1
grep -Fq "LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS=1" /tmp/phase12f-env.txt && echo "PASS: node max concurrency remains 1" || fail=1

if ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_QUEUE_LANE|OLLAMA_NUM_PARALLEL)=" /etc/ai-platform/laptop-queue-worker.env' >/tmp/phase12f-forbidden-env.txt 2>/dev/null; then
  echo "FAIL: forbidden queue lane or Ollama parallel env is active"
  cat /tmp/phase12f-forbidden-env.txt
  fail=1
else
  echo "PASS: queue lane and Ollama parallel remain unset"
fi

ssh "$CT101" 'pct exec 101 -- grep -nF "LAPTOP_QUEUE_MAX_JOBS_PER_RUN must be 1" /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh' && echo "PASS: max jobs preflight guard remains" || fail=1
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12f-worker-active.txt && grep -Fq "active" /tmp/phase12f-worker-active.txt && echo "PASS: CT101 worker service active" || fail=1

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
bad_status="$(git status --short | grep -vF ' M edge_controller.py' | grep -vF '?? docs/phase-12f-read-only-lane-dispatch-readiness.md' | grep -vF '?? ops/smoke/check-phase-12f-read-only-lane-dispatch-readiness.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12F source/doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12F read-only lane dispatch readiness smoke passed"
else
  echo "FAIL: Phase 12F read-only lane dispatch readiness smoke failed"
fi

[ "$fail" = "0" ]
