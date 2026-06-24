#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-x-bounded-no-model-execution-job-124.md"

echo "=== stage-16-fc-o45-e-x static smoke ==="

test -s "$DOC"
grep -F -q 'Job id: `124`' "$DOC"
grep -F -q 'Post-status: `completed`' "$DOC"
grep -F -q 'Job type: `companion.chat`' "$DOC"
grep -F -q 'Requested model: `mock/no-model`' "$DOC"
grep -F -q 'Attempts remained: `0`' "$DOC"
grep -F -q 'Job result rows after: `1`' "$DOC"
grep -F -q 'did not start persistent workers' "$DOC"
grep -F -q 'did not start persistent workers, activate scheduler/timer, call Ollama, call any real model' "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-x static smoke"
