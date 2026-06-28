#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-c-browser-sqlite-parser-decision.md"

test -f "${DOC}"

grep -Fq "Stage 17K-C — Browser SQLite Parser Decision" "${DOC}"
grep -Fq "Decision: use a locally vendored, pinned sql.js asset set" "${DOC}"
grep -Fq "Do not use a CDN dependency for production" "${DOC}"
grep -Fq "sql-wasm.js" "${DOC}"
grep -Fq "sql-wasm.wasm" "${DOC}"
grep -Fq "Anki Deck1: 2 cards, 2 notes" "${DOC}"
grep -Fq "Anki Deck2: 1 card, 1 note" "${DOC}"
grep -Fq "decks.name for deck names" "${DOC}"
grep -Fq "notetypes.name for note type names" "${DOC}"
grep -Fq "Study with Anki" "${DOC}"
grep -Fq "Study with My Decks" "${DOC}"
grep -Fq "No frontend deploy, backend deploy, DB write" "${DOC}"

echo "PASS: Stage 17K-C browser SQLite parser decision smoke passed"
