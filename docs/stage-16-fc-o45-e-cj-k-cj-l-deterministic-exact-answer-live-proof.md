# Stage 16 FC-O45-E-CJ-K/CJ-L — Deterministic Exact-Answer Live Proof

Date: 2026-06-26

## Summary

CJ-K deployed the deterministic exact-answer short-circuit helpers to CT203.

CJ-L proved one fresh Companion exact-answer job can complete with an exact response and no model call.

## CJ-K live backend deploy

Active CT203 backend file:

    /opt/edge-queue-controller/current/edge_controller.py

Before SHA:

    a4c2a93aa38b7445f360910f2e20ddf2172b1c250c2a1ee889e18d71eec9b54e

After SHA:

    313b4eb9f2cd0577d8fb5fa2c5c93bc1fadcdc4dfa3418b113af7fa9c64cda46

Backup path:

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-cj-k-deterministic-exact-answer-short-circuit-deploy-20260626T040230Z

Only this service was restarted:

    edge-queue-controller.service

The controller remained active on port 7070.

## CJ-K live helper smoke

The live helper returned:

    response_text=FC-O45-E-CJ-K-LIVE-SHORT-CIRCUIT-OK
    model=backend-deterministic/no-model
    model_required=false
    model_call_allowed=false
    semantic_exact_marker_pass=true

No model call occurred.

## CJ-L no-model runtime proof

CJ-L inserted one fresh Companion job:

    id=575
    job_type=companion.chat
    requested_model=qwen2.5:0.5b
    prompt marker=FC-O45-E-CJ-L-SHORT-CIRCUIT-OK

The live deterministic helper produced:

    response_text=FC-O45-E-CJ-L-SHORT-CIRCUIT-OK
    model=backend-deterministic/no-model
    model_call_allowed=false
    semantic_exact_marker_pass=true

CJ-L claimed job 575, inserted exactly one job_results row, and marked job 575 completed.

Final verification:

    id=575
    status=completed
    attempts=1
    requested_model=qwen2.5:0.5b
    job_type=companion.chat
    result_rows=1
    result_model=backend-deterministic/no-model
    response=FC-O45-E-CJ-L-SHORT-CIRCUIT-OK

## Important distinction

This proves exact-marker Companion tasks should be handled by deterministic backend short-circuit, not by qwen2.5 prompt obedience.

Normal Companion, Study Companion, and non-exact jobs still require model/Study action handling.

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation, no backend deploy during CJ-L, no service mutation during CJ-L, no CT203 runtime patch during CJ-L, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package/model pull, no PVESO call, and no Ollama/model/helper call occurred during CJ-L.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Next recommendation

Wire the deterministic exact-answer short-circuit into the bounded Companion job execution path, while keeping persistent workers disabled.
