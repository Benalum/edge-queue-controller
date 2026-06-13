#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12Q-B smoke: conditional no-lane fallback blocker refinement ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12q-b-conditional-no-lane-fallback-blocker-refinement.md"
grep -Fq "Phase 12Q-B Conditional No-Lane Fallback Blocker Refinement" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "no_no_lane_fallback_worker is not a reason" "$DOC" && echo "PASS: expected reason removal documented" || fail=1
grep -Fq "evidence.no_lane_fallback_worker_required=false" "$DOC" && echo "PASS: fallback required evidence documented" || fail=1
grep -Fq "not_required_without_current_no_lane_risk" "$DOC" && echo "PASS: fallback requirement source documented" || fail=1
grep -Fq "enable persistent lane cutover" "$DOC" && echo "PASS: safety marker documented" || fail=1

echo
echo "=== source checks ==="
grep -Fq "STAGE_5P12O_PERSISTENT_LANE_CUTOVER_READINESS_GATE_BEGIN" edge_controller.py && echo "PASS: gate marker exists" || fail=1
grep -Fq '"warnings": []' edge_controller.py && echo "PASS: warnings field exists" || fail=1
grep -Fq '"no_lane_fallback_worker_required": False' edge_controller.py && echo "PASS: fallback required evidence field exists" || fail=1
grep -Fq 'current_no_lane_risk = bool' edge_controller.py && echo "PASS: current no-lane risk calculation exists" || fail=1
grep -Fq 'current_no_lane_risk and not fallback_candidates' edge_controller.py && echo "PASS: conditional fallback reason exists" || fail=1
grep -Fq 'no_no_lane_fallback_worker_absent_but_no_current_no_lane_risk' edge_controller.py && echo "PASS: fallback warning exists" || fail=1

echo
echo "=== python syntax check ==="
python3 -m py_compile edge_controller.py && echo "PASS: edge_controller.py compiles" || fail=1

echo
echo "=== controller health ==="
curl -sS --max-time 8 -o /tmp/phase12qb-smoke-health.json -w "health_code=%{http_code} time=%{time_total}\n" http://127.0.0.1:7070/health || fail=1
python3 -m json.tool /tmp/phase12qb-smoke-health.json >/tmp/phase12qb-smoke-health.pretty && grep -Fq '"ok": true' /tmp/phase12qb-smoke-health.pretty && echo "PASS: controller health ok" || fail=1

echo
echo "=== live conditional gate check ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12qb-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12qb-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"

gate = worker.get("persistent_lane_cutover_readiness") or {}
reasons = set(gate.get("reasons") or [])
blockers = gate.get("blockers") or {}
evidence = gate.get("evidence") or {}
warnings = gate.get("warnings") or []

summary = {
    "worker_state": worker.get("state"),
    "gate_source": gate.get("source"),
    "ready": gate.get("ready"),
    "dry_run_only": gate.get("dry_run_only"),
    "reasons": sorted(reasons),
    "warnings": warnings,
    "active_unsupported_jobs": blockers.get("active_unsupported_jobs"),
    "recent_no_lane_jobs_after_lane_contract": blockers.get("recent_no_lane_jobs_after_lane_contract"),
    "no_lane_fallback_worker_required": evidence.get("no_lane_fallback_worker_required"),
    "no_lane_fallback_requirement_source": evidence.get("no_lane_fallback_requirement_source"),
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("source") == "stage_5p12o_read_only_persistent_lane_cutover_gate", gate
assert gate.get("dry_run_only") is True, gate
assert gate.get("ready") is False, gate

assert blockers.get("active_unsupported_jobs") == [], blockers
assert blockers.get("recent_no_lane_jobs_after_lane_contract") == [], blockers

assert "historical_no_lane_jobs_detected" not in reasons, gate
assert "no_no_lane_fallback_worker" not in reasons, gate

assert evidence.get("no_lane_fallback_worker_present") is False, evidence
assert evidence.get("no_lane_fallback_worker_required") is False, evidence
assert evidence.get("no_lane_fallback_requirement_source") == "not_required_without_current_no_lane_risk", evidence

expected_remaining = {
    "primary_worker_unfiltered",
    "persistent_lane_workers_not_active",
}
missing = expected_remaining - reasons
assert not missing, {"missing": sorted(missing), "reasons": sorted(reasons), "gate": gate}

assert "no_no_lane_fallback_worker_absent_but_no_current_no_lane_risk" in warnings, warnings

print("PASS: live gate treats missing fallback as warning only when no current no-lane risk exists")
PY

echo
echo "=== no active queued/running app_jobs check ==="
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
    COALESCE(payload_json->>'queue_lane', '(none)') AS queue_lane,
    COALESCE(payload_json->>'route_source', '(none)') AS route_source,
    assigned_worker_id,
    created_at
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
echo "=== no no-lane rows after lane contract began check ==="
python3 - <<'PY' || fail=1
import json
import subprocess

sql = r"""
WITH first_lane_contract AS (
  SELECT MIN(created_at) AS first_seen_at
  FROM app_jobs
  WHERE job_type = 'ollama_chat'
    AND payload_json->>'routing_contract_version' = 'stage_5p11r_v1'
    AND COALESCE(payload_json->>'queue_lane', '') != ''
)
SELECT COALESCE(json_agg(row_to_json(t)), '[]'::json)::text
FROM (
  SELECT
    j.id,
    j.status,
    j.requested_model,
    COALESCE(j.payload_json->>'route_source', '(none)') AS route_source,
    COALESCE(j.payload_json->>'queue_lane', '(none)') AS queue_lane,
    j.created_at,
    flc.first_seen_at AS lane_contract_first_seen_at
  FROM app_jobs j
  CROSS JOIN first_lane_contract flc
  WHERE j.job_type = 'ollama_chat'
    AND flc.first_seen_at IS NOT NULL
    AND j.created_at >= flc.first_seen_at
    AND COALESCE(j.payload_json->>'queue_lane', '') = ''
  ORDER BY j.created_at DESC NULLS LAST, j.id DESC
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
print("PASS: no no-lane app_jobs were created after lane contract began")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12qb-primary-active.txt && grep -Fq "active" /tmp/phase12qb-primary-active.txt && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12qb-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12qb-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12qb-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12qb-small-active.txt
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
  | grep -vF '?? docs/phase-12q-b-conditional-no-lane-fallback-blocker-refinement.md' \
  | grep -vF '?? ops/smoke/check-phase-12q-b-conditional-no-lane-fallback-blocker-refinement.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12Q-B code/doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12Q-B conditional no-lane fallback blocker refinement smoke passed"
else
  echo "FAIL: Phase 12Q-B conditional no-lane fallback blocker refinement smoke failed"
fi

[ "$fail" = "0" ]
