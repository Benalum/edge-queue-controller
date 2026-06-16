#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-A persistent lane worker re-entry baseline ==="

PHASE="phase-14j-a-persistent-lane-worker-reentry-baseline"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-A docs/smoke/runtime files exist"

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

doc = Path("docs/phase-14j-a-persistent-lane-worker-reentry-baseline.md").read_text()

required = [
    "docs/smoke only",
    "persistent lane worker blocker re-entry",
    "This phase does not implement persistent lane workers",
    "This phase does not change scheduler behavior",
    "This phase does not filter the primary worker yet",
    "This phase does not call live model endpoints",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "persistent_lane_workers_not_active",
    "primary_worker_unfiltered",
    "warmup_execution_disabled",
    "router_rollout_parked",
    "ct101_runtime_protected",
    "worker registration surfaces",
    "job assignment and scheduler surfaces",
    "worker capability filters",
    "Router evidence work is parked",
    "writer helper is not created",
    "runtime persistence is not active",
    "router activation remains parked",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== controller worker/scheduler surface inventory, static and capped ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

groups = {
    "worker": ["worker", "workers", "worker_id"],
    "queue": ["queue", "queued", "job"],
    "scheduler": ["scheduler", "dispatch", "assign", "claim"],
    "health_state": ["stale", "unhealthy", "disabled", "offline", "heartbeat"],
    "lane_terms": ["lane", "pool", "capability", "capabilities", "primary"],
    "warmup": ["warmup"],
}

for label, needles in groups.items():
    total = sum(text.lower().count(n.lower()) for n in needles)
    print(f"{label}_marker_count={total}")

if "worker" not in text.lower():
    raise SystemExit("FAIL: expected worker surface markers in edge_controller.py")
if "job" not in text.lower():
    raise SystemExit("FAIL: expected job surface markers in edge_controller.py")

print("PASS: static worker/scheduler inventory completed")
PY

echo
echo "=== router evidence parked markers ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "_phase14iag_queued_chat_router_shadow_enabled",
    "_phase14iag_queued_chat_router_shadow_decision",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED",
    "_phase14iag_queued_chat_router_shadow_decision(guard_payload)",
]

blocked_runtime_writer = [
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
    "_phase14i_record_router_shadow_evidence",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITE_ENABLED",
]

missing = [m for m in required if m not in text]
found = [m for m in blocked_runtime_writer if m in text]

if missing:
    raise SystemExit("FAIL: missing router shadow parked markers: " + ", ".join(missing))
if found:
    raise SystemExit("FAIL: router evidence writer markers unexpectedly present: " + ", ".join(found))

print("PASS: router evidence remains parked with no runtime writer markers")
PY

echo
echo "=== changed files limited to Phase 14J-A docs/smoke ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-a-persistent-lane-worker-reentry-baseline.md",
    "ops/smoke/check-phase-14j-a-persistent-lane-worker-reentry-baseline.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-A docs/smoke")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-a-persistent-lane-worker-reentry-baseline.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-A smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-A persistent lane worker re-entry baseline smoke complete ==="
