#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ae-r2-db-lock-pveso-route-readiness-unblocker.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AE-R2" "$DOC"
grep -Fq "database is locked" "$DOC"
grep -Fq "could not resolve hostname" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO worker/helper/model/Ollama API call" "$DOC"
grep -Fq "Do not run" "$DOC"
grep -Fq "Live read-only output" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AE-R2 DB lock + PVESO route readiness unblocker doc smoke"
