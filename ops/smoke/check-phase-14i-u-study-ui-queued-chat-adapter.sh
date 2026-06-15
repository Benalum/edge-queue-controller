#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-u-study-ui-queued-chat-adapter"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-U Study UI queued-chat adapter ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
test -f "$STUDY_APP"
echo "PASS: required docs/smoke/frontend files exist"

echo
echo "=== checkpoint ==="
git status --short
git log --oneline --decorate -10
git tag --points-at HEAD || true

echo
echo "=== compile and frontend syntax ==="
python3 -m py_compile edge_controller.py
if command -v node >/dev/null 2>&1; then
  node --check "$STUDY_APP"
else
  echo "WARN: node not found; skipped frontend syntax check"
fi
echo "PASS: compile/frontend syntax check complete"

echo
echo "=== Study UI queued-chat adapter verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "PHASE_14I_U_STUDY_UI_QUEUED_CHAT_ADAPTER",
    "url: `${base}/chat/queued`,",
    "body: { message: prompt, requested_model: \"gemma4:e4b\" }",
    "url: `${base}/jobs`,",
    "body: { job_type: \"ollama_chat\", prompt, requested_model: \"gemma4:e4b\" }",
    "`${base}/chat/queued/${encodeURIComponent(jobId)}`",
    "`${base}/jobs/${jobId}`",
    "`${base}/job/${jobId}`",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing Study UI adapter markers: {missing}")

submit_idx = text.index("url: `${base}/chat/queued`,")
legacy_submit_idx = text.index("url: `${base}/jobs`,")
if submit_idx > legacy_submit_idx:
    raise SystemExit("FAIL: queued-chat submit must come before legacy /jobs fallback")

poll_idx = text.index("`${base}/chat/queued/${encodeURIComponent(jobId)}`")
legacy_poll_idx = text.index("`${base}/jobs/${jobId}`")
if poll_idx > legacy_poll_idx:
    raise SystemExit("FAIL: queued-chat poll fallback must come before legacy /jobs poll fallback")

print("PASS: Study UI queued-chat adapter and legacy fallback order verified")
PY2

echo
echo "=== backend route preservation verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
    '@app.post("/jobs")',
    '@app.get("/jobs")',
    '@app.post("/public/jobs")',
    '@app.get("/public/jobs/{job_id}")',
    '@app.get("/public/jobs")',
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing backend route markers: {missing}")

expected_counts = {
    '@app.post("/jobs")': 1,
    '@app.get("/jobs")': 1,
    '@app.post("/api/chat/queued")': 1,
    '@app.get("/api/chat/queued/{job_id}")': 1,
    "_phase14ik_legacy_local_jobs_routes_enabled(": 4,
    "_public_create_ollama_job(": 3,
}
bad = {}
for marker, expected in expected_counts.items():
    actual = text.count(marker)
    if actual != expected:
        bad[marker] = {"expected": expected, "actual": actual}
if bad:
    raise SystemExit(f"FAIL: unexpected backend route/helper counts: {bad}")

print("PASS: backend routes preserved and direct /jobs not gated")
PY2

echo
echo "=== exact queued-chat request model compatibility ==="
python3 - <<'PY2'
from pathlib import Path
import ast

text = Path("edge_controller.py").read_text()
tree = ast.parse(text)

fields = {}
for node in ast.walk(tree):
    if isinstance(node, ast.ClassDef) and node.name == "_S5F9QueuedChatRequest":
        for stmt in node.body:
            if isinstance(stmt, ast.AnnAssign) and isinstance(stmt.target, ast.Name):
                fields[stmt.target.id] = ast.unparse(stmt.annotation)

for required in ["message", "requested_model"]:
    if required not in fields:
        raise SystemExit(f"FAIL: queued-chat request model missing {required}")

for forbidden in ["prompt", "model"]:
    if forbidden in fields:
        raise SystemExit(f"FAIL: queued-chat request model unexpectedly has {forbidden}; update adapter")

print("PASS: queued-chat adapter body matches exact backend request model")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-u-study-ui-queued-chat-adapter.md").read_text()

required = [
    "Phase 14I-U implements the default-preserving Study UI queued-chat adapter",
    "`frontend/study-ui/app.js`",
    "`` `${base}/chat/queued` ``",
    "`message: prompt`",
    "`requested_model: \"gemma4:e4b\"`",
    "`` `${base}/jobs` ``",
    "`` `${base}/chat/queued/${encodeURIComponent(jobId)}` ``",
    "Phase 14I-U does not gate direct `/jobs`.",
    "Job 23 is not mutated.",
]
missing = [item for item in required if item not in doc]
if missing:
    raise SystemExit(f"FAIL: missing documentation markers: {missing}")

print("PASS: required documentation markers found")
PY2

echo
echo "=== read-only/privacy guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|curl[[:space:]].*/queue/summary|curl[[:space:]].*/system/status|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
model_danger="$(
  grep -RInE 'curl.*(/api/generate|/api/chat|/admin/model-warmup)' "$SELF" 2>/dev/null \
    | grep -v 'grep -RInE' || true
)"
if [ -n "$danger" ] || [ -n "$model_danger" ]; then
  [ -n "$danger" ] && echo "$danger"
  [ -n "$model_danger" ] && echo "$model_danger"
  echo "FAIL: smoke script contains mutation, model execution, or live queue dump pattern"
  exit 1
fi
echo "PASS: read-only/privacy guard passed"

echo
echo "=== done: Phase 14I-U Study UI queued-chat adapter smoke complete ==="
