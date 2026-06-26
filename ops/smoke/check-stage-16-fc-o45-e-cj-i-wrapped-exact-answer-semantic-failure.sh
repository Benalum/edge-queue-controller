#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cj-h-r2-wrapped-exact-answer-semantic-failure.md"

test -f "$DOC"

grep -Fq "Wrapped Exact-Answer Semantic Failure" "$DOC"
grep -Fq "kind=exact_answer" "$DOC"
grep -Fq "FC-O45-E-CJ-H-WRAPPED-OK" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "OK" "$DOC"
grep -Fq "id=574" "$DOC"
grep -Fq "status=failed" "$DOC"
grep -Fq "result_rows=0" "$DOC"
grep -Fq "semantic exact mismatch: got=OK" "$DOC"
grep -Fq "Prompt wrapping alone is not enough" "$DOC"
grep -Fq "deterministic short-circuit" "$DOC"
grep -Fq "do not call the model" "$DOC"
grep -Fq "No frontend patch" "$DOC"

echo "PASS stage-16-fc-o45-e-cj-i wrapped exact-answer semantic failure record smoke"
