# Stage 16 E3Z-BX — CT101 Minimal Ollama Runtime Activation Plan No-Apply

## Purpose

Plan the first CT101 model runtime activation for the CT203-native worker endpoint proof.

This stage is no-apply.

It does not start Docker, unmask Docker, start containerd, start Ollama, call a model endpoint, claim jobs, complete jobs, or mutate runtime state.

## Current proof jobs

Stage E3Z-BV inserted fresh CT203 SQLite proof jobs:

- job 37: queued, attempts 0, requested_model qwen2.5:0.5b, expected response E3Z-MODEL-A-OK
- job 38: queued, attempts 0, requested_model qwen2.5:0.5b, expected response E3Z-MODEL-B-OK

Do not reuse jobs 35 or 36.

## Runtime inventory from E3Z-BW R6

CT101 services are currently idle:

- ai-platform-laptop-queue-worker.service: inactive and masked
- docker.service: inactive and masked
- docker.socket: inactive and masked
- containerd.service: inactive and masked
- ollama.service: inactive and masked

CT101 has Docker binaries:

- docker
- containerd
- ctr
- runc

CT101 does not have docker-compose, podman, nerdctl, or host-level ollama binary available.

## Approved candidate runtime path

Use only:

`/opt/llm-stack/docker-compose.yml`

This compose file is the minimal Ollama-only stack:

- service: ollama
- container_name: ollama
- image: ollama/ollama:latest
- restart: unless-stopped
- OLLAMA_HOST=0.0.0.0:11434
- OLLAMA_NUM_PARALLEL=1
- OLLAMA_KEEP_ALIVE=30m
- OLLAMA_MAX_TRANSFER_STREAMS=1
- volume: /mnt/ollama-models/ollama:/root/.ollama

## Explicitly forbidden runtime paths for first proof

Do not use:

- /opt/ai-platform/docker-compose.yml
- /opt/ai-platform/docker-compose.fresh.yml
- /opt/portainer-agent/docker-compose.yml
- /opt/comfyui/docker-compose.yml

Reason: these broader stacks can start Postgres, Redis, API, worker, frontend, Kokoro TTS, Whisper ASR, Portainer, or ComfyUI and are outside the first model proof scope.

## Activation strategy

The next approved runtime stage should do the minimum required to expose local Ollama in CT101:

1. Confirm jobs 37 and 38 are still queued attempts 0 result_rows 0.
2. Confirm no running jobs.
3. Confirm CT101 worker service remains inactive and masked.
4. Confirm Docker, Docker socket, and containerd are inactive and masked before activation.
5. Unmask only containerd.service, docker.service, and docker.socket if required.
6. Start only containerd and docker.
7. Use only /opt/llm-stack/docker-compose.yml.
8. Start only the ollama service/container from that compose file.
9. Verify no non-Ollama containers are running.
10. Verify local Ollama health/list endpoint.
11. Do not call a generation endpoint yet unless separately approved.

## First model-call strategy

After local Ollama health is proven, a separate approval should run one bounded CT101 one-shot worker script:

1. Claim exact job 37 only.
2. Call local Ollama for requested_model qwen2.5:0.5b.
3. Complete job 37 only.
4. Verify response_text contains or equals expected marker E3Z-MODEL-A-OK.
5. Verify job 38 remains queued attempts 0 result_rows 0.
6. Verify no running jobs remain.
7. Keep CT101 persistent worker service inactive and masked.

## Idle safety after proof

If pausing after proof:

- stop the Ollama container if no longer needed
- consider masking Docker services again
- consider disabling EDGE_CT203_SQLITE_WORKER_API_ENABLED if no worker proof is actively underway
- leave job 38 queued only if the next proof will continue soon; otherwise decide whether to complete, fail, or remove it under a separate approved DB boundary

## Approval boundaries ahead

Separate approvals are required for:

1. CT101 Docker/containerd/Ollama activation using only /opt/llm-stack
2. any model endpoint call
3. CT101 one-shot claim/model/complete proof for job 37
4. idle rollback of Docker/Ollama
5. disabling CT203-native worker API if pausing
