#!/usr/bin/env bash
set -euo pipefail

ROOT="${EDGE_QUEUE_CONTROLLER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$ROOT"

PHASE="phase-14i-j-disabled-legacy-local-edge-jobs-retirement-flag-plan"
DOC="docs/${PHASE}.md"
SELF="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-J disabled legacy local Edge jobs retirement flag plan ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SELF"
test -x "$SELF"
echo "PASS: required docs/smoke files exist"

echo
echo "=== checkpoint ==="
git status --short
git log --oneline --decorate -8
git tag --points-at HEAD || true

echo
echo "=== compile ==="
python3 -m py_compile edge_controller.py
echo "PASS: edge_controller.py compiles"

echo
echo "=== static route preservation and retirement candidate markers ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

preserve = [
    '@app.post("/api/chat/queued")',
    '@app.get("/api/chat/queued/{job_id}")',
    "_s5f19_create_real_user_queued_chat_job",
]

legacy = [
    '@app.post("/public/jobs")',
    '@app.get("/public/jobs/{job_id}")',
    '@app.get("/public/jobs")',
    '@app.post("/public/companion/chat")',
    '@app.post("/api/companion/chat")',
    '@app.get("/api/chat/queue/status")',
    '@app.get("/public/chat/queue/status")',
    "def _public_create_ollama_job",
]

missing_preserve = [item for item in preserve if item not in text]
missing_legacy = [item for item in legacy if item not in text]

if missing_preserve:
    raise SystemExit(f"FAIL: missing preserved /api/chat/queued markers: {missing_preserve}")
if missing_legacy:
    raise SystemExit(f"FAIL: missing legacy local jobs markers: {missing_legacy}")

print("PASS: preserved /api/chat/queued markers and legacy retirement candidates found")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-j-disabled-legacy-local-edge-jobs-retirement-flag-plan.md").read_text()

required = [
    "Do not retire `/api/chat/queued`.",
    "EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED",
    "EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED",
    "EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED",
    "EDGE_LEGACY_LOCAL_JOBS_ADMIN_ARCHIVE_ENABLED",
    "Default: `1`",
    "Default: `0`",
    "Do not delete or mutate job 23 yet.",
    "Do not forward job 23 to CT101.",
    "This phase does not change route behavior.",
]

missing = [item for item in required if item not in doc]
if missing:
    raise SystemExit(f"FAIL: missing documentation markers: {missing}")

print("PASS: required documentation markers found")
PY

echo
echo "=== no new runtime flag helpers or route behavior expected yet ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()
unexpected = [
    "EDGE_LEGACY_LOCAL_JOBS_ROUTES_ENABLED",
    "EDGE_LEGACY_COMPANION_LOCAL_JOB_CREATE_ENABLED",
    "EDGE_LEGACY_LOCAL_QUEUE_STATUS_ENABLED",
    "EDGE_LEGACY_LOCAL_JOBS_ADMIN_ARCHIVE_ENABLED",
]
present = [item for item in unexpected if item in text]
if present:
    raise SystemExit(f"FAIL: Phase 14I-J should be docs-only; unexpected runtime markers in edge_controller.py: {present}")

print("PASS: no runtime flag implementation added in docs-only Phase 14I-J")
PY

echo
echo "=== read-only/privacy guard for this smoke script ==="
danger="$(
  grep -RInE 'curl[[:space:]].*(-X|--request)[[:space:]]*(POST|PUT|PATCH|DELETE)|systemctl[[:space:]]+(start|restart|enable|disable|stop)|(^|[[:space:]])(pct|qm)[[:space:]]+(start|stop|reboot|reset|shutdown|set|exec)|ollama[[:space:]]+(run|pull|rm|stop|serve)|/queue/summary|/system/status' "$SELF" 2>/dev/null \
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
echo "=== done: Phase 14I-J flag plan smoke complete ==="
