#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12i-vm200-deploy-anki-private-profile-event.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12i-vm200-deploy-anki-private-profile-event"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
ANKI="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Only two files were deployed" "$DOC"
grep -Fq "No wrapper" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "No local backups change" "$DOC"
grep -Fq "No Anki source file mutation" "$DOC"
grep -Fq "anki-manifest-panel.js?v=stage17k-z-r12i-anki-private-profile-event-20260701" "$INDEX"
grep -Fq "APC_ANKI_MANIFEST_PRIVATE_PROFILE_EVENT_ONLY_R12H_R2" "$ANKI"
grep -Fq "Buddies Who Study reads deck names and card counts locally in this browser." "$ANKI"
grep -Fq "R12I_VM200_TWO_FILE_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12I smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12i VM200 deploy Anki private Profile event smoke"
