#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-e-anki-local-only-study-contract.md"

test -f "${DOC}"

grep -Fq "Stage 17K-E — Anki Local-only Study Contract" "${DOC}"
grep -Fq "Anki decks are a browser-local, read-only study source" "${DOC}"
grep -Fq "Study with Anki" "${DOC}"
grep -Fq "Study with MyDecks" "${DOC}"
grep -Fq "Card/question/answer/media content remains local to the browser" "${DOC}"
grep -Fq "APC does not upload Anki deck names, card text, answers, note fields, tags, or media" "${DOC}"
grep -Fq "mark the card right or wrong locally" "${DOC}"
grep -Fq "write to collection.anki2 or collection.anki21" "${DOC}"
grep -Fq "source type: anki_browser_local" "${DOC}"
grep -Fq "session length in seconds" "${DOC}"
grep -Fq "cards reviewed count" "${DOC}"
grep -Fq "deck name" "${DOC}"
grep -Fq "per-card right/wrong history" "${DOC}"
grep -Fq "MyDecks permissions must stay separate from Anki permissions" "${DOC}"
grep -Fq "No frontend deploy, backend deploy, DB write" "${DOC}"

echo "PASS: Stage 17K-E Anki local-only study contract smoke passed"
