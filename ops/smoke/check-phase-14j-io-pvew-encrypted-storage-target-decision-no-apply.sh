#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-io-pvew-encrypted-storage-target-decision-no-apply"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "PASS_PVEW_ENCRYPTED_STORAGE_TARGET_DECISION_NO_APPLY" "$DOC"
grep -Fq "Do not create encrypted storage on PVEW local-lvm yet" "$DOC"
grep -Fq "Do not use data-2tb on PVEW" "$DOC"
grep -Fq "Do not reuse or delete vm-9300 volumes" "$DOC"
grep -Fq "dedicated disk physically attached to PVEW" "$DOC"
grep -Fq "CT203 and CT204 root disks can remain plain" "$DOC"
grep -Fq "Attach a dedicated data disk to PVEW, then run read-only disk discovery" "$DOC"
grep -Fq "No encryption, formatting, mounting, DB migration, or service startup" "$DOC"
grep -Fq "PVESO shutdown" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|pveam|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump|lvremove|pvesm set|pvesm remove)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} encrypted storage target decision no-apply record verified"
