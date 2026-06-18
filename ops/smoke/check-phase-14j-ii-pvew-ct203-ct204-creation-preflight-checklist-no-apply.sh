#!/usr/bin/env bash
set -euo pipefail

PHASE="phase-14j-ii-pvew-ct203-ct204-creation-preflight-checklist-no-apply"
DOC="docs/${PHASE}.md"

test -f "$DOC"
grep -Fq "NO_APPLY_PREFLIGHT_ONLY_CT203_CT204_NOT_CREATED" "$DOC"
grep -Fq "CT203 and CT204 are still not created" "$DOC"
grep -Fq "laptop DB quick_check is ok" "$DOC"
grep -Fq "CT203 is unused" "$DOC"
grep -Fq "CT204 is unused" "$DOC"
grep -Fq "no user/platform data is copied, dumped, imported, or migrated" "$DOC"
grep -Fq "no encryption key is generated, printed, stored, or installed" "$DOC"
grep -Fq "no public route, DNS, Cloudflare, or tunnel mutation occurs" "$DOC"

if grep -Eq '^[[:space:]]*(pct|qm|cryptsetup|lvcreate|mkfs|mount|systemctl|sqlite3[[:space:]].*\.dump)' "$DOC"; then
  echo "FAIL: doc contains executable mutation-looking command line"
  exit 1
fi

echo "PASS: ${PHASE} docs-only no-apply creation preflight verified"
