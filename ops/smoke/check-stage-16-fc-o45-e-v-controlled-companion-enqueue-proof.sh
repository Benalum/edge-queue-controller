#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-v-controlled-companion-enqueue-proof.md"

echo "=== stage-16-fc-o45-e-v-controlled-companion-enqueue-proof static smoke ==="

test -s "$DOC"
grep -F -q 'New job id: `124`' "$DOC"
grep -F -q 'Status: `queued`' "$DOC"
grep -F -q 'Job type: `companion.chat`' "$DOC"
grep -F -q 'Requested model: `mock/no-model`' "$DOC"
grep -F -q 'Attempts: `0`' "$DOC"
grep -F -q 'Forwarded: no' "$DOC"
grep -F -q 'Completed: no' "$DOC"
grep -F -q 'did not complete the job' "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-v-controlled-companion-enqueue-proof static smoke"
