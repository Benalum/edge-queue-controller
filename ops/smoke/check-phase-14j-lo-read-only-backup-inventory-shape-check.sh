#!/usr/bin/env bash
set -euo pipefail
set +H

PHASE="phase-14j-lo-read-only-backup-inventory-shape-check"
DOC="docs/${PHASE}.md"

echo "=== smoke: ${PHASE} ==="

test -f "$DOC"

grep -q "Phase 14J-LO" "$DOC"
grep -q "Read-Only Backup Inventory Shape Check" "$DOC"
grep -q "138b1ed" "$DOC"
grep -q "controller-phase-14j-ln-ct203-backup-hardening-no-apply-2026-06-18" "$DOC"
grep -q "public_system_status_http=200" "$DOC"
grep -q "overall_state=online" "$DOC"
grep -q "normalized_schema_version=2" "$DOC"
grep -q "node_ids_sorted=ct-203,ct-204,pvew,vm-200" "$DOC"
grep -q "private_storage_policy=manual-unlock-only" "$DOC"
grep -q "private_storage_mount_state_public=unknown" "$DOC"
grep -q "ct204_expected_state=stopped" "$DOC"
grep -q "ct204_data_authority=false" "$DOC"
grep -q "pvew_ssh=not_reachable_or_alias_missing" "$DOC"
grep -q "Optional host/CT203 backup inventory was skipped" "$DOC"
grep -q "No assumptions were made about live host mount state" "$DOC"
grep -q "CT204 remains stopped, backup-data-only, and non-authoritative" "$DOC"
grep -q "PVESO remains parked/on-demand" "$DOC"
grep -q "No DB restore/import/migration/authority change occurred" "$DOC"
grep -q "No storage unlock/mount/key/crypttab/fstab/auto-unlock/auto-mount mutation occurred" "$DOC"
grep -q "PASS_PHASE_14J_LO_READ_ONLY_BACKUP_INVENTORY_SHAPE_CHECK_RECORDED" "$DOC"

echo "PASS: 14J-LO read-only backup inventory evidence doc guardrails present"
echo "PASS_${PHASE}"
