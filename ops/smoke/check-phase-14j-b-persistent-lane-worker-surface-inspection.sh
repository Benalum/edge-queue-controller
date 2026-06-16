#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14J-B persistent lane worker surface inspection ==="

PHASE="phase-14j-b-persistent-lane-worker-surface-inspection"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "edge_controller.py"; do
  test -f "$f"
done
echo "PASS: required 14J-B docs/smoke/runtime files exist"

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

doc = Path("docs/phase-14j-b-persistent-lane-worker-surface-inspection.md").read_text()

required = [
    "docs/smoke-only implementation surface inspection",
    "This phase does not implement persistent lane workers",
    "This phase does not change worker registration",
    "This phase does not change scheduler behavior",
    "This phase does not filter the primary worker yet",
    "This phase does not call live model endpoints",
    "This phase does not mutate CT101",
    "This phase does not mutate job 23",
    "persistent_lane_workers_not_active",
    "primary_worker_unfiltered",
    "worker_assignment_not_lane_safe",
    "scheduler_lane_awareness_not_proven",
    "fallback_lane_behavior_not_proven",
    "Worker registration surface",
    "Worker heartbeat and status surface",
    "Worker capability metadata surface",
    "Scheduler job selection surface",
    "Worker assignment and dispatch surface",
    "Fallback behavior surface",
    "Primary/default worker filtering surface",
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "No runtime lane behavior should change",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== static worker/scheduler function surface inventory ==="
python3 - <<'PY'
from pathlib import Path
import re

text = Path("edge_controller.py").read_text()
lines = text.splitlines()

def_names = []
for line in lines:
    m = re.match(r"^def\s+([A-Za-z0-9_]+)\s*\(", line)
    if m:
        name = m.group(1)
        lowered = name.lower()
        if any(k in lowered for k in [
            "worker", "queue", "job", "dispatch", "scheduler",
            "schedule", "claim", "assign", "heartbeat", "capab",
            "fallback", "warmup", "lane", "primary"
        ]):
            def_names.append(name)

print(f"matched_function_count={len(def_names)}")
for name in def_names[:80]:
    print(f"surface_def={name}")

if len(def_names) < 5:
    raise SystemExit("FAIL: expected multiple worker/queue/scheduler function surfaces")

print("PASS: static function surface inventory completed")
PY

echo
echo "=== static marker count inventory ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text().lower()

groups = {
    "worker": ["worker", "workers", "worker_id"],
    "registration": ["register", "registration"],
    "heartbeat": ["heartbeat", "last_seen"],
    "queue_job": ["queue", "queued", "job", "jobs"],
    "scheduler_dispatch": ["scheduler", "dispatch", "assign", "claim"],
    "state_filtering": ["stale", "unhealthy", "disabled", "offline"],
    "capabilities": ["capability", "capabilities"],
    "lane_primary": ["lane", "pool", "primary", "default"],
    "fallback": ["fallback"],
    "warmup": ["warmup"],
}

for label, needles in groups.items():
    total = sum(text.count(n.lower()) for n in needles)
    print(f"{label}_marker_count={total}")

required_positive = ["worker", "queue_job", "scheduler_dispatch", "state_filtering", "capabilities"]
for label in required_positive:
    needles = groups[label]
    total = sum(text.count(n.lower()) for n in needles)
    if total <= 0:
        raise SystemExit(f"FAIL: expected positive marker count for {label}")

print("PASS: marker count inventory completed")
PY

echo
echo "=== current safety boundaries still preserved ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

forbidden_new_runtime_markers = [
    "EDGE_PERSISTENT_LANE_WORKERS_ENABLED",
    "_phase14j_persistent_lane_worker_enabled",
    "_phase14j_worker_lane_eligible",
    "_phase14j_filter_primary_worker",
]

found = [m for m in forbidden_new_runtime_markers if m in text]
if found:
    raise SystemExit("FAIL: future lane runtime markers already present in edge_controller.py: " + ", ".join(found))

router_forbidden = [
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITE_ENABLED",
    "_phase14i_record_router_shadow_evidence",
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
]

found_router = [m for m in router_forbidden if m in text]
if found_router:
    raise SystemExit("FAIL: router evidence writer markers unexpectedly present: " + ", ".join(found_router))

print("PASS: future lane helpers and router writer markers remain absent")
PY

echo
echo "=== changed files limited to Phase 14J-B docs/smoke ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14j-b-persistent-lane-worker-surface-inspection.md",
    "ops/smoke/check-phase-14j-b-persistent-lane-worker-surface-inspection.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14J-B docs/smoke")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14j-b-persistent-lane-worker-surface-inspection.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama|ssh|docker|pct)\b")
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live/external command: {stripped}")

if bad:
    raise SystemExit("FAIL: 14J-B smoke contains forbidden live/external behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14J-B persistent lane worker surface inspection smoke complete ==="
