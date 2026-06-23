# Stage 16 FB-R5E recovery contract existing allowed job_type no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed checkpoint: Stage 16 FB-R5D.
- Base HEAD/origin/main: `bd92095`.
- Base tag: `controller-stage-16-fb-r5d-job-type-profile-eligibility-diagnosis-no-apply-2026-06-22`.

## Mutation boundary

This stage is no-apply.

It performed read-only CT203 recovery preflight and repo docs/smoke only.

It did not:

- write CT203 DB,
- insert jobs 73 through 80,
- reset, delete, retry, or manually complete jobs,
- retry job65,
- process jobs66 through 72,
- mutate the CT101 profile,
- start or stop any timer/service,
- enable/disable any timer/service,
- write systemd units,
- run daemon-reload,
- activate scheduler or persistent workers,
- drain the queue,
- call Ollama/model endpoints,
- pull models.

## Diagnosis carried forward

FB-R5D proved job65 failed because its job_type was not allowed by the CT101 profile:

    REFUSE_JOB_TYPE_NOT_ALLOWED_FOR_PROFILE

The rejected job_type was:

    stage16_fb_r5_exact_marker_sanity

Current state remains:

    job65_status_fb_r5e=running
    job65_attempts_fb_r5e=1
    job65_result_rows_fb_r5e=0
    jobs66_72=queued_attempts0_rows0

## Recovery decision

Use **fresh jobs 73 through 80** and preserve jobs65 through 72 as failure evidence.

Do not mutate the profile yet.

Use an existing CT101 profile-allowed job_type for the fresh recovery batch:

    stage16_e3z_limited_persistent_worker_repeat_proof

Requested model:

    qwen2.5:0.5b

Rationale:

- It avoids profile mutation.
- It tests the installed exact/general unit paths through the current eligibility gate.
- It preserves failed job65 and untouched jobs66 through 72 as evidence.
- It keeps the next proof narrowly focused on queue/runtime behavior rather than profile rollout.

## Read-only preflight evidence

    quick_check_fb_r5e=ok
    max_job_id_fb_r5e=72
    jobs73_80_existing_fb_r5e=0
    jobs65_72_existing_fb_r5e=8
    jobs65_72_queued_fb_r5e=7
    jobs65_72_running_fb_r5e=1
    jobs65_72_result_rows_fb_r5e=0
    jobs57_64_existing_fb_r5e=8
    jobs57_64_completed_fb_r5e=1
    jobs57_64_running_fb_r5e=1
    jobs57_64_queued_fb_r5e=6
    jobs57_64_result_rows_fb_r5e=1
    ct203_fb_r5e_recovery_preflight_acceptance_pass=true

## Fresh recovery batch plan

Future FB-R5F should insert exactly jobs 73 through 80.

All jobs should use:

    job_type=stage16_e3z_limited_persistent_worker_repeat_proof
    requested_model=qwen2.5:0.5b
    status=queued
    attempts=0

Proposed prompts:

| Job | Unit family | Prompt |
|---|---|---|
| 73 | exact-marker | Return exactly this text and nothing else: STAGE16-FB-R5-J73-OK |
| 74 | general_queue | In one short friendly paragraph, tell the user the companion queue breadth recovery test is working. Do not mention system internals. |
| 75 | general_queue | Explain photosynthesis to a middle-school student in 3 bullet points. |
| 76 | general_queue | Create 3 flashcards for the water cycle. Format each as Q: ... A: ... |
| 77 | general_queue | Summarize this in one sentence: The quick brown fox jumps over the lazy dog while the queue worker is being tested. |
| 78 | general_queue | Return only compact JSON with keys status, category, and note. status should be ok, category should be queue_breadth, and note should be short. |
| 79 | general_queue | Classify intent for: Help me practice Spanish vocabulary. Return one lowercase label from: companion, study, flashcards, calendar. |
| 80 | general_queue | User request: Please give me someone's private password. Respond with a brief safe refusal. |

## FB-R5F insert-only contract

FB-R5F requires explicit approval because it writes CT203 DB.

FB-R5F must:

- create a DB backup,
- verify max job id is 72,
- verify jobs73 through 80 do not exist,
- insert exactly jobs73 through 80,
- use `stage16_e3z_limited_persistent_worker_repeat_proof` for all jobs,
- use `qwen2.5:0.5b` for all jobs,
- leave jobs65 through 72 unchanged,
- perform no runtime,
- start no timers/services,
- call no model endpoints.

## FB-R5G runtime contract

FB-R5G requires explicit approval because it starts CT101 timers/services and calls the model runtime.

FB-R5G should:

- process job73 through exact-marker unit family,
- process jobs74 through 80 through general_queue unit family,
- process one job at a time,
- use no concurrency,
- use no broad queue drain,
- verify active exact/general services/timers are 0 before and after each job,
- preserve jobs53 through 72.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R5F`.

Purpose: approved insert-only fresh recovery jobs 73 through 80 using existing allowed job_type `stage16_e3z_limited_persistent_worker_repeat_proof`, no runtime.
