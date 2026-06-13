# Phase 12R-D Model Memory Eviction Strategy Inspection

Phase 12R-D is inspection-only.

It documents how the platform should handle a future model that does not fit in RAM/VRAM while other models are already loaded.

## Problem

A future model may require more memory than is currently available because other models are loaded.

The platform needs a safe model memory policy so it can load the requested model without killing active jobs or corrupting queue state.

## Decision

The platform should support memory-aware model eviction.

When a job needs model X:

1. check whether model X is already loaded
2. check whether enough memory appears available
3. if enough memory is available, warm model X
4. if not enough memory is available, unload only safe idle models
5. warm model X
6. run the job only after model X is ready

## Safety rule

Never unload a model that is actively running a job.

The queue must distinguish:

- active model: currently running a job
- reserved/warming model: about to run or currently loading
- idle-hot model: loaded recently and useful to keep if memory allows
- idle-cold model: loaded but safe to unload
- failed-warmup model: requested but failed to load

## Eviction priority

Eviction order should be:

1. idle-cold models
2. idle-hot low-priority models
3. idle-hot large models not needed soon
4. never active or reserved/warming models

## Lane priority proposal

### model-tiny

Keep if possible because it is cheap and useful for intent parsing, routing, quick study flows, and lightweight Companion tasks.

Evict only if a larger model requires memory and tiny is idle.

### model-small

Keep while there is recent Study or Companion demand.

Evict if idle and a larger model requires memory.

### companion-medium

Keep only while a Companion session is active or recent.

Evict before blocking tiny/small recovery.

### large or special model X

Load on demand.

It may evict idle tiny/small/medium models, but must not evict active models.

## Future Model Memory Manager

A future implementation should track:

- `model_name`
- `lane`
- `loaded`
- `active_job_count`
- `last_used_at`
- `warmup_started_at`
- `keep_alive_until`
- `priority`
- `estimated_memory_mb`
- `safe_to_evict`
- `eviction_reason`

## Future `ensure_model_ready(model)` behavior

Before a worker runs a job, the worker or controller should call a guarded model readiness path:

1. read loaded models from Ollama
2. read active jobs from the queue
3. determine whether the requested model is loaded
4. if loaded, continue
5. if not loaded and memory is tight, unload safe idle models
6. warm requested model with a bounded request
7. only then run the job

## Unload methods

Future implementation can unload models through either:

- `ollama stop <model>`
- an Ollama API request with `keep_alive=0`

Phase 12R-D does not perform unloads.

## Status evidence needed later

Future `/system/status` should expose read-only evidence such as:

- loaded models
- active model jobs
- model warmup state
- safe eviction candidates
- memory pressure state
- last eviction decision
- last warmup decision

## Current safety state

Phase 12R-D must preserve:

- primary worker active
- model-tiny lane worker inactive
- model-small lane worker inactive
- router rollout parked
- persistent cutover blocked
- no model unloads
- no service changes
- no job claim behavior changes

## Recommendation

Add model memory management in stages:

1. read-only loaded-model status evidence
2. read-only eviction candidate planning
3. manual guarded warm/unload helper
4. integrate warmup before lane job claim
5. only then activate persistent lane workers

Phase 12R-D is documentation and smoke only.
