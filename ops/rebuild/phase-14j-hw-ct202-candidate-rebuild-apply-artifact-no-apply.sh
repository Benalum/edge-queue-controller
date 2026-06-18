#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hw-ct202-candidate-rebuild-apply-artifact-no-apply"
REQUIRED_APPROVAL="APPROVE_PHASE_14J_HW_CT202_CANDIDATE_REBUILD_APPLY_ARTIFACT_NO_APPLY"

TARGET_DB="/srv/edge-controller/data/edge_queue.sqlite3"
BACKUP_DIR="/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z"
EXPECTED_BACKUP_DB_SIZE="262144"
EXPECTED_BACKUP_DB_SHA256="43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314"
EXPECTED_MANIFEST_SHA256="dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491"
EXPECTED_ROLLBACK_CHECKLIST_SHA256="3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6"
EXPECTED_TARGET_TABLE_COUNT="39"

HP_SCRIPT="ops/rebuild/phase-14j-hp-ct202-rebuild-script-artifact-no-apply.sh"
HR_SCRIPT="ops/rebuild/phase-14j-hr-ct202-rollback-command-artifact-no-restore-no-rebuild.sh"
HT_SCRIPT="ops/rehearsal/phase-14j-ht-ct202-private-rehearsal-artifact-no-restore-no-rebuild-no-apply.sh"

approval="${APC_HW_APPROVAL:-}"
allow_dirty="${APC_ALLOW_DIRTY:-0}"

echo "=== ${PHASE} ==="
echo "MODE=candidate_rebuild_apply_artifact_no_apply"
echo "NO real candidate rebuild approval phrase defined"
echo "NO restore"
echo "NO rebuild"
echo "NO cutover/apply"
echo "NO data authority path selection"
echo "NO Path C execution"
echo "NO CT202 schema apply"
echo "NO CT202 data migration/import"
echo "NO SQLite open with sqlite3"
echo "NO SQL dump"
echo "NO row content output"
echo "NO live laptop DB mutation"
echo "NO CT202 DB mutation"
echo "NO backup creation"
echo "NO restore operation"
echo "NO systemctl start"
echo "NO systemctl enable"
echo "NO CT202 onboot/autostart mutation"
echo "NO Cloudflare/DNS/tunnel mutation"
echo "NO public route mutation"
echo "NO CT101/model/Ollama/worker call"
echo "NO secrets printed"

echo
echo "=== approval guard ==="
test "$approval" = "$REQUIRED_APPROVAL"
echo "PASS: no-apply candidate rebuild artifact approval phrase confirmed"

echo
echo "=== repo/artifact guard ==="
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"
head_now="$(git rev-parse --short HEAD)"
origin_main_local="$(git rev-parse --short origin/main 2>/dev/null || true)"
status_short="$(git status --short)"
echo "repo_root=$repo_root"
echo "head_now=$head_now"
echo "origin_main_local=${origin_main_local:-unknown}"
echo "git_status_short=${status_short:-<clean>}"

if [ -n "${APC_EXPECTED_HEAD:-}" ]; then
  test "$head_now" = "$APC_EXPECTED_HEAD"
  [ -z "$origin_main_local" ] || test "$origin_main_local" = "$APC_EXPECTED_HEAD"
  if [ -n "$status_short" ] && [ "$allow_dirty" != "1" ]; then
    echo "FAIL: repo is dirty and APC_ALLOW_DIRTY is not set"
    exit 1
  fi
  if [ -n "$status_short" ]; then
    echo "PASS: expected dirty repo allowed for pre-commit artifact smoke"
  else
    echo "PASS: repo clean for expected checkpoint guard"
  fi
fi

test -x "$HP_SCRIPT"
test -x "$HR_SCRIPT"
test -x "$HT_SCRIPT"
echo "PASS: HP, HR, and HT safety artifacts exist and are executable"

echo
echo "=== future candidate rebuild target summary ==="
echo "target_db=$TARGET_DB"
echo "target_table_count=$EXPECTED_TARGET_TABLE_COUNT"
echo "target_schema_source=Phase 14J-HK target manifest plus runtime-compatible laptop continuity evidence"
echo "target_omit_or_defer=credit_ledger,user_credit_wallets"
echo "critical_mismatch_workers=target laptop runtime-compatible shape with lane/default-off metadata"
echo "critical_mismatch_credit_reservations=target runtime/laptop continuity shape"

echo
echo "=== future candidate rebuild guard summary ==="
echo "required_backup_dir=$BACKUP_DIR"
echo "expected_backup_db_size=$EXPECTED_BACKUP_DB_SIZE"
echo "expected_backup_db_sha256=$EXPECTED_BACKUP_DB_SHA256"
echo "expected_manifest_sha256=$EXPECTED_MANIFEST_SHA256"
echo "expected_rollback_checklist_sha256=$EXPECTED_ROLLBACK_CHECKLIST_SHA256"
echo "required_ct202_status=running"
echo "required_ct202_hostname=edge-controller"
echo "required_ct202_onboot=0"
echo "required_service_enabled=not_enabled"
echo "required_service_active=not_active"
echo "required_checked_listener=absent_on_7070_8787_8765"
echo "required_laptop_authority=unchanged"
echo "required_public_routes=unchanged"
echo "required_cutover_gate=CLOSED"

echo
echo "=== future preservation design ==="
echo "Before any future candidate DB replacement, preserve current CT202 candidate DB."
echo "Preservation metadata must include timestamp, file size, sha256, source path, destination path, and reason label."
echo "Preservation must include no row content and no SQL dump."
echo "Future mutating phase must fail closed if preservation fails."

echo
echo "=== future candidate rebuild action design, not executed ==="
cat <<'PLAN'
1. Confirm future real candidate rebuild approval phrase.
2. Confirm repo checkpoint and clean tree.
3. Confirm CT202 private candidate posture.
4. Confirm HM/HN backup hashes.
5. Preserve current CT202 candidate DB.
6. Create candidate DB from target schema source only.
7. Verify target table count 39.
8. Verify CT202-only drift tables remain omitted/deferred.
9. Verify workers and credit_reservations mismatch decisions.
10. Keep service disabled/inactive.
11. Keep CT202 onboot 0.
12. Keep cutover gate CLOSED.
13. Do not import live laptop data.
14. Do not mutate public routes.
15. Do not start services.
PLAN

echo
echo "=== forbidden operations summary ==="
echo "This artifact contains no rebuild implementation."
echo "This artifact contains no schema apply implementation."
echo "This artifact contains no restore implementation."
echo "This artifact contains no data import implementation."
echo "This artifact contains no service start/enable implementation."
echo "This artifact contains no route mutation implementation."
echo "This artifact contains no SQL dump implementation."
echo "This artifact contains no row-content output implementation."
echo "This artifact does not define the real candidate rebuild approval phrase."

echo
echo "=== ${PHASE} result ==="
echo "PASS: no-apply candidate rebuild artifact ran safely"
echo "PASS: future candidate rebuild boundary summarized"
echo "PASS: preservation design summarized"
echo "PASS: no restore/rebuild/schema apply performed"
echo "PASS: no data authority path selected"
echo "PASS: no SQLite DB opened with sqlite3"
echo "PASS: no SQL dump or row content output"
echo "PASS: no service start/enable or onboot mutation"
echo "PASS: no route/cutover mutation"
