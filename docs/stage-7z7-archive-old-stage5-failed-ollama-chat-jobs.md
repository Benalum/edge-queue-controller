# Stage 7Z-7 Archive Old Stage 5 Failed Ollama Chat Jobs

Stage 7Z-7 removes old Stage 5 test failures from the active System queue view.

## Problem

The System page showed:

- queued: 0
- running: 0
- failed: 5

Those 5 failed jobs were old Stage 5 test jobs, not current user work.

The failed rows were in Postgres `app_jobs` with:

- `job_type = 'ollama_chat'`
- `status = 'failed'`

## Constraint Finding

`app_jobs.status` has a CHECK constraint that only allows:

- `queued`
- `running`
- `complete`
- `failed`
- `cancelled`

So `status = 'archived'` is not allowed.

`job_type` has no CHECK constraint, so the safe archive path was to keep the historical status as `failed` but move the old test rows out of the active `ollama_chat` queue view.

## Change

Updated exactly 5 known old Stage 5 test rows:

- from `job_type = 'ollama_chat'`
- to `job_type = 'ollama_chat_archived'`

The rows still preserve their historical `status = 'failed'`.

## Verification

After archive:

- active `ollama_chat` complete: 38
- active `ollama_chat` failed: 0
- archived `ollama_chat_archived` failed: 5
- System queue showed queued 0, running 0, failed 0
- CT101 Laptop Queue Worker showed queued 0, running 0, failed 0
- all normalized platform cards stayed online
- `/workers/registry` stayed clean with total 0
- `/workers/remediation/tick` saw worker_count 0
- legacy laptop `/tick` scheduler timer stayed disabled/inactive
- modern power/remediation timers stayed active

## Decision

Keep old Stage 5 failed test jobs archived as `ollama_chat_archived`.

Active queue health should reflect current `ollama_chat` work only.
