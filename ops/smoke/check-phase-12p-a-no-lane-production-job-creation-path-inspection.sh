#!/usr/bin/env bash
set -u

fail=0
CT101="root@100.88.194.19"

echo "=== Phase 12P-A smoke: no-lane production job creation path inspection ==="

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || fail=1

echo
echo "=== local baseline ==="
git status --short
git log --oneline -8
git tag --points-at HEAD

echo
echo "=== doc checks ==="
DOC="docs/phase-12p-a-no-lane-production-job-creation-path-inspection.md"
grep -Fq "Phase 12P-A No-Lane Production Job Creation Path Inspection" "$DOC" && echo "PASS: doc title found" || fail=1
grep -Fq "local jobs table" "$DOC" && echo "PASS: local jobs table correction documented" || fail=1
grep -Fq "Postgres app_jobs" "$DOC" && echo "PASS: app_jobs path documented" || fail=1
grep -Fq "Historical no-lane evidence" "$DOC" && echo "PASS: historical no-lane evidence documented" || fail=1
grep -Fq "Do not immediately patch _public_create_ollama_job" "$DOC" && echo "PASS: patch caution documented" || fail=1

echo
echo "=== source check: direct public helper uses local jobs table ==="
python3 - <<'PY' || fail=1
from pathlib import Path

s = Path("edge_controller.py").read_text()
start = s.index("def _public_create_ollama_job(")
end = s.index("@app.post(\"/public/jobs\")", start)
body = s[start:end]

print(body[:1800])

assert "INSERT INTO jobs" in body, "direct helper should insert into local jobs table"
assert "INSERT INTO app_jobs" not in body, "direct helper unexpectedly inserts into app_jobs"
print("PASS: _public_create_ollama_job writes local jobs, not app_jobs")
PY

echo
echo "=== source check: real-user app_jobs helper is lane-tagged ==="
python3 - <<'PY' || fail=1
from pathlib import Path

s = Path("edge_modules/chat_queue_real_user_creation.py").read_text()
required = [
    "STAGE_5P11R_MODEL_LANE_CONTRACT_BEGIN",
    "stage5p11r_build_model_lane_decision",
    "\"routing_contract_version\": routing_decision[\"version\"]",
    "\"model_tier\": routing_decision[\"model_tier\"]",
    "\"model_lane\": routing_decision[\"model_lane\"]",
    "\"queue_lane\": routing_decision[\"queue_lane\"]",
    "\"model_max_parallel_hint\": routing_decision[\"max_parallel_hint\"]",
    "INSERT INTO app_jobs",
]
missing = [item for item in required if item not in s]
assert not missing, missing
print("PASS: real-user app_jobs helper has lane metadata contract")
PY

echo
echo "=== source check: synthetic app_jobs helper remains synthetic/test path ==="
python3 - <<'PY' || fail=1
from pathlib import Path

s = Path("edge_modules/chat_queue_creation.py").read_text()
assert "Synthetic queued-chat job creation helper" in s
assert "INSERT INTO app_jobs" in s
assert "\"route_source\": \"stage_5f8_synthetic_helper\"" in s
assert "\"queue_lane\"" not in s
print("PASS: synthetic helper is app_jobs-producing and currently no-lane/test-only")
PY

echo
echo "=== controller health and persistent cutover gate ==="
curl -sS --max-time 12 http://127.0.0.1:7070/system/status | python3 -m json.tool >/tmp/phase12pa-system-status.json || fail=1

python3 - <<'PY' || fail=1
import json

data = json.load(open("/tmp/phase12pa-system-status.json"))
worker = next((s for s in data.get("services", []) if s.get("id") == "ct101-laptop-queue-worker"), None)
assert worker, "ct101-laptop-queue-worker missing"
gate = worker.get("persistent_lane_cutover_readiness") or {}

