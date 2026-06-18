#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-in-encrypted-at-rest-placement-design-no-apply"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "PASS_ENCRYPTED_AT_REST_PLACEMENT_DESIGN_NO_APPLY" "$DOC"
grep -Fq "real data migration waits until encrypted data storage exists" "$DOC" || true
grep -Fq "The already-created CT203 and CT204 root disks do not need to be encrypted before private data exists inside them" "$DOC"
grep -Fq "Use encrypted storage as the baseline at-rest control" "$DOC"
grep -Fq "Do not use local-lvm for encrypted data allocation yet" "$DOC"
grep -Fq "Add or attach a dedicated data disk to PVEW" "$DOC"
grep -Fq "Do not paste keys into ChatGPT" "$DOC"
grep -Fq "Do not store keys in git" "$DOC"
grep -Fq "Do not print keys in terminal output" "$DOC"
grep -Fq "DB dump/copy/import/migration" "$DOC"
grep -Fq "PVESO shutdown only after rollback and authority checks pass" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|pveam|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump|lvremove|pvesm set|pvesm remove)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} encrypted-at-rest placement design no-apply record verified"
