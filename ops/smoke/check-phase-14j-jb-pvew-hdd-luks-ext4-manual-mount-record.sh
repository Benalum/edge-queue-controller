#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-jb-pvew-hdd-luks-ext4-manual-mount-record.md"

echo "=== smoke: Phase 14J-JB PVEW HDD LUKS/ext4 manual mount record ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_record" "$DOC"
grep -F "APPROVE_PHASE_14J_JA_PVEW_HDD_WIPE_LUKS_CREATE_MANUAL_UNLOCK_ONLY" "$DOC"
grep -F "/dev/disk/by-id/ata-Hitachi_HDS721010CLA332_JP2940J81AMYSD" "$DOC"
grep -F "Hitachi HDS721010CLA332" "$DOC"
grep -F "JP2940J81AMYSD" "$DOC"
grep -F "Partition label: apc-private-luks" "$DOC"
grep -F "LUKS mapper name: apc_private_data" "$DOC"
grep -F "LUKS UUID: a033a91a-7635-4b60-97d5-db7731861a9f" "$DOC"
grep -F "Filesystem: ext4" "$DOC"
grep -F "Filesystem label: apc-private-data" "$DOC"
grep -F "Filesystem UUID: 6787d385-bd40-4cca-81a1-0e1bc62b6157" "$DOC"
grep -F "Manual mount path: /srv/apc-private-data" "$DOC"
grep -F "No /etc/crypttab persistence was added" "$DOC"
grep -F "No /etc/fstab persistence was added" "$DOC"
grep -F "CT203 remains stopped" "$DOC"
grep -F "CT204 remains stopped" "$DOC"
grep -F "No database dump, copy, import, migration, or controller authority move occurred" "$DOC"
grep -F "The encrypted storage is currently manual/nonpersistent" "$DOC"

echo "PASS: Phase 14J-JB record doc validated"
