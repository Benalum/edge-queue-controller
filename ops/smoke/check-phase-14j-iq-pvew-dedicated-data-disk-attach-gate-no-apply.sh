#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-iq-pvew-dedicated-data-disk-attach-gate-no-apply"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "PASS_PVEW_DEDICATED_DATA_DISK_ATTACH_GATE_NO_APPLY" "$DOC"
grep -Fq "candidate_data_disk_count=0" "$DOC"
grep -Fq "Encrypted storage creation is blocked" "$DOC"
grep -Fq "Attach or provision a dedicated data disk for PVEW" "$DOC"
grep -Fq "run read-only disk discovery first" "$DOC"
grep -Fq "Do not format, mount, encrypt" "$DOC"
grep -Fq "Keys must not be pasted into ChatGPT" "$DOC"
grep -Fq "Manual unlock comes before any automatic unlock design" "$DOC"
grep -Fq "PVESO shutdown only after rollback checks pass" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|pveam|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump|lvremove|pvesm set|pvesm remove)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} dedicated data disk attach gate no-apply record verified"
