#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ij-pvew-ct203-ct204-template-blocker-review-no-apply"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "NO_APPLY_TEMPLATE_BLOCKER_CT203_CT204_NOT_CREATED" "$DOC"
grep -Fq "template cache was empty" "$DOC"
grep -Fq "CT203 was unused" "$DOC"
grep -Fq "CT204 was unused" "$DOC"
grep -Fq "download one approved LXC template" "$DOC"
grep -Fq "no CT203/CT204 creation yet" "$DOC"
grep -Fq "no data migration/copy/dump/import" "$DOC"
grep -Fq "no encryption key generation" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|pveam|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} docs-only template blocker review verified"