summary = {
    "worker_state": worker.get("state"),
    "gate_source": gate.get("source"),
    "gate_ready": gate.get("ready"),
    "gate_dry_run_only": gate.get("dry_run_only"),
    "gate_reasons": gate.get("reasons"),
}
print(json.dumps(summary, indent=2, sort_keys=True))

assert worker.get("state") == "online", summary
assert gate.get("source") == "stage_5p12o_read_only_persistent_lane_cutover_gate", gate
assert gate.get("dry_run_only") is True, gate
assert gate.get("ready") is False, gate
print("PASS: persistent cutover gate live and safely not ready")
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
    COALESCE(payload_json->>'queue_lane', '(none)') AS queue_lane,
    COALESCE(requested_model, '(none)') AS requested_model,
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
echo "=== historical no-lane app_jobs still present ==="
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
    payload_json->>'route_source' AS route_source,
    payload_json->>'queue_lane' AS queue_lane,
    payload_json->>'model_tier' AS model_tier,
    payload_json->>'model_lane' AS model_lane,
    created_at
  FROM app_jobs
  WHERE job_type = 'ollama_chat'
    AND COALESCE(payload_json->>'queue_lane', '') = ''
  ORDER BY created_at DESC NULLS LAST, id DESC
  LIMIT 10
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
assert rows, "expected historical no-lane app_jobs rows"
assert any(row.get("requested_model") == "gemma4:e4b" for row in rows), rows
print("PASS: historical no-lane app_jobs rows remain detectable")
PY

echo
echo "=== recent lane-tagged app_jobs proof ==="
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
    payload_json->>'route_source' AS route_source,
    payload_json->>'queue_lane' AS queue_lane,
    payload_json->>'model_tier' AS model_tier,
    payload_json->>'model_lane' AS model_lane,
    payload_json->>'routing_contract_version' AS routing_contract_version,
    assigned_worker_id,
    created_at
  FROM app_jobs
  WHERE job_type = 'ollama_chat'
    AND COALESCE(payload_json->>'queue_lane', '') != ''
  ORDER BY created_at DESC NULLS LAST, id DESC
  LIMIT 10
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
assert any(row.get("id") == "s5f18-job-c57e61463dfd7e39" for row in rows), rows
assert any(row.get("queue_lane") == "model-tiny" for row in rows), rows
assert any(row.get("queue_lane") == "model-small" for row in rows), rows
print("PASS: recent lane-tagged app_jobs proof exists")
PY

echo
echo "=== CT101 service safety state ==="
ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker.service' >/tmp/phase12pa-primary-active.txt && grep -Fq "active" /tmp/phase12pa-primary-active.txt && echo "PASS: primary worker active" || fail=1

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-tiny.service' >/tmp/phase12pa-tiny-active.txt 2>/dev/null; then
  echo "FAIL: tiny lane service active unexpectedly"
  cat /tmp/phase12pa-tiny-active.txt
  fail=1
else
  echo "PASS: tiny lane service inactive"
fi

if ssh "$CT101" 'pct exec 101 -- systemctl is-active ai-platform-laptop-queue-worker@model-small.service' >/tmp/phase12pa-small-active.txt 2>/dev/null; then
  echo "FAIL: small lane service active unexpectedly"
  cat /tmp/phase12pa-small-active.txt
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
  | grep -vF '?? docs/phase-12p-a-no-lane-production-job-creation-path-inspection.md' \
  | grep -vF '?? ops/smoke/check-phase-12p-a-no-lane-production-job-creation-path-inspection.sh' || true)"
git status --short

if [ -n "$bad_status" ]; then
  echo "FAIL: unexpected local changed files"
  echo "$bad_status"
  fail=1
else
  echo "PASS: only Phase 12P-A doc/smoke files changed"
fi

echo
if [ "$fail" = "0" ]; then
  echo "PASS: Phase 12P-A no-lane production job creation path inspection smoke passed"
else
  echo "FAIL: Phase 12P-A no-lane production job creation path inspection smoke failed"
fi

[ "$fail" = "0" ]
