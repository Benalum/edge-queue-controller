#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12L-B smoke: source-safe CT101 lane env fix ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12l-b-source-safe-ct101-lane-env-fix.md"
grep -Fq "Phase 12L-B Source-Safe CT101 Lane Env Fix" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "model-tiny: command not found" "$DOC" && echo "PASS: failure marker found" || fail=1
grep -Fq "CT101_model_tiny_lane_worker" "$DOC" && echo "PASS: tiny source-safe name documented" || fail=1
grep -Fq "CT101_model_small_lane_worker" "$DOC" && echo "PASS: small source-safe name documented" || fail=1
grep -Fq "No test job was inserted" "$DOC" && echo "PASS: no-job safety marker found" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12lb-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12lb-smoke-health.json >/tmp/phase12lb-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12lb-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== CT101 source-safe env checks ==="
ssh "$CT101" 'pct exec 101 -- bash -lc "
set -u

echo \"--- tiny env ---\"
grep -nE \"^(LAPTOP_QUEUE_WORKER_ID|LAPTOP_QUEUE_WORKER_NODE_ID|LAPTOP_QUEUE_WORKER_NAME|LAPTOP_QUEUE_WORKER_NODE_NAME|LAPTOP_QUEUE_QUEUE_LANE|LAPTOP_QUEUE_ALLOWED_MODELS|LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK|LAPTOP_QUEUE_MAX_JOBS_PER_RUN|LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS)=\" /etc/ai-platform/laptop-queue-worker-model-tiny.env

echo
echo \"--- small env ---\"
grep -nE \"^(LAPTOP_QUEUE_WORKER_ID|LAPTOP_QUEUE_WORKER_NODE_ID|LAPTOP_QUEUE_WORKER_NAME|LAPTOP_QUEUE_WORKER_NODE_NAME|LAPTOP_QUEUE_QUEUE_LANE|LAPTOP_QUEUE_ALLOWED_MODELS|LAPTOP_QUEUE_OLLAMA_MODEL_FALLBACK|LAPTOP_QUEUE_MAX_JOBS_PER_RUN|LAPTOP_QUEUE_NODE_MAX_CONCURRENT_JOBS)=\" /etc/ai-platform/laptop-queue-worker-model-small.env

echo
echo \"--- source tiny env ---\"
bash -lc \"set -a; source /etc/ai-platform/laptop-queue-worker.env; source /etc/ai-platform/laptop-queue-worker-model-tiny.env; set +a; echo worker_id=\\\$LAPTOP_QUEUE_WORKER_ID; echo queue_lane=\\\$LAPTOP_QUEUE_QUEUE_LANE; echo worker_name=\\\$LAPTOP_QUEUE_WORKER_NAME\"

echo
echo \"--- source small env ---\"
bash -lc \"set -a; source /etc/ai-platform/laptop-queue-worker.env; source /etc/ai-platform/laptop-queue-worker-model-small.env; set +a; echo worker_id=\\\$LAPTOP_QUEUE_WORKER_ID; echo queue_lane=\\\$LAPTOP_QUEUE_QUEUE_LANE; echo worker_name=\\\$LAPTOP_QUEUE_WORKER_NAME\"
"' >/tmp/phase12lb-ct101-env.txt || fail=1

cat /tmp/phase12lb-ct101-env.txt

grep -Fq "LAPTOP_QUEUE_WORKER_NAME=CT101_model_tiny_lane_worker" /tmp/phase12lb-ct101-env.txt && echo "PASS: tiny worker name source-safe" || fail=1
grep -Fq "LAPTOP_QUEUE_WORKER_NODE_NAME=CT101_model_tiny_lane_node" /tmp/phase12lb-ct101-env.txt && echo "PASS: tiny node name source-safe" || fail=1
grep -Fq "LAPTOP_QUEUE_WORKER_NAME=CT101_model_small_lane_worker" /tmp/phase12lb-ct101-env.txt && echo "PASS: small worker name source-safe" || fail=1
grep -Fq "LAPTOP_QUEUE_WORKER_NODE_NAME=CT101_model_small_lane_node" /tmp/phase12lb-ct101-env.txt && echo "PASS: small node name source-safe" || fail=1
grep -Fq "worker_id=ct101-stage5g21-managed-browser-model-tiny" /tmp/phase12lb-ct101-env.txt && echo "PASS: tiny source test worker id ok" || fail=1
grep -Fq "worker_id=ct101-stage5g21-managed-browser-model-small" /tmp/phase12lb-ct101-env.txt && echo "PASS: small source test worker id ok" || fail=1

echo
echo "=== CT101 preflight override checks, no service starts ==="
ssh "$CT101" 'pct exec 101 -- bash -lc "
STAGE5G23_OVERRIDE_ENV_FILE=/etc/ai-platform/laptop-queue-worker-model-tiny.env /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh
STAGE5G23_OVERRIDE_ENV_FILE=/etc/ai-platform/laptop-queue-worker-model-small.env /opt/ai-platform/ops/runtime/laptop-queue-worker-preflight.sh
"' && echo "PASS: tiny and small override preflights pass" || fail=1

echo
echo "=== CT101 service safety checks ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12lb-primary-active.txt && grep -Fq "active" /tmp/phase12lb-primary-active.txt && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12lb-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12lb-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12lb-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12lb-small-active.txt
  fail=1
else
  echo "PASS: small lane service inactive"
fi

echo
echo "=== controller live status remains primary-only ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12lb-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12lb-system-status.json"))
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
bad_status="$(git status --short | grep -vF '?? docs/phase-12l-b-source-safe-ct101-lane-env-fix.md' | grep -vF '?? ops/smoke/check-phase-12l-b-source-safe-ct101-lane-env-fix.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12L-B doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12L-B source-safe lane env smoke passed"
else
  echo "FAIL: Phase 12L-B source-safe lane env smoke failed"
fi

[ "$fail" = "0" ]
