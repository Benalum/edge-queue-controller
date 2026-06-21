# Stage 16 E3D — PVESO Model Inventory and Manifests No-Apply

Date: 2026-06-20

## Scope

Read-only model inventory and manifest decision checkpoint after E3C repaired PVESO Ollama localhost health/list access.

## Non-mutating guarantees

- No prompt/completion/generate/chat/embed calls.
- No model pull/download.
- No worker activation.
- No scheduler activation.
- No DB writes.
- No CT101 start.
- No CT/VM start/stop/restart.
- No private storage mount/unlock.
- No Cloudflare/DNS/tunnel/nginx mutation.
- No CT203 service restart/reload/env mutation.
- No public model endpoint exposure.

## Current Ollama state

- PVESO `ollama.service` active.
- `OLLAMA_HOST=127.0.0.1:11434`.
- Non-localhost `11434` listener count: 0.
- Ollama API version: `0.15.4`.
- `/api/tags` model count: `2`.

## Local model tags

- `qwen2.5-coder:32b-instruct-q4_K_M`
- `qwen2.5:32b-instruct-q4_K_M`

## Inventory finding

PVESO currently has two usable Ollama model manifests in the active model directory:

- Coder/reasoning candidate: `qwen2.5-coder:32b-instruct-q4_K_M`
- General reasoning/companion candidate: `qwen2.5:32b-instruct-q4_K_M`

A legacy model directory also exists under `/usr/share/ollama/.ollama/models` with blobs but no manifests. It should not be treated as runnable inventory until a later explicit model-store consolidation/import decision.

## Decision

E3D does not activate any worker or scheduler path. The next safe stage is E3E: first no-write local prompt smoke against PVESO localhost only, with explicit approval, using one known local tag and strict guards.

Recommended E3E approval should remain separate because it would be the first prompt/generate-style model call.
