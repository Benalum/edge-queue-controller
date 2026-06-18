#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-jd-pvew-root-only-private-storage-helper-record.md"

echo "=== smoke: Phase 14J-JD helper record ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_record" "$DOC"
grep -F "APPROVE_PHASE_14J_JD_CREATE_ROOT_ONLY_PRIVATE_STORAGE_UNLOCK_MOUNT_HELPER_NO_SECRETS" "$DOC"
grep -F "Helper path: /root/apc-private-storage-unlock-mount.sh" "$DOC"
grep -F "Owner/group: root:root" "$DOC"
grep -F "Permissions: 700" "$DOC"
grep -F "Embedded secrets: none" "$DOC"
grep -F "/etc/crypttab mutation: none" "$DOC"
grep -F "/etc/fstab mutation: none" "$DOC"
grep -F "systemd service/timer creation: none" "$DOC"
grep -F "mapper_state=already_open" "$DOC"
grep -F "mount_state=already_mounted" "$DOC"
grep -F "PASS_APC_PRIVATE_STORAGE_UNLOCK_MOUNT_HELPER" "$DOC"
grep -F "PASS_NO_PERSISTENCE_BOUNDARIES_UNCHANGED" "$DOC"
grep -F "CT203 remains stopped" "$DOC"
grep -F "CT204 remains stopped" "$DOC"
grep -F "VM200 remains public/static only" "$DOC"
grep -F "Manual recovery path after reboot" "$DOC"

echo "PASS: Phase 14J-JD helper record doc validated"
