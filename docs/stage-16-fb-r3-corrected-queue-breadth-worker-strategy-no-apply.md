# Stage 16 FB-R3 corrected queue breadth worker strategy no-apply

Date: 2026-06-22

## Base checkpoint

- Prior completed stage: Stage 16 FB-R2.
- Base HEAD/origin/main: `6023189`.
- Base tag: `controller-stage-16-fb-r2-partial-runtime-failure-evidence-checkpoint-no-retry-2026-06-22`.

## Mutation boundary

This FB-R3 stage is repo-only planning.

It does not:

- write the CT203 database,
- insert, reset, delete, retry, or manually complete jobs,
- retry job 53,
- retry job 54,
- retry job 55,
- retry job 56,
- retry job 57,
- retry job 58,
- process jobs 59 through 64,
- apply schema,
- write CT101 unit files,
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

## Why this strategy is needed

Stage 16 FB showed that the queue can insert breadth jobs and that the installed CT101 exact-job path can complete an exact-marker request.

Evidence:

- job 57 completed successfully with exact response `STAGE16-FB-J57-OK`,
- job 58 reached the installed worker and failed with `REFUSE_EXPECTED_MARKER_NOT_FOUND`,
- job 58 remains running with attempts 1 and no result rows,
- jobs 59 through 64 remain queued with attempts 0 and no result rows,
- job58 service remains in systemd failed state as evidence,
- active exact-job services and timers are 0 after cleanup.

The failure is not a queue insert failure. It is a worker-mode mismatch.

The installed worker is still an exact-marker proof worker. It expects marker-style prompts and refuses non-exact natural-language prompts. Queue breadth testing needs a general queue worker mode that can accept normal companion, study, flashcard, summary, JSON, router, and refusal prompts.

## Current evidence preservation

The following evidence must remain preserved:

- jobs 37 through 52: completed, one result row each,
- job 53: running, attempts 1, result rows 0,
- job 54: running, attempts 1, result rows 0,
- job 55: completed, attempts 1, result rows 1, response `E3Z-EW-OK`,
- job 56: completed, attempts 1, result rows 1, response `E3Z-EY-OK`,
- job 57: completed, attempts 1, result rows 1, response `STAGE16-FB-J57-OK`,
- job 58: running, attempts 1, result rows 0, worker refused expected marker not found,
- jobs 59 through 64: queued, attempts 0, result rows 0.

Do not reset, delete, manually complete, or silently retry jobs 57 through 64.

## Corrected design target

The corrected design should separate three things that were mixed together in FB:

1. **Exact-marker proof worker**
   - For strict proof jobs.
   - Requires embedded expected marker.
   - Refuses when expected marker is missing.
   - Good for one-shot infrastructure proof.

2. **General queue breadth worker**
   - For normal user-style requests.
   - Does not require exact-marker extraction.
   - Writes exactly one result row on successful model response.
   - Records bounded response metadata.
   - Leaves acceptance classification to post-run verification.

3. **Acceptance classifier**
   - Runs after each job or after the batch.
   - Interprets the model response according to the job category.
   - Does not decide whether the worker should call the model.
   - Does not mutate historical evidence unless explicitly designed.

## Proposed worker-mode contract

A future corrected worker should support an explicit worker mode.

Recommended modes:

- `exact_marker`
- `general_queue`

The default should remain safe and conservative.

Suggested runtime environment contract:

    EDGE_WORKER_MODE=exact_marker
    EDGE_WORKER_MODE=general_queue

For `exact_marker`:

- require expected marker extraction,
- require exact response validation,
- fail closed on missing marker,
- preserve existing proof-worker behavior.

For `general_queue`:

- do not require marker extraction,
- do not require exact response match,
- require one allowed job id only,
- require one claimed job only,
- require one result row only,
- enforce max response size,
- enforce model timeout,
- preserve last_error on failure,
- return a nonzero service exit only when the job was not safely completed or recorded.

## Future code-change stage

Before any new runtime breadth proof, create a no-runtime repo implementation stage.

Recommended future stage: `Stage 16 FB-R4`.

FB-R4 should modify code only and add tests/smokes for a general queue worker mode.

FB-R4 must not:

- insert jobs,
- process jobs,
- call Ollama,
- start timers or services,
- enable persistent workers,
- enable scheduler dispatch.

