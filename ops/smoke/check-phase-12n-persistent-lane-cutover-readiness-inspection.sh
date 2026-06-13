#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12N smoke: persistent lane cutover readiness inspection ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12n-persistent-lane-cutover-readiness-inspection.md"
grep -Fq "Phase 12N Persistent Lane Cutover Readiness Inspection" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "Persistent lane cutover is not ready yet" "$DOC" && echo "PASS: not-ready finding documented" || fail=1
grep -Fq "Historical no-lane evidence" "$DOC" && echo "PASS: no-lane evidence section found" || fail=1
grep -Fq "no-lane fallback worker" "$DOC" && echo "PASS: fallback worker risk documented" || fail=1
grep -Fq "No persistent lane cutover was enabled" "$DOC" && echo "PASS: safety marker found" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12n-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12n-smoke-health.json >/tmp/phase12n-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12n-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== live controller status remains primary-only ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12n-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12n-system-status.json"))
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
    "warnings": plan.get("warnings"),
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
echo "=== historical no-lane risk still detectable ==="
python3 - <<'PY' || fail=1
import json
import subprocess

sql = r"""
SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
FROM (
  SELECT
    status,
    COALESCE(requested_model, '(none)') AS requested_model,
    COALESCE(payload_json->>'route_source', '(none)') AS route_source,
    COUNT(*)::int AS count,
    MAX(created_at) AS newest_created_at
  FROM app_jobs
  WHERE job_type = 'ollama_chat'
    AND COALESCE(payload_json->>'queue_lane', '') = ''
  GROUP BY
    status,
    COALESCE(requested_model, '(none)'),
    COALESCE(payload_json->>'route_source', '(none)')
  ORDER BY newest_created_at DESC NULLS LAST, count DESC
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
assert rows, "expected historical no-lane risk rows during Phase 12N"
assert any(row.get("requested_model") == "gemma4:e4b" for row in rows), rows
print("PASS: historical no-lane risk remains documented and detectable")
PY

echo
echo "=== controlled lane proofs still present ==="
python3 - <<'PY' || fail=1
import json
import subprocess

ids = [
    "phase12l-tiny-job-7ddc80a044438855",
    "phase12m-small-job-e8ec453de2951427",
]
sql = f"""
SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
FROM (
  SELECT
    id,
    status,
    requested_model,
    assigned_worker_id,
    payload_json->>'queue_lane' AS queue_lane,
    result_json
  FROM app_jobs
  WHERE id IN ({','.join(repr(x) for x in ids)})
  ORDER BY id
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

by_id = {row["id"]: row for row in rows}
assert set(by_id) == set(ids), by_id

tiny = by_id["phase12l-tiny-job-7ddc80a044438855"]
small = by_id["phase12m-small-job-e8ec453de2951427"]

assert tiny["status"] == "complete", tiny
assert tiny["requested_model"] == "qwen3:0.6b", tiny
assert tiny["queue_lane"] == "model-tiny", tiny
assert tiny["assigned_worker_id"] == "ct101-stage5g21-managed-browser-model-tiny", tiny

assert small["status"] == "complete", small
assert small["requested_model"] == "qwen3:1.7b", small
assert small["queue_lane"] == "model-small", small
assert small["assigned_worker_id"] == "ct101-stage5g21-managed-browser-model-small", small

print("PASS: controlled tiny/small lane proofs still present")
PY

echo
echo "=== CT101 service state remains safe ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12n-primary-active.txt && grep -Fq "active" /tmp/phase12n-primary-active.txt && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12n-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12n-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12n-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12n-small-active.txt
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
"' >/tmp/phase12n-enabled-state.txt || fail=1
cat /tmp/phase12n-enabled-state.txt

grep -Fq "enabled" /tmp/phase12n-enabled-state.txt && echo "PASS: primary enabled state present" || fail=1
grep -Fq "disabled" /tmp/phase12n-enabled-state.txt && echo "PASS: lane disabled state present" || fail=1

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
bad_status="$(git status --short | grep -vF '?? docs/phase-12n-persistent-lane-cutover-readiness-inspection.md' | grep -vF '?? ops/smoke/check-phase-12n-persistent-lane-cutover-readiness-inspection.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12N doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12N persistent lane cutover readiness inspection smoke passed"
else
  echo "FAIL: Phase 12N persistent lane cutover readiness inspection smoke failed"
fi

[ "$fail" = "0" ]
