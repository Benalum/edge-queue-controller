#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-hp-ct202-rebuild-script-artifact-no-apply"
DOC="docs/${PHASE}.md"
SCRIPT="ops/rebuild/${PHASE}.sh"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"
test -f "$SCRIPT"
test -x "$SCRIPT"

require_present() {
  local file="$1"
  local needle="$2"
  echo "CHECK: $needle"
  grep -Fq "$needle" "$file"
  echo "PASS: $needle"
}

require_absent() {
  local file="$1"
  local needle="$2"
  echo "CHECK_ABSENT: $needle"
  if grep -Fq "$needle" "$file"; then
    echo "FAIL: unexpected text present in $file: $needle"
    exit 1
  fi
  echo "PASS_ABSENT: $needle"
}

require_present "$DOC" 'Phase 14J-HP - CT202 rebuild script artifact, no apply'
require_present "$DOC" 'Previous checkpoint: Phase 14J-HO at commit `d19e2b0`'
require_present "$DOC" 'APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY'
require_present "$DOC" 'HP-R1 failed safely during local artifact smoke.'
require_present "$DOC" 'HP-R2 keeps the same no-apply scope'
require_present "$DOC" 'ops/rebuild/phase-14j-hp-ct202-rebuild-script-artifact-no-apply.sh'
require_present "$DOC" 'The artifact is executable but safe by default.'
require_present "$DOC" 'The artifact does not open a remote connection in HP.'
require_present "$DOC" 'Expected HM/HN backup directory'
require_present "$DOC" '/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z'
require_present "$DOC" 'sha256: `43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314`'
require_present "$DOC" 'Target include count'
require_present "$DOC" '`39` laptop continuity tables'
require_present "$DOC" '`credit_ledger`'
require_present "$DOC" '`user_credit_wallets`'
require_present "$DOC" '`ad_reward_events`'
require_present "$DOC" '`calendar_events`'
require_present "$DOC" '`credit_reservations`'
require_present "$DOC" '`study_decks`'
require_present "$DOC" '`study_cards`'
require_present "$DOC" '`study_sessions`'
require_present "$DOC" '`user_credit_ledger`'
require_present "$DOC" '`worker_events`'
require_present "$DOC" '`workers`'
require_present "$DOC" 'contains no rebuild implementation'
require_present "$DOC" 'contains no schema apply implementation'
require_present "$DOC" 'contains no restore implementation'
require_present "$DOC" 'contains no data import implementation'
require_present "$DOC" 'APC_ALLOW_DIRTY=1'
require_present "$DOC" 'Phase 14J-HQ - CT202 rollback command design, no restore/no rebuild'
require_present "$DOC" 'APPROVE_PHASE_14J_HQ_CT202_ROLLBACK_COMMAND_DESIGN_NO_RESTORE_NO_REBUILD'
require_present "$DOC" 'The CT202 controller cutover readiness gate remains CLOSED.'
require_present "$DOC" 'This phase does not authorize restore.'
require_present "$DOC" 'Do not run migration/import/copy/dump from this phase.'

require_present "$SCRIPT" 'REQUIRED_APPROVAL="APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY"'
require_present "$SCRIPT" 'allow_dirty="${APC_ALLOW_DIRTY:-0}"'
require_present "$SCRIPT" 'MODE=no_apply_prerequisite_and_plan_check_only'
require_present "$SCRIPT" 'NO restore'
require_present "$SCRIPT" 'NO rebuild'
require_present "$SCRIPT" 'NO cutover/apply'
require_present "$SCRIPT" 'NO CT202 schema apply'
require_present "$SCRIPT" 'NO SQLite open with sqlite3'
require_present "$SCRIPT" 'NO SQL dump'
require_present "$SCRIPT" 'NO systemctl start'
require_present "$SCRIPT" 'NO systemctl enable'
require_present "$SCRIPT" 'BACKUP_DIR="/root/apc-ct202-backups/phase-14j-hm-ct202-guarded-backup-only-no-rebuild-20260618T031207Z"'
require_present "$SCRIPT" 'EXPECTED_DB_SHA256="43d519dd3a93db783c224ef1972231e0e46fdd1274f1647e456064cab2a21314"'
require_present "$SCRIPT" 'EXPECTED_DB_SIZE="262144"'
require_present "$SCRIPT" 'PASS: expected dirty repo allowed for pre-commit artifact smoke'
require_present "$SCRIPT" 'Target include count: 39 laptop continuity tables.'
require_present "$SCRIPT" 'credit_ledger'
require_present "$SCRIPT" 'user_credit_wallets'
require_present "$SCRIPT" 'workers: target current runtime-compatible laptop shape'
require_present "$SCRIPT" 'credit_reservations: target current runtime/laptop continuity shape'
require_present "$SCRIPT" 'PASS: no-apply rebuild script artifact ran safely'
require_present "$SCRIPT" 'PASS: no restore/rebuild/schema apply performed'

