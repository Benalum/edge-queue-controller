#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-g-study-source-selector-plan.md"

test -f "${DOC}"

grep -Fq "Stage 17K-G — Study Source Selector Plan" "${DOC}"
grep -Fq "Study with Anki" "${DOC}"
grep -Fq "Study with MyDecks" "${DOC}"
grep -Fq "Anki is a browser-local, read-only source" "${DOC}"
grep -Fq "upload Anki deck names" "${DOC}"
grep -Fq "write to Anki" "${DOC}"
grep -Fq "source type: anki_browser_local" "${DOC}"
grep -Fq "session length in seconds" "${DOC}"
grep -Fq "cards reviewed count" "${DOC}"
grep -Fq "Companion should become source-aware" "${DOC}"
grep -Fq "MyDecks permissions must remain separate from Anki permissions" "${DOC}"
grep -Fq "No frontend deploy, backend deploy, DB write" "${DOC}"

echo "PASS: Stage 17K-G Study source selector plan smoke passed"
