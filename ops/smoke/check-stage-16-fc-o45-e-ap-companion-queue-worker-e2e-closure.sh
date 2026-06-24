#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ap-companion-queue-worker-e2e-closure.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AP" "$DOC"
grep -Fq "normal browser signed-in submit" "$DOC"
grep -Fq "transient exact-one queue worker reads that job" "$DOC"
grep -Fq "result-reader-compatible completed Companion job" "$DOC"
grep -Fq "id=132" "$DOC"
grep -Fq "requested_model=qwen2.5:0.5b" "$DOC"
grep -Fq "quality_pass=true" "$DOC"
grep -Fq "quality_flags=none" "$DOC"
grep -Fq "Hello! Feel free to ask any questions or let me know how I can help today!" "$DOC"
grep -Fq "FC-O45-E-AQ" "$DOC"
grep -Fq "NO model generation" "$DOC"
grep -Fq "Live read-only output" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AP Companion queue-worker E2E closure doc smoke"
