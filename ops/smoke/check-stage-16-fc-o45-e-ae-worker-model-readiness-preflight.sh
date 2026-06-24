#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ae-worker-model-readiness-preflight.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AE" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO worker/helper/model/Ollama API call" "$DOC"
grep -Fq "FC-O45-E-AF" "$DOC"
grep -Fq "exact one-job proof path" "$DOC"
grep -Fq "Live read-only output" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AE worker/model readiness preflight doc smoke"
