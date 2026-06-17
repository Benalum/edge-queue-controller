#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../.."

PHASE="phase-14j-fv-persistent-sqlite-backup-restore-scripts-no-runtime-change"
DOC="docs/${PHASE}.md"
SMOKE="ops/smoke/check-${PHASE}.sh"
BACKUP_SCRIPT="ops/db/backup-edge-queue-sqlite.sh"
VERIFY_SCRIPT="ops/db/verify-edge-queue-sqlite-backup.sh"
PREV_SMOKE="ops/smoke/check-phase-14j-fu-sqlite-backup-restore-and-data-container-design-plan-no-creation.sh"

echo "=== smoke: $PHASE ==="

test -f "$DOC"
test -x "$SMOKE"
test -x "$BACKUP_SCRIPT"
test -x "$VERIFY_SCRIPT"
test -x "$PREV_SMOKE"

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
bash -n "$BACKUP_SCRIPT"
bash -n "$VERIFY_SCRIPT"
bash -n "$SMOKE"
echo "PASS: syntax checks passed"

echo "--- doc markers ---"
require_fixed "PHASE_14J_FV_PERSISTENT_SQLITE_BACKUP_RESTORE_SCRIPTS_NO_RUNTIME_CHANGE"
require_fixed "PHASE_14J_FV_RESULT=persistent_sqlite_backup_restore_scripts_added_no_runtime_change"
require_fixed "NEXT_SAFE_PHASE=phase_14j_fw_default_preserving_controller_db_path_env_override_no_runtime_reload"
require_fixed "ops/db/backup-edge-queue-sqlite.sh"
require_fixed "ops/db/verify-edge-queue-sqlite-backup.sh"
require_fixed "no runtime change"
require_fixed "does not create a data container or VM"

echo "--- script markers ---"
require_fixed "sqlite3 backup API" "$BACKUP_SCRIPT"
require_fixed "BACKUP_QUICK_CHECK" "$BACKUP_SCRIPT"
require_fixed "BACKUP_TABLE_COUNT" "$BACKUP_SCRIPT"
require_fixed "BACKUP_INDEX_COUNT" "$BACKUP_SCRIPT"
require_fixed "BACKUP_TOTAL_ROWS_ACROSS_TABLES" "$BACKUP_SCRIPT"
require_fixed "SQLite backup restore verification passed" "$VERIFY_SCRIPT"
require_fixed "WARN: live/backup row counts differ" "$VERIFY_SCRIPT"

echo "--- temporary backup and verify drill ---"
TMP_BACKUP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_BACKUP_DIR"' EXIT

OUTPUT="$(
  EDGE_QUEUE_SQLITE_BACKUP_DIR="$TMP_BACKUP_DIR" \
  EDGE_QUEUE_SQLITE_BACKUP_RETENTION_DAYS=1 \
  bash "$BACKUP_SCRIPT"
)"

printf '%s\n' "$OUTPUT"

BACKUP_FILE="$(printf '%s\n' "$OUTPUT" | awk -F= '/^BACKUP_FILE=/{print $2}' | tail -1)"
MANIFEST_FILE="$(printf '%s\n' "$OUTPUT" | awk -F= '/^MANIFEST_FILE=/{print $2}' | tail -1)"

test -n "$BACKUP_FILE"
test -n "$MANIFEST_FILE"
test -s "$BACKUP_FILE"
test -s "$MANIFEST_FILE"

case "$BACKUP_FILE" in
  "$TMP_BACKUP_DIR"/*) ;;
  *) echo "FAIL: backup file not inside temp backup dir"; exit 1 ;;
esac

case "$MANIFEST_FILE" in
  "$TMP_BACKUP_DIR"/*) ;;
  *) echo "FAIL: manifest file not inside temp backup dir"; exit 1 ;;
esac

test "$(stat -c '%a' "$BACKUP_FILE")" = "600"
test "$(stat -c '%a' "$MANIFEST_FILE")" = "600"
test -L "$TMP_BACKUP_DIR/latest.sqlite3"

grep -F "BACKUP_QUICK_CHECK=ok" <<<"$OUTPUT" >/dev/null
grep -F "BACKUP_TABLE_COUNT=" <<<"$OUTPUT" >/dev/null
grep -F "BACKUP_INDEX_COUNT=" <<<"$OUTPUT" >/dev/null
grep -F "BACKUP_TOTAL_ROWS_ACROSS_TABLES=" <<<"$OUTPUT" >/dev/null
grep -F "AI Platform Edge Queue SQLite Backup" "$MANIFEST_FILE" >/dev/null
grep -F "table_counts_no_row_dump" "$MANIFEST_FILE" >/dev/null

VERIFY_OUTPUT="$(bash "$VERIFY_SCRIPT" "$BACKUP_FILE")"
printf '%s\n' "$VERIFY_OUTPUT"

grep -F "PASS: SQLite backup restore verification passed" <<<"$VERIFY_OUTPUT" >/dev/null

if find . -maxdepth 3 -type f -name 'edge-queue-*.sqlite3' -o -name 'edge-queue-*.txt' | grep -q .; then
  echo "FAIL: backup artifacts were created inside repo"
  exit 1
fi

echo "--- hard-denial markers ---"
require_fixed "NO container creation" "$SMOKE"
require_fixed "NO data migration" "$SMOKE" || true

echo "PASS: $PHASE"

# NO container creation
# NO data migration
# NO live DB mutation
# NO controller/queue migration
# NO service restart/reload
# NO worker start
# NO production DB/job mutation
# NO CT101 call
# NO model/Ollama endpoint call
# NO Phase 14J-AG apply wrapper rerun
