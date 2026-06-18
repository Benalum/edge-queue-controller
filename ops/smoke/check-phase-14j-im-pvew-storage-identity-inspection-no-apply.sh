#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-im-pvew-storage-identity-inspection-no-apply"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "PASS_PVEW_STORAGE_IDENTITY_INSPECTION_NO_APPLY" "$DOC"
grep -Fq "vm-9300-disk-0" "$DOC"
grep -Fq "vm-9300-disk-1" "$DOC"
grep -Fq "qm 9300 status: absent" "$DOC"
grep -Fq "pct 9300 status: absent" "$DOC"
grep -Fq "Do not delete them" "$DOC"
grep -Fq "data-2tb: disabled" "$DOC"
grep -Fq "nodes: pveso" "$DOC"
grep -Fq "Do not allocate encrypted data storage on local-lvm yet" "$DOC"
grep -Fq "Container OS/root disks do not need to be encrypted before private data exists" "$DOC"
grep -Fq "Only migrate data after the encrypted storage path is created" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|pveam|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump|lvremove|pvesm set|pvesm remove)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} storage identity no-apply record verified"
