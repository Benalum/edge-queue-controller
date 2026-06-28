#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-h-study-source-selector-ui-live-proof.md"

test -f "${DOC}"

grep -Fq "Stage 17K-H — Study Source Selector UI Live Proof" "${DOC}"
grep -Fq "7a00c69" "${DOC}"
grep -Fq "stage17kh-study-source-selector-ui-20260628" "${DOC}"
grep -Fq "selectorPanel: true" "${DOC}"
grep -Fq "hasStudyWithAnki: true" "${DOC}"
grep -Fq "hasStudyWithMyDecks: true" "${DOC}"
grep -Fq "ankiSummaryAvailable: true" "${DOC}"
grep -Fq "sourceType: anki_browser_local" "${DOC}"
grep -Fq "deckName: Anki Deck1" "${DOC}"
grep -Fq "readOnly: true" "${DOC}"
grep -Fq "canEdit: false" "${DOC}"
grep -Fq "canCreate: false" "${DOC}"
grep -Fq "canDelete: false" "${DOC}"
grep -Fq "canFlag: false" "${DOC}"
grep -Fq "canWriteAnki: false" "${DOC}"
grep -Fq "canUploadAnkiContent: false" "${DOC}"
grep -Fq "It does not call the backend" "${DOC}"
grep -Fq "No backend deploy, DB write, Anki write" "${DOC}"

echo "PASS: Stage 17K-H Study source selector UI live proof smoke passed"
