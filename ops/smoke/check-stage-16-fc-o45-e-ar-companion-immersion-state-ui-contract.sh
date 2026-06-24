#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ar-companion-immersion-state-ui-contract.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AR" "$DOC"
grep -Fq "Companion Immersion State UI Contract" "$DOC"
grep -Fq "Immersion Mode" "$DOC"
grep -Fq "last user message" "$DOC"
grep -Fq "listening" "$DOC"
grep -Fq "thinking" "$DOC"
grep -Fq "speaking" "$DOC"
grep -Fq "needs_attention" "$DOC"
grep -Fq "Debug details should not be the main user experience" "$DOC"
grep -Fq "Study Tools compatibility" "$DOC"
grep -Fq "FC-O45-E-AS" "$DOC"
grep -Fq "NO backend/frontend deploy" "$DOC"
grep -Fq "Live source inventory" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AR Companion Immersion state UI contract doc smoke"
