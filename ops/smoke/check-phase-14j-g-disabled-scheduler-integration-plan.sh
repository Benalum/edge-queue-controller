#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-G disabled scheduler integration plan ==="

PHASE="phase-14j-g-disabled-scheduler-integration-plan"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-G docs/smoke/runtime files exist"

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

doc = Path("docs/phase-14j-g-disabled-scheduler-integration-plan.md").read_text()

required = [
    "docs/smoke-only plan",
    "This phase does not change scheduler behavior",
    "This phase does not wire lane helpers into scheduler code",
    "This phase does not filter the primary worker",
    "This phase does not change worker registration",
    "This phase does not call live model endpoints",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "_phase14j_lane_workers_enabled",
    "_phase14j_filter_workers_for_lane",
    "select_best_worker_for_job",
    "score_worker_for_job should not be changed",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "Required No-Behavior-Change Rule",
    "Primary/default worker filtering remains separate",
    "Phase 14J-H",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== helper skeleton markers present ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "_phase14j_lane_workers_enabled",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_filter_workers_for_lane",
]

missing = [m for m in required if m not in text]
if missing:
    raise SystemExit("FAIL: missing Phase 14J-E helper markers: " + ", ".join(missing))

print("PASS: Phase 14J-E helper markers remain present")
PY

echo
echo "=== scheduler surfaces present and still unwired ==="
python3 - <<'PY'
from pathlib import Path
import ast

text = Path("edge_controller.py").read_text()
module = ast.parse(text)

defs = {node.name: node for node in module.body if isinstance(node, ast.FunctionDef)}

required_defs = [
    "select_best_worker_for_job",
    "score_worker_for_job",
    "estimate_job_requirements",
    "scheduler_preview",
]

missing = [name for name in required_defs if name not in defs]
if missing:
    raise SystemExit("FAIL: missing scheduler surfaces: " + ", ".join(missing))

helper_names = [
    "_phase14j_lane_workers_enabled",
    "_phase14j_job_lane_metadata",
    "_phase14j_worker_lane_metadata",
    "_phase14j_worker_eligible_for_job",
    "_phase14j_filter_workers_for_lane",
]

bad = []
for name in required_defs:
    src = ast.get_source_segment(text, defs[name]) or ""
    for helper in helper_names:
        if helper in src:
            bad.append(f"{name}:{helper}")

if bad:
    raise SystemExit("FAIL: scheduler surfaces already reference lane helpers: " + ", ".join(bad))

print("PASS: scheduler surfaces exist and remain unwired")
PY

echo
echo "=== lane helpers still isolated to helper block ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

start_marker = "# Phase 14J-E persistent lane worker default-off helper skeletons."
before, marker, after_marker = text.partition(start_marker)
if not marker:
    raise SystemExit("FAIL: Phase 14J-E helper block marker missing")

helper_body, end_marker, after = after_marker.partition("def _phase14iag_queued_chat_router_shadow_enabled")
if not end_marker:
    raise SystemExit("FAIL: Phase 14J-E helper block boundary missing")

outside = before + "def _phase14iag_queued_chat_router_shadow_enabled" + after

helper_calls = [
    "_phase14j_lane_workers_enabled(",
    "_phase14j_job_lane_metadata(",
    "_phase14j_worker_lane_metadata(",
    "_phase14j_worker_eligible_for_job(",
    "_phase14j_filter_workers_for_lane(",
]

found = [m for m in helper_calls if m in outside]
if found:
    raise SystemExit("FAIL: Phase 14J helper calls found outside helper block: " + ", ".join(found))

print("PASS: Phase 14J helpers remain isolated to helper block")
PY

echo
echo "=== safety boundaries still preserved ==="
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
    raise SystemExit("FAIL: router evidence writer markers unexpectedly present: " + ", ".join(found))

required_disabled = [
    "_stage5p12l_disabled_manual_warmup_action_blueprint",
    "_stage5p12y_disabled_future_warmup_execution_skeleton",
]

missing = [m for m in required_disabled if m not in text]
if missing:
    raise SystemExit("FAIL: disabled warmup markers missing: " + ", ".join(missing))

print("PASS: router writer absent and disabled warmup markers still present")
PY

echo
echo "=== changed files limited to Phase 14J-G docs/smoke ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-g-disabled-scheduler-integration-plan.md",
    "ops/smoke/check-phase-14j-g-disabled-scheduler-integration-plan.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-G docs/smoke")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-g-disabled-scheduler-integration-plan.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-G smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-G disabled scheduler integration plan smoke complete ==="
