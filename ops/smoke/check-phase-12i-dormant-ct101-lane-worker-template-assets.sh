#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12I smoke: dormant CT101 lane-worker template assets ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12i-dormant-ct101-lane-worker-template-assets.md"
grep -Fq "Phase 12I Dormant CT101 Lane Worker Template Assets" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "ai-platform-laptop-queue-worker@.service" "$DOC" && echo "PASS: template doc marker found" || fail=1
grep -Fq "model-tiny" "$DOC" && echo "PASS: tiny lane doc marker found" || fail=1
grep -Fq "model-small" "$DOC" && echo "PASS: small lane doc marker found" || fail=1
grep -Fq "dormant assets only" "$DOC" && echo "PASS: dormant safety doc marker found" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12i-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12i-smoke-health.json >/tmp/phase12i-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12i-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== live controller still sees primary unfiltered worker ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12i-smoke-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12i-smoke-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

registered = worker.get("registered_capacity") or {}
caps = registered.get("capabilities") or {}
plan = worker.get("lane_dispatch_readiness") or {}

summary = {
    "worker_state": worker.get("state"),
    "worker_id": registered.get("worker_id"),
    "worker_node_id": registered.get("worker_node_id"),
    "registered_capabilities": caps,
    "lane_dispatch_readiness": {
        "dry_run_only": plan.get("dry_run_only"),
        "dispatch_enabled": plan.get("dispatch_enabled"),
        "claim_filter_enabled": plan.get("claim_filter_enabled"),
        "active_queue_lane": plan.get("active_queue_lane"),
        "lanes": plan.get("lanes"),
    },
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert registered.get("worker_id") == "ct101-stage5g21-managed-browser", summary
assert registered.get("worker_node_id") == "ct101-stage5g21-managed-browser-node", summary
assert caps.get("queue_lane") is None, caps
assert caps.get("ollama_num_parallel") is None, caps
assert caps.get("max_jobs_per_run") == 1, caps
assert caps.get("node_max_concurrent_jobs") == 1, caps
assert plan.get("dry_run_only") is True, plan
assert plan.get("dispatch_enabled") is False, plan
assert plan.get("claim_filter_enabled") is False, plan
assert plan.get("active_queue_lane") is None, plan

print("PASS: controller still sees only primary unfiltered worker")
PY

echo
echo "=== CT101 dormant template asset checks ==="
ssh "$CT101" 'pct exec 101 -- test -f /etc/systemd/system/ai-platform-laptop-queue-worker@.service' && echo "PASS: template present" || fail=1
ssh "$CT101" 'pct exec 101 -- systemctl cat ai-platform-laptop-queue-worker@model-tiny.service --no-pager >/tmp/phase12i-template-tiny.txt' && echo "PASS: tiny template renders" || fail=1
ssh "$CT101" 'pct exec 101 -- systemctl cat ai-platform-laptop-queue-worker@model-small.service --no-pager >/tmp/phase12i-template-small.txt' && echo "PASS: small template renders" || fail=1

ssh "$CT101" 'pct exec 101 -- test -x /opt/ai-platform/ops/runtime/laptop-queue-worker-instance-loop.sh' && echo "PASS: instance loop executable" || fail=1
ssh "$CT101" 'pct exec 101 -- bash -n /opt/ai-platform/ops/runtime/laptop-queue-worker-instance-loop.sh' && echo "PASS: instance loop syntax ok" || fail=1

echo
echo "=== CT101 dormant env checks ==="
ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_WORKER_ID|LAPTOP_QUEUE_WORKER_NODE_ID|LAPTOP_QUEUE_QUEUE_LANE|LAPTOP_QUEUE_ALLOWED_MODELS|LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK|LAPTOP_QUEUE_MAX_JOBS_PER_RUN|LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS)=" /etc/ai-platform/laptop-queue-worker-model-tiny.env' >/tmp/phase12i-tiny-env.txt && echo "PASS: tiny env captured" || fail=1
cat /tmp/phase12i-tiny-env.txt

grep -Fq "LAPTOP_QUEUE_WORKER_ID=ct101-stage5g21-managed-browser-model-tiny" /tmp/phase12i-tiny-env.txt && echo "PASS: tiny worker id found" || fail=1
grep -Fq "LAPTOP_QUEUE_QUEUE_LANE=model-tiny" /tmp/phase12i-tiny-env.txt && echo "PASS: tiny queue lane found" || fail=1
grep -Fq "LAPTOP_QUEUE_ALLOWED_MODELS=qwen3:0.6b" /tmp/phase12i-tiny-env.txt && echo "PASS: tiny allowed model found" || fail=1
grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" /tmp/phase12i-tiny-env.txt && echo "PASS: tiny max jobs remains 1" || fail=1
grep -Fq "LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS=1" /tmp/phase12i-tiny-env.txt && echo "PASS: tiny node max concurrency remains 1" || fail=1

ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_WORKER_ID|LAPTOP_QUEUE_WORKER_NODE_ID|LAPTOP_QUEUE_QUEUE_LANE|LAPTOP_QUEUE_ALLOWED_MODELS|LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK|LAPTOP_QUEUE_MAX_JOBS_PER_RUN|LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS)=" /etc/ai-platform/laptop-queue-worker-model-small.env' >/tmp/phase12i-small-env.txt && echo "PASS: small env captured" || fail=1
cat /tmp/phase12i-small-env.txt

