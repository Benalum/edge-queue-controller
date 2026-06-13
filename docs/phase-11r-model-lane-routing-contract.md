# Phase 11R Model Lane Routing Contract

Phase 11R adds contract-only model lane metadata to real-user queued Companion jobs.

## Goal

Prepare the Companion queue for future multi-model scheduling without changing live execution behavior yet.

## What changed

Real-user queued chat jobs now include these fields inside `app_jobs.payload_json`:

- `routing_contract_version`
- `routing_decision`
- `model_tier`
- `model_lane`
- `queue_lane`
- `model_max_parallel_hint`

## Initial model lane registry

- tiny: `qwen3:0.6b`, max parallel hint 4
- small: `qwen3:1.7b`, max parallel hint 2
- medium: `gemma3:4b`, max parallel hint 1
- large: `gemma4:e4b`, max parallel hint 1

## Safety boundary

This phase does not:

- migrate `app_jobs`
- migrate CT101 `jobs`
- change worker claim order
- change worker concurrency
- change Ollama parallelism
- restart services

The current live bottleneck remains one-at-a-time execution until later phases add lane-aware claiming and worker concurrency.
