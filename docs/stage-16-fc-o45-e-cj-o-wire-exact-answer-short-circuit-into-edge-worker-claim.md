# Stage 16 FC-O45-E-CJ-O — Wire Exact-Answer Short-Circuit Into Edge-Worker Claim

Date: 2026-06-26

## Scope

Backend source/docs/smoke only.

No frontend patch. No frontend deploy. No public /var/www mutation. No backend deploy. No CT203 runtime patch. No DB write. No schema migration. No job mutation. No result insert. No model/helper/Ollama call. No scheduler/timer/persistent-worker activation. No service change. No CT/VM restart.

## Why this exists

CJ-L proved deterministic exact-answer completion works for a fresh Companion job without calling Ollama:

    job_id=575
    response=FC-O45-E-CJ-L-SHORT-CIRCUIT-OK
    result_model=backend-deterministic/no-model

CJ-N-R2 identified the real backend wiring target:

    /internal/edge-worker/jobs/claim
    function=e3z_bl_edge_worker_claim

and confirmed the completion endpoint already supports inserting result text/model:

    /internal/edge-worker/jobs/{job_id}/complete
    function=e3z_bl_edge_worker_complete

## Source change

CJ-O enriches the claimed job dict inside e3z_bl_edge_worker_claim.

When a claimed job is:

    job_type=companion.chat

and the job prompt contains an explicit exact-answer marker parsed by the CJ-E/CJ-J helper, the claim response includes:

    companion_execution.mode=deterministic_exact_answer_short_circuit
    companion_execution.complete_without_model=true
    companion_execution.model=backend-deterministic/no-model
    companion_execution.response_text=<exact marker>
    companion_execution.model_required=false
    companion_execution.model_call_allowed=false
    companion_execution.semantic_exact_marker_pass=true
    companion_execution.result_source=backend_deterministic_exact_answer_short_circuit

## Behavior

A bounded worker can now claim an exact-answer Companion job, see the deterministic payload, and call the existing complete endpoint without calling Ollama.

Non-exact Companion jobs are unchanged.

Study and Voice routes are unchanged.

## Runtime note

This is source-only. It does not deploy the backend, insert jobs, complete jobs, call a model, start a worker, enable a timer, or enable persistent workers.

## Next recommendation

Deploy this backend source to CT203, then run one bounded fresh exact-answer Companion job through the internal claim/complete API and verify that the worker path completes it with backend-deterministic/no-model and no Ollama call.
