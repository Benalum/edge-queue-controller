#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-i-anki-readonly-session-adapter-plan.md"

test -f "${DOC}"

grep -Fq 'Stage 17K-I — Anki Read-only Session Adapter Plan' "${DOC}"
grep -Fq 'APC_ANKI_READONLY_SESSION' "${DOC}"
grep -Fq 'APC_STUDY_STORE' "${DOC}"
grep -Fq 'Anki card content must not be stored in localStorage' "${DOC}"
grep -Fq 'Ask the user to select the Anki file again' "${DOC}"
grep -Fq 'source_type === anki_browser_local' "${DOC}"
grep -Fq 'use `fetch`, `XMLHttpRequest`, or `sendBeacon`' "${DOC}"
grep -Fq 'split `notes.flds` on the Anki field separator' "${DOC}"
grep -Fq 'map `Front` to question' "${DOC}"
grep -Fq 'map `Back` to answer' "${DOC}"
grep -Fq 'Companion may read from the Anki read-only session adapter' "${DOC}"
grep -Fq 'aggregate-only metrics' "${DOC}"
grep -Fq 'No frontend deploy, backend deploy, DB write' "${DOC}"

echo "PASS: Stage 17K-I Anki read-only session adapter plan smoke passed"
