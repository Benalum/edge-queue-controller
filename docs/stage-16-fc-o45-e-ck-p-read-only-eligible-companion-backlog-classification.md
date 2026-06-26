# Stage 16 FC-O45-E-CK-P — Read-Only Eligible Companion Backlog Classification

Date: 2026-06-26

## Summary

CK-P classified the live CT203 eligible queued `companion.chat` backlog in read-only mode.

No cleanup or mutation was performed.

## Scope

Read-only CT203 DB classification plus repo posture and public status smoke.

No frontend patch, no frontend deploy, no public /var/www mutation, no source mutation, no commit, no tag, no push, no backend deploy, no CT203 runtime patch, no DB write, no schema migration, no job mutation, no result insert, no service start, no service stop, no service restart, no service enable, no timer install, no timer enable/start, no selector/manual-wrapper/helper invocation, no model/helper/Ollama call, no scheduler/timer/persistent-worker activation, no CT/VM restart, no package install, and no secret values printed.

## Runtime preflight

CT203 was running.

Reporter SHA verified:

    81030f3544dde5dc7437318bbd857591d0c3b6518c8fe6a3dd923df1a000286d

Scheduler/timer/worker posture before classification:

    edge-queue-scheduler-one-shot.timer=inactive
    edge-queue-scheduler-one-shot.service=inactive
    edge-deterministic-companion-worker-once@999999.service=inactive

Scheduler/timer/worker posture after classification:

    edge-queue-scheduler-one-shot.timer=inactive
    edge-queue-scheduler-one-shot.service=inactive
    edge-deterministic-companion-worker-once@999999.service=inactive

## DB totals

DB integrity:

    CK_P_DB_INTEGRITY=ok

Live counts:

    CK_P_JOBS_TOTAL=575
    CK_P_RESULTS_TOTAL=82
    CK_P_QUEUED_TOTAL=465
    CK_P_COMPANION_TOTAL=459
    CK_P_ELIGIBLE_COMPANION_TOTAL=440

## Eligible rows by requested model

All 440 eligible queued `companion.chat` rows use the mock/no-model requested model:

    CK_P_MODEL_COUNT requested_model=mock/no-model count=440

## Eligible rows by day

    CK_P_DAY_COUNT day=2026-06-20 count=1 min_id=24 max_id=24
    CK_P_DAY_COUNT day=2026-06-24 count=1 min_id=130 max_id=130
    CK_P_DAY_COUNT day=2026-06-25 count=438 min_id=133 max_id=570

## Prompt pattern buckets

    CK_P_PROMPT_BUCKET bucket=say_hello_one_sentence count=437
    CK_P_PROMPT_BUCKET bucket=other_prompt count=2
    CK_P_PROMPT_BUCKET bucket=stage15e_mock_validation count=1

## Oldest eligible sample

    id=24 created_at=2026-06-20T05:02:17.068028+00:00 requested_model=mock/no-model prompt='stage15e-authenticated-mock-queued-chat-validation-2026-06-20T0448Z'
    id=130 created_at=2026-06-24T23:30:29.632435+00:00 requested_model=mock/no-model prompt='say hello in 1 sentence'
    id=133 created_at=2026-06-25T01:14:17.860197+00:00 requested_model=mock/no-model prompt='Say hello in 1 sentence to me.'

## Newest eligible sample

    id=568 created_at=2026-06-25T01:36:29.420762+00:00 requested_model=mock/no-model prompt='Say hello i 1 sentence'
    id=569 created_at=2026-06-25T01:43:16.805622+00:00 requested_model=mock/no-model prompt='Say hello in 1 sentence'
    id=570 created_at=2026-06-25T02:16:12.718709+00:00 requested_model=mock/no-model prompt='ask me how my day is in 1 sentence.'

## Classification result

CK-P completed successfully:

    CK_P_BACKLOG_CLASSIFICATION_DONE=yes
    CK_P_READ_ONLY_CLASSIFICATION_COMPLETE=yes

## Public smoke

Public GET requests returned HTTP 200 for:

    /api/system/status
    /api/companion/voice/status

## Operational conclusion

The 440 eligible queued `companion.chat` backlog is not production Companion work. It is old mock/no-model test traffic, mostly repeated one-sentence hello prompts.

Before any broader dispatch, timer, or automation path is enabled, the platform needs a guarded cleanup or exclusion policy so this old mock/no-model backlog cannot be accidentally executed.
