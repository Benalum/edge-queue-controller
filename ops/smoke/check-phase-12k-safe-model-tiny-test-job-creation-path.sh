#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12K smoke: safe model-tiny test job creation path ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12k-safe-model-tiny-test-job-creation-path.md"
grep -Fq "Phase 12K Safe Model-Tiny Test Job Creation Path" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "requested_model" "$DOC" && echo "PASS: requested_model doc marker found" || fail=1
grep -Fq "queue_lane" "$DOC" && echo "PASS: queue_lane doc marker found" || fail=1
grep -Fq "qwen3:0.6b" "$DOC" && echo "PASS: qwen tiny model doc marker found" || fail=1
grep -Fq "No test job was inserted" "$DOC" && echo "PASS: no-insert safety marker found" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12k-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12k-smoke-health.json >/tmp/phase12k-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12k-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== live controller status remains unfiltered ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12k-smoke-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12k-smoke-system-status.json"))
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

print("PASS: controller still sees primary unfiltered worker only")
PY

echo
echo "=== app_jobs schema checks ==="
python3 - <<'PY' || fail=1
import json
import subprocess

sql = r"""
SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
FROM (
  SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
  FROM information_schema.columns
  WHERE table_name = 'app_jobs'
  ORDER BY ordinal_position
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
by_name = {row["column_name"]: row for row in rows}
print(json.dumps(rows, indent=2, sort_keys=True))

required = {
    "id": "text",
    "job_type": "text",
    "status": "text",
    "requested_model": "text",
    "payload_json": "jsonb",
    "result_json": "jsonb",
    "created_at": "timestamp with time zone",
    "updated_at": "timestamp with time zone",
}
for name, data_type in required.items():
    assert name in by_name, f"missing column {name}"
    assert by_name[name]["data_type"] == data_type, (name, by_name[name])

assert by_name["status"]["column_default"] == "'queued'::text", by_name["status"]
print("PASS: app_jobs schema supports controlled model-tiny test insert")
PY

echo
echo "=== historical tiny lane shape check ==="
python3 - <<'PY' || fail=1
import json
import subprocess

sql = r"""
SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
FROM (
  SELECT
    id,
    status,
    requested_model,
    payload_json->>'model_tier' AS model_tier,
    payload_json->>'model_lane' AS model_lane,
    payload_json->>'queue_lane' AS queue_lane,
    payload_json->>'routing_contract_version' AS routing_contract_version
  FROM app_jobs
  WHERE job_type = 'ollama_chat'
    AND requested_model = 'qwen3:0.6b'
    AND payload_json->>'queue_lane' = 'model-tiny'
  ORDER BY created_at DESC NULLS LAST, id DESC
  LIMIT 3
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
assert rows, "expected at least one historical model-tiny job"
row = rows[0]
assert row["requested_model"] == "qwen3:0.6b", row
assert row["model_tier"] == "tiny", row
assert row["model_lane"] == "model-tiny", row
assert row["queue_lane"] == "model-tiny", row
print("PASS: historical model-tiny job shape exists")
PY

echo
echo "=== CT101 service state checks ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12k-primary-active.txt && grep -Fq "active" /tmp/phase12k-primary-active.txt && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12k-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12k-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12k-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12k-small-active.txt
  fail=1
else
  echo "PASS: small lane service inactive"
fi

echo
echo "=== CT101 tiny env checks ==="
ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_WORKER_ID|LAPTOP_QUEUE_WORKER_NODE_ID|LAPTOP_QUEUE_QUEUE_LANE|LAPTOP_QUEUE_ALLOWED_MODELS|LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK|LAPTOP_QUEUE_MAX_JOBS_PER_RUN|LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS)=" /etc/ai-platform/laptop-queue-worker-model-tiny.env' >/tmp/phase12k-tiny-env.txt && echo "PASS: tiny env captured" || fail=1
cat /tmp/phase12k-tiny-env.txt
grep -Fq "LAPTOP_QUEUE_QUEUE_LANE=model-tiny" /tmp/phase12k-tiny-env.txt && echo "PASS: tiny queue lane env ready" || fail=1
grep -Fq "LAPTOP_QUEUE_ALLOWED_MODELS=qwen3:0.6b" /tmp/phase12k-tiny-env.txt && echo "PASS: tiny allowed model env ready" || fail=1
grep -Fq "LAPTOP_QUEUE_MAX_JOBS_PER_RUN=1" /tmp/phase12k-tiny-env.txt && echo "PASS: tiny max jobs safe" || fail=1

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
bad_status="$(git status --short | grep -vF '?? docs/phase-12k-safe-model-tiny-test-job-creation-path.md' | grep -vF '?? ops/smoke/check-phase-12k-safe-model-tiny-test-job-creation-path.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12K doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12K safe model-tiny test job creation path smoke passed"
else
  echo "FAIL: Phase 12K safe model-tiny test job creation path smoke failed"
fi

[ "$fail" = "0" ]
