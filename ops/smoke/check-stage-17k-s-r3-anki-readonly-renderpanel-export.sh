#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/index.html"
ANKI="${REPO_ROOT}/frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-readonly-session.js"
DOC="${REPO_ROOT}/docs/stage-17k-s-r3-anki-readonly-renderpanel-export.md"

test -f "${INDEX}"
test -f "${ANKI}"
test -f "${DOC}"

grep -Fq 'stage17ks-r3-anki-readonly-renderpanel-export-20260628' "${INDEX}"
grep -Fq 'stage17ks-r3-anki-readonly-renderpanel-export-20260628' "${ANKI}"
grep -Fq 'window.APC_ANKI_READONLY_SESSION' "${ANKI}"
grep -Fq 'renderPanel: renderPanel' "${ANKI}"
grep -Fq 'snapshot: snapshot' "${ANKI}"
grep -Fq 'currentCard: currentCard' "${ANKI}"
grep -Fq 'backend_calls_allowed: false' "${ANKI}"
grep -Fq 'anki_write_allowed: false' "${ANKI}"
grep -Fq 'mydecks_writeback_allowed: false' "${ANKI}"

grep -Fq 'Anki Readonly renderPanel Export' "${DOC}"
grep -Fq 'mounted: false' "${DOC}"
grep -Fq 'adapter present: yes' "${DOC}"
grep -Fq 'adapter rendered: no' "${DOC}"
grep -Fq 'renderPanel: renderPanel' "${DOC}"
grep -Fq 'No backend deploy, DB write, Anki write' "${DOC}"

if command -v node >/dev/null 2>&1; then
  node --check "${ANKI}"
fi

echo "PASS: Stage 17K-S-R3 Anki readonly renderPanel export smoke passed"
