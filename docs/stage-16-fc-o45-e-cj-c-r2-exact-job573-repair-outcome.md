# Stage 16 FC-O45-E-CJ-C-R2 — Exact Job573 Repair Outcome

Date: 2026-06-26

## Summary

CJ-C attempted a bounded exact one-shot completion for Companion job 573. It made a qwen2.5:0.5b model call and attempted to insert a result, but then hit a schema mismatch:

    sqlite3.OperationalError: no such column: completed_at

The CJ-C wrapper printed success lines after the traceback, but those success lines were not trustworthy.

CJ-C-R2 verified and repaired the exact job573 state safely.

## Verified state before repair

CJ-C-R2 verified job 573 as:

    id=573
    status=running
    attempts=1
    requested_model=qwen2.5:0.5b
    job_type=companion.chat
    result_rows=0
    prompt_marker_present=true

Actual jobs columns were:

    id
    job_type
    prompt
    requested_model
    status
    attempts
    last_error
    created_at
    updated_at
    forwarded_at
    user_id

The jobs table did not have completed_at.

Actual job_results columns were:

    job_id
    model
    response_text
    response_json
    error
    created_at
    updated_at

## Repair action

CJ-C-R2 made one bounded PVESO Ollama call using:

    model=qwen2.5:0.5b
    job_id=573
    job_type=companion.chat

It then inserted one job_results row and updated only job 573 using actual schema columns.

## Final verified state

CJ-C-R2 verified:

    id=573
    status=completed
    attempts=1
    requested_model=qwen2.5:0.5b
    job_type=companion.chat
    result_rows=1

## Semantic result

The backend/model/result mechanics succeeded, but the semantic exact-answer requirement failed.

The prompt asked for an exact marker:

    FC-O45-E-CF-R2-BROWSER-OK

The model returned a rambly/truncated response beginning with:

    FC-O45-E-CF-R2-browser is an official product of Alibaba Cloud...

This means job573 is mechanically completed, but not semantically exact.

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation, no backend deploy, no service mutation, no CT203 runtime patch, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no model pull/download occurred.

## Next recommendation

Add a backend decision/model prompt wrapper for Companion jobs so exact-answer tasks and Study tool tasks get deterministic instructions before model execution.
