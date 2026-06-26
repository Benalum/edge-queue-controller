#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

CONTROLLER="./edge_controller.py"
DOC="docs/stage-16-fc-o45-e-cj-o-wire-exact-answer-short-circuit-into-edge-worker-claim.md"

test -f "$CONTROLLER"
test -f "$DOC"

grep -Fq "APC_STAGE16_FC_O45_E_CJ_O_CLAIM_SHORT_CIRCUIT_RESPONSE_START" "$CONTROLLER"
grep -Fq "APC_STAGE16_FC_O45_E_CJ_O_CLAIM_SHORT_CIRCUIT_RESPONSE_END" "$CONTROLLER"
grep -Fq "def e3z_bl_edge_worker_claim" "$CONTROLLER"
grep -Fq "claimed[\"companion_execution\"]" "$CONTROLLER"
grep -Fq "\"mode\": \"deterministic_exact_answer_short_circuit\"" "$CONTROLLER"
grep -Fq "\"complete_without_model\": True" "$CONTROLLER"
grep -Fq "\"model_call_allowed\": False" "$CONTROLLER"
grep -Fq "\"semantic_exact_marker_pass\": True" "$CONTROLLER"
grep -Fq "backend_deterministic_exact_answer_short_circuit" "$CONTROLLER"
grep -Fq "_stage16_cj_j_companion_exact_answer_result" "$CONTROLLER"

grep -Fq "Wire Exact-Answer Short-Circuit Into Edge-Worker Claim" "$DOC"
grep -Fq "/internal/edge-worker/jobs/claim" "$DOC"
grep -Fq "e3z_bl_edge_worker_claim" "$DOC"
grep -Fq "/internal/edge-worker/jobs/{job_id}/complete" "$DOC"
grep -Fq "backend-deterministic/no-model" "$DOC"
grep -Fq "complete_without_model=true" "$DOC"
grep -Fq "model_call_allowed=false" "$DOC"
grep -Fq "Non-exact Companion jobs are unchanged" "$DOC"
grep -Fq "No frontend patch" "$DOC"
grep -Fq "source-only" "$DOC"

python3 - <<'PY'
from pathlib import Path
import ast

source = Path("edge_controller.py").read_text()
ast.parse(source)
print("python_ast_parse_ok=yes")

tree = ast.parse(source)
claim = None
for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == "e3z_bl_edge_worker_claim":
        claim = node
        break
assert claim is not None, "claim function missing"

segment = ast.get_source_segment(source, claim)
assert "APC_STAGE16_FC_O45_E_CJ_O_CLAIM_SHORT_CIRCUIT_RESPONSE_START" in segment
assert "claimed[\"companion_execution\"]" in segment
assert "_stage16_cj_j_companion_exact_answer_result" in segment
assert "\"complete_without_model\": True" in segment
assert "\"model_call_allowed\": False" in segment
assert "\"semantic_exact_marker_pass\": True" in segment

cj_e_start = source.index("# APC_STAGE16_FC_O45_E_CJ_E_COMPANION_PROMPT_WRAPPER_START")
cj_e_end = source.index("# APC_STAGE16_FC_O45_E_CJ_E_COMPANION_PROMPT_WRAPPER_END")
cj_j_start = source.index("# APC_STAGE16_FC_O45_E_CJ_J_DETERMINISTIC_EXACT_ANSWER_START")
cj_j_end = source.index("# APC_STAGE16_FC_O45_E_CJ_J_DETERMINISTIC_EXACT_ANSWER_END")

ns = {}
exec(source[cj_e_start:cj_e_end], ns)
exec(source[cj_j_start:cj_j_end], ns)

prompt = "Please answer exactly: FC-O45-E-CJ-O-CLAIM-WIRE-OK"
result = ns["_stage16_cj_j_companion_exact_answer_result"](prompt)
assert result["response_text"] == "FC-O45-E-CJ-O-CLAIM-WIRE-OK", result
assert result["model"] == "backend-deterministic/no-model", result
assert result["model_call_allowed"] is False, result
assert result["semantic_exact_marker_pass"] is True, result

print("claim_short_circuit_static_unit_smoke_ok=yes")
PY

echo "PASS stage-16-fc-o45-e-cj-o wire exact-answer short-circuit into edge-worker claim smoke"
