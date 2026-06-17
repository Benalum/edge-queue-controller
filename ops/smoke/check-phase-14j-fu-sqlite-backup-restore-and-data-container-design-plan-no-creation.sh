#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-fu-sqlite-backup-restore-and-data-container-design-plan-no-creation"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"

require_fixed() {
  local marker="$1"
  echo "CHECK: $marker"
  grep -Fq "$marker" "$DOC"
  echo "PASS: $marker"
}

echo "--- phase/result markers ---"
require_fixed "PHASE_14J_FU_SQLITE_BACKUP_RESTORE_AND_DATA_CONTAINER_DESIGN_PLAN_NO_CREATION"
require_fixed "PHASE_14J_FU_RESULT=sqlite_backup_restore_drill_passed_data_container_design_plan_recorded_no_creation"
require_fixed "NEXT_SAFE_PHASE=phase_14j_fv_persistent_sqlite_backup_restore_scripts_no_runtime_change"

echo "--- backup/restore proof markers ---"
require_fixed "PHASE_14J_FU_TEMP_SQLITE_BACKUP_DRILL=passed"
require_fixed "PHASE_14J_FU_TEMP_SQLITE_RESTORE_DRILL=passed"
require_fixed "live quick_check: ok"
require_fixed "live table count: 39"
require_fixed "live index count: 18"
require_fixed "live total rows across tables: 25,354"
require_fixed "backup quick_check: ok"
require_fixed "backup table count: 39"
require_fixed "backup index count: 18"
require_fixed "backup total rows across tables: 25,354"
require_fixed "restore quick_check: ok"
require_fixed "restore table count: 39"
require_fixed "restore total rows across tables: 25,354"

echo "--- DB path/config boundary markers ---"
require_fixed 'edge_controller.py` uses `DB_PATH = Path("edge_queue.sqlite3")'
require_fixed "PHASE_14J_FU_DB_PATH_CONFIGURABILITY=current_controller_db_path_repo_relative_default_only"
require_fixed "default-off/env-based controller DB path configurability patch"
require_fixed 'default behavior still uses repo-local `edge_queue.sqlite3`'

echo "--- future plan markers ---"
require_fixed "persistent SQLite backup script"
require_fixed "persistent SQLite restore verification script"
require_fixed "no runtime change"
require_fixed "data container or VM"
require_fixed "controller/queue container"
require_fixed "worker container"

echo "--- hard-denial markers ---"
require_fixed "no container creation"
require_fixed "no data migration"
require_fixed "no live DB mutation"
require_fixed "no controller/queue migration"
require_fixed "no service restart/reload"
require_fixed "no worker start"
require_fixed "no production DB/job mutation"
require_fixed "no CT101 call"
require_fixed "no model/Ollama endpoint call"
require_fixed "no Phase 14J-AG apply wrapper rerun"

echo "--- doc secret/raw endpoint guard ---"
if grep -Eq 'eyJ[a-zA-Z0-9_-]{20,}|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|cloudflared.*token[[:space:]]+[A-Za-z0-9._=-]{20,}' "$DOC"; then
  echo "FAIL: possible secret/token/private key material in $DOC"
  exit 1
fi

if grep -Eq '100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}' "$DOC"; then
  echo "FAIL: raw private/Tailscale IP found in $DOC"
  exit 1
fi

echo "PASS: $PHASE"
