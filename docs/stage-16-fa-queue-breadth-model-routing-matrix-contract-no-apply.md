# Stage 16 FA queue breadth/model-routing matrix contract no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 E3Z-EZ-R2.
- Base HEAD/origin/main: `b0260e6`.
- Base tag: `controller-stage-16-e3z-ez-r2-installed-unit-repeatability-recovered-success-checkpoint-2026-06-22`.

## Mutation boundary

This FA stage is repo-only planning.

It does not:

- write the CT203 database,
- insert, reset, delete, retry, or manually complete jobs,
- start, stop, restart, reload, enable, or disable services,
- start, stop, restart, enable, or disable timers,
- activate scheduler services or timers,
- enable persistent workers,
- drain the queue,
- mutate CT101 unit files,
- run daemon-reload,
- start, stop, or restart CTs or VMs,
- mutate Docker containers,
- call Ollama generate, chat, embed, or model endpoints,
- pull or download models,
- change model inventory,
- mutate SSH config,
- mutate `/etc/hosts`.

## Purpose

Stage 16 FA defines the first queue breadth and model-routing test matrix before running a batch of different user-style requests.

The project is moving from exact single-job installed-unit proofs into controlled queue breadth tests. FA is intentionally no-apply so the request matrix, model routing expectations, evidence preservation rules, and future concurrency gates are documented before runtime mutation.

## Current evidence baseline

Installed CT101 exact-job path evidence:

- job 53: failed evidence, running, attempts 1, result rows 0,
- job 54: failed evidence, running, attempts 1, result rows 0,
- job 55: successful evidence, completed, attempts 1, result rows 1, response `E3Z-EW-OK`,
- job 56: successful evidence, completed, attempts 1, result rows 1, response `E3Z-EY-OK`,
- jobs 37 through 52: completed, exactly one result row each.

CT101 default-off posture after E3Z-EZ-R2:

- active exact-job services: 0,
- active exact-job timers: 0,
- permanent CT101 worker inactive/disabled,
- legacy laptop worker units inactive/masked,
- installed timer template disabled,
- installed service template static,
- Ollama running/healthy.

## Design target

The next runtime family should test queue breadth before concurrency.

The order is:

1. FA: define matrix, no-apply.
2. FB: run a small bounded serial breadth proof.
3. FC: run serial multi-model or multi-profile proof.
4. FD: define concurrency preflight, no-apply.
5. FE: run limited concurrency proof.
6. FF: run broader concurrency/load proof.

No concurrency test should run until FD documents explicit limits and FE is separately approved.

## Model-routing principle

Users do not call models directly.

Expected production flow remains:

    Frontend -> Backend API -> CT203 job queue -> Scheduler/lease -> Worker -> Model

The queue tests must preserve that principle. Even when a job has `requested_model`, the backend/queue remains authoritative and results must be written through the job/result path.

## Model inventory rule

FA does not assume model inventory beyond what is already installed and approved.

Future runtime tests may use only models observed as already present on CT101/PVESO. No model pull or download is allowed in FA, FB, FC, FD, FE, or FF unless a separate explicit model inventory/pull approval stage is created.

Initial safe runtime model for FB:

- `qwen2.5:0.5b`

Later FC may include other installed models only after a read-only model inventory checkpoint confirms them.

## Request matrix for FB serial breadth proof

FB should use a small bounded serial batch, not concurrency.

Recommended batch size: 8 jobs.

Recommended execution mode:

- one active worker path at a time,
- one installed exact-job timer/service instance per job,
- no persistent worker enablement,
- no scheduler/timer dispatch enablement,
- no queue drain,
- no retry of prior evidence jobs,
- no model pull.

### FB job matrix

| Planned job | Category | Model/profile | Prompt intent | Acceptance type |
|---|---|---|---|---|
| 57 | exact marker sanity | `qwen2.5:0.5b` | Return exact marker only | exact match |
| 58 | short companion chat | `qwen2.5:0.5b` | friendly one-paragraph answer | non-empty bounded text |
| 59 | study/tutor explanation | `qwen2.5:0.5b` | explain a simple concept | contains required terms |
| 60 | flashcard generation | `qwen2.5:0.5b` | create 3 Q/A cards | structured line check |
| 61 | summarization | `qwen2.5:0.5b` | summarize provided short text | concise summary check |
| 62 | JSON-style response | `qwen2.5:0.5b` | return small JSON object | parseable JSON check if supported |
| 63 | router/intention classification | `qwen2.5:0.5b` | classify request category | exact label check |
| 64 | safe refusal boundary | `qwen2.5:0.5b` | refuse a disallowed request safely | contains refusal marker |

FB should keep output checks simple and deterministic enough for a local small model.

## Recommended FB prompt contracts

### Job 57 exact marker sanity

Marker:

    STAGE16-FB-J57-OK

Prompt:

    Return exactly this text and nothing else: STAGE16-FB-J57-OK

Acceptance:

- response exactly equals `STAGE16-FB-J57-OK`,
- response sha256 equals sha256 of exactly that marker.

### Job 58 short companion chat

Prompt:

    In one friendly paragraph, say that the queue breadth test is working and mention the word companion.

Acceptance:

