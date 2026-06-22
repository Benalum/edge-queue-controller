# Stage 16 E3Z-BZ — CT101 Ollama Container-Only Model Runtime and Concurrency Plan No-Apply

## Purpose

Define the safe target topology for CT101 model runtime after BY/BY-R3.

This stage is no-apply.

It does not delete model files, remove Docker volumes, prune Docker, pull models, start or stop containers, call model generation, claim jobs, complete jobs, fail jobs, unmask worker services, or activate scheduler/timer paths.

## Current containment checkpoint

BY-R3 verified:

- CT203 DB integrity is ok.
- jobs_total is 37.
- job_results_total is 16.
- jobs_status_running is 0.
- job 37 is queued, attempts 0, requested_model qwen2.5:0.5b, result_rows 0.
- job 38 is queued, attempts 0, requested_model qwen2.5:0.5b, result_rows 0.
- CT101 worker service remains inactive and masked.
- Docker/containerd are active.
- Only Docker container running inside CT101 is ollama.
- ollama image is ollama/ollama:latest.
- docker exec ollama ollama list works.

## Target topology

The intended runtime topology is:

- PVESO host: Proxmox host only.
- CT101 llms: model runtime container host.
- CT101 Docker: only the Ollama runtime container should run for first proof.
- CT203: controller, API, queue, and SQLite DB authority.
- Scheduler: remains inactive until separately approved.
- CT101 persistent worker service: remains inactive and masked until separately approved.

## Container-only model ownership

The target is that model serving happens only through the Ollama Docker container.

Do not install or depend on a host-level Ollama service on PVESO or CT101 for the first proof.

Do not run a PVESO-host Ollama service.

Do not use the masked CT101 ollama.service.

Do not delete model paths until a separate read-only model storage authority map proves which paths are bind mounts, which paths are stale, and which paths are actively used by the running Ollama container.

## Known model storage path

The minimal stack compose file is:

/opt/llm-stack/docker-compose.yml

It maps:

/mnt/ollama-models/ollama:/root/.ollama

Therefore, for the first proof, the active runtime model authority should be treated as the Ollama container view of /root/.ollama backed by CT101 path /mnt/ollama-models/ollama.

Before any cleanup, run a read-only authority map that records:

- docker inspect ollama mounts
- CT101 mount source for /mnt/ollama-models
- whether PVESO host has any separate Ollama model service path
- whether /root/.ollama or /usr/share/ollama inside CT101 are active, stale, or symlinked
- checksums or inventory counts only, no deletion

## Available models from BY-R3

Current container model list:

- gemma3:4b
- llama3.2:3b
- qwen3:1.7b
- qwen3:0.6b
- gemma4:e4b

## Proof job model mismatch

Jobs 37 and 38 currently request:

qwen2.5:0.5b

That exact model was not present in the BY-R3 Ollama model list.

Do not run the model proof until one of these is approved:

1. Repair jobs 37 and 38 to an available small model, recommended qwen3:0.6b or qwen3:1.7b.
2. Pull or install qwen2.5:0.5b under a separate model install approval.

Recommended path for speed and safety:

- Repair job 37 and job 38 requested_model to qwen3:0.6b.
- Keep prompts and expected markers unchanged.
- Then run one bounded model proof against job 37 only.

## Concurrency target

Ollama concurrency should be controlled explicitly through environment variables in the minimal Ollama runtime.

The important controls are:

- OLLAMA_MAX_LOADED_MODELS: how many models can be loaded concurrently if memory allows.
- OLLAMA_NUM_PARALLEL: how many parallel requests each loaded model can process.
- OLLAMA_MAX_QUEUE: how many requests can queue when busy.

Initial conservative runtime settings:

- OLLAMA_MAX_LOADED_MODELS=2
- OLLAMA_NUM_PARALLEL=2
- OLLAMA_MAX_QUEUE=16

Reasoning:

- Small models can support more parallelism.
- Large models should be routed with per-model concurrency 1 until memory behavior is measured.
- Parallel requests increase memory use because each parallel request increases context allocation.

## CT203 scheduling direction

CT203 should not send users directly to models.

CT203 should classify jobs into model tiers and concurrency classes:

- router_small: qwen3:0.6b or qwen3:1.7b, parallel target 2 to 4 after proof
- study_light: gemma3:4b or qwen3:1.7b, parallel target 1 to 2 after proof
- companion_default: gemma4:e4b, parallel target 1 initially
- deep_large: future larger model, parallel target 1 only

CT203 scheduler should track:

- requested_model
- model_tier
- concurrency_class
- max_parallel_per_model
- max_loaded_models
- active_model_requests
- active_total_requests
- queue depth by model

## Near-term sequence

1. BZ: document this no-apply plan.
2. CA: read-only model storage authority map.
3. CB: no-apply plan to repair jobs 37 and 38 from qwen2.5:0.5b to an available model.
4. CC: approved DB update to repair only jobs 37 and 38 requested_model if chosen.
5. CD: bounded model generation proof for exact job 37 only.
6. CE: second proof or two-request concurrency probe, depending on CD outcome.
7. CF: repo/source refresh handoff checkpoint.

## Explicit non-goals

Do not delete model files yet.

Do not remove Docker volumes.

Do not prune Docker.

Do not start /opt/ai-platform compose stacks.

Do not start CT101 persistent worker service.

Do not activate scheduler or timer.

Do not expose model endpoints directly to public users.

Do not run model generation before the requested_model mismatch is resolved.
