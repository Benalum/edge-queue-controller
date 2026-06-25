#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-bn-r2-companion-model-worker-readiness-read-only.md"

test -f "$DOC"

grep -Fq "Stage 16 FC-O45-E-BN-R2" "$DOC"
grep -Fq "Enter-to-send works live" "$DOC"
grep -Fq "mock/no-model" "$DOC"
grep -Fq "job: \`568\`" "$DOC"
grep -Fq "job_results.id" "$DOC"
grep -Fq "NO DB write" "$DOC"
grep -Fq "NO job mutation" "$DOC"
grep -Fq "NO model/helper/Ollama generation call" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "BN_R2_READ_ONLY_READY_FOR_NEXT_APPROVAL" "$DOC"
grep -Fq "EXPECTED_REASON_FOR_MOCK_NO_MODEL" "$DOC"
grep -Fq "FC-O45-E-BO" "$DOC"

echo "PASS: Stage 16 FC-O45-E-BN-R2 Companion model-worker readiness read-only smoke"
