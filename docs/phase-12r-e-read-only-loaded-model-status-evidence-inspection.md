# Phase 12R-E Read-Only Loaded Model Status Evidence Inspection

Phase 12R-E is inspection-only.

It prepares for read-only model memory status evidence before any model warmup, unload, persistent lane activation, or router rollout.

## Discovery result

The CT101 namespace discovered that Ollama is reachable at:

- `http://100.88.245.33:11434`

The following localhost-style paths were not reachable from the CT101 probe path:

- `http://127.0.0.1:11434`
- `http://localhost:11434`
- `http://ollama:11434`
- `http://llms_ollama:11434`

The discovered working path returned:

- `/api/version` with HTTP 200
- `/api/tags` with HTTP 200
- `/api/ps` with HTTP 200

At the time of discovery, `/api/ps` returned an empty loaded-model list. That is safe and expected when no model is actively loaded.

## Purpose

The platform needs visibility into loaded models before it can safely implement model warmup and memory eviction.

Future system status evidence should eventually include:

- Ollama reachability
- Ollama base URL used by CT101 workers
- installed models from the Ollama tags API
- loaded or running models from the Ollama ps API
- memory snapshot
- model memory manager mode
- safe eviction candidates
- last warmup decision
- last eviction decision

## Safety policy

Phase 12R-E must not:

- start lane workers
- stop lane workers
- unload models
- warm models
- run model prompts
- change worker env files
- change Docker containers
- change systemd services
- enable router rollout
- mark persistent cutover ready

## Future read-only model status shape

A future status object should expose a read-only model memory status block with:

- mode equals read_only
- ollama_reachable
- ollama_base_url
- installed_models
- loaded_models
- memory totals and available memory
- safe_eviction_candidates
- active_models
- warming_models
- last_warmup_decision
- last_eviction_decision

In Phase 12R-E this remains a strategy and inspection target only.

## Eviction safety reminder

A model should only be considered evictable when:

- no active job is using it
- it is not reserved for a claimed job
- it is not warming
- it is past its keep-alive preference
- unloading it will not break current lane guarantees

## Recommended implementation sequence

1. discover actual Ollama reachability path
2. add read-only status evidence only
3. add read-only eviction candidate planning
4. add manual guarded warm or unload helper
5. integrate ensure_model_ready before lane job execution
6. only then activate persistent lane workers

Phase 12R-E is documentation and smoke only.
