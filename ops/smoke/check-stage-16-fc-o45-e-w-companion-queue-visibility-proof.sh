#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-w-companion-queue-visibility-proof.md"

echo "=== stage-16-fc-o45-e-w static smoke ==="

test -s "$DOC"
grep -F -q 'Job id: `124`' "$DOC"
grep -F -q 'Status: `queued`' "$DOC"
grep -F -q 'Job type: `companion.chat`' "$DOC"
grep -F -q 'Requested model: `mock/no-model`' "$DOC"
grep -F -q 'Attempts: `0`' "$DOC"
grep -F -q 'Result rows: `0`' "$DOC"
grep -F -q 'This phase was read-only against CT203 SQLite' "$DOC"
grep -F -q 'did not mutate the DB' "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-w static smoke"
