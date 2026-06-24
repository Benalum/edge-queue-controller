#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-aj-exact-one-companion-persona-model-job.md"

test -f "$DOC"
grep -Fq "Stage 16 FC-O45-E-AJ" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AJ_EXACT_ONE_COMPANION_PERSONA_MODEL_JOB" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "Companion persona wrapper" "$DOC"
grep -Fq "Target job" "$DOC"
grep -Fq "128" "$DOC"
grep -Fq "quality_pass=true" "$DOC"
grep -Fq "quality_flags=none" "$DOC"
grep -Fq "NO scheduler activation" "$DOC"
grep -Fq "NO persistent worker activation" "$DOC"
grep -Fq "FC_O45_E_AJ_RUNTIME_RECORDED" "$DOC"

echo "PASS: Stage 16 FC-O45-E-AJ exact-one Companion persona model job doc smoke"
