#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ah-job127-result-reader-quality-contract.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AH" "$DOC"
grep -Fq "Target job: `127`" "$DOC"
grep -Fq "requested_model=qwen2.5:0.5b" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "I am Qwen" "$DOC"
grep -Fq "Product-quality finding" "$DOC"
grep -Fq "FC-O45-E-AI" "$DOC"
grep -Fq "NO model generation" "$DOC"
grep -Fq "Live read-only output" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AH job127 result-reader quality contract doc smoke"
