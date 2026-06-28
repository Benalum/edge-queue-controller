#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-f-browser-local-anki-deck-ui-live-proof.md"

test -f "${DOC}"

grep -Fq "Stage 17K-F — Browser-local Anki Deck UI Live Proof" "${DOC}"
grep -Fq "bac9b71" "${DOC}"
grep -Fq "stage17kf-browser-local-deck-ui-20260628" "${DOC}"
grep -Fq "application/wasm" "${DOC}"
grep -Fq "652953" "${DOC}"
grep -Fq "hasLocalDecks: true" "${DOC}"
grep -Fq "hasAnkiDeck1: true" "${DOC}"
grep -Fq "hasAnkiDeck2: true" "${DOC}"
grep -Fq "localSummary.status: extracted" "${DOC}"
grep -Fq "source_type: anki_browser_local" "${DOC}"
grep -Fq "No CDN resource was used" "${DOC}"
grep -Fq "no deck names sent to server" "${DOC}"
grep -Fq "No backend deploy, DB write, Anki write" "${DOC}"

echo "PASS: Stage 17K-F browser-local Anki deck UI live proof smoke passed"
