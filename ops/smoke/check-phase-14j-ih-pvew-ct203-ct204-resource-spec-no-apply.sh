#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ih-pvew-ct203-ct204-resource-spec-no-apply"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "NO_APPLY_RESOURCE_SPEC_ONLY_CT203_CT204_NOT_CREATED" "$DOC"
grep -Fq "CT203" "$DOC"
grep -Fq "edge-controller-pvew" "$DOC"
grep -Fq "CT204" "$DOC"
grep -Fq "edge-data-pvew" "$DOC"
grep -Fq "Laptop controller remains the live controller/queue authority" "$DOC"
grep -Fq "VM200" "$DOC"
grep -Fq "no public route" "$DOC"
grep -Fq "no encryption key will be printed" "$DOC"
grep -Fq "no data will be copied, dumped, imported, or migrated" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} docs-only no-apply resource spec verified"
