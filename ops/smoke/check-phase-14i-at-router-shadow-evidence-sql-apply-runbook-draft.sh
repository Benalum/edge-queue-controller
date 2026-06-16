#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
SQL="ops/db/laptop-app-schema-v3-router-shadow-evidence.sql"
FUTURE_APPLY="ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh"

echo "=== Phase 14I-AT router shadow evidence SQL apply runbook draft ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SMOKE"
test -f "$SQL"
echo "PASS: required docs/smoke and existing SQL artifact files exist"

echo
echo "=== existing apply/backup/restore surfaces exist ==="
test -f ops/db/apply-laptop-app-schema.sh
test -f ops/db/apply-laptop-app-schema-v2-chat-source-job-id.sh
test -f ops/db/backup-laptop-postgres.sh
test -f ops/db/restore-laptop-postgres.sh
test -f ops/db/verify-laptop-postgres-restore-drill.sh
echo "PASS: existing apply/backup/restore surfaces found"

echo
echo "=== future apply wrapper must not exist in this phase ==="
test ! -f "$FUTURE_APPLY"
echo "PASS: future apply wrapper has not been created"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
path = Path("edge_controller.py")
compile(path.read_text(), str(path), "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== SQL artifact still has expected markers ==="
python3 - <<'PY'
from pathlib import Path

sql = Path("ops/db/laptop-app-schema-v3-router-shadow-evidence.sql").read_text()

required = [
    "CREATE TABLE IF NOT EXISTS queued_chat_router_shadow_evidence",
    "INSERT INTO app_schema_migrations",
    "stage-14i-router-shadow-evidence",
    "ON CONFLICT (version) DO NOTHING",
    "COMMIT;",
]

missing = [marker for marker in required if marker not in sql]
if missing:
    raise SystemExit("FAIL: missing SQL artifact markers: " + ", ".join(missing))

print("PASS: SQL artifact markers still present")
PY

echo
echo "=== runbook documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md").read_text()

required = [
    "It does not apply a database migration.",
    "It does not call `psql`.",
    "It does not source database environment files.",
    "It does not read database secrets.",
    "It does not touch the database.",
    "It does not create an apply script.",
    "It does not add a writer.",
    "It does not change runtime behavior.",
    "It does not expose router shadow output to the browser.",
    "ops/db/laptop-app-schema-v3-router-shadow-evidence.sql",
    "ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh",
    "Existing Apply Pattern",
    "Candidate Future Apply Wrapper",
    "Candidate Future Apply Command Shape",
    "Future Apply Output Rules",
    "Future Verification Queries",
    "Apply Stop Conditions",
    "Writer Separation Rule",
    "Router Activation Separation Rule",
    "Phase 14I-AT Validation Scope",
]

missing = [marker for marker in required if marker not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: runbook documentation markers verified")
PY

echo
echo "=== no runtime writer or route implementation introduced outside allowed existing artifact ==="
python3 - <<'PY'
from pathlib import Path

allowed = {
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
    "docs",
}

hits = []

for path in Path(".").rglob("*"):
    if not path.is_file():
        continue

    rel = path.as_posix()
    if rel in allowed:
        continue
    if rel.startswith("ops/smoke/"):
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
    raise SystemExit("FAIL: writer/runtime marker found outside allowed existing artifact:\n" + "\n".join(hits))

print("PASS: no runtime writer or route implementation markers found outside allowed existing artifact")
PY

echo
echo "=== changed files limited to Phase 14I-AT ==="
python3 - <<'PY'
import subprocess

expected = {
    "docs/phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.md",
    "ops/smoke/check-phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.sh",
}

status = subprocess.check_output(["git", "status", "--short"], text=True)
unexpected = []

for line in status.splitlines():
    path = line[3:] if len(line) > 3 else line
    if path not in expected:
        unexpected.append(line)

if unexpected:
    raise SystemExit("FAIL: unexpected changed files for Phase 14I-AT:\n" + "\n".join(unexpected))

print("PASS: changed files are limited to Phase 14I-AT docs/smoke")
PY

echo
echo "=== read-only/privacy guard for this smoke script ==="
python3 - <<'PY'
from pathlib import Path

smoke = Path("ops/smoke/check-phase-14i-at-router-shadow-evidence-sql-apply-runbook-draft.sh").read_text()

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
echo "=== done: Phase 14I-AT router shadow evidence SQL apply runbook draft smoke complete ==="
