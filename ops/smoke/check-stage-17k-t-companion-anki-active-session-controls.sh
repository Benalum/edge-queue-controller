#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
ANKI="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js"
DOC="${REPO_ROOT}/docs/stage-17k-t-companion-anki-active-session-controls.md"

test -f "${INDEX}"
test -f "${ANKI}"
test -f "${DOC}"

grep -Fq 'stage17kt-companion-anki-active-session-controls-20260628' "${INDEX}"
grep -Fq 'stage17kt-companion-anki-active-session-controls-20260628' "${ANKI}"
grep -Fq 'function isCompanionRoute()' "${ANKI}"
grep -Fq 'if (!isStudyRoute() && !isCompanionRoute()) return;' "${ANKI}"
grep -Fq 'document.getElementById("apc-companion-local-anki-bridge")' "${ANKI}"
grep -Fq 'renderPanel: renderPanel' "${ANKI}"
grep -Fq 'extractBasicCardsIntoMemory: extractBasicCardsIntoMemory' "${ANKI}"
grep -Fq 'snapshot: snapshot' "${ANKI}"
grep -Fq 'currentCard: currentCard' "${ANKI}"
grep -Fq 'backend_calls_allowed: false' "${ANKI}"
grep -Fq 'anki_write_allowed: false' "${ANKI}"
grep -Fq 'mydecks_writeback_allowed: false' "${ANKI}"

grep -Fq 'Companion Anki Active Session Controls' "${DOC}"
grep -Fq 'active: true' "${DOC}"
grep -Fq 'cards in memory: > 0' "${DOC}"
grep -Fq 'no question text' "${DOC}"
grep -Fq 'no answer text' "${DOC}"
grep -Fq 'No backend deploy, DB write, Anki write' "${DOC}"

if command -v node >/dev/null 2>&1; then
  node --check "${ANKI}"
fi

echo "PASS: Stage 17K-T Companion Anki active session controls smoke passed"
