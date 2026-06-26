#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

CONTROLLER="./edge_controller.py"
DOC="docs/stage-16-fc-o45-e-cj-j-deterministic-exact-answer-short-circuit-contract.md"

test -f "$CONTROLLER"
test -f "$DOC"

grep -Fq "APC_STAGE16_FC_O45_E_CJ_J_DETERMINISTIC_EXACT_ANSWER_START" "$CONTROLLER"
grep -Fq "APC_STAGE16_FC_O45_E_CJ_J_DETERMINISTIC_EXACT_ANSWER_END" "$CONTROLLER"
grep -Fq "def _stage16_cj_j_should_short_circuit_exact_answer" "$CONTROLLER"
grep -Fq "def _stage16_cj_j_companion_exact_answer_result" "$CONTROLLER"
grep -Fq "def _stage16_cj_j_companion_short_circuit_contract" "$CONTROLLER"
grep -Fq "backend_deterministic_exact_answer_short_circuit" "$CONTROLLER"
grep -Fq "backend-deterministic/no-model" "$CONTROLLER"
grep -Fq "semantic_exact_marker_pass" "$CONTROLLER"
grep -Fq "model_call_allowed" "$CONTROLLER"

grep -Fq "Deterministic Exact-Answer Short-Circuit Contract" "$DOC"
grep -Fq "qwen2.5:0.5b" "$DOC"
grep -Fq "FC-O45-E-CJ-H-WRAPPED-OK" "$DOC"
grep -Fq "FC-O45-E-CJ-J-SHORT-CIRCUIT-OK" "$DOC"
grep -Fq "backend-deterministic/no-model" "$DOC"
grep -Fq "model_call_allowed=false" "$DOC"
grep -Fq "source-only" "$DOC"
grep -Fq "No frontend patch" "$DOC"

python3 - <<'PY'
from pathlib import Path
import ast

source = Path("edge_controller.py").read_text()
ast.parse(source)
print("python_ast_parse_ok=yes")

cj_e_start = source.index("# APC_STAGE16_FC_O45_E_CJ_E_COMPANION_PROMPT_WRAPPER_START")
cj_e_end = source.index("# APC_STAGE16_FC_O45_E_CJ_E_COMPANION_PROMPT_WRAPPER_END")
cj_j_start = source.index("# APC_STAGE16_FC_O45_E_CJ_J_DETERMINISTIC_EXACT_ANSWER_START")
cj_j_end = source.index("# APC_STAGE16_FC_O45_E_CJ_J_DETERMINISTIC_EXACT_ANSWER_END")

ns = {}
exec(source[cj_e_start:cj_e_end], ns)
exec(source[cj_j_start:cj_j_end], ns)

prompt = "Stage 16 proof. Please answer exactly: FC-O45-E-CJ-J-SHORT-CIRCUIT-OK"
decision = ns["_stage16_cj_j_should_short_circuit_exact_answer"](prompt)
assert decision["ok"] is True, decision
assert decision["short_circuit"] is True, decision
assert decision["marker"] == "FC-O45-E-CJ-J-SHORT-CIRCUIT-OK", decision
assert decision["response_text"] == "FC-O45-E-CJ-J-SHORT-CIRCUIT-OK", decision
assert decision["model_required"] is False, decision
assert decision["model_call_allowed"] is False, decision

result = ns["_stage16_cj_j_companion_exact_answer_result"](prompt)
assert result["ok"] is True, result
assert result["response_text"] == "FC-O45-E-CJ-J-SHORT-CIRCUIT-OK", result
assert result["model"] == "backend-deterministic/no-model", result
assert result["semantic_exact_marker_pass"] is True, result
assert result["model_call_allowed"] is False, result

non_exact = ns["_stage16_cj_j_should_short_circuit_exact_answer"]("Tell me about study habits.")
assert non_exact["short_circuit"] is False, non_exact
assert non_exact["reason"] == "no_explicit_exact_answer_marker", non_exact

contract = ns["_stage16_cj_j_companion_short_circuit_contract"]()
assert contract["ok"] is True, contract
assert contract["source_only"] is True, contract
assert contract["model_call_enabled_by_this_helper"] is False, contract

print("deterministic_exact_answer_short_circuit_unit_smoke_ok=yes")
PY

echo "PASS stage-16-fc-o45-e-cj-j deterministic exact-answer short-circuit source smoke"
