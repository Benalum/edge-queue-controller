# CT101 Bounded Ollama Poller Smoke — Stage 5E-21

## Purpose

Stage 5E-21 verifies CT101 can process one synthetic laptop queue job using real Ollama execution.

## What this smoke does

1. Starts a temporary laptop queue API server.
2. Finds an available CT101 Ollama model.
3. Creates synthetic laptop queue jobs.
4. Updates the first synthetic job with a prompt payload.
5. Runs CT101 bounded poller in Ollama mode for one job.
6. Verifies the job completed with source ct101_bounded_ollama_poller.
7. Verifies the result contains reply, model, mode, and elapsed_seconds.
8. Verifies the worker returned idle.
9. Cleans up synthetic rows.

## Safety

The smoke remains:

- synthetic-only
- bounded
- token-protected
- not connected to Docker Compose
- not production

## What this stage does not do

This stage does not:

- modify the production CT101 worker loop
- change Docker Compose
- start a persistent worker
- migrate production jobs
- claim non-synthetic jobs
- change user-facing behavior
