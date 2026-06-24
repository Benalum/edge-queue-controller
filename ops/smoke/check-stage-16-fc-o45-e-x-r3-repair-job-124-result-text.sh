#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-x-r3-repair-job-124-result-text.md"

echo "=== stage-16-fc-o45-e-x-r4 static smoke ==="

test -s "$DOC"
grep -F -q 'Job id: `124`' "$DOC"
grep -F -q 'Job status before and after repair: `completed`' "$DOC"
grep -F -q 'Requested model: `mock/no-model`' "$DOC"
grep -F -q 'Existing result rows for job 124: `1`' "$DOC"
grep -F -q 'New result rows inserted: `0`' "$DOC"
grep -F -q 'FC-O45-E-X-R4 repaired mock no-model completion text for Companion job 124.' "$DOC"
grep -F -q 'did not insert another result row' "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-x-r4 static smoke"