- status completed,
- attempts 1,
- one result row,
- response is non-empty,
- response contains `companion`,
- response length is under a configured bounded maximum.

### Job 59 study/tutor explanation

Prompt:

    Explain photosynthesis in two short sentences for a middle school student. Include the words sunlight and sugar.

Acceptance:

- response contains `sunlight`,
- response contains `sugar`,
- response is bounded.

### Job 60 flashcard generation

Prompt:

    Create exactly three flashcards about planets. Format each as Q: ... A: ...

Acceptance:

- response contains exactly or at least three `Q:` markers,
- response contains at least three `A:` markers,
- response is bounded.

### Job 61 summarization

Prompt:

    Summarize this in one sentence: The queue stores work, the worker processes one job, and the result is saved for the user.

Acceptance:

- one result row,
- response contains `queue` or `worker`,
- response is bounded.

### Job 62 JSON-style response

Prompt:

    Return a compact JSON object with keys status and feature. Use status="ok" and feature="queue".

Acceptance:

- response is parseable JSON after trimming simple markdown fences if needed,
- `status` equals `ok`,
- `feature` equals `queue`.

If the small model wraps JSON in markdown, FB may record that as a model-format finding, but should not silently loosen the acceptance rules without documenting it.

### Job 63 router/intention classification

Prompt:

    Classify this request as one label from companion, study, flashcards, summary: "Help me practice vocabulary cards." Return only the label.

Acceptance:

- response exactly equals `flashcards`, or the stage records exact mismatch as evidence.

### Job 64 safe refusal boundary

Prompt:

    The user asks for something unsafe. Reply with a brief refusal and include the word safety.

Acceptance:

- response contains `safety`,
- response is non-empty and bounded.

This is not a full safety system test; it is a queue breadth formatting test.

## FB runtime constraints

A future FB runtime proof must:

- create one CT203 backup before inserting the batch,
- insert exactly jobs 57 through 64,
- preserve jobs 53 through 56,
- preserve jobs 37 through 52,
- process jobs serially,
- use one installed exact-job timer/service instance at a time,
- constrain each worker invocation with a single `EDGE_ALLOWED_JOB_IDS=<job_id>`,
- never use a broad allowed-job list,
- never start persistent workers,
- never enable scheduler/timer dispatch,
- never drain the queue,
- never pull models,
- stop each exact timer/service instance after its proof,
- verify no exact-job service/timer remains active after each job,
- verify CT101 default-off after the batch.

## FB acceptance summary

FB passes only if:

- jobs 57 through 64 are inserted exactly once,
- each job is processed exactly once,
- each job has attempts 1,
- each job has exactly one result row,
- each job has an acceptance outcome recorded,
- deterministic jobs meet exact/structured acceptance,
- non-deterministic jobs meet bounded non-empty acceptance,
- jobs 53 and 54 remain running attempts 1 result rows 0,
- jobs 55 and 56 remain completed attempts 1 result rows 1,
- jobs 37 through 52 remain completed with one result row each,
- no unapproved job is claimed,
- CT101 returns to default-off,
- repo is checkpointed only after verification.

FB may still pass with documented model-format findings for non-exact prompts if the queue mechanics pass and the acceptance rules clearly classify those findings. However, the exact marker sanity job must pass exactly.

## FC multi-model serial proof

FC should happen only after FB passes.

FC should remain serial and may use multiple model profiles only after a read-only model inventory proves the models are present.

FC should not test concurrency.

FC should verify:

- requested model is honored or documented,
- unavailable model requests fail safely,
- model routing metadata is recorded,
- one result row per job,
- no duplicate claims.

## FD concurrency preflight no-apply

FD must define concurrency limits before any concurrent runtime proof.

Required limits:

- maximum active jobs overall,
- maximum active jobs per worker,
- maximum active jobs per model,
- maximum installed timer instances allowed at once,
- maximum service instances allowed at once,
- max lease duration,
- stale running job detection,
- duplicate result prevention,
- idempotent result insertion,
- retry policy,
- cancellation policy,
- model timeout policy,
- cleanup after partial failure,
- evidence preservation rules.

FD must also define resource guardrails for CT101/PVESO:

- CPU load threshold,
- memory threshold,
- swap threshold,
- Ollama health check requirement,
- maximum simultaneous model calls,
- maximum batch size,
- abort criteria.

## FE limited concurrency proof

FE should be the first runtime concurrency stage.

Initial recommended limit:

- maximum active jobs: 2,
- maximum simultaneous model calls: 1 or 2 depending on FD findings,
- small batch size: 4 jobs,
- only models already proven in FB/FC.

FE requires explicit runtime approval.

## FF broader concurrency/load proof

FF should only happen after FE passes.

FF may increase:

- job count,
- request variety,
- worker count,
- model variety,
- concurrency.

FF must still preserve evidence and must have explicit approval.

## Recommended next stage

Recommended next stage: `Stage 16 FB`.

Purpose: perform a small bounded serial queue breadth runtime proof for jobs 57 through 64 using installed exact-job timer/service invocations one at a time.

FB requires explicit runtime approval because it will insert multiple jobs, start multiple exact timer/service instances serially, and call Ollama for each job.
