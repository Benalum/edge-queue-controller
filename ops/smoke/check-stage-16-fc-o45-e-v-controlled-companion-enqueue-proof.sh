#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-v-controlled-companion-enqueue-proof.md"

echo "=== stage-16-fc-o45-e-v-controlled-companion-enqueue-proof static smoke ==="

test -s "$DOC"
grep -q "New job id: `124`" "$DOC"
grep -q "Status: `queued`" "$DOC"
grep -q "Job type: `companion.chat`" "$DOC"
grep -q "Attempts: `0`" "$DOC"
grep -q "Forwarded: no" "$DOC"
grep -q "Completed: no" "$DOC"
grep -q "did not complete the job" "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-v-controlled-companion-enqueue-proof static smoke"
