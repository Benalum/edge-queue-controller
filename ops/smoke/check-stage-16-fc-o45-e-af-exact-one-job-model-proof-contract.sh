#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-af-exact-one-job-model-proof-contract.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AF" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AG_EXACT_ONE_COMPANION_MODEL_JOB" "$DOC"
grep -Fq "NO worker/helper/model/Ollama API call" "$DOC"
grep -Fq "exactly one new signed-in" "$DOC"
grep -Fq "companion.chat" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "Never claim or mutate jobs other than the exact target job id" "$DOC"
grep -Fq "Live read-only inventory" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AF exact-one-job model proof contract doc smoke"
