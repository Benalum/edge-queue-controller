# CT101 Bounded Ollama Failure Smoke — Stage 5E-22

## Purpose

Stage 5E-22 verifies CT101 handles bounded Ollama execution failure safely through the laptop-owned queue.

## What this smoke does

1. Starts a temporary laptop queue API server.
2. Creates synthetic laptop queue jobs.
3. Updates one synthetic job with an intentionally invalid Ollama model.
4. Runs the CT101 bounded poller in Ollama mode.
5. Verifies the job becomes failed.
6. Verifies error_text contains the bounded Ollama failure marker.
7. Verifies the worker returns idle.
8. Cleans up all synthetic rows.

## Safety

This smoke is:

- synthetic-only
- bounded
- token-protected
- not connected to Docker Compose
- not production
- not user-facing

## What this stage does not do

This stage does not:

- modify the production CT101 worker loop
- change Docker Compose
- start a persistent worker
- migrate production jobs
- claim non-synthetic jobs
- change chat/study behavior
