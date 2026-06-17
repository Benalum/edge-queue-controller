#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-fw-default-preserving-controller-db-path-env-override-no-runtime-reload"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
TARGET="edge_controller.py"
PREV_SMOKE="ops/smoke/check-phase-14j-fv-persistent-sqlite-backup-restore-scripts-no-runtime-change.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$PREV_SMOKE"
test -f "$TARGET"

require_fixed() {
  local marker="$1"
  local file="${2:-$DOC}"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$file"
  echo "PASS: $marker"
}

echo "--- previous smoke regression ---"
"$PREV_SMOKE"

echo "--- syntax checks ---"
python3 -m py_compile "$TARGET"
bash -n "$SMOKE"
echo "PASS: syntax checks passed"

echo "--- doc markers ---"
require_fixed "PHASE_14J_FW_DEFAULT_PRESERVING_CONTROLLER_DB_PATH_ENV_OVERRIDE_NO_RUNTIME_RELOAD"
require_fixed "PHASE_14J_FW_RESULT=default_preserving_controller_db_path_env_override_added_no_runtime_reload"
require_fixed "NEXT_SAFE_PHASE=phase_14j_fx_data_container_or_vm_target_design_no_creation"
require_fixed "EDGE_QUEUE_SQLITE_DB_PATH"
require_fixed "EDGE_QUEUE_DB_PATH"
require_fixed "EDGE_CONTROLLER_DB_PATH"
require_fixed "fallback edge_queue.sqlite3"
require_fixed "no runtime config change"
require_fixed "no systemd mutation"
require_fixed "no env file mutation"

echo "--- code markers ---"
require_fixed "import os" "$TARGET"
require_fixed "DB_PATH = Path(" "$TARGET"
require_fixed 'os.environ.get("EDGE_QUEUE_SQLITE_DB_PATH")' "$TARGET"
require_fixed 'os.environ.get("EDGE_QUEUE_DB_PATH")' "$TARGET"
require_fixed 'os.environ.get("EDGE_CONTROLLER_DB_PATH")' "$TARGET"
require_fixed 'or "edge_queue.sqlite3"' "$TARGET"

echo "--- AST validation ---"
python3 - <<'PY'
import ast
from pathlib import Path

src = Path("edge_controller.py").read_text()
tree = ast.parse(src)
matches = []

for node in tree.body:
    if isinstance(node, ast.Assign):
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == "DB_PATH":
                matches.append(node)

if len(matches) != 1:
    raise SystemExit(f"FAIL: expected one DB_PATH assignment, found {len(matches)}")

segment = ast.get_source_segment(src, matches[0]) or ""
for marker in ["EDGE_QUEUE_SQLITE_DB_PATH", "EDGE_QUEUE_DB_PATH", "EDGE_CONTROLLER_DB_PATH", "edge_queue.sqlite3"]:
    if marker not in segment:
        raise SystemExit(f"FAIL: missing DB_PATH marker: {marker}")

print("PASS: DB_PATH assignment is env-configurable and default-preserving")
PY

echo "--- hard-denial markers ---"
require_fixed "no container creation"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no controller/queue migration"
require_fixed "no service restart/reload"
require_fixed "no runtime config change"
require_fixed "no systemd mutation"
require_fixed "no env file mutation"
require_fixed "no worker start"
require_fixed "no production DB/job mutation"
require_fixed "no CT101 call"
require_fixed "no model/Ollama endpoint call"
require_fixed "no Phase 14J-AG apply wrapper rerun"

echo "PASS: $PHASE"
