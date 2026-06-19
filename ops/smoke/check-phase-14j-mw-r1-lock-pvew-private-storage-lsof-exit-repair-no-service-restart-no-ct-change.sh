#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-mw-r1-lock-pvew-private-storage-lsof-exit-repair-no-service-restart-no-ct-change"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -Fq "COMPLETED." "$DOC"
grep -Fq "APPROVE_PHASE_14J_MW_LOCK_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE" "$DOC"
grep -Fq "can return nonzero when no files are open" "$DOC"
grep -Fq "no service restart/reload/enable/start/stop" "$DOC"
grep -Fq "no CT/VM start/stop/restart/config mutation" "$DOC"
grep -Fq "no backup creation" "$DOC"
grep -Fq "RESULT_REMOTE=PASS_PHASE_14J_MW_R1_PVEW_PRIVATE_STORAGE_UNMOUNTED_AND_MAPPER_CLOSED" "$DOC"
grep -Fq "PVEW private storage is locked/unmounted." "$DOC"
grep -Fq "/srv/apc-private-data" "$DOC"
grep -Fq "/dev/mapper/apc_private_data" "$DOC"
grep -Fq "CT204 remains stopped, backup-data-only, and data_authority=false." "$DOC"
grep -Fq "Any private storage reopen/unlock/mount requires a separate explicit approval boundary." "$DOC"
grep -Fq "Smoke recovery note" "$DOC"
grep -Fq "This recovery step did not rerun storage mutation." "$DOC"
grep -Fq "RESULT=PASS_PHASE_14J_MW_R1_LOCK_PVEW_PRIVATE_STORAGE_NO_SERVICE_RESTART_NO_CT_CHANGE_DONE" "$DOC"

echo "PASS: Phase 14J-MW-R1 apply record contains required evidence and gates"
