# Stage 16 FC-O45-E-CK-S — Guarded Mock Companion Cleanup Dry-Run Proof

Date: 2026-06-26

## Summary

CK-S installed the guarded mock Companion backlog cleanup dry-run tool on CT203 and executed it against the live DB in read-only mode.

No cleanup mutation was performed.

## Runtime tool

Installed path:

    /opt/edge-queue-controller/ops/db/plan-companion-mock-backlog-cleanup-read-only.py

Verified runtime SHA:

    16d5e145ee3fc917ff8474f82dac4c91ce4d6397c4cea54c0f1b4f3bc560af6f

No previous runtime cleanup dry-run tool existed before install.

Backup directory:

    /opt/edge-queue-controller/backups/stage-16-fc-o45-e-ck-s-install-run-cleanup-dry-run-20260626T051424Z

## Before snapshot

Read-only DB snapshot before dry-run:

    CK_S_DB_INTEGRITY=ok
    CK_S_BEFORE_JOBS_TOTAL=575
    CK_S_BEFORE_RESULTS_TOTAL=82
    CK_S_BEFORE_CANDIDATE_COUNT=440

## Candidate criteria

The dry-run candidate set used these exact criteria:

    job_type=companion.chat
    status=queued
    attempts=0
    result_rows=0
    requested_model=mock/no-model

## Text-mode dry-run proof

Text mode completed in read-only mode:

    mock_companion_cleanup_plan_read_only=yes
    candidate_count=440
    candidate_min_id=24
    candidate_max_id=570
    candidate_id_sha256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2
    future_cleanup_status=not_selected_by_this_tool
    requires_future_approval=yes
    mutated=no
    mock_companion_cleanup_plan_done=yes

Candidate day counts:

    candidate_day_count day=2026-06-20 count=1
    candidate_day_count day=2026-06-24 count=1
    candidate_day_count day=2026-06-25 count=438

Candidate prompt buckets:

    candidate_prompt_bucket bucket=other_prompt count=2
    candidate_prompt_bucket bucket=say_hello_one_sentence count=437
    candidate_prompt_bucket bucket=stage15e_mock_validation count=1

Oldest samples:

    id=24 stage15e_mock_validation
    id=130 say_hello_one_sentence
    id=133 say_hello_one_sentence

Newest samples:

    id=568 other_prompt prompt='Say hello i 1 sentence'
    id=569 say_hello_one_sentence prompt='Say hello in 1 sentence'
    id=570 other_prompt prompt='ask me how my day is in 1 sentence.'

## JSON-mode dry-run proof

JSON mode completed and validated:

    CK_S_JSON_OK=True
    CK_S_JSON_MODE=read_only
    CK_S_JSON_CANDIDATE_COUNT=440
    CK_S_JSON_MIN_ID=24
    CK_S_JSON_MAX_ID=570
    CK_S_JSON_ID_SHA256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2
    CK_S_JSON_MUTATED=False
    CK_S_JSON_REQUIRES_FUTURE_APPROVAL=True

## After snapshot

Read-only DB snapshot after dry-run:

    CK_S_AFTER_JOBS_TOTAL=575
    CK_S_AFTER_RESULTS_TOTAL=82
    CK_S_AFTER_CANDIDATE_COUNT=440
    CK_S_DB_COUNTS_UNCHANGED=yes

## Posture

Before and after CK-S:

    edge-queue-scheduler-one-shot.timer=inactive
    edge-queue-scheduler-one-shot.service=inactive
    edge-deterministic-companion-worker-once@999999.service=inactive

No persistent, general, or deterministic worker process was active.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no backend deploy, no CT203 backend runtime patch, no systemd install, no daemon-reload, no service start, no service stop, no service restart, no service enable, no timer install, no timer enable/start, no DB write, no schema migration, no job mutation, no result insert, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Operational conclusion

The exact cleanup candidate set is stable and fingerprinted:

    count=440
    min_id=24
    max_id=570
    candidate_id_sha256=2e7c58cb426b69406432c14aa1b6269cf85e6752ca2a63edecec91d08500a8d2

A future mutation phase should still require separate approval, a fresh DB backup, and an exact candidate fingerprint re-check immediately before any update.
