#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12E smoke: CT101 metadata-only lane/model advertisement ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
grep -Fq "Phase 12E CT101 Metadata-Only Lane/Model Advertisement" docs/phase-12e-ct101-metadata-only-lane-model-advertisement.md && echo "PASS: doc title found" || fail=1
grep -Fq "supported_lanes" docs/phase-12e-ct101-metadata-only-lane-model-advertisement.md && echo "PASS: supported_lanes doc marker found" || fail=1
grep -Fq "qwen3:0.6b" docs/phase-12e-ct101-metadata-only-lane-model-advertisement.md && echo "PASS: allowed model doc marker found" || fail=1
grep -Fq "metadata-only" docs/phase-12e-ct101-metadata-only-lane-model-advertisement.md && echo "PASS: metadata-only safety doc marker found" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12e-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12e-smoke-health.json >/tmp/phase12e-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12e-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== live registered_capacity metadata proof ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12e-smoke-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12e-smoke-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
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
assert caps.get("max_jobs_per_run") == 1, caps
assert caps.get("node_max_concurrent_jobs") == 1, caps
assert caps.get("supported_lanes") == ["model-tiny", "model-small"], caps
assert caps.get("supported_model_tiers") == ["tiny", "small"], caps
assert caps.get("allowed_models") == ["qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"], caps
assert caps.get("lane_capacity") == {"model-tiny": {"max": 1}, "model-small": {"max": 1}}, caps
assert caps.get("queue_lane") is None, caps
assert caps.get("ollama_num_parallel") is None, caps
assert caps.get("runtime_backend") == "ollama", caps
assert "error" not in registered, registered

print("PASS: /system/status advertises metadata-only lane/model capacity safely")
PY

echo
echo "=== CT101 env safety checks ==="
ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_MAX_JOBS_PER_RUN|LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS|LAPTOP_QUEUE_SUPPORTED_LANES|LAPTOP_QUEUE_SUPPORTED_MODEL_TIERS|LAPTOP_QUEUE_ALLOWED_MODELS)=" /etc/ai-platform/laptop-queue-worker.env' >/tmp/phase12e-env.txt && echo "PASS: CT101 metadata env captured" || fail=1
cat /tmp/phase12e-env.txt

grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" /tmp/phase12e-env.txt && echo "PASS: max jobs remains 1" || fail=1
grep -Fq "LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS=1" /tmp/phase12e-env.txt && echo "PASS: node max concurrency remains 1" || fail=1
grep -Fq "LAPTOP_QUEUE_SUPPORTED_LANES=model-tiny,model-small" /tmp/phase12e-env.txt && echo "PASS: supported lanes env found" || fail=1
grep -Fq "LAPTOP_QUEUE_SUPPORTED_MODEL_TIERS=tiny,small" /tmp/phase12e-env.txt && echo "PASS: supported tiers env found" || fail=1
grep -Fq "LAPTOP_QUEUE_ALLOWED_MODELS=qwen3:0.6b,qwen3:1.7b,llama3.2:3b" /tmp/phase12e-env.txt && echo "PASS: allowed models env found" || fail=1

if ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_QUEUE_LANE|OLLAMA_NUM_PARALLEL)=" /etc/ai-platform/laptop-queue-worker.env' >/tmp/phase12e-forbidden-env.txt 2>/dev/null; then
  echo "FAIL: forbidden queue lane or Ollama parallel env is active"
  cat /tmp/phase12e-forbidden-env.txt
  fail=1
else
  echo "PASS: queue lane and Ollama parallel remain unset"
fi

ssh "$CT101" 'pct exec 101 -- grep -nF "LAPTOP_QUEUE_MAX_JOBS_PER_RUN must be 1" /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh' && echo "PASS: max jobs preflight guard remains" || fail=1
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12e-worker-active.txt && grep -Fq "active" /tmp/phase12e-worker-active.txt && echo "PASS: CT101 worker service active" || fail=1

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
bad_status="$(git status --short | grep -vE '^\?\? docs/phase-12e-ct101-metadata-only-lane-model-advertisement\.md$' | grep -vE '^\?\? ops/smoke/check-phase-12e-ct101-metadata-only-lane-model-advertisement\.sh$' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12E doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12E metadata-only lane/model advertisement smoke passed"
else
  echo "FAIL: Phase 12E metadata-only lane/model advertisement smoke failed"
fi

[ "$fail" = "0" ]
