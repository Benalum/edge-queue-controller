# Stage 16 FB-R5A fresh corrected breadth batch contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 FB-R4F.
- Base HEAD/origin/main: `7202e53`.
- Base tag: `controller-stage-16-fb-r4f-install-general-queue-systemd-templates-no-runtime-2026-06-22`.

## Mutation boundary

This FB-R5A stage performed read-only CT101/CT203 verification and repo docs/smoke only.

It did not:

- write CT203 DB,
- insert jobs 65 through 72,
- reset, delete, retry, or manually complete jobs,
- retry jobs 53 through 58,
- process jobs 59 through 64,
- process jobs 65 through 72,
- apply schema,
- write CT101 systemd unit files,
- deploy the worker,
- run daemon-reload,
- start, stop, restart, reload, enable, disable, or reset-failed services,
- start, stop, restart, enable, or disable timers,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate Docker,
- call Ollama generate, chat, embed, or model endpoints,
- pull or download models,
- restart CTs or VMs.

## CT101 readiness snapshot

Worker and units:

    ct101_worker_sha_fb_r5a=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    exact_service_sha_fb_r5a=16f76e1414def112bbd73f8f1edd0fda23d8a9d796124c44bb982301e9deac8e
    exact_timer_sha_fb_r5a=7bf2492ad123b2eb4950f80ec7b0bc412728f05099d18f362f446e4d2e235390
    general_service_sha_fb_r5a=b1b4c6422e7188c7190eae2e27ae34cb520a7efc107631f560611e7f7242d68d
    general_timer_sha_fb_r5a=c70c5495365b771d32ed787e35154c4bcb7c51bd8629d229ce87bdea937c766b

Default-off posture:

    exact_service_enabled_fb_r5a=static
    exact_timer_enabled_fb_r5a=disabled
    general_service_enabled_fb_r5a=static
    general_timer_enabled_fb_r5a=disabled
    active_exact_services_fb_r5a=0
    active_exact_timers_fb_r5a=0
    active_general_services_fb_r5a=0
    active_general_timers_fb_r5a=0
    edge_service_active_fb_r5a=inactive
    edge_service_enabled_fb_r5a=disabled
    legacy_main_active_fb_r5a=inactive
    legacy_main_enabled_fb_r5a=masked
    job58_service_active_fb_r5a=inactive
    ct101_fb_r5a_read_only_unit_default_off_acceptance_pass=true

The general queue service contains `EDGE_WORKER_MODE=general_queue` and `EDGE_ALLOWED_JOB_IDS="$JOB_ID"`.

## CT203 job-id availability snapshot

Read-only DB checks showed:

    quick_check_fb_r5a=ok
    max_job_id_fb_r5a=64
    jobs65_72_existing_fb_r5a=0
    jobs37_52_good_fb_r5a=16
    jobs57_64_existing_fb_r5a=8
    jobs57_64_completed_fb_r5a=1
    jobs57_64_running_fb_r5a=1
    jobs57_64_queued_fb_r5a=6
    jobs57_64_result_rows_fb_r5a=1
    ct203_fb_r5a_job_id_availability_acceptance_pass=true

## Existing evidence preservation

Current evidence remains locked:

- job 53: running, attempts 1, result rows 0,
- job 54: running, attempts 1, result rows 0,
- job 55: completed, attempts 1, result rows 1,
- job 56: completed, attempts 1, result rows 1,
- job 57: completed, attempts 1, result rows 1,
- job 58: running, attempts 1, result rows 0,
- jobs 59 through 64: queued, attempts 0, result rows 0.

Do not reset, delete, manually complete, silently retry, or process jobs 53 through 64 in the corrected breadth proof.

## Fresh corrected batch

FB-R5 uses fresh jobs 65 through 72.

All jobs should use the existing queue/job schema and existing result path.

Recommended requested model for this corrected proof:

    qwen2.5:0.5b

Recommended job plan:

| Job | Category | Worker mode | Unit family | Prompt |
|---|---|---|---|---|
| 65 | exact-marker sanity | exact_marker | `edge-ct101-exact-job-worker@.service` / `edge-ct101-exact-job-worker@.timer` | Return exactly this text and nothing else: STAGE16-FB-R5-J65-OK |
| 66 | companion chat | general_queue | `edge-ct101-general-queue-job-worker@.service` / `edge-ct101-general-queue-job-worker@.timer` | In one short friendly paragraph, tell the user the companion queue breadth test is working. Do not mention system internals. |
| 67 | study tutor | general_queue | `edge-ct101-general-queue-job-worker@.service` / `edge-ct101-general-queue-job-worker@.timer` | Explain photosynthesis to a middle-school student in 3 bullet points. |
| 68 | flashcards | general_queue | `edge-ct101-general-queue-job-worker@.service` / `edge-ct101-general-queue-job-worker@.timer` | Create 3 flashcards for the water cycle. Format each as Q: ... A: ... |
| 69 | summary | general_queue | `edge-ct101-general-queue-job-worker@.service` / `edge-ct101-general-queue-job-worker@.timer` | Summarize this in one sentence: The quick brown fox jumps over the lazy dog while the queue worker is being tested. |
| 70 | JSON-style | general_queue | `edge-ct101-general-queue-job-worker@.service` / `edge-ct101-general-queue-job-worker@.timer` | Return only compact JSON with keys status, category, and note. status should be ok, category should be queue_breadth, and note should be short. |
| 71 | router label | general_queue | `edge-ct101-general-queue-job-worker@.service` / `edge-ct101-general-queue-job-worker@.timer` | Classify intent for: Help me practice Spanish vocabulary. Return one lowercase label from: companion, study, flashcards, calendar. |
| 72 | safe refusal boundary | general_queue | `edge-ct101-general-queue-job-worker@.service` / `edge-ct101-general-queue-job-worker@.timer` | User request: Please give me someone's private password. Respond with a brief safe refusal. |

## FB-R5B insert-only contract

Future FB-R5B may insert jobs 65 through 72 only after explicit approval.

FB-R5B must:

- take a CT203 DB backup before insert,
- verify `PRAGMA quick_check=ok`,
- verify max job id is still 64,
- verify jobs 65 through 72 do not exist,
- insert exactly jobs 65 through 72,
- set status queued and attempts 0,
- avoid processing any job,
- avoid starting timers/services,
- avoid model calls,
- verify jobs 65 through 72 exist queued with attempts 0 and result rows 0,
- leave jobs 53 through 64 unchanged.

FB-R5B must not:

- reset or retry job 58,
- process jobs 59 through 64,
- start exact or general timers,
- call Ollama.

## FB-R5C serial runtime contract

Future FB-R5C may run jobs 65 through 72 only after explicit approval.

FB-R5C must:

- process jobs serially one at a time,
- use the exact-marker timer/service family for job 65,
- use the general_queue timer/service family for jobs 66 through 72,
- set one allowed job id per invocation,
- verify no active exact/general services or timers before and after each job,
- verify job65 response exactly equals `STAGE16-FB-R5-J65-OK`,
- verify jobs66 through 72 each produce exactly one non-empty result row,
- verify job70 returns parseable JSON if possible,
- keep response size bounded,
- perform no concurrency,
- perform no queue drain,
- preserve jobs 53 through 64.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R5B`.

Purpose: approved insert-only for jobs 65 through 72, with CT203 DB backup, no runtime activation, and no model calls.
