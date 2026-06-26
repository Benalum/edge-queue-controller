# Stage 16 FC-O45-E-CJ-J — Deterministic Exact-Answer Short-Circuit Contract

Date: 2026-06-26

## Scope

Backend source/docs/smoke only.

No frontend patch. No frontend deploy. No public /var/www mutation. No backend deploy. No CT203 runtime patch. No DB write. No schema migration. No job mutation. No result insert. No model/helper/Ollama call. No scheduler/timer/persistent-worker activation. No service change. No CT/VM restart.

## Why this exists

CJ-H proved that prompt wrapping alone is not enough for qwen2.5:0.5b exact-marker tasks.

The live wrapper classified the prompt correctly, but qwen2.5 returned:

    OK

instead of:

    FC-O45-E-CJ-H-WRAPPED-OK

For exact-answer prompts, the backend should not ask the model to obey. It should extract the marker and return it deterministically.

## Added helpers

CJ-J adds source-only helpers:

- _stage16_cj_j_should_short_circuit_exact_answer
- _stage16_cj_j_companion_exact_answer_result
- _stage16_cj_j_companion_short_circuit_contract

## Behavior

For explicit prompts like:

    Please answer exactly: FC-O45-E-CJ-J-SHORT-CIRCUIT-OK

the helper returns:

    response_text=FC-O45-E-CJ-J-SHORT-CIRCUIT-OK
    model=backend-deterministic/no-model
    model_required=false
    model_call_allowed=false
    semantic_exact_marker_pass=true

## Safety boundary

The short-circuit only applies to explicit exact-answer prompts parsed by the existing CJ-E marker extractor.

Non-exact prompts continue to require normal Companion model or Study action handling.

## Runtime note

This is source-only. It does not wire the helper into the worker path, create jobs, complete jobs, call a model, start a scheduler, or enable persistent workers.
