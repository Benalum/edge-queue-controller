#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
DOC="$REPO/docs/stage-16-fc-o45-e-u-narrow-cleanup-stale-companion-job-123.md"

echo "=== stage-16-fc-o45-e-u static smoke ==="

test -s "$DOC"
grep -q "job \`123\`" "$DOC"
grep -q "companion.chat" "$DOC"
grep -q "mock/no-model" "$DOC"
grep -q "attempts: \`0\`" "$DOC"
grep -q "Row deletion: none" "$DOC"
grep -q "Schema change: none" "$DOC"
grep -q "PASS: signed-in Companion auth validated; queue_write=false." "$DOC"

echo "RESULT=PASS stage-16-fc-o45-e-u static smoke"
