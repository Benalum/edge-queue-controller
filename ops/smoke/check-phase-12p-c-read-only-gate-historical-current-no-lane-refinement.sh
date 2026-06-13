#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12P-C smoke: read-only gate historical-vs-current no-lane refinement ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12p-c-read-only-gate-historical-current-no-lane-refinement.md"
grep -Fq "Phase 12P-C Read-Only Gate Historical-vs-Current No-Lane Refinement" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "evidence.historical_no_lane_jobs_detected" "$DOC" && echo "PASS: evidence field documented" || fail=1
grep -Fq "recent_no_lane_jobs_after_lane_contract" "$DOC" && echo "PASS: recent no-lane blocker documented" || fail=1
grep -Fq "historical_no_lane_jobs_detected is evidence, not a readiness reason" "$DOC" && echo "PASS: historical evidence behavior documented" || fail=1
grep -Fq "enable persistent lane cutover" "$DOC" && echo "PASS: safety marker documented" || fail=1

echo
echo "=== source checks ==="
grep -Fq "STAGE_5P12O_PERSISTENT_LANE_CUTOVER_READINESS_GATE_BEGIN" edge_controller.py && echo "PASS: gate marker exists" || fail=1
grep -Fq '"evidence": {' edge_controller.py && echo "PASS: gate evidence section exists" || fail=1
grep -Fq '"recent_no_lane_jobs_after_lane_contract": []' edge_controller.py && echo "PASS: recent no-lane blocker field exists" || fail=1
grep -Fq 'lane_contract_first_seen_at' edge_controller.py && echo "PASS: lane contract first seen field exists" || fail=1

if grep -Fq 'add_reason("historical_no_lane_jobs_detected")' edge_controller.py; then
  echo "FAIL: old permanent historical no-lane blocker reason still exists"
  fail=1
else
  echo "PASS: old permanent historical no-lane reason removed"
fi

echo
echo "=== python syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12pc-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12pc-smoke-health.json >/tmp/phase12pc-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12pc-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== live refined gate check ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12pc-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12pc-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
blockers = gate.get("blockers") or {}
evidence = gate.get("evidence") or {}

summary = {
    "worker_state": worker.get("state"),
    "gate_source": gate.get("source"),
    "ready": gate.get("ready"),
    "dry_run_only": gate.get("dry_run_only"),
    "reasons": sorted(reasons),
    "evidence": evidence,
    "recent_no_lane_jobs_after_lane_contract": blockers.get("recent_no_lane_jobs_after_lane_contract"),
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("source") == "stage_5p12o_read_only_persistent_lane_cutover_gate", gate
assert gate.get("dry_run_only") is True, gate
assert gate.get("ready") is False, gate

assert "historical_no_lane_jobs_detected" not in reasons, gate
assert evidence.get("historical_no_lane_jobs_detected") is True, evidence
assert evidence.get("historical_no_lane_jobs"), evidence
assert evidence.get("lane_contract_first_seen_at"), evidence

recent = blockers.get("recent_no_lane_jobs_after_lane_contract")
assert isinstance(recent, list), blockers
assert recent == [], recent

expected_remaining = {
    "primary_worker_unfiltered",
    "persistent_lane_workers_not_active",
    "no_no_lane_fallback_worker",
}
missing = expected_remaining - reasons
assert not missing, {"missing": sorted(missing), "reasons": sorted(reasons), "gate": gate}

print("PASS: live gate separates historical evidence from current blockers")
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
rows = json.loads(subprocess.check_output(cmd, text=True))
print(json.dumps(rows, indent=2, sort_keys=True))
assert rows == [], rows
print("PASS: no active queued/running ollama_chat app_jobs")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12pc-primary-active.txt && grep -Fq "active" /tmp/phase12pc-primary-active.txt && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12pc-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12pc-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12pc-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12pc-small-active.txt
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
  | grep -vF ' M edge_controller.py' \
  | grep -vF '?? docs/phase-12p-c-read-only-gate-historical-current-no-lane-refinement.md' \
  | grep -vF '?? ops/smoke/check-phase-12p-c-read-only-gate-historical-current-no-lane-refinement.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12P-C code/doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12P-C read-only gate historical-vs-current no-lane refinement smoke passed"
else
  echo "FAIL: Phase 12P-C read-only gate historical-vs-current no-lane refinement smoke failed"
fi

[ "$fail" = "0" ]
