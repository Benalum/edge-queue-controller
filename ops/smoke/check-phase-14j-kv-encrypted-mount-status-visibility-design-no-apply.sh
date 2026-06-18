#!/usr/bin/env bash
set -euo pipefail
DOC="docs/phase-14j-kv-encrypted-mount-status-visibility-design-no-apply.md"
test -f "$DOC"
grep -Fq 'cannot directly inspect the PVEW host mount' "$DOC"
grep -Fq 'Do not fake mount visibility' "$DOC"
grep -Fq 'manual-unlock-only' "$DOC"
grep -Fq 'Option B' "$DOC"
grep -Fq 'mount_state=unknown' "$DOC"
echo PASS check-phase-14j-kv-encrypted-mount-status-visibility-design-no-apply
