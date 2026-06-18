#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-lp-pvew-operator-access-inventory-diagnostic-plan-no-apply"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -Fq "Phase 14J-LP" "$DOC"
grep -Fq "PVEW Operator Access / Inventory Diagnostic Plan, No Apply" "$DOC"
grep -Fq "be8eb3d" "$DOC"
grep -Fq "controller-phase-14j-lo-read-only-backup-inventory-shape-check-2026-06-18" "$DOC"
grep -Fq "pvew_ssh=not_reachable_or_alias_missing" "$DOC"
grep -Fq "This phase is docs/smoke only" "$DOC"
grep -Fq "SSH attempt" "$DOC"
grep -Fq "DB backup creation" "$DOC"
grep -Fq "DB restore/import/migration" "$DOC"
grep -Fq "storage unlock, mount, format, key, crypttab, fstab, auto-unlock, or auto-mount mutation" "$DOC"
grep -Fq "CT204 start, service activation, bind-mount role change, or data authority promotion" "$DOC"
grep -Fq "PVESO wake/start or worker/model runtime activation" "$DOC"
grep -Fq "Use read-only commands only" "$DOC"
grep -Fq "Avoid printing private IPs, Tailscale IPs, MAC addresses, tokens, secrets, passwords, bearer values, auth URLs, or keys" "$DOC"
grep -Fq "ssh -G pvew" "$DOC"
grep -Fq "ssh -o BatchMode=yes -o ConnectTimeout=5 pvew true" "$DOC"
grep -Fq "It must not create backups or restore DBs" "$DOC"
grep -Fq "PASS_PHASE_14J_LP_PVEW_OPERATOR_ACCESS_INVENTORY_DIAGNOSTIC_PLAN_NO_APPLY_DONE" "$DOC"

echo "PASS: 14J-LP no-apply operator access diagnostic plan guardrails present"
echo "PASS_${PHASE}"