require_absent "$DOC" 'APPROVE_CUTOVER_APPLY'
require_absent "$DOC" 'APPROVE_DATA_MIGRATION'
require_absent "$DOC" 'APPROVE_RUNTIME_APPLY'
require_absent "$DOC" 'APPROVE_ROUTE_APPLY'
require_absent "$DOC" 'APPROVE_CLOUDFLARE_APPLY'
require_absent "$DOC" 'APPROVE_SECRET_APPLY'
require_absent "$DOC" 'APPROVE_REBUILD_APPLY'
require_absent "$DOC" 'APPROVE_SCHEMA_APPLY'
require_absent "$DOC" 'APPROVE_RESTORE_APPLY'
require_absent "$DOC" 'systemctl enable edge-queue-controller.service'
require_absent "$DOC" 'pct set 202 -onboot 1'
require_absent "$DOC" 'cloudflare tunnel route'
require_absent "$DOC" 'cloudflared tunnel route'
require_absent "$DOC" 'ollama serve'
require_absent "$DOC" 'sqlite3 edge_queue.sqlite3 .dump'

require_absent "$SCRIPT" 'APPROVE_CUTOVER_APPLY'
require_absent "$SCRIPT" 'APPROVE_DATA_MIGRATION'
require_absent "$SCRIPT" 'APPROVE_RUNTIME_APPLY'
require_absent "$SCRIPT" 'APPROVE_ROUTE_APPLY'
require_absent "$SCRIPT" 'APPROVE_CLOUDFLARE_APPLY'
require_absent "$SCRIPT" 'APPROVE_SECRET_APPLY'
require_absent "$SCRIPT" 'APPROVE_REBUILD_APPLY'
require_absent "$SCRIPT" 'APPROVE_SCHEMA_APPLY'
require_absent "$SCRIPT" 'APPROVE_RESTORE_APPLY'
require_absent "$SCRIPT" 'systemctl enable edge-queue-controller.service'
require_absent "$SCRIPT" 'pct set 202 -onboot 1'
require_absent "$SCRIPT" 'cloudflare tunnel route'
require_absent "$SCRIPT" 'cloudflared tunnel route'
require_absent "$SCRIPT" 'ollama serve'
require_absent "$SCRIPT" 'sqlite3 edge_queue.sqlite3 .dump'

echo
echo "=== run HP no-apply artifact smoke with expected pre-commit dirty allowance ==="
APC_HP_APPROVAL="APPROVE_PHASE_14J_HP_CT202_REBUILD_SCRIPT_ARTIFACT_NO_APPLY" \
APC_EXPECTED_HEAD="$(git rev-parse --short HEAD)" \
APC_ALLOW_DIRTY="1" \
bash "$SCRIPT" | tee /tmp/apc-hp-artifact-smoke-output.txt

grep -Fq 'PASS: expected dirty repo allowed for pre-commit artifact smoke' /tmp/apc-hp-artifact-smoke-output.txt
grep -Fq 'PASS: no-apply rebuild script artifact ran safely' /tmp/apc-hp-artifact-smoke-output.txt
grep -Fq 'PASS: no restore/rebuild/schema apply performed' /tmp/apc-hp-artifact-smoke-output.txt
grep -Fq 'PASS: no service start/enable or onboot mutation' /tmp/apc-hp-artifact-smoke-output.txt
grep -Fq 'PASS: no route/cutover mutation' /tmp/apc-hp-artifact-smoke-output.txt

echo "PASS: ${PHASE}"
