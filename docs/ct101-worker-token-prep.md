# CT101 Worker Token Prep — Stage 5E-6

## Purpose

Stage 5E-6 prepares the laptop queue internal token for future CT101 worker connection.

This stage does not connect CT101 workers yet.

## Token file

The laptop queue token is stored outside git:

- ~/.config/ai-platform-controller/internal-queue.env

The file contains:

- LAPTOP_QUEUE_INTERNAL_TOKEN

The file must be chmod 600.

## Why this token exists

Future CT101 workers will need to authenticate to laptop/controller internal queue endpoints.

The token allows CT101 workers to call internal laptop queue endpoints such as:

- GET /internal/laptop-queue/summary
- POST /internal/laptop-queue/jobs/claim
- POST /internal/laptop-queue/jobs/{job_id}/complete

## Current status

The internal queue API exists and is token protected.

Stage 5E-5 verified:

- missing token returns 401
- wrong token returns 403
- correct token allows access

Stage 5E-6 verifies:

- token file exists outside git
- token file is chmod 600
- token value is not committed to the repo
- internal queue API can read the token from the file, not only from environment variables

## Future CT101 connection plan

Later, CT101 should receive the token through a secure local file or environment configuration.

Possible CT101 token destination:

- /opt/ai-platform/.secrets/laptop-queue.env

That file must stay outside git and outside public logs.

Future CT101 worker environment variables may include:

- LAPTOP_QUEUE_BASE_URL=http://100.88.245.33:7070
- LAPTOP_QUEUE_INTERNAL_TOKEN=...
- LAPTOP_QUEUE_WORKER_ID=...
- LAPTOP_QUEUE_JOB_TYPES=ollama_chat,companion_study_grade

Exact values are not final in this stage.

## Safe connection sequence

Future worker connection should happen in stages:

1. Create CT101 token file outside git.
2. Add CT101 read-only connectivity smoke to laptop summary endpoint.
3. Add CT101 synthetic claim/complete smoke.
4. Add isolated synthetic worker mode.
5. Only then consider opt-in real queued jobs.
6. Production migration comes later.

## What this stage does not do

This stage does not:

- modify CT101
- copy the token to CT101
- connect CT101 workers
- migrate production jobs
- change public UI behavior
- remove CT101 job routes
- remove old queues

## Cleanup requirement

After the full laptop queue migration is complete and verified, remove unused queue paths in a separate cleanup stage.

Cleanup must wait until:

- laptop queue is source of truth
- CT101 workers use laptop queue
- backups pass
- restore has been tested
- production behavior is verified
- rollback instructions exist