FB-R4 should add or update tests that prove:

- exact-marker mode still refuses missing marker,
- exact-marker mode still completes exact marker,
- general_queue mode does not require marker extraction,
- general_queue mode writes one result row for a supplied mocked response,
- general_queue mode does not claim jobs outside `EDGE_ALLOWED_JOB_IDS`,
- general_queue mode cannot process more than one job when configured one-shot,
- duplicate result insertion is prevented or refused.

## Future runtime continuation options

There are two safe continuation options after FB-R4.

### Option A: fresh corrected breadth batch

Create a new fresh batch, likely jobs 65 through 72.

Advantages:

- avoids changing FB evidence jobs 57 through 64,
- keeps job58 failure and jobs59-64 queued as preserved evidence,
- cleanly proves corrected worker behavior on new jobs.

Disadvantage:

- leaves queued jobs 59 through 64 as evidence until a later explicit archival/abandonment policy exists.

### Option B: explicitly approved continuation of jobs 59 through 64

Process queued jobs 59 through 64 using corrected general queue worker mode.

Advantages:

- uses already inserted FB batch jobs,
- avoids inserting another batch.

Disadvantages:

- jobs 57 and 58 would remain mixed evidence in the same batch,
- job58 should not be retried,
- batch acceptance must distinguish completed job57, failed job58, and continued jobs59-64.

Recommended path: Option A.

Use fresh jobs 65 through 72 for the corrected breadth proof after the general queue worker mode is implemented and tested.

## Corrected breadth proof proposal

Future corrected runtime stage should be named `Stage 16 FB-R5` or `Stage 16 FB-C`.

Recommended batch: jobs 65 through 72.

Recommended matrix:

| Planned job | Category | Worker mode | Model/profile | Acceptance |
|---|---|---|---|---|
| 65 | exact marker sanity | `exact_marker` | `qwen2.5:0.5b` | exact marker |
| 66 | companion chat | `general_queue` | `qwen2.5:0.5b` | bounded text contains companion |
| 67 | study/tutor | `general_queue` | `qwen2.5:0.5b` | contains required terms |
| 68 | flashcards | `general_queue` | `qwen2.5:0.5b` | contains Q/A markers |
| 69 | summary | `general_queue` | `qwen2.5:0.5b` | bounded summary |
| 70 | JSON-style | `general_queue` | `qwen2.5:0.5b` | parseable or documented model-format finding |
| 71 | router label | `general_queue` | `qwen2.5:0.5b` | exact label or documented finding |
| 72 | safe refusal boundary | `general_queue` | `qwen2.5:0.5b` | contains safety/refusal terms |

The corrected runtime stage must still process serially. No concurrency yet.

## Runtime acceptance after correction

A corrected serial breadth proof should pass if:

- fresh jobs are inserted exactly once,
- each job is claimed once,
- each job has attempts 1,
- each job has exactly one result row,
- exact marker job passes exact validation,
- general jobs produce bounded non-empty results,
- post-run classifier records pass/finding for each general job,
- no unapproved job is claimed,
- prior evidence jobs remain preserved,
- CT101 exact-job timers/services return to default-off after each job,
- no persistent worker or scheduler dispatch is enabled.

## Reset-failed policy

Job58 service currently remains failed as preserved evidence.

Do not reset-failed until one of these happens:

- a cleanup-only stage is explicitly approved,
- evidence has been checkpointed and the next stage needs a clean systemd view,
- reset-failed is limited only to `edge-ct101-exact-job-worker@58.service`,
- no DB/job state is changed.

A reset-failed cleanup should be separate from worker implementation and runtime proof.

## Concurrency boundary

No concurrency testing should begin until all of these are true:

- general queue worker mode exists,
- serial breadth proof passes,
- model inventory is documented,
- per-model and per-worker limits are documented,
- duplicate result prevention is tested,
- lease/stale-running behavior is documented,
- cleanup behavior for partial failures is documented.

## Recommended next stage

Recommended next stage: `Stage 16 FB-R4`.

Purpose: implement general queue worker mode in repo only, with tests/smokes and no runtime activation.

FB-R4 should preserve the existing exact-marker mode and add a separate `general_queue` mode.
