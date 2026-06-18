#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ip-pvew-dedicated-disk-discovery-no-apply"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "PASS_PVEW_DEDICATED_DISK_DISCOVERY_NO_CANDIDATE_DISK_NO_APPLY" "$DOC"
grep -Fq "candidate_data_disk_count=0" "$DOC"
grep -Fq "PNY CS900 120GB SSD" "$DOC"
grep -Fq "No dedicated PVEW data disk is currently visible" "$DOC"
grep -Fq "Do not create encrypted storage yet" "$DOC"
grep -Fq "Do not allocate encrypted data storage from local-lvm yet" "$DOC"
grep -Fq "Do not use data-2tb on PVEW" "$DOC"
grep -Fq "Do not reuse or delete vm-9300 volumes" "$DOC"
grep -Fq "physically attach or provision a dedicated data disk for PVEW" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|pveam|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump|lvremove|pvesm set|pvesm remove)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} dedicated disk discovery no-apply record verified"