grep -Fq "LAPTOP_QUEUE_WORKER_ID=ct101-stage5g21-managed-browser-model-small" /tmp/phase12i-small-env.txt && echo "PASS: small worker id found" || fail=1
grep -Fq "LAPTOP_QUEUE_QUEUE_LANE=model-small" /tmp/phase12i-small-env.txt && echo "PASS: small queue lane found" || fail=1
grep -Fq "LAPTOP_QUEUE_ALLOWED_MODELS=qwen3:1.7b,llama3.2:3b" /tmp/phase12i-small-env.txt && echo "PASS: small allowed models found" || fail=1
grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" /tmp/phase12i-small-env.txt && echo "PASS: small max jobs remains 1" || fail=1
grep -Fq "LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS=1" /tmp/phase12i-small-env.txt && echo "PASS: small node max concurrency remains 1" || fail=1

echo
echo "=== lane services remain inactive ==="
if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12i-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12i-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12i-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12i-small-active.txt
  fail=1
else
  echo "PASS: small lane service inactive"
fi

echo
echo "=== primary worker remains active and unfiltered ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12i-primary-active.txt && grep -Fq "active" /tmp/phase12i-primary-active.txt && echo "PASS: primary worker active" || fail=1
ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_WORKER_ID|LAPTOP_QUEUE_WORKER_NODE_ID|LAPTOP_QUEUE_MAX_JOBS_PER_RUN|LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS|LAPTOP_QUEUE_SUPPORTED_LANES|LAPTOP_QUEUE_SUPPORTED_MODEL_TIERS|LAPTOP_QUEUE_ALLOWED_MODELS|LAPTOP_QUEUE_QUEUE_LANE|OLLAMA_NUM_PARALLEL)=" /etc/ai-platform/laptop-queue-worker.env 2>/dev/null || true' >/tmp/phase12i-primary-env.txt && echo "PASS: primary env captured" || fail=1
cat /tmp/phase12i-primary-env.txt

grep -Fq "LAPTOP_QUEUE_WORKER_ID=ct101-stage5g21-managed-browser" /tmp/phase12i-primary-env.txt && echo "PASS: primary worker id unchanged" || fail=1
grep -Fq "LAPTOP_QUEUE_WORKER_NODE_ID=ct101-stage5g21-managed-browser-node" /tmp/phase12i-primary-env.txt && echo "PASS: primary worker node id unchanged" || fail=1
grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" /tmp/phase12i-primary-env.txt && echo "PASS: primary max jobs remains 1" || fail=1
grep -Fq "LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS=1" /tmp/phase12i-primary-env.txt && echo "PASS: primary node max concurrency remains 1" || fail=1

if grep -E "^(LAPTOP_QUEUE_QUEUE_LANE|OLLAMA_NUM_PARALLEL)=" /tmp/phase12i-primary-env.txt; then
  echo "FAIL: primary env has active queue lane or Ollama parallel"
  fail=1
else
  echo "PASS: primary queue lane and Ollama parallel remain unset"
fi

echo
echo "=== active queued/running job check ==="
python3 - <<'PY' || fail=1
import json
import subprocess

sql = r"""
SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
FROM (
  SELECT
    status,
    COALESCE(payload_json->>'queue_lane', '(none)') AS queue_lane,
    COALESCE(requested_model, '(none)') AS requested_model,
    COUNT(*)::int AS count
  FROM app_jobs
  WHERE job_type = 'ollama_chat'
    AND status IN ('queued', 'pending', 'running', 'claimed', 'processing', 'in_progress')
  GROUP BY
    status,
    COALESCE(payload_json->>'queue_lane', '(none)'),
    COALESCE(requested_model, '(none)')
  ORDER BY status, queue_lane, requested_model
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
data = json.loads(raw)
print(json.dumps(data, indent=2, sort_keys=True))
assert data == [], data
print("PASS: no active queued/running ollama_chat jobs")
PY

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
bad_status="$(git status --short | grep -vF '?? docs/phase-12i-dormant-ct101-lane-worker-template-assets.md' | grep -vF '?? ops/smoke/check-phase-12i-dormant-ct101-lane-worker-template-assets.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12I doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12I dormant lane-worker template assets smoke passed"
else
  echo "FAIL: Phase 12I dormant lane-worker template assets smoke failed"
fi

[ "$fail" = "0" ]
