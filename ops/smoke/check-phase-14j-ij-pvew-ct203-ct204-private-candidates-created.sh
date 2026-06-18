#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ij-pvew-ct203-ct204-private-candidates-created"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "PASS_CT203_CT204_CREATED_STOPPED_ONBOOT0_NON_AUTHORITATIVE" "$DOC"
grep -Fq "CT203 edge-controller-pvew" "$DOC"
grep -Fq "CT204 edge-data-pvew" "$DOC"
grep -Fq "Status after creation: stopped" "$DOC"
grep -Fq "Onboot/autostart: 0" "$DOC"
grep -Fq "Unprivileged: 1" "$DOC"
grep -Fq "VM200 website-edge remained running" "$DOC"
grep -Fq "no user/platform DB data was copied" "$DOC"
grep -Fq "no encrypted storage was created" "$DOC"
grep -Fq "thin-pool overcommit warnings" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|pveam|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} CT203/CT204 creation result record verified"
