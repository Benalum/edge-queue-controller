#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-b-r3-table-name-anki-summary-proof.md"

test -f "${DOC}"

grep -Fq "Stage 17K-B-R3 — Table-name Anki Summary Proof" "${DOC}"
grep -Fq "Anki Deck1: 2 cards, 2 notes" "${DOC}"
grep -Fq "Anki Deck2: 1 card, 1 note" "${DOC}"
grep -Fq "Basic: 3 notes" "${DOC}"
grep -Fq "Fields: Front, Back" "${DOC}"
grep -Fq "Deck names source: decks table" "${DOC}"
grep -Fq "Note type names source: notetypes table" "${DOC}"
grep -Fq "SQLite open mode: mode=ro" "${DOC}"
grep -Fq "Writes performed: false" "${DOC}"
grep -Fq "Uploads performed: false" "${DOC}"
grep -Fq "Anki file modified: false" "${DOC}"

echo "PASS: Stage 17K-B-R3 table-name Anki summary proof smoke passed"
