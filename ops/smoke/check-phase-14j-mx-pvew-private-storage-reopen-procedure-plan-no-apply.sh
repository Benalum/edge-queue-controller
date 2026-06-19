#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mx-pvew-private-storage-reopen-procedure-plan-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -Fq "NO-APPLY PLAN ONLY." "$DOC"
grep -Fq "This phase does not unlock, mount, format, write keys, edit crypttab, edit fstab" "$DOC"
grep -Fq "PVEW private storage is locked/unmounted." "$DOC"
grep -Fq "/srv/apc-private-data" "$DOC"
grep -Fq "/dev/mapper/apc_private_data" "$DOC"
grep -Fq "absent/closed" "$DOC"
grep -Fq "APPROVE_PHASE_14J_MY_REOPEN_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE" "$DOC"
grep -Fq "Read the passphrase through a hidden interactive prompt only." "$DOC"
grep -Fq "Do not paste or run this apply command until Phase 14J-MY is explicitly approved." "$DOC"
grep -Fq "The future apply phase must abort before unlocking or mounting if any of these are true:" "$DOC"
grep -Fq "multiple LUKS candidates are found without exact explicit device selection" "$DOC"
grep -Fq "no service restart/reload occurred" "$DOC"
grep -Fq "no backup, restore, DB migration, worker activation, or PVESO wake occurred" "$DOC"
grep -Fq "RESULT=PASS_PHASE_14J_MX_PVEW_PRIVATE_STORAGE_REOPEN_PROCEDURE_PLAN_NO_APPLY_DOC_READY" "$DOC"

echo "PASS: no-apply reopen procedure plan doc contains required gates"
