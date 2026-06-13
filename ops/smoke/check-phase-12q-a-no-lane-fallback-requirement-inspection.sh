#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12Q-A smoke: no-lane fallback requirement inspection ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12q-a-no-lane-fallback-requirement-inspection.md"
grep -Fq "Phase 12Q-A No-Lane Fallback Requirement Inspection" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "A no-lane fallback worker is not currently required for active production app_jobs traffic" "$DOC" && echo "PASS: main finding documented" || fail=1
grep -Fq "no no-lane app_jobs were created after the Stage 5P11R lane contract began" "$DOC" && echo "PASS: after-contract finding documented" || fail=1
grep -Fq "production real-user app_jobs creation is lane-tagged" "$DOC" && echo "PASS: production lane-tagged finding documented" || fail=1
grep -Fq "router rollout parked" "$DOC" && echo "PASS: safety marker documented" || fail=1

echo
echo "=== live refined persistent cutover gate ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12qa-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12qa-system-status.json"))
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
    "active_unsupported_jobs": blockers.get("active_unsupported_jobs"),
    "recent_no_lane_jobs_after_lane_contract": blockers.get("recent_no_lane_jobs_after_lane_contract"),
    "historical_no_lane_jobs_detected": evidence.get("historical_no_lane_jobs_detected"),
    "lane_contract_first_seen_at": evidence.get("lane_contract_first_seen_at"),
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("source") == "stage_5p12o_read_only_persistent_lane_cutover_gate", gate
assert gate.get("dry_run_only") is True, gate
assert gate.get("ready") is False, gate
assert "historical_no_lane_jobs_detected" not in reasons, gate
assert blockers.get("active_unsupported_jobs") == [], blockers
assert blockers.get("recent_no_lane_jobs_after_lane_contract") == [], blockers
assert evidence.get("historical_no_lane_jobs_detected") is True, evidence
assert evidence.get("lane_contract_first_seen_at"), evidence
assert "no_no_lane_fallback_worker" in reasons, gate
print("PASS: refined gate is live with no active/recent no-lane blockers")
PY

echo
echo "=== app_jobs insert inventory check ==="
python3 - <<'PY' || fail=1
from pathlib import Path

paths = [Path("edge_controller.py")] + sorted(Path("edge_modules").glob("*.py"))
hits = []
for path in paths:
    if not path.exists():
        continue
    for n, line in enumerate(path.read_text().splitlines(), start=1):
        if "INSERT INTO app_jobs" in line:
            hits.append(f"{path}:{n}")

print("\n".join(hits))
expected_fragments = {
    "edge_modules/chat_queue_creation.py",
    "edge_modules/chat_queue_persistence.py",
    "edge_modules/chat_queue_real_user_creation.py",
    "edge_modules/laptop_queue.py",
}
found = {hit.split(":", 1)[0] for hit in hits}
missing = expected_fragments - found
unexpected = found - expected_fragments
assert not missing, {"missing": sorted(missing), "hits": hits}
assert not unexpected, {"unexpected": sorted(unexpected), "hits": hits}
print("PASS: app_jobs insert inventory matches expected producer set")
PY

echo
echo "=== real-user helper lane contract check ==="
python3 - <<'PY' || fail=1
from pathlib import Path

s = Path("edge_modules/chat_queue_real_user_creation.py").read_text()
checks = {
    "real-user helper": "Real-user queued chat creation helper" in s,
    "lane contract marker": "STAGE_5P11R_MODEL_LANE_CONTRACT_BEGIN" in s,
    "queue_lane included": '"queue_lane": routing_decision["queue_lane"]' in s,
    "model_lane included": '"model_lane": routing_decision["model_lane"]' in s,
    "model_tier included": '"model_tier": routing_decision["model_tier"]' in s,
    "routing contract version included": '"routing_contract_version": routing_decision["version"]' in s,
    "app_jobs insert": "INSERT INTO app_jobs" in s,
}
print(checks)
assert all(checks.values()), checks
print("PASS: production real-user app_jobs helper is lane-tagged")
PY

echo
echo "=== synthetic/test producer boundary check ==="
python3 - <<'PY' || fail=1
from pathlib import Path

creation = Path("edge_modules/chat_queue_creation.py").read_text()
persistence = Path("edge_modules/chat_queue_persistence.py").read_text()
laptop_queue = Path("edge_modules/laptop_queue.py").read_text()

checks = {
    "creation synthetic helper": "Synthetic queued-chat job creation helper" in creation,
    "creation refuses non synthetic users": "Stage 5F-8 helper refuses non-synthetic user ids" in creation,
    "creation app_jobs insert": "INSERT INTO app_jobs" in creation,
    "creation no queue_lane today": '"queue_lane"' not in creation,
    "persistence synthetic test only": "synthetic/test-only" in persistence,
    "persistence app_jobs insert": "INSERT INTO app_jobs" in persistence,
    "laptop queue synthetic helpers": "create_synthetic_user" in laptop_queue and "cleanup_synthetic" in laptop_queue,
    "laptop queue test create job": "def create_job(" in laptop_queue and "INSERT INTO app_jobs" in laptop_queue,
}
print(checks)
assert all(checks.values()), checks
print("PASS: remaining no-lane app_jobs producers are synthetic/test support paths")
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
echo "=== no-lane rows after lane contract began check ==="
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
    COALESCE(j.payload_json->>'synthetic', '(missing)') AS synthetic,
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
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12qa-primary-active.txt && grep -Fq "active" /tmp/phase12qa-primary-active.txt && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12qa-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12qa-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12qa-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12qa-small-active.txt
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
  | grep -vF '?? docs/phase-12q-a-no-lane-fallback-requirement-inspection.md' \
  | grep -vF '?? ops/smoke/check-phase-12q-a-no-lane-fallback-requirement-inspection.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12Q-A doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12Q-A no-lane fallback requirement inspection smoke passed"
else
  echo "FAIL: Phase 12Q-A no-lane fallback requirement inspection smoke failed"
fi

[ "$fail" = "0" ]
