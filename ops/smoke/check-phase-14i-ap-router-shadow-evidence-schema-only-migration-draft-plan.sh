#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14i-ap-router-shadow-evidence-schema-only-migration-draft-plan"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo "=== Phase 14I-AP router shadow evidence schema-only migration draft plan ==="

echo
echo "=== required files ==="
test -f "$DOC"
test -f "$SMOKE"
echo "PASS: required docs/smoke files exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
path = Path("edge_controller.py")
compile(path.read_text(), str(path), "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== schema-only draft documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-ap-router-shadow-evidence-schema-only-migration-draft-plan.md").read_text()

required = [
    "It does not apply a database migration.",
    "It does not add a migration file.",
    "It does not add SQL.",
    "It does not add executable schema code.",
    "It does not add a writer.",
    "It does not change runtime behavior.",
    "It does not expose router shadow output to the browser.",
    "It does not persist router shadow evidence.",
    "It does not enable router model selection.",
    "ops/db/laptop-app-schema-v3-router-shadow-evidence.sql",
    "stage-14i-router-shadow-evidence",
    "queued_chat_router_shadow_evidence",
    "Candidate Future Column Groups",
    "Blocked Fields",
    "Candidate Future Index Strategy",
    "Future Migration Apply Boundary",
    "Future Writer Boundary",
    "Backup and Rollback Requirement",
    "Phase 14I-AP Validation Scope",
]

missing = [marker for marker in required if marker not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

blocked = [
    "CREATE TABLE",
    "INSERT INTO",
    "ALTER TABLE",
    "DROP TABLE",
    "BEGIN;",
    "COMMIT;",
]

found = [marker for marker in blocked if marker in doc]
if found:
    raise SystemExit("FAIL: doc contains executable SQL instead of a schema-only draft plan: " + ", ".join(found))

print("PASS: schema-only draft documentation markers verified")
PY

echo
echo "=== no runtime/schema implementation introduced outside docs/smoke ==="
python3 - <<'PY'
from pathlib import Path

markers = [
    "queued_chat_router_shadow_evidence",
    "router_shadow_evidence_table",
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
    "shadow_evidence_writer",
    "stage-14i-router-shadow-evidence",
]

skip_dirs = {
    ".git",
    "__pycache__",
    ".pytest_cache",
    "docs",
}

allowed_prefixes = (
    "ops/smoke/",
)

hits = []

for path in Path(".").rglob("*"):
    if not path.is_file():
        continue

    parts = set(path.parts)
    if parts & skip_dirs:
        continue

    rel = path.as_posix()
    if rel.startswith(allowed_prefixes):
        continue

    if path.suffix not in {".py", ".sql", ".js", ".jsx", ".ts", ".tsx", ".sh", ".service", ".timer"}:
        continue

    text = path.read_text(errors="ignore")
    for marker in markers:
        if marker in text:
            hits.append(f"{rel}: {marker}")

if hits:
    raise SystemExit("FAIL: runtime/schema implementation marker found outside docs/smoke:\n" + "\n".join(hits))

print("PASS: no runtime/schema implementation markers found outside docs/smoke")
PY

echo
echo "=== no migration or sql files added in this phase ==="
python3 - <<'PY'
import subprocess

expected = {
    "docs/phase-14i-ap-router-shadow-evidence-schema-only-migration-draft-plan.md",
    "ops/smoke/check-phase-14i-ap-router-shadow-evidence-schema-only-migration-draft-plan.sh",
}

status = subprocess.check_output(["git", "status", "--short"], text=True)
unexpected = []

for line in status.splitlines():
    path = line[3:] if len(line) > 3 else line
    lowered = path.lower()

    if path not in expected:
        unexpected.append(line)

    if path not in expected and (
        lowered.endswith(".sql")
        or "/migration" in lowered
        or "migrations/" in lowered
        or "alembic" in lowered
        or "schema-v3" in lowered
    ):
        unexpected.append(line)

if unexpected:
    raise SystemExit("FAIL: unexpected changed files for docs/smoke-only phase:\n" + "\n".join(unexpected))

print("PASS: changed files are limited to Phase 14I-AP docs/smoke")
PY

echo
echo "=== read-only/privacy guard for this smoke script ==="
python3 - <<'PY'
from pathlib import Path

smoke = Path("ops/smoke/check-phase-14i-ap-router-shadow-evidence-schema-only-migration-draft-plan.sh").read_text()

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
echo "=== done: Phase 14I-AP router shadow evidence schema-only migration draft plan smoke complete ==="
