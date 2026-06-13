# Phase 12R-C Model Warmup and Keep-Alive Strategy Inspection

Phase 12R-C is inspection-only.

It defines the safe model loading policy before persistent lane workers are activated.

## Problem

After boot, Ollama may be running but individual models may not be loaded into RAM/VRAM yet.

A worker can be online while the first job for a model still pays the model load cost.

If the queue treats that delay as a failure, the platform can incorrectly fail jobs during cold start.

## Recommended policy

Use lazy, lane-aware model warmup.

Do not load every model at boot.

Recommended lifecycle:

1. boot controller and CT101 services
2. workers register as online but cold
3. first job for a lane/model triggers warmup for that specific model
4. worker waits for warmup within a bounded timeout
5. worker claims/runs the job after the target model is ready
6. model stays loaded for a configured keep-alive window
7. idle models unload naturally when no longer needed

## Why not preload every model?

Preloading every model at boot can:

- slow down boot
- consume RAM/VRAM before there is real demand
- make CT101 look busy immediately after boot
- cause model eviction/thrashing if several models compete for memory
- hide model-specific cold-start problems

## Lane-specific policy

### model-tiny

`model-tiny` should be cheap enough to warm quickly.

Future implementation may optionally keep it warm longer because it is useful for:

- fast intent parsing
- routing decisions
- lightweight study/companion tasks

### model-small

`model-small` should warm on first real small-lane demand.

It should not be loaded at boot unless there is a queued small job or explicit warmup request.

### primary/unfiltered worker

The primary unfiltered worker should not be converted or preloaded yet.

It remains the safe fallback while lane workers are still dormant.

### future companion-medium

A future medium model should warm only when Companion needs it.

It should not block tiny/small lanes.

## Queue behavior requirement

The queue/worker system should eventually distinguish:

- worker online
- worker cold
- worker warming model
- model ready
- worker busy
- worker failed warmup

A model load delay should not be treated the same as a job failure.

## Future implementation requirements

A safe implementation should add:

- model warmup helper using a tiny bounded Ollama request
- per-model warmup timeout
- per-model keep-alive setting
- status evidence for loaded/warming models
- no job claim before the worker can run the requested model
- safe fallback if warmup fails
- no automatic persistent lane worker activation until smoke passes

## Current decision

The next runtime implementation should not load all models at boot.

It should prefer first-needed model loading with bounded warmup and keep-alive.

Phase 12R-C does not change services, worker env, model loading, router rollout, or queue behavior.
