#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"
TEST_JOB_ID="phase12m-small-job-e8ec453de2951427"

echo "=== Phase 12M-A smoke: controlled model-small lane activation test ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12m-a-controlled-model-small-lane-activation-test.md"
grep -Fq "Phase 12M-A Controlled Model-Small Lane Activation Test" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "$TEST_JOB_ID" "$DOC" && echo "PASS: test job id documented" || fail=1
grep -Fq "ct101-stage5g21-managed-browser-model-small" "$DOC" && echo "PASS: small worker documented" || fail=1
grep -Fq "small lane ok" "$DOC" && echo "PASS: small reply documented" || fail=1
grep -Fq "does not yet enable persistent lane workers" "$DOC" && echo "PASS: limitation documented" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12ma-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12ma-smoke-health.json >/tmp/phase12ma-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12ma-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== controlled test job proof ==="
PHASE12MA_TEST_JOB_ID="$TEST_JOB_ID" python3 - <<'PY' || fail=1
import json
import os
import subprocess

job_id = os.environ["PHASE12MA_TEST_JOB_ID"]
sql = f"""
SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
FROM (
  SELECT
    id,
    status,
    requested_model,
    assigned_worker_id,
    payload_json->>'queue_lane' AS queue_lane,
    payload_json->>'model_tier' AS model_tier,
    payload_json->>'model_lane' AS model_lane,
    result_json,
    error_text,
    started_at,
    finished_at
  FROM app_jobs
  WHERE id = {job_id!r}
) t;
"""

py = "from edge_modules.chat_queue_persistence import _psql_at\n" + f"print(_psql_at({sql!r}))\n"
raw = subprocess.check_output(["bash", "-lc", "python3 - <<'INNER'\n" + py + "INNER"], text=True)
rows = json.loads(raw)
print(json.dumps(rows, indent=2, sort_keys=True))

assert rows, "controlled small test job not found"
row = rows[0]
result = row.get("result_json") or {}

assert row["id"] == job_id, row
assert row["status"] == "complete", row
assert row["requested_model"] == "qwen3:1.7b", row
assert row["assigned_worker_id"] == "ct101-stage5g21-managed-browser-model-small", row
assert row["queue_lane"] == "model-small", row
assert row["model_tier"] == "small", row
assert row["model_lane"] == "model-small", row
assert row["error_text"] is None, row
assert result.get("model") == "qwen3:1.7b", result
assert result.get("worker") == "ct101-stage5g21-managed-browser-model-small", result
assert result.get("reply") == "small lane ok", result

print("PASS: controlled model-small job proof ok")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12ma-primary-active.txt && grep -Fq "active" /tmp/phase12ma-primary-active.txt && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12ma-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12ma-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12ma-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12ma-small-active.txt
  fail=1
else
  echo "PASS: small lane service inactive"
fi

echo
echo "=== CT101 source-safe small env remains ready ==="
ssh "$CT101" 'pct exec 101 -- grep -nE "^(LAPTOP_QUEUE_WORKER_ID|LAPTOP_QUEUE_WORKER_NODE_ID|LAPTOP_QUEUE_WORKER_NAME|LAPTOP_QUEUE_WORKER_NODE_NAME|LAPTOP_QUEUE_QUEUE_LANE|LAPTOP_QUEUE_ALLOWED_MODELS|LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK|LAPTOP_QUEUE_MAX_JOBS_PER_RUN|LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS)=" /etc/ai-platform/laptop-queue-worker-model-small.env' >/tmp/phase12ma-small-env.txt && echo "PASS: small env captured" || fail=1
cat /tmp/phase12ma-small-env.txt

grep -Fq "LAPTOP_QUEUE_WORKER_ID=ct101-stage5g21-managed-browser-model-small" /tmp/phase12ma-small-env.txt && echo "PASS: small worker id ready" || fail=1
grep -Fq "LAPTOP_QUEUE_QUEUE_LANE=model-small" /tmp/phase12ma-small-env.txt && echo "PASS: small queue lane ready" || fail=1
grep -Fq "LAPTOP_QUEUE_ALLOWED_MODELS=qwen3:1.7b,llama3.2:3b" /tmp/phase12ma-small-env.txt && echo "PASS: small allowed models ready" || fail=1
grep -Fq "LAPTOP_QUEUE_WORKER_NAME=CT101_model_small_lane_worker" /tmp/phase12ma-small-env.txt && echo "PASS: small name source-safe" || fail=1

echo
echo "=== controller live status remains primary-only after controlled test ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12ma-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12ma-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

registered = worker.get("registered_capacity") or {}
caps = registered.get("capabilities") or {}
plan = worker.get("lane_dispatch_readiness") or {}

summary = {
    "worker_state": worker.get("state"),
    "worker_id": registered.get("worker_id"),
    "worker_node_id": registered.get("worker_node_id"),
    "queue_lane": caps.get("queue_lane"),
    "dry_run_only": plan.get("dry_run_only"),
    "dispatch_enabled": plan.get("dispatch_enabled"),
    "claim_filter_enabled": plan.get("claim_filter_enabled"),
    "active_queue_lane": plan.get("active_queue_lane"),
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert registered.get("worker_id") == "ct101-stage5g21-managed-browser", summary
assert registered.get("worker_node_id") == "ct101-stage5g21-managed-browser-node", summary
assert caps.get("queue_lane") is None, summary
assert plan.get("dry_run_only") is True, summary
assert plan.get("dispatch_enabled") is False, summary
assert plan.get("claim_filter_enabled") is False, summary
assert plan.get("active_queue_lane") is None, summary

print("PASS: controller still sees primary unfiltered worker only")
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
echo "=== router rollout parked guard ==="
if systemctl show edge-queue-controller -p Environment --value | tr " " "\n" | grep -E "ROUTER.*DRY_RUN|PERSISTENT.*ROLLOUT.*ENABLED=1"; then
  echo "FAIL: unexpected router rollout env found"
  fail=1
else
  echo "PASS: no active router rollout env found"
fi

echo
echo "=== changed files guard ==="
bad_status="$(git status --short | grep -vF '?? docs/phase-12m-a-controlled-model-small-lane-activation-test.md' | grep -vF '?? ops/smoke/check-phase-12m-a-controlled-model-small-lane-activation-test.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12M-A doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12M-A controlled model-small lane activation smoke passed"
else
  echo "FAIL: Phase 12M-A controlled model-small lane activation smoke failed"
fi

[ "$fail" = "0" ]
