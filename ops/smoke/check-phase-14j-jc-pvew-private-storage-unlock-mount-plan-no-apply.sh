#!/usr/bin/env bash
set -euo pipefail

DOC="docs/phase-14j-jc-pvew-private-storage-unlock-mount-plan-no-apply.md"

echo "=== smoke: Phase 14J-JC private storage unlock/mount plan, no apply ==="

test -f "$DOC"

grep -F "MUTATION_SCOPE: docs_smoke_only_no_apply" "$DOC"
grep -F "Commit 1b005e6" "$DOC"
grep -F "a033a91a-7635-4b60-97d5-db7731861a9f" "$DOC"
grep -F "6787d385-bd40-4cca-81a1-0e1bc62b6157" "$DOC"
grep -F "no keyfile exists" "$DOC"
grep -F "no passphrase is stored" "$DOC"
grep -F "no /etc/crypttab entry exists" "$DOC"
grep -F "no /etc/fstab entry exists" "$DOC"
grep -F "/root/apc-private-storage-unlock-mount.sh" "$DOC"
grep -F "APPROVE_PHASE_14J_JD_CREATE_ROOT_ONLY_PRIVATE_STORAGE_UNLOCK_MOUNT_HELPER_NO_SECRETS" "$DOC"
grep -F "CT203 and CT204 remain stopped" "$DOC"
grep -F "VM200 has no private data access" "$DOC"
grep -F "Do not casually reboot PVEW" "$DOC"

echo "PASS: Phase 14J-JC no-apply plan doc validated"
