# Stage 16 E3Z-AY — CT101 queue-worker integration plan (no apply)

## Purpose

This document records the no-apply queue-worker direction after CT101 `llms` was started safely through the PVESO forced-command path.

CT203 remains the controller, queue, scheduler, and database authority. CT101 is the intended model-worker container and must not become the controller.

## Existing integrated pieces

- CT203 queue and DB authority are live.
- CT203 worker registry and heartbeat routes exist in `edge_controller.py`.
- Queue claim, complete, recovery, internal token, lane metadata, scheduler preview, and Ollama forwarding symbols already exist in the repo.
- PVESO now exposes a narrow forced-command worker-control path for inventory, CT101 status, and CT101 start observe.
- CT101 `llms` is running with `/mnt/ollama-models` mounted.
- Docker/Ollama runtime activation remains blocked until old Docker restart policies are handled safely.

## Integration principle

Do not build a parallel queue system. Reuse the existing CT203 queue APIs, worker registry, lane metadata, and job result paths wherever possible.

## Required next design decision

Pick one of these two paths:

1. Reuse the existing internal queue worker/register/heartbeat and claim/complete routes from CT101.
2. Add only a thin CT101 worker service that wraps the existing CT203 queue routes and local model adapter.

## Guardrails

- Do not call `/api/generate` during no-apply or readiness phases.
- Do not activate scheduler or timers until the worker path is explicitly proven.
- Do not start Docker or containers as part of this no-apply plan.
- Do not mutate jobs 35 or 36 until a separately approved worker execution proof.
- Do not reuse job 34.
