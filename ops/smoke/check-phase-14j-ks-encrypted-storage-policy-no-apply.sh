#!/usr/bin/env bash
set -euo pipefail
DOC="docs/phase-14j-ks-encrypted-storage-policy-no-apply.md"
test -f "$DOC"
grep -Fq 'manual-unlock only' "$DOC"
grep -Fq 'Do not add crypttab, fstab, keyfiles' "$DOC"
grep -Fq 'CT204 remains stopped' "$DOC"
grep -Fq 'admin/status visibility' "$DOC"
echo PASS check-phase-14j-ks-encrypted-storage-policy-no-apply
