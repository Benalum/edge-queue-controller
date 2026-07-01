#!/usr/bin/env bash
set -euo pipefail

PANEL="frontend/wrapper-ui/apc-wrapper-local/privatepages/profile-google-sync-panel.js"
DOC="docs/stage-17k-z-r11v-r2-profile-local-data-copy-commit-recovery.md"
OUT_DIR="docs/smoke/generated/stage-17k-z-r11v-r2-profile-local-data-copy-commit-recovery"

test -f "$PANEL"
test -f "$DOC"
test -d "$OUT_DIR"

grep -Fq "Buddies Who Study local data" "$PANEL"
grep -Fq "Create hidden Buddies Who Study local data database" "$PANEL"
grep -Fq "Read Buddies Who Study local data metadata" "$PANEL"
grep -Fq "Rollback/delete Buddies Who Study local data proof files" "$PANEL"
grep -Fq "I understand Buddies Who Study will create hidden app data" "$PANEL"

if grep -Fq "I understand APC will" "$PANEL"; then
  echo "FAIL: old user-facing APC consent copy remains"
  exit 1
fi

if grep -Fq "APC-native decks" "$PANEL"; then
  echo "FAIL: old APC-native decks copy remains"
  exit 1
fi

if grep -Fq "Create hidden APC sync database" "$PANEL"; then
  echo "FAIL: old hidden APC sync database copy remains"
  exit 1
fi

if grep -Fq "Read APC app data metadata" "$PANEL"; then
  echo "FAIL: old Read APC app data metadata copy remains"
  exit 1
fi

if grep -Fq "Rollback/delete APC proof files" "$PANEL"; then
  echo "FAIL: old Rollback/delete APC proof files copy remains"
  exit 1
fi

grep -Fq "No deploy" "$DOC"
grep -Fq "No frontend live mutation" "$DOC"
grep -Fq "No backend route addition" "$DOC"
grep -Fq "No server private Study persistence" "$DOC"
grep -Fq "No Google Drive or OAuth activation" "$DOC"
grep -Fq "No Anki source file mutation" "$DOC"
grep -Fq "Only one source file is intended to change" "$DOC"
grep -Fq "Buddies Who Study local data" "$DOC"
grep -Fq "copy-only" "$DOC"

test -f "$OUT_DIR/copy-check."*.txt
grep -Fq "PASS Buddies Who Study local data copy present" "$OUT_DIR/copy-check."*.txt

echo "PASS stage-17k-z-r11v-r2 Profile local data copy commit recovery smoke"
