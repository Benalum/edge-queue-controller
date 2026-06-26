#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

CONTROLLER="./edge_controller.py"
DOC="docs/stage-16-fc-o45-e-cj-e-backend-companion-prompt-wrapper-contract.md"

test -f "$CONTROLLER"
test -f "$DOC"

grep -Fq "APC_STAGE16_FC_O45_E_CJ_E_COMPANION_PROMPT_WRAPPER_START" "$CONTROLLER"
grep -Fq "APC_STAGE16_FC_O45_E_CJ_E_COMPANION_PROMPT_WRAPPER_END" "$CONTROLLER"
grep -Fq "def _stage16_cj_e_extract_exact_answer_marker" "$CONTROLLER"
grep -Fq "def _stage16_cj_e_build_exact_answer_prompt" "$CONTROLLER"
grep -Fq "def _stage16_cj_e_classify_companion_model_prompt" "$CONTROLLER"
grep -Fq "def _stage16_cj_e_companion_prompt_wrapper_contract" "$CONTROLLER"
grep -Fq "exact_output_only" "$CONTROLLER"
grep -Fq "study_tool_aware" "$CONTROLLER"
grep -Fq "plain_direct_answer" "$CONTROLLER"
grep -Fq "model_call_enabled_by_this_helper" "$CONTROLLER"

grep -Fq "Backend Companion Prompt Wrapper Contract" "$DOC"
grep -Fq "FC-O45-E-CF-R2-BROWSER-OK" "$DOC"
grep -Fq "No frontend patch" "$DOC"
grep -Fq "exact_answer" "$DOC"
grep -Fq "study_companion" "$DOC"
grep -Fq "general_companion" "$DOC"
grep -Fq "source-only" "$DOC"

python3 - <<'PY'
from pathlib import Path
import ast

source = Path("edge_controller.py").read_text()
ast.parse(source)
print("python_ast_parse_ok=yes")

ns = {}
block_start = source.index("# APC_STAGE16_FC_O45_E_CJ_E_COMPANION_PROMPT_WRAPPER_START")
block_end = source.index("# APC_STAGE16_FC_O45_E_CJ_E_COMPANION_PROMPT_WRAPPER_END")
block = source[block_start:block_end]

exec(block, ns)

marker = ns["_stage16_cj_e_extract_exact_answer_marker"](
    "Stage 16 test. Please answer exactly: FC-O45-E-CF-R2-BROWSER-OK"
)
assert marker == "FC-O45-E-CF-R2-BROWSER-OK", marker

classified = ns["_stage16_cj_e_classify_companion_model_prompt"](
    "Stage 16 test. Please answer exactly: FC-O45-E-CF-R2-BROWSER-OK"
)
assert classified["kind"] == "exact_answer", classified
assert classified["marker"] == "FC-O45-E-CF-R2-BROWSER-OK", classified
assert "Return exactly and only" in classified["wrapped_prompt"], classified
assert "FC-O45-E-CF-R2-BROWSER-OK" in classified["wrapped_prompt"], classified
assert classified["temperature"] == 0, classified

study = ns["_stage16_cj_e_classify_companion_model_prompt"](
    "Make flashcards for photosynthesis"
)
assert study["kind"] == "study_companion", study
assert "front/back" in study["wrapped_prompt"], study

general = ns["_stage16_cj_e_classify_companion_model_prompt"](
    "How are you?"
)
assert general["kind"] == "general_companion", general

contract = ns["_stage16_cj_e_companion_prompt_wrapper_contract"]()
assert contract["ok"] is True
assert contract["runtime_worker_enabled"] is False
assert contract["model_call_enabled_by_this_helper"] is False

print("prompt_wrapper_unit_smoke_ok=yes")
PY

echo "PASS stage-16-fc-o45-e-cj-e backend Companion prompt wrapper contract smoke"
