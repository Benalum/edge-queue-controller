#!/usr/bin/env bash
set -euo pipefail

DOC="docs/stage-16-fc-o45-e-ai-companion-persona-wrapper-contract.md"
AH_SMOKE="ops/smoke/check-stage-16-fc-o45-e-ah-job127-result-reader-quality-contract.sh"

test -f "$DOC"
test -x "$AH_SMOKE"

grep -Fq "Stage 16 FC-O45-E-AI" "$DOC"
grep -Fq "Companion persona wrapper contract" "$DOC"
grep -Fq "I am Qwen" "$DOC"
grep -Fq "model_identity_leakage_qwen" "$DOC"
grep -Fq "vendor_identity_leakage_alibaba" "$DOC"
grep -Fq "Do not identify yourself as Qwen" "$DOC"
grep -Fq "APPROVE_FC_O45_E_AJ_EXACT_ONE_COMPANION_PERSONA_MODEL_JOB" "$DOC"
grep -Fq "NO model generation" "$DOC"
grep -Fq "NO backend/frontend deploy" "$DOC"

if grep -n 'grep -Fq "Target job: `127`"' "$AH_SMOKE"; then
  echo "REFUSE_AH_SMOKE_BACKTICK_COMMAND_SUBSTITUTION_STILL_PRESENT"
  exit 1
fi

"$AH_SMOKE" >/tmp/fc_o45_e_ai_ah_smoke.out 2>/tmp/fc_o45_e_ai_ah_smoke.err
if grep -Fq "command not found" /tmp/fc_o45_e_ai_ah_smoke.err; then
  echo "REFUSE_AH_SMOKE_STILL_PRINTS_COMMAND_NOT_FOUND"
  cat /tmp/fc_o45_e_ai_ah_smoke.err
  exit 1
fi

echo "PASS: Stage 16 FC-O45-E-AI Companion persona wrapper contract doc smoke"
