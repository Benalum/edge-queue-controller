#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ag-r3-exact-one-companion-model-job.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AG-R3" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AG_EXACT_ONE_COMPANION_MODEL_JOB" "$DOC"
grep -Fq "pvescheduler.service" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "Target job:" "$DOC"
grep -Fq "127" "$DOC"
grep -Fq "exactly one" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"
grep -Fq "FC_O45_E_AG_R3_RUNTIME_PASS" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AG-R3 exact-one Companion model job doc smoke"
