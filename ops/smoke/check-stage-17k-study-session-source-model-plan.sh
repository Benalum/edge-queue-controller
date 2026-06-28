#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-study-session-source-model-plan.md"

test -f "${DOC}"

grep -Fq "Stage 17K — Study Session Source Model Plan" "${DOC}"
grep -Fq "Study Session with Anki" "${DOC}"
grep -Fq "Study Session with My Decks" "${DOC}"
grep -Fq "Link My Decks with the user's Google Drive" "${DOC}"
grep -Fq "No upload" "${DOC}"
grep -Fq "No backend save" "${DOC}"
grep -Fq "No Anki write" "${DOC}"
grep -Fq "No CDN dependency for production" "${DOC}"
grep -Fq "Do not perform any of the following without a separate approval" "${DOC}"

echo "PASS: Stage 17K Study Session source model plan smoke passed"
