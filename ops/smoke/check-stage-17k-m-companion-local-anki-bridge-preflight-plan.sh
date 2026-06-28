#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-m-companion-local-anki-bridge-preflight-plan.md"
COMPANION="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/companion.js"
ANKI="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js"
STUDY_SELECTOR="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/study-source-selector.js"

test -f "${DOC}"
test -f "${COMPANION}"
test -f "${ANKI}"
test -f "${STUDY_SELECTOR}"

grep -Fq 'Stage 17K-M — Companion Local Anki Bridge Preflight Plan' "${DOC}"
grep -Fq 'controller-stage-17k-l-anki-local-review-loop-live-proof-2026-06-28' "${DOC}"
grep -Fq 'APC_ANKI_READONLY_SESSION.snapshot()' "${DOC}"
grep -Fq 'APC_ANKI_READONLY_SESSION.currentCard()' "${DOC}"
grep -Fq 'privatepages/companion-local-anki-bridge.js' "${DOC}"
grep -Fq 'backend_calls_allowed: false' "${DOC}"
grep -Fq 'anki_write_allowed: false' "${DOC}"
grep -Fq 'fetch' "${DOC}"
grep -Fq 'XMLHttpRequest' "${DOC}"
grep -Fq 'sendBeacon' "${DOC}"
grep -Fq 'No frontend deploy, backend deploy, DB write' "${DOC}"

grep -Fq 'APC_ANKI_READONLY_SESSION' "${ANKI}"
grep -Fq 'currentCard' "${ANKI}"
grep -Fq 'snapshot' "${ANKI}"
grep -Fq 'card_text_localstorage_allowed: false' "${ANKI}"
grep -Fq 'backend_calls_allowed: false' "${ANKI}"
grep -Fq 'anki_write_allowed: false' "${ANKI}"
grep -Fq 'anki_browser_local' "${STUDY_SELECTOR}"

echo "PASS: Stage 17K-M Companion local Anki bridge preflight plan smoke passed"
