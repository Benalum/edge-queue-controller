#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12D smoke: registered worker capacity status ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== source checks ==="
git status --short
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py py_compile ok" || fail=1
grep -nF "STAGE_5P12D_REGISTERED_WORKER_CAPACITY_STATUS_BEGIN" edge_controller.py && echo "PASS: Phase 12D begin marker found" || fail=1
grep -nF "STAGE_5P12D_REGISTERED_WORKER_CAPACITY_STATUS_END" edge_controller.py && echo "PASS: Phase 12D end marker found" || fail=1
grep -nF '"registered_capacity": registered_capacity' edge_controller.py && echo "PASS: registered_capacity field found" || fail=1

echo
echo "=== doc checks ==="
grep -Fq "Phase 12D Registered Worker Capacity Status" docs/phase-12d-registered-worker-capacity-status.md && echo "PASS: doc title found" || fail=1
grep -Fq "registered_capacity" docs/phase-12d-registered-worker-capacity-status.md && echo "PASS: doc registered_capacity marker found" || fail=1
grep -Fq "node_max_concurrent_jobs" docs/phase-12d-registered-worker-capacity-status.md && echo "PASS: doc node capacity marker found" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12d-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12d-smoke-health.json >/tmp/phase12d-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12d-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== live /system/status registered_capacity proof ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12d-smoke-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12d-smoke-system-status.json"))
services = data.get("services") or []
worker = next((s for s in services if s.get("id") == "ct101-laptop-queue-worker"), None)

assert worker, "ct101-laptop-queue-worker service missing"
registered = worker.get("registered_capacity")
assert isinstance(registered, dict), worker

caps = registered.get("capabilities") or {}

summary = {
    "state": worker.get("state"),
    "worker_id": registered.get("worker_id"),
    "worker_node_id": registered.get("worker_node_id"),
    "capabilities": caps,
}

print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert registered.get("worker_id") == "ct101-stage5g21-managed-browser", summary
assert registered.get("worker_node_id") == "ct101-stage5g21-managed-browser-node", summary
assert caps.get("job_types") == ["ollama_chat"], caps
assert caps.get("max_jobs_per_run") == 1, caps
assert caps.get("node_max_concurrent_jobs") == 1, caps
assert caps.get("allowed_models") == ["gemma4:e4b"], caps
assert caps.get("lane_capacity") == {}, caps
assert caps.get("runtime_backend") == "ollama", caps
assert "error" not in registered, registered

print("PASS: /system/status exposes registered_capacity safely")
PY

echo
echo "=== CT101 safety guards ==="
if ssh "$CT101" 'pct exec 101 -- grep -RInE "^LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS=|^LAPTOP_QUEUE_SUPPORTED_LANES=|^LAPTOP_QUEUE_SUPPORTED_MODEL_TIERS=|^LAPTOP_QUEUE_ALLOWED_MODELS=|^LAPTOP_QUEUE_QUEUE_LANE=" /opt/ai-platform/.env /opt/ai-platform/.secrets/laptop-queue.env /etc/ai-platform/laptop-queue-worker.env' >/tmp/phase12d-future-env.txt 2>/dev/null; then
  echo "FAIL: future capacity or queue lane env is set"
  cat /tmp/phase12d-future-env.txt
  fail=1
else
  echo "PASS: future capacity and queue lane env remain unset"
fi

ssh "$CT101" 'pct exec 101 -- grep -nF "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" /etc/ai-platform/laptop-queue-worker.env' && echo "PASS: max jobs env remains 1" || fail=1
ssh "$CT101" 'pct exec 101 -- grep -nF "LAPTOP_QUEUE_MAX_JOBS_PER_RUN must be 1" /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh' && echo "PASS: max jobs preflight guard remains" || fail=1
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12d-worker-active.txt && grep -Fq "active" /tmp/phase12d-worker-active.txt && echo "PASS: CT101 worker service active" || fail=1

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
bad_status="$(git status --short | grep -vE '^ M edge_controller\.py$' | grep -vE '^\?\? docs/phase-12d-registered-worker-capacity-status\.md$' | grep -vE '^\?\? ops/smoke/check-phase-12d-registered-worker-capacity-status\.sh$' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12D source/doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12D registered worker capacity status smoke passed"
else
  echo "FAIL: Phase 12D registered worker capacity status smoke failed"
fi

[ "$fail" = "0" ]
