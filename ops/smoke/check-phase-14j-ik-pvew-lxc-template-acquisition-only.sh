#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ik-pvew-lxc-template-acquisition-only"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "PASS_PVEW_TEMPLATE_ACQUIRED_ONLY_CT203_CT204_NOT_CREATED" "$DOC"
grep -Fq "debian-13-standard_13.1-2_amd64.tar.zst" "$DOC"
grep -Fq 'VM200 `website-edge` remained running' "$DOC"
grep -Fq "CT203 remained unused" "$DOC"
grep -Fq "CT204 remained unused" "$DOC"
grep -Fq "no CT203/CT204 creation occurred" "$DOC"
grep -Fq "no encrypted storage was created" "$DOC"
grep -Fq "no encryption key was generated" "$DOC"
grep -Fq "no user/platform DB data was copied" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|pveam|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} template acquisition result record verified"
