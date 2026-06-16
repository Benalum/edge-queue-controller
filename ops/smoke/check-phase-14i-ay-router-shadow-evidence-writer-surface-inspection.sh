#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 14I-AY router shadow evidence writer surface inspection ==="

PHASE="phase-14i-ay-router-shadow-evidence-writer-surface-inspection"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
SQL="ops/db/laptop-app-schema-v3-router-shadow-evidence.sql"
APPLY="ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh"

echo
echo "=== required files ==="
for f in "$DOC" "$SMOKE" "$SQL" "$APPLY"; do
  test -f "$f"
done
echo "PASS: required AY docs/smoke and existing SQL/apply artifacts exist"

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

doc = Path("docs/phase-14i-ay-router-shadow-evidence-writer-surface-inspection.md").read_text()

required = [
    "docs/smoke-only inspection phase",
    "This phase does not add writer code",
    "This phase does not write to the database",
    "This phase does not change runtime behavior",
    "queued_chat_router_shadow_evidence",
    "_phase14iag_queued_chat_router_shadow_enabled",
    "_phase14iag_queued_chat_router_shadow_decision",
    "_phase14iag_queued_chat_router_shadow_decision(guard_payload)",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED",
    "Future Insertion Point",
    "Future Writer Control Flow",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITE_ENABLED",
    "Future Allowlist Boundary",
    "Future Forbidden Boundary",
    "raw prompts",
    "raw messages",
    "raw request bodies",
    "cookies",
    "auth headers",
    "bearer tokens",
    "Future Failure Boundary",
    "Phase 14I-AZ park-or-proceed decision gate",
    "persistent lane worker blocker re-entry",
]

missing = [m for m in required if m not in doc]
if missing:
    raise SystemExit("FAIL: missing documentation markers: " + ", ".join(missing))

print("PASS: documentation markers verified")
PY

echo
echo "=== existing router shadow markers still present ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

required = [
    "_phase14iag_queued_chat_router_shadow_enabled",
    "_phase14iag_queued_chat_router_shadow_decision",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_ENABLED",
    "_phase14iag_queued_chat_router_shadow_decision(guard_payload)",
]

missing = [m for m in required if m not in text]
if missing:
    raise SystemExit("FAIL: missing router shadow markers: " + ", ".join(missing))

print("PASS: existing router shadow markers remain present")
PY

echo
echo "=== runtime writer still absent ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()

blocked_runtime_markers = [
    "insert_router_shadow_evidence",
    "record_router_shadow_evidence",
    "persist_router_shadow_evidence",
    "_phase14i_writer_gate_enabled",
    "_phase14i_router_shadow_evidence_payload_from_decision",
    "_phase14i_record_router_shadow_evidence",
    "EDGE_QUEUED_CHAT_ROUTER_SHADOW_EVIDENCE_WRITE_ENABLED",
]

found = [m for m in blocked_runtime_markers if m in text]
if found:
    raise SystemExit("FAIL: runtime writer markers found in edge_controller.py: " + ", ".join(found))

print("PASS: runtime writer markers remain absent from edge_controller.py")
PY

echo
echo "=== SQL/apply artifacts still static-valid ==="
python3 - <<'PY'
from pathlib import Path

sql = Path("ops/db/laptop-app-schema-v3-router-shadow-evidence.sql").read_text()
apply = Path("ops/db/apply-laptop-app-schema-v3-router-shadow-evidence.sh").read_text()

required_sql = [
    "CREATE TABLE IF NOT EXISTS queued_chat_router_shadow_evidence",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_created_at",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_related_job_id",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_request_surface",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_policy_status",
    "CREATE INDEX IF NOT EXISTS idx_qcrse_writer_gate_enabled",
]

required_apply = [
    "REQUIRED_CONFIRM",
    "backup-laptop-postgres.sh",
    "restore-laptop-postgres.sh",
    "verify-laptop-postgres-restore-drill.sh",
    "ON_ERROR_STOP=1",
    "table_exists",
    "marker_exists",
]

missing_sql = [m for m in required_sql if m not in sql]
missing_apply = [m for m in required_apply if m not in apply]

if missing_sql:
    raise SystemExit("FAIL: missing SQL markers: " + ", ".join(missing_sql))
if missing_apply:
    raise SystemExit("FAIL: missing apply markers: " + ", ".join(missing_apply))

print("PASS: SQL/apply artifact markers verified")
PY

echo
echo "=== queued route surface remains single shadow hook call ==="
python3 - <<'PY'
from pathlib import Path

text = Path("edge_controller.py").read_text()
needle = "_phase14iag_queued_chat_router_shadow_decision(guard_payload)"
count = text.count(needle)

if count != 1:
    raise SystemExit(f"FAIL: expected exactly one queued-chat shadow hook call, found {count}")

print("PASS: queued-chat shadow hook call count remains exactly one")
PY

echo
echo "=== changed files limited to Phase 14I-AY docs/smoke ==="
python3 - <<'PY'
import subprocess

allowed = {
    "docs/phase-14i-ay-router-shadow-evidence-writer-surface-inspection.md",
    "ops/smoke/check-phase-14i-ay-router-shadow-evidence-writer-surface-inspection.sh",
}

out = subprocess.check_output(["git", "status", "--short"], text=True)
paths = [line[3:] for line in out.splitlines() if line.strip()]
unexpected = [p for p in paths if p not in allowed]
if unexpected:
    raise SystemExit("FAIL: unexpected changed files: " + ", ".join(unexpected))

print("PASS: changed files are limited to Phase 14I-AY docs/smoke")
PY

echo
echo "=== smoke script behavior guard ==="
python3 - <<'PY'
from pathlib import Path
import re

smoke = Path("ops/smoke/check-phase-14i-ay-router-shadow-evidence-writer-surface-inspection.sh").read_text()

live_cmd_re = re.compile(r"^\s*(curl|psql|pg_dump|ollama)\b")
apply_exec_marker = "bash " + '"$' + "APPLY" + '"'
bad = []

for lineno, line in enumerate(smoke.splitlines(), 1):
    stripped = line.strip()
    if live_cmd_re.match(stripped):
        bad.append(f"line {lineno}: live command: {stripped}")
    if apply_exec_marker in line:
        bad.append(f"line {lineno}: apply wrapper execution")

if bad:
    raise SystemExit("FAIL: AY smoke contains forbidden live/apply behavior:\n" + "\n".join(bad))

print("PASS: smoke behavior guard passed")
PY

echo
echo "=== done: Phase 14I-AY router shadow evidence writer surface inspection smoke complete ==="
