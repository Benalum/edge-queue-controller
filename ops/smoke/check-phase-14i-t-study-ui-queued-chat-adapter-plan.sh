#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-t-study-ui-queued-chat-adapter-plan"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"
STUDY_APP="frontend/study-ui/app.js"

echo "=== Phase 14I-T Study UI queued-chat adapter plan ==="

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
echo "=== exact queued-chat request model verification ==="
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

required_present = {
    "message",
    "chat_id",
    "requested_model",
    "mode",
    "user_id",
    "authenticated_user_id",
}
missing = sorted(required_present - set(fields))
if missing:
    raise SystemExit(f"FAIL: queued-chat request model missing expected fields: {missing}")

for forbidden in ["prompt", "model"]:
    if forbidden in fields:
        raise SystemExit(f"FAIL: queued-chat request model unexpectedly has {forbidden}; update adapter plan")

print("PASS: exact queued-chat request model fields match Phase 14I-T plan")
PY2

echo
echo "=== backend queued-chat route verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
    "request.model_dump(exclude_none=True)",
    'requested_model=guard_payload.get("requested_model") or guard_payload.get("model")',
    '"job_id": queued.job_id',
    '"status": queued.status',
    '"chat_id": queued.chat_id',
    '"user_message_id": queued.user_message_id',
    '"payload_json": queued.payload_json',
    "FROM app_jobs",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing backend queued-chat markers: {missing}")

print("PASS: backend queued-chat route markers match Phase 14I-T plan")
PY2

echo
echo "=== Study UI current pre-migration baseline verification ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("frontend/study-ui/app.js").read_text()

required = [
    "function buildCompanionPrompt(message)",
    "async function sendCompanionToApi(message)",
    "async function pollJob(jobId, pollUrl = \"\")",
    "`${base}/jobs/${jobId}`",
    "`${base}/job/${jobId}`",
    "url: `${base}/jobs`,",
    "body: { job_type: \"ollama_chat\", prompt, requested_model: \"gemma4:e4b\" }",
]

missing = [item for item in required if item not in text]
if missing:
    raise SystemExit(f"FAIL: missing Study UI current baseline markers: {missing}")

if "/api/chat/queued" in text:
    raise SystemExit("FAIL: Study UI already references /api/chat/queued; Phase 14I-T plan needs update")

print("PASS: Study UI current pre-migration direct /jobs baseline verified")
PY2

echo
echo "=== route/helper counts ==="
python3 - <<'PY2'
from pathlib import Path

text = Path("edge_controller.py").read_text()

expected_counts = {
    '@app.post("/jobs")': 1,
    '@app.get("/jobs")': 1,
    '@app.post("/public/jobs")': 1,
    '@app.get("/public/jobs/{job_id}")': 1,
    '@app.get("/public/jobs")': 1,
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
    raise SystemExit(f"FAIL: unexpected route/helper counts: {bad}")

print("PASS: route/helper counts match Phase 14I-T baseline")
PY2

echo
echo "=== documentation markers ==="
python3 - <<'PY2'
from pathlib import Path

doc = Path("docs/phase-14i-t-study-ui-queued-chat-adapter-plan.md").read_text()

required = [
    "Phase 14I-T records the safe frontend adapter plan",
    "`frontend/study-ui/app.js`",
    "`` `${base}/jobs` ``",
    "`` `${base}/jobs/${jobId}` ``",
    "`_S5F9QueuedChatRequest`",
    "`message`",
    "`requested_model`",
    "`prompt`",
    "`model`",
    "the frontend adapter should put the fully built Study companion prompt into `message`",
    "`POST /api/chat/queued`",
    "`GET /api/chat/queued/{job_id}`",
    "`app_jobs`",
    "Do not gate direct `POST /jobs` or `GET /jobs` until the Study UI no longer references direct `/jobs`.",
    "Job 23 is not mutated.",
    "Phase 14I-U may implement a default-preserving Study UI adapter.",
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
echo "=== done: Phase 14I-T adapter plan smoke complete ==="
