# Stage 16 FC-O45-E-CJ-H-R2 — Wrapped Exact-Answer Semantic Failure

Date: 2026-06-26

## Summary

CJ-H attempted a fresh wrapped exact-answer Companion one-shot proof using the live CJ-E prompt wrapper.

The wrapper worked correctly, but qwen2.5 did not return the exact marker.

CJ-H-R2 verified the real database state read-only.

## Wrapper behavior

The live prompt wrapper classified the prompt as:

    kind=exact_answer
    marker=FC-O45-E-CJ-H-WRAPPED-OK
    semantic_guard=exact_output_only
    temperature=0
    num_predict=32

The wrapped prompt included:

    Return exactly and only the requested marker.

## Model behavior

The bounded qwen2.5:0.5b call returned:

    OK

Expected exact marker:

    FC-O45-E-CJ-H-WRAPPED-OK

So the semantic exactness check failed.

## Verified database state

CJ-H inserted fresh Companion job 574.

CJ-H-R2 verified:

    id=574
    job_type=companion.chat
    status=failed
    attempts=1
    requested_model=qwen2.5:0.5b
    result_rows=0
    last_error=semantic exact mismatch: got=OK

The prompt marker was present in the job prompt.

## Interpretation

Prompt wrapping alone is not enough for exact-marker tasks on qwen2.5:0.5b.

For exact-answer tasks, the backend should use a deterministic short-circuit:

- detect explicit exact-answer prompt
- extract marker
- return marker directly
- do not call the model
- record the response as deterministic backend output

This keeps the model path for normal Companion and Study tasks, but removes fragile exact-marker prompts from model execution.

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation, no backend deploy, no service mutation, no CT203 runtime patch, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no model pull/download occurred.

## Next recommendation

Add a backend deterministic exact-answer short-circuit contract source patch.
