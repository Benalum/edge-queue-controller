#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14i-ar-router-shadow-evidence-schema-only-sql-artifact"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
SQL="ops/db/laptop-app-schema-v3-router-shadow-evidence.sql"

echo "=== Phase 14I-AR router shadow evidence schema-only SQL artifact ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SMOKE"
test -f "$SQL"
echo "PASS: required SQL/docs/smoke files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
path = Path("edge_controller.py")
compile(path.read_text(), str(path), "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== SQL artifact markers ==="
python3 - <<'PY'
from pathlib import Path

sql = Path("ops/db/laptop-app-schema-v3-router-shadow-evidence.sql").read_text()

required = [
    "BEGIN;",
    "CREATE TABLE IF NOT EXISTS queued_chat_router_shadow_evidence",
    "evidence_id TEXT PRIMARY KEY",
    "created_at TIMESTAMPTZ NOT NULL DEFAULT now()",
    "related_job_id TEXT",
    "router_policy_version TEXT NOT NULL DEFAULT 'unknown'",
    "router_decision_status TEXT NOT NULL DEFAULT 'not_recorded'",
    "decision_confidence NUMERIC(5,4)",
    "browser_exposed BOOLEAN NOT NULL DEFAULT FALSE",
    "evidence_persisted_by_writer BOOLEAN NOT NULL DEFAULT FALSE",
    "route_behavior_changed BOOLEAN NOT NULL DEFAULT FALSE",
    "writer_gate_name TEXT NOT NULL DEFAULT 'EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITER_ENABLED'",
    "writer_gate_enabled BOOLEAN NOT NULL DEFAULT FALSE",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_created_at",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_related_job_id",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_request_surface",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_policy_status",
    "INSERT INTO app_schema_migrations",
    "stage-14i-router-shadow-evidence",
    "ON CONFLICT (version) DO NOTHING",
    "COMMIT;",
]

missing = [marker for marker in required if marker not in sql]
if missing:
    raise SystemExit("FAIL: missing SQL markers: " + ", ".join(missing))

blocked = [
    "prompt_text",
    "raw_prompt",
    "message_text",
    "raw_message",
    "context_text",
    "raw_context",
    "request_body",
    "raw_request",
    "queue_summary",
    "cookie",
    "auth_header",
    "bearer",
    "session_token",
    "secret",
    "payload_json",
    "full_payload",
    "router_trace",
    "model_response",
]

lowered = sql.lower()
found = [marker for marker in blocked if marker in lowered]
if found:
    raise SystemExit("FAIL: SQL contains blocked unsafe storage marker(s): " + ", ".join(found))

print("PASS: SQL artifact markers and blocked-field checks passed")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-ar-router-shadow-evidence-schema-only-sql-artifact.md").read_text()

required = [
    "This phase does not apply a database migration.",
    "This phase does not call `psql`.",
    "This phase does not add a writer.",
    "This phase does not change runtime behavior.",
    "This phase does not expose router shadow output to the browser.",
    "This phase does not persist router shadow evidence at runtime.",
    "ops/db/laptop-app-schema-v3-router-shadow-evidence.sql",
    "queued_chat_router_shadow_evidence",
    "stage-14i-router-shadow-evidence",
    "Writer Separation Rule",
    "Apply Separation Rule",
    "Prior Smoke Note",
    "Phase 14I-AR Validation Scope",
]

missing = [marker for marker in required if marker not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== no runtime writer or route implementation introduced outside allowed phase files ==="
python3 - <<'PY'
from pathlib import Path

allowed = {
    "docs/phase-14i-ar-router-shadow-evidence-schema-only-sql-artifact.md",
    "ops/smoke/check-phase-14i-ar-router-shadow-evidence-schema-only-sql-artifact.sh",
    "ops/db/laptop-app-schema-v3-router-shadow-evidence.sql",
}

markers = [
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
    "shadow_evidence_writer",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITER_ENABLED",
]

skip_dirs = {
    ".git",
    "__pycache__",
    ".pytest_cache",
}

hits = []

for path in Path(".").rglob("*"):
    if not path.is_file():
        continue

    rel = path.as_posix()
    if rel in allowed:
        continue

    if rel.startswith("docs/") or rel.startswith("ops/smoke/"):
        continue

    parts = set(path.parts)
    if parts & skip_dirs:
        continue

    if path.suffix not in {".py", ".sql", ".js", ".jsx", ".ts", ".tsx", ".sh", ".service", ".timer"}:
        continue

    text = path.read_text(errors="ignore")
    for marker in markers:
        if marker in text:
            hits.append(f"{rel}: {marker}")

if hits:
    raise SystemExit("FAIL: writer/runtime marker found outside allowed phase files:\n" + "\n".join(hits))

print("PASS: no runtime writer or route implementation markers found outside allowed phase files")
PY

echo
echo "=== changed files limited to Phase 14I-AR ==="
python3 - <<'PY'
import subprocess

expected = {
    "docs/phase-14i-ar-router-shadow-evidence-schema-only-sql-artifact.md",
    "ops/smoke/check-phase-14i-ar-router-shadow-evidence-schema-only-sql-artifact.sh",
    "ops/db/laptop-app-schema-v3-router-shadow-evidence.sql",
}

status = subprocess.check_output(["git", "status", "--short"], text=True)
unexpected = []

for line in status.splitlines():
    path = line[3:] if len(line) > 3 else line
    if path not in expected:
        unexpected.append(line)

if unexpected:
    raise SystemExit("FAIL: unexpected changed files for Phase 14I-AR:\n" + "\n".join(unexpected))

print("PASS: changed files are limited to Phase 14I-AR SQL/docs/smoke")
PY

echo
echo "=== read-only/privacy guard for this smoke script ==="
python3 - <<'PY'
from pathlib import Path

smoke = Path("ops/smoke/check-phase-14i-ar-router-shadow-evidence-schema-only-sql-artifact.sh").read_text()

forbidden = [
    "cu" + "rl ",
    "ps" + "ql ",
    "sql" + "ite3 ",
    "requests" + ".",
    "http" + "://",
    "https" + "://",
    "Author" + "ization:",
    "Cook" + "ie:",
    "Bear" + "er ",
]

hits = [item for item in forbidden if item in smoke]
if hits:
    raise SystemExit("FAIL: smoke contains forbidden live/secret-bearing operation markers: " + ", ".join(hits))

print("PASS: read-only/privacy guard passed")
PY

echo
echo "=== done: Phase 14I-AR router shadow evidence schema-only SQL artifact smoke complete ==="
