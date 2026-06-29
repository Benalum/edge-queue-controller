#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="$ROOT/docs/stage-17k-y-r3-global-anki-companion-banner-live-proof.md"
INDEX="$ROOT/frontend/wrapper-ui/apc-wrapper-local/index.html"

test -f "$DOC"
test -f "$INDEX"

grep -Fq "Global Anki + Companion Banner Live Proof" "$DOC"
grep -Fq "Anki + Companion update:" "$DOC"
grep -Fq "Companion study integration is in progress" "$DOC"
grep -Fq "Google sync for personal data is planned and not yet enabled" "$DOC"

grep -Fq "<strong>Anki + Companion update:</strong>" "$INDEX"
grep -Fq "Anki decks can be read locally in your browser for deck and card counts." "$INDEX"
grep -Fq "Companion study integration is in progress." "$INDEX"
grep -Fq "Google sync for personal data is planned and not yet enabled." "$INDEX"

echo "PASS: Stage 17K-Y-R3 global banner live proof smoke passed"
