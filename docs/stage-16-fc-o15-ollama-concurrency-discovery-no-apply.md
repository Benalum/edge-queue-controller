# Stage 16 FC-O15 Ollama concurrency discovery no-apply

Date: 2026-06-23

## Base checkpoint

- Prior completed checkpoint: Stage 16 FC-O14.
- Base HEAD/origin/main: `018eb2e`.
- Base tag: `controller-stage-16-fc-o14-run-only-job113-qwen3-summary-hygiene-one-shot-2026-06-23`.

## Mutation boundary

This stage is read-only against CT101 and CT203.

It did not write CT203 DB, mutate jobs, process jobs, mutate CT101 profile, change worker code, start runtime, start/stop/restart/reload/enable/disable/reset-failed services, clear failed unit evidence, write systemd units, run daemon-reload, activate scheduler, enable persistent workers, mutate Docker, call Ollama generation/model endpoints, pull models, or restart CTs/VMs.

## Why this stage exists

FC-O14 proved qwen3:1.7b summary output hygiene after the no-think profile flags.

Before increasing worker throughput, inspect whether Ollama should handle per-model concurrency while CT203 remains the durable queue authority.

Official Ollama concurrency knobs to consider:

- `OLLAMA_NUM_PARALLEL`: parallel requests per model.
- `OLLAMA_MAX_LOADED_MODELS`: concurrently loaded models.
- `OLLAMA_MAX_QUEUE`: Ollama-side queued requests.
- `OLLAMA_CONTEXT_LENGTH`: context length, which affects memory when parallelism increases.

## Current Ollama concurrency environment

    OLLAMA_NUM_PARALLEL=1
1
    OLLAMA_MAX_LOADED_MODELS=<unset>
    OLLAMA_MAX_QUEUE=<unset>
    OLLAMA_CONTEXT_LENGTH=<unset>

## CT203 queue state

    quick_check_fc_o15=ok
    job105_status_fc_o15=running
    job105_attempts_fc_o15=1
    job105_result_rows_fc_o15=0
    job106_status_fc_o15=queued
    job106_attempts_fc_o15=0
    job106_result_rows_fc_o15=0
    jobs107_111_remain_queued_attempts0_rows0=true
    job112_status_fc_o15=completed
    job112_result_rows_fc_o15=1
    job113_status_fc_o15=completed
    job113_result_rows_fc_o15=1
    ct203_fc_o15_read_only_acceptance_pass=true

## CT101 posture

    profile_sha_fc_o15=44f9b1ffb18e7292db8074b783802a4ac81c6276b3cb1f4eedcbddf6f962b899
    worker_sha_fc_o15=25ca696949851075a2dd77b715275ff1d08847249dc8d95d9be8336b60b740ca
    active_exact_services_fc_o15=0
    active_exact_timers_fc_o15=0
    active_general_services_fc_o15=0
    active_general_timers_fc_o15=0
    failed_general_units_fc_o15=6
    ct101_fc_o15_read_only_acceptance_pass=true

## Decision

The safest architecture remains:

- CT203 is the durable queue and claim authority.
- CT101 worker controls which jobs are claimed and completed.
- Ollama may later be allowed to handle bounded per-model request parallelism underneath the worker.
- Do not let Ollama become the durable job queue.
- Do not raise concurrency until memory/VRAM headroom and model-specific behavior are explicitly bounded.

## Recommended next steps

1. Run job106 only as a qwen3 JSON one-shot, now that job113 proved clean no-think summary output.
2. Separately plan a bounded concurrency apply stage after job106, likely starting with a small value such as one model family and `OLLAMA_NUM_PARALLEL=2`, only if memory allows.
