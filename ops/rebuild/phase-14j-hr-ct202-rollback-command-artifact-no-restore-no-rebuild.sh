#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hr-ct202-rollback-command-artifact-no-restore-no-rebuild"
REQUIRED_APPROVAL="APPROVE_PHASE_14J_HR_CT202_ROLLBACK_COMMAND_ARTIFACT_NO_RESTORE_NO_REBUILD"
BACKUP_DIR="/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z"
EXPECTED_DB_SIZE="262144"
EXPECTED_DB_SHA256="43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314"
EXPECTED_MANIFEST_SHA256="dc372a0213df90efe7e1e87659b9e2d9e412f6f6c4b1dac18de4903584076491"
EXPECTED_ROLLBACK_CHECKLIST_SHA256="3c3cd5b419e299ec355d552e9b776dd6a089026f819b26c7a7224b75cda2e3d6"

approval="${APC_HR_APPROVAL:-}"
allow_dirty="${APC_ALLOW_DIRTY:-0}"

echo "=== ${PHASE} ==="
echo "MODE=no_restore_rollback_plan_check_only"
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
echo "PASS: no-restore rollback artifact approval phrase confirmed"

echo
echo "=== optional repo guard ==="
if git rev-parse --show-toplevel >/dev/null 2>&1; then
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
else
  echo "PASS: no git repo detected; repo guard skipped"
fi

echo
echo "=== rollback prerequisites summary ==="
echo "expected_backup_dir=$BACKUP_DIR"
echo "expected_db_size=$EXPECTED_DB_SIZE"
echo "expected_db_sha256=$EXPECTED_DB_SHA256"
echo "expected_manifest_sha256=$EXPECTED_MANIFEST_SHA256"
echo "expected_rollback_checklist_sha256=$EXPECTED_ROLLBACK_CHECKLIST_SHA256"
echo "required_artifacts:"
echo "- ct202-edge_queue.sqlite3"
echo "- ct202-pct-config.txt"
echo "- ct202-app-summary.txt"
echo "- ct202-service-summary.txt"
echo "- ct202-env-config-posture.txt"
echo "- rollback-checklist.txt"
echo "- manifest.txt"

echo
echo "=== required CT202 posture before any future restore ==="
echo "- CT202 private candidate only"
echo "- CT202 service inactive"
echo "- CT202 service not enabled"
echo "- CT202 onboot 0"
echo "- no checked listener on 7070/8787/8765"
echo "- laptop controller and laptop-local DB remain live authority"
echo "- public routes unchanged"
echo "- cutover readiness gate CLOSED"

echo
echo "=== planned rollback order, design only ==="
cat <<'PLAN'
1. Confirm future explicit restore approval phrase.
2. Confirm CT202 is private candidate and not public authority.
3. Confirm public routes remain unchanged.
4. Confirm laptop controller and laptop-local DB remain live authority.
5. Confirm CT202 service is inactive and not enabled.
6. Confirm CT202 onboot remains 0.
7. Verify HM/HN backup directory and artifact hashes.
8. Preserve current CT202 candidate DB as a pre-restore artifact if safe.
9. Replace CT202 candidate DB from verified HM backup only after future restore approval.
10. Verify restored file size and SHA256.
11. Keep CT202 service disabled/inactive.
12. Keep CT202 onboot 0.
13. Keep cutover readiness gate CLOSED.
14. Do not start services.
15. Do not mutate routes.
PLAN

echo
echo "=== forbidden operations summary ==="
echo "This artifact contains no restore implementation."
echo "This artifact contains no rebuild implementation."
echo "This artifact contains no schema apply implementation."
echo "This artifact contains no data import implementation."
echo "This artifact contains no service start/enable implementation."
echo "This artifact contains no route mutation implementation."
echo "This artifact opens no remote connection in HR."

echo
echo "=== ${PHASE} result ==="
echo "PASS: no-restore rollback command artifact ran safely"
echo "PASS: no restore/rebuild/schema apply performed"
echo "PASS: no data authority path selected"
echo "PASS: no SQLite DB opened with sqlite3"
echo "PASS: no SQL dump or row content output"
echo "PASS: no service start/enable or onboot mutation"
echo "PASS: no route/cutover mutation"
