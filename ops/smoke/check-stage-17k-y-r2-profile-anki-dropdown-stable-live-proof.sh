#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-17k-y-r2-profile-anki-dropdown-stable-live-proof.md"
INDEX="$ROOT/frontend/wrapper-ui/apc-wrapper-local/index.html"
MANIFEST="$ROOT/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js"

test -f "$DOC"
test -f "$INDEX"
test -f "$MANIFEST"

grep -Fq "Profile Anki Dropdown Stable Live Proof" "$DOC"
grep -Fq "dropdown stays open when clicked" "$DOC"
grep -Fq "Decks: 2" "$DOC"
grep -Fq "Total cards: 3" "$DOC"
grep -Fq "Anki Deck1: 2 card(s)" "$DOC"
grep -Fq "Anki Deck2: 1 card(s)" "$DOC"
grep -Fq "Study no longer shows Anki UI" "$DOC"
grep -Fq "Companion no longer shows Anki debug/local-card panels" "$DOC"

grep -Fq "stage17kyr2-profile-anki-dropdown-stable-20260629" "$INDEX"
grep -Fq "stage17kyr2-profile-anki-dropdown-stable-20260629" "$MANIFEST"
grep -Fq "Where is my Anki file?" "$MANIFEST"
grep -Fq "Deck card counts" "$MANIFEST"

echo "PASS: Stage 17K-Y-R2 Profile Anki dropdown stable live proof smoke passed"
