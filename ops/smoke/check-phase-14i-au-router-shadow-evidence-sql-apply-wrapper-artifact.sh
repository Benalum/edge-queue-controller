#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14i-au-router-shadow-evidence-sql-apply-wrapper-artifact"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
SQL="ops/db/laptop-app-schema-v3-router-shadow-evidence.sql"
APPLY="ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh"

echo "=== Phase 14I-AU router shadow evidence SQL apply wrapper artifact ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SMOKE"
test -f "$SQL"
test -f "$APPLY"
test -x "$APPLY"
echo "PASS: required apply/docs/smoke and existing SQL artifact files exist"

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
echo "=== apply wrapper static markers and safety gates ==="
python3 - <<'PY'
from pathlib import Path

apply = Path("ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh").read_text()

required = [
    "REQUIRED_CONFIRM=\"APPLY_ROUTER_SHADOW_EVIDENCE_SCHEMA\"",
    "SCHEMA_FILE=\"ops/db/laptop-app-schema-v3-router-shadow-evidence.sql\"",
    "BACKUP_SCRIPT=\"ops/db/backup-laptop-postgres.sh\"",
    "RESTORE_SCRIPT=\"ops/db/restore-laptop-postgres.sh\"",
    "RESTORE_DRILL_SCRIPT=\"ops/db/verify-laptop-postgres-restore-drill.sh\"",
    "DATABASE_URL is not set",
    "Secrets: not printed",
    "bash \"$BACKUP_SCRIPT\"",
    "queued_chat_router_shadow_evidence",
    "stage-14i-router-shadow-evidence",
]

required.append("ps" + "ql \"$DATABASE_URL\"")

missing = [marker for marker in required if marker not in apply]
if missing:
    raise SystemExit("FAIL: missing apply wrapper markers: " + ", ".join(missing))

blocked = [
    "set -x",
    "echo \"$DATABASE_URL\"",
    "echo ${DATABASE_URL",
    "printenv",
    "env |",
    "cat \"$ENV_FILE\"",
    "cat $ENV_FILE",
]

found = [marker for marker in blocked if marker in apply]
if found:
    raise SystemExit("FAIL: apply wrapper contains unsafe secret-output marker(s): " + ", ".join(found))

confirm_idx = apply.find("REQUIRED_CONFIRM=\"APPLY_ROUTER_SHADOW_EVIDENCE_SCHEMA\"")
psql_idx = apply.find("ps" + "ql \"$DATABASE_URL\"")
backup_idx = apply.find("bash \"$BACKUP_SCRIPT\"")

if confirm_idx < 0 or psql_idx < 0 or backup_idx < 0:
    raise SystemExit("FAIL: cannot verify confirm/backup/apply ordering")

if not (confirm_idx < backup_idx < psql_idx):
    raise SystemExit("FAIL: apply wrapper ordering should require confirm, then backup, then psql apply")

print("PASS: apply wrapper static markers and safety gates verified")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-au-router-shadow-evidence-sql-apply-wrapper-artifact.md").read_text()

required = [
    "This phase does not run the apply wrapper.",
    "This phase does not apply a database migration.",
    "This phase does not call `psql`.",
    "This phase does not source database environment files.",
    "This phase does not read database secrets.",
    "This phase does not touch the database.",
    "This phase does not add a writer.",
    "This phase does not change runtime behavior.",
    "ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh",
    "APPLY_ROUTER_SHADOW_EVIDENCE_SCHEMA",
    "Safety Boundary",
    "Future Apply Behavior",
    "Future Apply Stop Conditions",
    "Writer Separation Rule",
    "Prior Smoke Note",
    "Phase 14I-AU Validation Scope",
]

missing = [marker for marker in required if marker not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== no runtime writer or route implementation introduced outside allowed artifacts ==="
python3 - <<'PY'
from pathlib import Path

allowed = {
    "ops/db/laptop-app-schema-v3-router-shadow-evidence.sql",
    "ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh",
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
    raise SystemExit("FAIL: writer/runtime marker found outside allowed artifacts:\n" + "\n".join(hits))

print("PASS: no runtime writer or route implementation markers found outside allowed artifacts")
PY

echo
echo "=== changed files limited to Phase 14I-AU ==="
python3 - <<'PY'
import subprocess

expected = {
    "docs/phase-14i-au-router-shadow-evidence-sql-apply-wrapper-artifact.md",
    "ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh",
    "ops/smoke/check-phase-14i-au-router-shadow-evidence-sql-apply-wrapper-artifact.sh",
}

status = subprocess.check_output(["git", "status", "--short"], text=True)
unexpected = []

for line in status.splitlines():
    path = line[3:] if len(line) > 3 else line
    if path not in expected:
        unexpected.append(line)

if unexpected:
    raise SystemExit("FAIL: unexpected changed files for Phase 14I-AU:\n" + "\n".join(unexpected))

print("PASS: changed files are limited to Phase 14I-AU apply/docs/smoke")
PY

echo
echo "=== read-only/privacy guard for this smoke script ==="
python3 - <<'PY2'
from pathlib import Path

smoke = Path("ops/smoke/check-phase-14i-au-router-shadow-evidence-sql-apply-wrapper-artifact.sh").read_text()

# This smoke statically verifies that the future apply wrapper contains the
# expected database apply command. Therefore, the guard must reject executable
# live operations in the smoke itself without rejecting quoted/static marker
# strings used by the validator.
forbidden_shell_starts = [
    "cu" + "rl ",
    "ps" + "ql ",
    "sql" + "ite3 ",
]

forbidden_substrings = [
    "requests" + ".",
    "http" + "://",
    "https" + "://",
    "Author" + "ization:",
    "Cook" + "ie:",
    "Bear" + "er ",
]

hits = []

for lineno, line in enumerate(smoke.splitlines(), start=1):
    stripped = line.strip()

    if not stripped:
        continue

    # Ignore comments and quoted/static marker lines.
    if stripped.startswith("#") or stripped.startswith('"') or stripped.startswith("'"):
        continue

    for item in forbidden_shell_starts:
        if stripped.startswith(item):
            hits.append(f"line {lineno}: {item.strip()}")

    for item in forbidden_substrings:
        if item in stripped:
            hits.append(f"line {lineno}: {item}")

if hits:
    raise SystemExit("FAIL: smoke contains forbidden live/secret-bearing operation markers:\n" + "\n".join(hits))

print("PASS: read-only/privacy guard passed")
PY2

echo
echo "=== done: Phase 14I-AU router shadow evidence SQL apply wrapper artifact smoke complete ==="
