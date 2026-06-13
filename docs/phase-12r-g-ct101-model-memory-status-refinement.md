# Phase 12R-G CT101 Model Memory Status Refinement

Phase 12R-G refines the read-only model memory status added in Phase 12R-F.

## Goal

Phase 12R-F exposed `model_memory_status.memory`, but that memory snapshot came from the controller host because the helper runs inside `edge_controller.py`.

Phase 12R-G makes the status clearer by exposing:

- `controller_memory`
- `ct101_memory`

The old `memory` field remains as a temporary compatibility alias but is explicitly labeled deprecated.

## Safety

Phase 12R-G is read-only.

It must not:

- warm models
- unload models
- call Ollama generate/chat endpoints
- run prompts
- start persistent lane workers
- change CT101 env files
- change Docker containers
- enable router rollout
- mark persistent cutover ready

## CT101 memory source

The CT101 memory snapshot is read through the existing Proxmox/Tailscale path:

- SSH target: `root@100.88.194.19`
- command path: `pct exec 101`
- file read: `/proc/meminfo`

This is read-only and only collects:

- MemTotal
- MemAvailable
- SwapTotal
- SwapFree

## Expected status shape

The CT101 worker status should contain:

- `model_memory_status.controller_memory`
- `model_memory_status.ct101_memory`
- `model_memory_status.memory.note`
- `model_memory_status.mode = read_only`
- `model_memory_status.safe_eviction_candidates = []`
- `model_memory_status.active_models = []`
- `model_memory_status.warming_models = []`

## Future phases

Later phases can use `ct101_memory` plus Ollama `/api/ps` to plan safe eviction candidates.

Phase 12R-G only refines read-only evidence labels and adds CT101 memory visibility.
