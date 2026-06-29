#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="$ROOT/frontend/wrapper-ui/apc-wrapper-local/index.html"
DOC="$ROOT/docs/stage-17k-y-r3-global-anki-companion-banner.md"

test -f "$INDEX"
test -f "$DOC"

grep -Fq "<strong>Anki + Companion update:</strong>" "$INDEX"
grep -Fq "Anki decks can be read locally in your browser for deck and card counts." "$INDEX"
grep -Fq "Companion study integration is in progress." "$INDEX"
grep -Fq "Google sync for personal data is planned and not yet enabled." "$INDEX"

for old in \
  "<strong>Data ownership update:</strong>" \
  "We’re working toward Google Drive sync" \
  "Current storage remains on the existing platform until Drive sync is built, tested, and enabled."
do
  if grep -Fq "$old" "$INDEX"; then
    echo "old banner marker remains: $old"
    exit 1
  fi
done

grep -Fq "Global Anki + Companion Banner" "$DOC"
grep -Fq "No backend deploy, DB write, Anki write" "$DOC"

echo "PASS: Stage 17K-Y-R3 global Anki + Companion banner smoke passed"
