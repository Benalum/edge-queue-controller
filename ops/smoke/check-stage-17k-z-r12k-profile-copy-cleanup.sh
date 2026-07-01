#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12k-profile-copy-cleanup.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12k-profile-copy-cleanup"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
ANKI="frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Only four files were deployed" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "Save your data locally." "$PANEL"
grep -Fq "<pre data-apc-local-backup-status hidden></pre>" "$PANEL"
grep -Fq "node.hidden = lines.length === 0;" "$MOUNT"
grep -Fq "Choose your Anki collection file. Buddies Who Study will not edit any of your Anki files." "$ANKI"
grep -Fq "anki-manifest-panel.js?v=stage17k-z-r12k-profile-copy-cleanup-20260701" "$INDEX"
grep -Fq "profile-local-backups-panel.js?v=stage17k-z-r12k-profile-copy-cleanup-20260701" "$INDEX"
grep -Fq "profile-local-backups-mount.js?v=stage17k-z-r12k-profile-copy-cleanup-20260701" "$INDEX"

for bad in \
  "Save a copy of your Buddies Who Study local data to a folder you choose on this device." \
  "This does not upload anything, does not modify Anki files, and does not browse your other files." \
  "Do not choose your Anki profile folder. Use a separate backup folder." \
  "Storage: browser-local export. Server upload: no. Anki source mutation: no." \
  "Ready. Choose a local backup folder or download a backup file." \
  "Choose your Anki collection file. Buddies Who Study reads deck names and card counts locally in this browser."; do
  if grep -R -Fq "$bad" "$PANEL" "$MOUNT" "$ANKI"; then
    echo "FAIL old requested text remains: $bad"
    exit 1
  fi
done

grep -Fq "R12K_VM200_COPY_CLEANUP_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12K smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12k Profile copy cleanup smoke"
