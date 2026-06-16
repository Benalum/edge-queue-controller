#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14I-AW router shadow evidence controlled DB apply ==="

PHASE="phase-14i-aw-router-shadow-evidence-controlled-db-apply"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
SQL="ops/db/laptop-app-schema-v3-router-shadow-evidence.sql"
APPLY="ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$SQL" "$APPLY"; do
  test -f "$f"
done
echo "PASS: required AW docs/smoke and existing SQL/apply artifacts exist"

echo
echo "=== in-memory runtime syntax check ==="
python3 - <<'PY'
from pathlib import Path
compile(Path("edge_controller.py").read_text(), "edge_controller.py", "exec")
print("PASS: edge_controller.py syntax compiles in memory")
PY

echo
echo "=== SQL artifact still has expected markers ==="
python3 - <<'PY'
from pathlib import Path

sql = Path("ops/db/laptop-app-schema-v3-router-shadow-evidence.sql").read_text()

required = [
    "CREATE TABLE IF NOT EXISTS queued_chat_router_shadow_evidence",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_created_at",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_related_job_id",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_request_surface",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_policy_status",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_writer_gate_enabled",
]

blocked = [
    "raw_prompt",
    "raw_message",
    "raw_messages",
    "raw_request_body",
    "request_body",
    "queue_payload",
    "full_job_payload",
    "cookie",
    "bearer",
    "auth_header",
    "password",
    "secret",
]

missing = [m for m in required if m not in sql]
bad = [m for m in blocked if m.lower() in sql.lower()]

if missing:
    raise SystemExit("FAIL: missing SQL markers: " + ", ".join(missing))
if bad:
    raise SystemExit("FAIL: blocked privacy markers found in SQL: " + ", ".join(bad))

print("PASS: SQL artifact markers and blocked-field checks passed")
PY

echo
echo "=== apply wrapper still gated and backup-first ==="
python3 - <<'PY'
from pathlib import Path

text = Path("ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh").read_text()

required = [
    "REQUIRED_CONFIRM",
    "backup-laptop-postgres.sh",
    "restore-laptop-postgres.sh",
    "verify-laptop-postgres-restore-drill.sh",
    "ON_ERROR_STOP=1",
    "table_exists",
    "marker_exists",
]

missing = [m for m in required if m not in text]
if missing:
    raise SystemExit("FAIL: missing apply wrapper markers: " + ", ".join(missing))

backup_pos = text.find("backup-laptop-postgres.sh")
psql_pos = text.find("psql")
if backup_pos == -1 or psql_pos == -1 or backup_pos > psql_pos:
    raise SystemExit("FAIL: backup marker must appear before first psql marker")

print("PASS: apply wrapper markers and backup-before-apply ordering verified")
PY

echo
echo "=== documentation markers ==="
python3 - <<'PY'
from pathlib import Path

doc = Path("docs/phase-14i-aw-router-shadow-evidence-controlled-db-apply.md").read_text()

required = [
    "controlled database apply",
    "backup created successfully",
    "schema applied inside a transaction",
    "queued_chat_router_shadow_evidence",
    "migration marker exists",
    "safe count-only row state was `0`",
    "No runtime writer exists",
    "No runtime persistence exists",
    "No browser exposure exists",
    "Router model selection remains disabled",
    "Writer creation remains a separate future gate",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== no runtime writer implementation introduced ==="
python3 - <<'PY'
from pathlib import Path

blocked_runtime_markers = [
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
]

text = Path("edge_controller.py").read_text()
found = [m for m in blocked_runtime_markers if m in text]
if found:
    raise SystemExit("FAIL: runtime writer markers found in edge_controller.py: " + ", ".join(found))

print("PASS: no runtime writer implementation markers found in edge_controller.py")
PY

echo
echo "=== changed files limited to Phase 14I-AW docs/smoke ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14i-aw-router-shadow-evidence-controlled-db-apply.md",
    "ops/smoke/check-phase-14i-aw-router-shadow-evidence-controlled-db-apply.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14I-AW docs/smoke")
PY

echo
echo "=== read-only/privacy guard for this smoke script ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14i-aw-router-shadow-evidence-controlled-db-apply.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama)\b")
apply_exec = "bash " + '"$APPLY"'
confirm_env = "APC_" + "CONFIRM"

bad = []
for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live command: {stripped}")
    if apply_exec in line:
        bad.append(f"line {lineno}: apply wrapper execution")
    if confirm_env in line:
        bad.append(f"line {lineno}: confirmation env usage")

if bad:
    raise SystemExit("FAIL: AW smoke contains forbidden live/apply behavior:\n" + "\n".join(bad))

print("PASS: read-only/privacy guard passed")
PY

echo
echo "=== done: Phase 14I-AW router shadow evidence controlled DB apply smoke complete ==="
