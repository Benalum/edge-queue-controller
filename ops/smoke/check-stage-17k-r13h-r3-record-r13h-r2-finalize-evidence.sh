#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-r13h-r3-record-r13h-r2-finalize-evidence.md"
PRIOR_OUT="docs/smoke/generated/stage-17k-r13h-r2-finalize-compact-backup-preview-text-after-tag-collision"

test -f "$DOC"
test -d "$PRIOR_OUT"

grep -Fq "Record R13H-R2 Finalize Evidence" "$DOC"
grep -Fq "Docs/evidence only" "$DOC"
grep -Fq "No source mutation" "$DOC"
grep -Fq "No merge/save/overwrite path" "$DOC"

grep -R "PASS live R13H static smoke" "$PRIOR_OUT"
grep -R "api_system_status=200" "$PRIOR_OUT"
grep -R "api_me_status=401" "$PRIOR_OUT"
grep -R "signup_status=403" "$PRIOR_OUT"

echo "PASS stage-17k-r13h-r3 record R13H-R2 finalize evidence smoke"
