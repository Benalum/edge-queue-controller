# Stage 16 FC-O45-E-CK-N-R2 — Corrected Live Read-Only Reporter Proof

Date: 2026-06-26

## Summary

CK-N-R2 completed the corrected live read-only proof for the eligible Companion job reporter.

The prior CK-N run had successfully executed the reporter in text mode, but the JSON validation step was scripted incorrectly. CK-N-R2 corrected that by capturing JSON output first, validating it separately, and comparing before/after DB counts.

## Runtime components verified before proof

CT203 live backend SHA:

    1eb84e48c6835741abc31fbd68acb759a690af3d026a96d6d284540cde0072a2

Runtime helper SHA:

    7a72ae2d644f04dbcbf4c580722525fb32f19da992c557bc99207a4eefa28419

Runtime systemd unit SHA:

    265283d77df5ad9ff1bc5a151ee7faa882b754f26cc1fe41533b0c18f6737f7a

Runtime manual wrapper SHA:

    481bbae24f683880bdbc67fffc8ae3605603aba84913613db7f5b2f7ace00595

Runtime selector SHA:

    1115a5c2e6759d75f9cbfe92b80b668659a91e86f58f6c5da68ee26532e52c41

Runtime reporter SHA:

    81030f3544dde5dc7437318bbd857591d0c3b6518c8fe6a3dd923df1a000286d

## Before snapshot

Read-only DB snapshot before reporter invocation:

    CK_N_R2_DB_INTEGRITY=ok
    CK_N_R2_BEFORE_JOBS_TOTAL=575
    CK_N_R2_BEFORE_RESULTS_TOTAL=82
    CK_N_R2_BEFORE_ELIGIBLE_COMPANION_JOBS=440

## Text-mode reporter proof

The installed reporter ran against the live DB in read-only text mode:

    eligible_companion_jobs_read_only=yes
    eligible_companion_jobs_marker=<none>
    eligible_companion_jobs_total=440
    eligible_companion_jobs_returned=25
    eligible_companion_jobs_report_done=yes

The first returned eligible jobs included:

    id=24 requested_model=mock/no-model
    id=130 requested_model=mock/no-model
    id=133 requested_model=mock/no-model
    id=134 requested_model=mock/no-model
    id=135 requested_model=mock/no-model

Most returned rows were older queued mock/no-model Companion prompts.

## JSON-mode reporter proof

The installed reporter also ran in read-only JSON mode and validated cleanly:

    CK_N_R2_JSON_OK=True
    CK_N_R2_JSON_DB_MODE=read_only
    CK_N_R2_JSON_TOTAL_ELIGIBLE=440
    CK_N_R2_JSON_RETURNED=25

## After snapshot

Read-only DB snapshot after reporter invocation:

    CK_N_R2_AFTER_JOBS_TOTAL=575
    CK_N_R2_AFTER_RESULTS_TOTAL=82
    CK_N_R2_AFTER_ELIGIBLE_COMPANION_JOBS=440

The before/after count comparison passed:

    CK_N_R2_DB_COUNTS_UNCHANGED=yes

## Posture

Before and after the reporter run:

    edge-queue-scheduler-one-shot.timer=inactive
    edge-queue-scheduler-one-shot.service=inactive
    edge-deterministic-companion-worker-once@999999.service=inactive

No persistent, general, or deterministic worker process was active.

## What this proves

The installed reporter can safely read the live CT203 queue and report eligible queued `companion.chat` jobs without mutating the DB or starting execution.

The reporter opens SQLite in read-only mode and supports both text and JSON output.

## Guardrails kept

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation during runtime proof, no backend deploy, no CT203 runtime patch, no DB write, no schema migration, no job mutation, no result insert, no service start, no service stop, no service restart, no service enable, no timer install, no timer enable/start, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Operational note

The live DB currently has 440 eligible queued `companion.chat` rows. Many are older `mock/no-model` prompts. Before any automatic or broader dispatch work, the queue should be cleaned up or filtered so only approved, marker-specific jobs are eligible for execution.
