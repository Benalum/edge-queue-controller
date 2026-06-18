#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-il-pvew-storage-risk-posture-no-apply"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "PASS_PVEW_STORAGE_RISK_POSTURE_CAPTURED_NO_APPLY" "$DOC"
grep -Fq "VG pve free: 13.63 GiB" "$DOC"
grep -Fq "Thin autoextend threshold: 100" "$DOC"
grep -Fq "vm-9300-disk-0" "$DOC"
grep -Fq "vm-9300-disk-1" "$DOC"
grep -Fq "data-2tb: disabled" "$DOC"
grep -Fq "Do not create encrypted storage yet" "$DOC"
grep -Fq "storage deletion" "$DOC"
grep -Fq "encrypted storage creation" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|pveam|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} storage risk posture no-apply record verified"
