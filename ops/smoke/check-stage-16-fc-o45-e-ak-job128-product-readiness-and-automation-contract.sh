#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ak-job128-product-readiness-and-automation-contract.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AK" "$DOC"
grep -Fq 'Target job: `128`' "$DOC"
grep -Fq "quality pass: \`true\`" "$DOC"
grep -Fq "quality flags: \`none\`" "$DOC"
grep -Fq "Hello! How can I assist you today?" "$DOC"
grep -Fq "normal signed-in submit -> automatic bounded worker completion -> result-reader display" "$DOC"
grep -Fq "FC-O45-E-AL" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AM_EXACT_ONE_SUBMIT_TO_PERSONA_WORKER_RESULT" "$DOC"
grep -Fq "NO model generation" "$DOC"
grep -Fq "Live read-only output" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AK job128 product readiness and automation contract doc smoke"
