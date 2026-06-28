#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOC="${REPO_ROOT}/docs/stage-17k-j-anki-readonly-session-skeleton-live-proof.md"

test -f "${DOC}"

grep -Fq 'Stage 17K-J — Anki Read-only Session Skeleton Live Proof' "${DOC}"
grep -Fq '0a0a69b' "${DOC}"
grep -Fq 'stage17kj-anki-readonly-session-skeleton-20260628' "${DOC}"
grep -Fq 'APC_ANKI_READONLY_SESSION' "${DOC}"
grep -Fq 'selection_source_type: anki_browser_local' "${DOC}"
grep -Fq 'selected_deck_name: Anki Deck1' "${DOC}"
grep -Fq 'status: skeleton_active' "${DOC}"
grep -Fq 'active: true' "${DOC}"
grep -Fq 'selected_file_name: collection.anki2' "${DOC}"
grep -Fq 'selected_file_size: 139264' "${DOC}"
grep -Fq 'selected_file_header_kind: sqlite-anki-collection' "${DOC}"
grep -Fq 'card_count_in_memory: 0' "${DOC}"
grep -Fq 'browser_memory_only: true' "${DOC}"
grep -Fq 'card_text_localstorage_allowed: false' "${DOC}"
grep -Fq 'backend_calls_allowed: false' "${DOC}"
grep -Fq 'anki_write_allowed: false' "${DOC}"
grep -Fq 'mydecks_writeback_allowed: false' "${DOC}"
grep -Fq 'No backend deploy, DB write, Anki write' "${DOC}"
grep -Fq 'No Anki card text was extracted' "${DOC}"
grep -Fq 'No backend API call is allowed' "${DOC}"

echo "PASS: Stage 17K-J Anki read-only session skeleton live proof smoke passed"
