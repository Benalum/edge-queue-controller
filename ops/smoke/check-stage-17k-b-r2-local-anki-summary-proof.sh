#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-b-r2-local-anki-summary-proof.md"

test -f "${DOC}"
grep -Fq "Stage 17K-B-R2 — Local Anki Summary Proof" "${DOC}"
grep -Fq "sqlite-anki-collection" "${DOC}"
grep -Fq "Cards: \`3\`" "${DOC}"
grep -Fq "Notes: \`3\`" "${DOC}"
grep -Fq "Decks with cards: \`2\`" "${DOC}"
grep -Fq "Default\`: 2 cards, 2 notes" "${DOC}"
grep -Fq "Deck 1782669587926\`: 1 card, 1 note" "${DOC}"
grep -Fq "SQLite open mode: \`mode=ro\`" "${DOC}"
grep -Fq "Writes performed: \`false\`" "${DOC}"
grep -Fq "Uploads performed: \`false\`" "${DOC}"

echo "PASS: Stage 17K-B-R2 local Anki summary proof smoke passed"
