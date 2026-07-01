#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-17k-z-r12l-r2-restore-profile-local-backups-card.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r12l-r2-restore-profile-local-backups-card"
INDEX="frontend/wrapper-ui/apc-wrapper-local/index.html"
PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-panel.js"
MOUNT="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-local-backups-mount.js"
CSS="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-private-polish.css"

test -f "$DOC"
test -d "$OUT_DIR"
grep -Fq "Restore Profile Local Backups Card" "$DOC"
grep -Fq "Only four files were deployed" "$DOC"
grep -Fq "No privatepages.js change" "$DOC"
grep -Fq "No Anki logic change" "$DOC"
grep -Fq "No Google Drive sync logic change" "$DOC"

grep -Fq "profile-local-backups-panel.js?v=stage17k-z-r12l-r2-restore-profile-local-backups-card-20260701" "$INDEX"
grep -Fq "profile-local-backups-mount.js?v=stage17k-z-r12l-r2-restore-profile-local-backups-card-20260701" "$INDEX"
grep -Fq "profile-private-polish.css?v=stage17k-z-r12l-r2-restore-profile-local-backups-card-20260701" "$INDEX"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_PANEL_R12L_R2_RESTORED_CARD" "$PANEL"
grep -Fq "Buddies Who Study local backups" "$PANEL"
grep -Fq "Save your data locally." "$PANEL"
grep -Fq "data-apc-local-backup-choose-folder" "$PANEL"
grep -Fq "data-apc-local-backup-download" "$PANEL"
grep -Fq "APC_PROFILE_LOCAL_BACKUPS_MOUNT_R12L_R2_RESTORED_CARD" "$MOUNT"
grep -Fq "function mountIfPrivateProfileShell()" "$MOUNT"
grep -Fq "function scheduleMountIfPrivateProfileShell()" "$MOUNT"
grep -Fq "APC_PRIVATE_PROFILE_LOCAL_BACKUPS_VISIBLE_R12L_R2" "$CSS"

for bad in \
  "Save a copy of your Buddies Who Study local data to a folder you choose on this device." \
  "This does not upload anything, does not modify Anki files, and does not browse your other files." \
  "Do not choose your Anki profile folder. Use a separate backup folder." \
  "Storage: browser-local export. Server upload: no. Anki source mutation: no." \
  "Ready. Choose a local backup folder or download a backup file."; do
  if grep -R -Fq "$bad" "$PANEL" "$MOUNT"; then
    echo "FAIL old local backup text remains: $bad"
    exit 1
  fi
done

grep -Fq "R12L_R2_VM200_LOCAL_BACKUPS_RESTORE_DEPLOY_DONE" "$OUT_DIR/vm200-deploy."*.txt
grep -Fq "PASS public static R12L-R2 smoke" "$OUT_DIR/public-static-smoke."*.txt
grep -Fq "api_system_status=200" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "api_me_status=401" "$OUT_DIR/public-api-guard-smoke."*.txt
grep -Fq "signup_status=403" "$OUT_DIR/public-api-guard-smoke."*.txt

echo "PASS stage-17k-z-r12l-r2 restore Profile local backups card smoke"
