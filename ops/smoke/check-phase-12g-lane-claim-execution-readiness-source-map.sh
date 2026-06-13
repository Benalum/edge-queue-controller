#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12G smoke: lane claim execution readiness source map ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12g-lane-claim-execution-readiness-source-map.md"
grep -Fq "Phase 12G Lane Claim Execution Readiness Source Map" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "call_ollama()" "$DOC" && echo "PASS: call_ollama doc marker found" || fail=1
grep -Fq "job.requested_model" "$DOC" && echo "PASS: requested_model doc marker found" || fail=1
grep -Fq "Do not enable lane claims yet" "$DOC" && echo "PASS: no-enable warning doc marker found" || fail=1
grep -Fq "single CT101 worker service" "$DOC" && echo "PASS: single worker design warning found" || fail=1

echo
echo "=== controller health and readiness status ==="
curl -sS --max-time 8 -o /tmp/phase12g-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12g-smoke-health.json >/tmp/phase12g-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12g-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12g-smoke-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12g-smoke-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker service missing"

registered = worker.get("registered_capacity") or {}
caps = registered.get("capabilities") or {}
plan = worker.get("lane_dispatch_readiness") or {}

summary = {
    "worker_state": worker.get("state"),
    "registered_capabilities": caps,
    "lane_dispatch_readiness": {
        "dry_run_only": plan.get("dry_run_only"),
        "runtime_enabled": plan.get("runtime_enabled"),
        "dispatch_enabled": plan.get("dispatch_enabled"),
        "claim_filter_enabled": plan.get("claim_filter_enabled"),
        "active_queue_lane": plan.get("active_queue_lane"),
        "supported_lanes": plan.get("supported_lanes"),
        "allowed_models": plan.get("allowed_models"),
        "lanes": plan.get("lanes"),
    },
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert plan.get("dry_run_only") is True, plan
assert plan.get("runtime_enabled") is False, plan
assert plan.get("dispatch_enabled") is False, plan
assert plan.get("claim_filter_enabled") is False, plan
assert plan.get("active_queue_lane") is None, plan
assert plan.get("supported_lanes") == ["model-tiny", "model-small"], plan
assert plan.get("allowed_models") == ["qwen3:0.6b", "qwen3:1.7b", "llama3.2:3b"], plan
assert caps.get("queue_lane") is None, caps
assert caps.get("ollama_num_parallel") is None, caps

print("PASS: live readiness remains read-only and unfiltered")
PY

echo
echo "=== controller source checks ==="
grep -nF "queue_lane: str | None = None" edge_controller.py && echo "PASS: controller claim request queue_lane field found" || fail=1
grep -nF "queue_lane=request.queue_lane" edge_controller.py && echo "PASS: controller claim passes queue_lane found" || fail=1
grep -nF "payload_json->>'queue_lane'" edge_modules/laptop_queue.py && echo "PASS: controller claim helper queue_lane SQL filter found" || fail=1
grep -nF "FOR UPDATE SKIP LOCKED" edge_modules/laptop_queue.py && echo "PASS: claim locking marker found" || fail=1

echo
echo "=== CT101 source and env checks ==="
ssh "$CT101" 'pct exec 101 -- grep -nE "def claim_one|queue_lane|payload\\[\"queue_lane\"\\]|/internal/laptop-queue/jobs/claim" /opt/ai-platform/backend/app/worker/laptop_queue_client.py' >/tmp/phase12g-client.txt && echo "PASS: CT101 client queue_lane refs captured" || fail=1
cat /tmp/phase12g-client.txt

grep -Fq "def claim_one" /tmp/phase12g-client.txt && echo "PASS: CT101 claim_one found" || fail=1
grep -Fq "queue_lane" /tmp/phase12g-client.txt && echo "PASS: CT101 queue_lane support found" || fail=1
grep -Fq 'payload["queue_lane"]' /tmp/phase12g-client.txt && echo "PASS: CT101 queue_lane payload marker found" || fail=1

ssh "$CT101" 'pct exec 101 -- grep -nE "LAPTOP_QUEUE_QUEUE_LANE|job.get\\(\"requested_model\"\\)|LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK|LAPTOP_QUEUE_OLLAMA_BASE_URL|client.claim_one|call_ollama\\(job\\)" /opt/ai-platform/ops/smoke/laptop_queue_bounded_synthetic_poller.py' >/tmp/phase12g-poller.txt && echo "PASS: CT101 poller refs captured" || fail=1
cat /tmp/phase12g-poller.txt

grep -Fq 'job.get("requested_model")' /tmp/phase12g-poller.txt && echo "PASS: CT101 execution uses requested_model" || fail=1
grep -Fq "LAPTOP_QUEUE_QUEUE_LANE" /tmp/phase12g-poller.txt && echo "PASS: CT101 poller reads queue lane env" || fail=1
grep -Fq "client.claim_one" /tmp/phase12g-poller.txt && echo "PASS: CT101 poller calls claim_one" || fail=1
grep -Fq "call_ollama(job)" /tmp/phase12g-poller.txt && echo "PASS: CT101 poller calls Ollama with job" || fail=1

ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_MAX_JOBS_PER_RUN|LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS|LAPTOP_QUEUE_SUPPORTED_LANES|LAPTOP_QUEUE_SUPPORTED_MODEL_TIERS|LAPTOP_QUEUE_ALLOWED_MODELS)=" /etc/ai-platform/laptop-queue-worker.env' >/tmp/phase12g-env.txt && echo "PASS: CT101 env captured" || fail=1
cat /tmp/phase12g-env.txt

grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" /tmp/phase12g-env.txt && echo "PASS: max jobs remains 1" || fail=1
grep -Fq "LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS=1" /tmp/phase12g-env.txt && echo "PASS: node max concurrency remains 1" || fail=1

if ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_QUEUE_LANE|OLLAMA_NUM_PARALLEL)=" /etc/ai-platform/laptop-queue-worker.env' >/tmp/phase12g-forbidden-env.txt 2>/dev/null; then
  echo "FAIL: forbidden queue lane or Ollama parallel env is active"
  cat /tmp/phase12g-forbidden-env.txt
  fail=1
else
  echo "PASS: queue lane and Ollama parallel remain unset"
fi

ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12g-worker-active.txt && grep -Fq "active" /tmp/phase12g-worker-active.txt && echo "PASS: CT101 worker service active" || fail=1

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
bad_status="$(git status --short | grep -vF '?? docs/phase-12g-lane-claim-execution-readiness-source-map.md' | grep -vF '?? ops/smoke/check-phase-12g-lane-claim-execution-readiness-source-map.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12G doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12G lane claim execution readiness smoke passed"
else
  echo "FAIL: Phase 12G lane claim execution readiness smoke failed"
fi

[ "$fail" = "0" ]
