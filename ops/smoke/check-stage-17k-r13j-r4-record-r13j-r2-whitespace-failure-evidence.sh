#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13j-r4-record-r13j-r2-whitespace-failure-evidence.md"
PRIOR_OUT="docs/smoke/generated/stage-17k-r13j-r2-deploy-current-backup-save-plan-preview-only-safe-patch"
PRIOR_DOC="docs/stage-17k-r13j-r2-deploy-current-backup-save-plan-preview-only-safe-patch.md"
PRIOR_SMOKE="ops/smoke/check-stage-17k-r13j-r2-deploy-current-backup-save-plan-preview-only-safe-patch.sh"

test -f "$DOC"
test -d "$PRIOR_OUT"
test -f "$PRIOR_DOC"
test -f "$PRIOR_SMOKE"

grep -Fq "Record R13J-R2 Whitespace-Failure Evidence" "$DOC"
grep -Fq "Docs/evidence only" "$DOC"
grep -Fq "No source mutation" "$DOC"
grep -Fq "No merge/save/overwrite path" "$DOC"

grep -R "R13J_R2_VM200_CURRENT_BACKUP_SAVE_PLAN_PREVIEW_ONLY_DEPLOY_DONE" "$PRIOR_OUT"
grep -R "PASS public static R13J-R2 smoke" "$PRIOR_OUT"
grep -R "api_system_status=200" "$PRIOR_OUT"
grep -R "api_me_status=401" "$PRIOR_OUT"
grep -R "signup_status=403" "$PRIOR_OUT"

echo "PASS stage-17k-r13j-r4 record R13J-R2 whitespace-failure evidence smoke"
