#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-ln-ct203-backup-hardening-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -q "Phase 14J-LN" "$DOC"
grep -q "CT203 Backup Hardening Plan, No Apply" "$DOC"
grep -q "CT203 .*live controller/API/queue authority" "$DOC"
grep -q "CT204 .*stopped, backup-data-only, and not data authority" "$DOC"
grep -q "manual-unlock-only" "$DOC"
grep -q "No Class A backup creation is performed by this phase" "$DOC"
grep -q "No storage inspection or mutation is performed by this phase" "$DOC"
grep -q "No CT203 service or config inspection is performed by this phase" "$DOC"
grep -q "No live infrastructure, DB, storage, service, CT/VM, route, tunnel, Cloudflare, PVESO, or CT204 mutation occurred" "$DOC"
grep -q "PASS_PHASE_14J_LN_CT203_BACKUP_HARDENING_NO_APPLY_DONE" "$DOC"

# Required explicit non-mutation guardrails.
grep -q "DB restore, import, migration, authority switch, or controller DB swap" "$DOC"
grep -q "crypttab, fstab, auto-unlock, or auto-mount mutation" "$DOC"
grep -q "CT204 start, CT204 service activation, CT204 bind-mount role change, or CT204 authority promotion" "$DOC"
grep -q "PVESO wake/start or worker/model runtime activation" "$DOC"
grep -q "Cloudflare, DNS, tunnel, nginx public route, or public cutover mutation" "$DOC"

echo "PASS: static no-apply backup hardening doc guardrails present"
echo "PASS_${PHASE}"
