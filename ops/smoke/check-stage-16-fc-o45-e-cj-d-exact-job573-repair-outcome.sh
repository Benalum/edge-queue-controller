#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

DOC="docs/stage-16-fc-o45-e-cj-c-r2-exact-job573-repair-outcome.md"

test -f "$DOC"

grep -Fq "Exact Job573 Repair Outcome" "$DOC"
grep -Fq "sqlite3.OperationalError: no such column: completed_at" "$DOC"
grep -Fq "status=running" "$DOC"
grep -Fq "attempts=1" "$DOC"
grep -Fq "result_rows=0" "$DOC"
grep -Fq "completed_at" "$DOC"
grep -Fq "job_id" "$DOC"
grep -Fq "response_text" "$DOC"
grep -Fq "status=completed" "$DOC"
grep -Fq "result_rows=1" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "FC-O45-E-CF-R2-BROWSER-OK" "$DOC"
grep -Fq "semantically exact" "$DOC"
grep -Fq "No frontend patch" "$DOC"

echo "PASS stage-16-fc-o45-e-cj-d exact job573 repair outcome smoke"
