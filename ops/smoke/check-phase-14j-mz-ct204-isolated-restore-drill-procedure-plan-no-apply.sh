#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mz-ct204-isolated-restore-drill-procedure-plan-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -Fq "NO-APPLY PLAN ONLY." "$DOC"
grep -Fq "This phase does not unlock or mount private storage" "$DOC"
grep -Fq "PVEW private storage is locked/unmounted." "$DOC"
grep -Fq "CT204 remains stopped, backup-data-only, and" "$DOC"
grep -Fq "APPROVE_PHASE_14J_MY_REOPEN_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE" "$DOC"
grep -Fq "APPROVE_PHASE_14J_NA_CT204_ISOLATED_RESTORE_DRILL_NO_AUTHORITY_NO_PUBLIC_ROUTE" "$DOC"
grep -Fq "The future restore-drill phase must not:" "$DOC"
grep -Fq "promote CT204 to data authority" "$DOC"
grep -Fq "replace CT203 DB" "$DOC"
grep -Fq "change Cloudflare, DNS, tunnels, or cutover behavior" "$DOC"
grep -Fq "Known latest verified backup bundle:" "$DOC"
grep -Fq "/srv/apc-private-data/backups/ct203/ct203-backup-20260619T002628Z" "$DOC"
grep -Fq "The drill must not set CT204 as data authority." "$DOC"
grep -Fq "RESULT=PASS_PHASE_14J_MZ_CT204_ISOLATED_RESTORE_DRILL_PROCEDURE_PLAN_NO_APPLY_DOC_READY" "$DOC"

echo "PASS: CT204 isolated restore-drill no-apply plan doc contains required gates"
