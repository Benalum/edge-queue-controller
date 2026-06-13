#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12P-B smoke: historical-vs-current no-lane gate refinement inspection ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12p-b-historical-current-no-lane-gate-refinement-inspection.md"
grep -Fq "Phase 12P-B Historical-vs-Current No-Lane Gate Refinement Inspection" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "historical_no_lane_jobs_detected is currently a permanent blocker" "$DOC" && echo "PASS: current permanent blocker documented" || fail=1
grep -Fq "Inspection found no active unsupported/no-lane jobs" "$DOC" && echo "PASS: active no-lane state documented" || fail=1
grep -Fq "recent_no_lane_jobs_after_lane_contract" "$DOC" && echo "PASS: future recent no-lane blocker documented" || fail=1
grep -Fq "router rollout parked" "$DOC" && echo "PASS: safety marker documented" || fail=1

echo
echo "=== source check: current gate still treats historical rows as reason before refinement ==="
grep -Fq "STAGE_5P12O_PERSISTENT_LANE_CUTOVER_READINESS_GATE_BEGIN" edge_controller.py && echo "PASS: gate marker exists" || fail=1
grep -Fq 'add_reason("historical_no_lane_jobs_detected")' edge_controller.py && echo "PASS: current historical no-lane reason exists before refinement" || fail=1
grep -Fq '"historical_no_lane_jobs": []' edge_controller.py && echo "PASS: current historical no-lane blocker field exists" || fail=1

echo
echo "=== controller health and current gate ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12pb-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12pb-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"
gate = worker.get("persistent_lane_cutover_readiness") or {}

summary = {
    "worker_state": worker.get("state"),
    "gate_source": gate.get("source"),
    "gate_ready": gate.get("ready"),
    "gate_dry_run_only": gate.get("dry_run_only"),
    "gate_reasons": gate.get("reasons"),
    "historical_no_lane_count": len((gate.get("blockers") or {}).get("historical_no_lane_jobs") or []),
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("source") == "stage_5p12o_read_only_persistent_lane_cutover_gate", gate
assert gate.get("dry_run_only") is True, gate
assert gate.get("ready") is False, gate
assert "historical_no_lane_jobs_detected" in set(gate.get("reasons") or []), gate
print("PASS: current gate is live and still shows historical no-lane reason before refinement")
PY

echo
echo "=== active unsupported/no-lane app_jobs check ==="
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
    COALESCE(payload_json->>'route_source', '(none)') AS route_source,
    COALESCE(payload_json->>'queue_lane', '(none)') AS queue_lane,
    created_at
  FROM app_jobs
  WHERE job_type = 'ollama_chat'
    AND status IN ('queued', 'pending', 'running', 'claimed', 'processing', 'in_progress')
    AND (
      COALESCE(payload_json->>'queue_lane', '') = ''
      OR COALESCE(payload_json->>'queue_lane', '') NOT IN ('model-tiny', 'model-small')
    )
  ORDER BY created_at DESC NULLS LAST, id DESC
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
rows = json.loads(subprocess.check_output(cmd, text=True))
print(json.dumps(rows, indent=2, sort_keys=True))
assert rows == [], rows
print("PASS: no active unsupported/no-lane app_jobs")
PY

echo
echo "=== historical no-lane evidence check ==="
python3 - <<'PY' || fail=1
import json
import subprocess

sql = r"""
SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
FROM (
  SELECT
    status,
    requested_model,
    COALESCE(payload_json->>'route_source', '(none)') AS route_source,
    COUNT(*)::int AS count,
    MAX(created_at) AS newest_created_at,
    MIN(created_at) AS oldest_created_at
  FROM app_jobs
  WHERE job_type = 'ollama_chat'
    AND COALESCE(payload_json->>'queue_lane', '') = ''
  GROUP BY
    status,
    requested_model,
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
rows = json.loads(subprocess.check_output(cmd, text=True))
print(json.dumps(rows, indent=2, sort_keys=True))
assert rows, "expected historical no-lane rows"
assert any(row.get("requested_model") == "gemma4:e4b" for row in rows), rows
print("PASS: historical no-lane evidence remains detectable")
PY

echo
echo "=== lane-tagged app_jobs proof ==="
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
    COALESCE(payload_json->>'route_source', '(none)') AS route_source,
    payload_json->>'routing_contract_version' AS routing_contract_version,
    payload_json->>'queue_lane' AS queue_lane,
    payload_json->>'model_tier' AS model_tier,
    payload_json->>'model_lane' AS model_lane,
    created_at
  FROM app_jobs
  WHERE job_type = 'ollama_chat'
    AND COALESCE(payload_json->>'queue_lane', '') != ''
  ORDER BY created_at DESC NULLS LAST, id DESC
  LIMIT 12
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
rows = json.loads(subprocess.check_output(cmd, text=True))
print(json.dumps(rows, indent=2, sort_keys=True))
assert rows, "expected lane-tagged app_jobs rows"
assert any(row.get("queue_lane") == "model-tiny" for row in rows), rows
assert any(row.get("queue_lane") == "model-small" for row in rows), rows
assert any(row.get("routing_contract_version") == "stage_5p11r_v1" for row in rows), rows
print("PASS: lane-tagged app_jobs proof exists")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12pb-primary-active.txt && grep -Fq "active" /tmp/phase12pb-primary-active.txt && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12pb-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12pb-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12pb-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12pb-small-active.txt
  fail=1
else
  echo "PASS: small lane service inactive"
fi

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
  | grep -vF '?? docs/phase-12p-b-historical-current-no-lane-gate-refinement-inspection.md' \
  | grep -vF '?? ops/smoke/check-phase-12p-b-historical-current-no-lane-gate-refinement-inspection.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12P-B doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12P-B historical-vs-current no-lane gate refinement inspection smoke passed"
else
  echo "FAIL: Phase 12P-B historical-vs-current no-lane gate refinement inspection smoke failed"
fi

[ "$fail" = "0" ]
