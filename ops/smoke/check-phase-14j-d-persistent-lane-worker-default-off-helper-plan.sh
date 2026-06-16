#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-D persistent lane worker default-off helper plan ==="

PHASE="phase-14j-d-persistent-lane-worker-default-off-helper-plan"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-D docs/smoke/runtime files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14j-d-persistent-lane-worker-default-off-helper-plan.md").read_text()

required = [
    "docs/smoke-only implementation plan",
    "This phase does not add runtime helper code",
    "This phase does not implement persistent lane workers",
    "This phase does not change worker registration",
    "This phase does not change scheduler behavior",
    "This phase does not filter the primary worker yet",
    "This phase does not call live model endpoints",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "_phase14j_lane_workers_enabled",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_filter_workers_for_lane",
    "No-Behavior-Change Requirement",
    "Scheduler integration must be a later separate gate",
    "Primary worker filtering must be a later separate gate",
    "Phase 14J-E",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== future helper markers still absent from runtime ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

forbidden = [
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "_phase14j_lane_workers_enabled",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_filter_workers_for_lane",
]

found = [m for m in forbidden if m in text]
if found:
    raise SystemExit("FAIL: future lane helper markers already present in edge_controller.py: " + ", ".join(found))

print("PASS: future lane helper markers remain absent from runtime")
PY

echo
echo "=== existing worker/scheduler surfaces still present ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "select_best_worker_for_job",
    "score_worker_for_job",
    "worker_heartbeat",
    "workers_registry",
    "scheduler_preview",
]

missing = [m for m in required if m not in text]
if missing:
    raise SystemExit("FAIL: missing existing worker/scheduler surfaces: " + ", ".join(missing))

print("PASS: existing worker/scheduler surfaces remain present")
PY

echo
echo "=== router evidence and warmup safety boundaries still preserved ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

forbidden = [
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITE_ENABLED",
    "_phase14i_record_router_shadow_evidence",
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
]

found = [m for m in forbidden if m in text]
if found:
    raise SystemExit("FAIL: router writer markers unexpectedly present: " + ", ".join(found))

required = [
    "_stage5p12l_disabled_manual_warmup_action_blueprint",
    "_stage5p12y_disabled_future_warmup_execution_skeleton",
]

missing = [m for m in required if m not in text]
if missing:
    raise SystemExit("FAIL: expected disabled warmup markers missing: " + ", ".join(missing))

print("PASS: router writer absent and disabled warmup markers still present")
PY

echo
echo "=== changed files limited to Phase 14J-D docs/smoke ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-d-persistent-lane-worker-default-off-helper-plan.md",
    "ops/smoke/check-phase-14j-d-persistent-lane-worker-default-off-helper-plan.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-D docs/smoke")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-d-persistent-lane-worker-default-off-helper-plan.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-D smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-D persistent lane worker default-off helper plan smoke complete ==="
