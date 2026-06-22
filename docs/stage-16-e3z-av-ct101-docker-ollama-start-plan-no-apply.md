# Stage 16 E3Z-AV R2 — CT101 Docker/Ollama start plan, no apply

## Purpose

This document records the no-apply activation boundary after Stage 16 E3Z-AU R4 showed that CT101 `llms` is running and the Docker/Ollama runtime is present but disabled.

This phase is repo docs/smoke only. It does not mutate CT101, PVESO, CT203, the database, scheduler, timers, Docker, containerd, volumes, containers, or model endpoints.

## Observed input facts

From Stage 16 E3Z-AU R4:

- CT101 `llms` is running.
- `/mnt/ollama-models` is mounted and readable.
- Docker binary exists at `/bin/docker`.
- `containerd`, `ctr`, and `runc` binaries exist.
- `docker-compose` is absent.
- Compose candidates exist under `/opt/llm-stack`, `/opt/portainer-agent`, `/opt/comfyui`, and `/opt/ai-platform`.
- docker.service, docker.socket, and containerd.service are masked and inactive.
- Docker API is unavailable because `/var/run/docker.sock` is absent.
- No containers, images, volumes, or networks could be listed because the daemon is not running.
- No Ollama listener or model-serving process is active.
- Jobs 35 and 36 remained queued with attempts=0 and result_rows=0.
- CT203 scheduler and timer remained inactive/not-found.

## Correct runtime assumption

Ollama on CT101 should be treated as Docker-based for this stage. Do not repair it by treating `ollama.service` as the primary runtime unless a later explicit design decision changes that.

## Future apply boundary, not performed here

A future apply phase may perform only the minimum Docker-runtime repair needed to make the existing CT101 Docker/Ollama stack observable, with explicit approval.

Allowed only in a future apply phase:

1. Validate CT101 is still running and named `llms`.
2. Validate CT101 `onboot` is still 0 unless separately approved.
3. Validate CT203 DB and scheduler/timer idle guards before mutation.
4. Back up any affected systemd mask state or unit metadata before changing it.
5. Unmask/start only the minimum Docker runtime components needed for inventory:
   - `containerd.service`
   - `docker.socket`
   - `docker.service`
6. Observe Docker daemon health and list containers/images/volumes/networks.
7. Select a candidate compose/runtime path for Ollama only after inventory proves what exists.

Explicitly not allowed without a later approval boundary:

- Do not call /api/generate.
- Do not call `/api/chat`, `/api/embed`, `/api/embeddings`, `/api/tags`, `/api/version`, or any other Ollama/model endpoint.
- Do not pull images.
- Do not run `docker compose up`.
- Do not start or restart containers.
- Do not create or mutate volumes.
- Do not write jobs or job results.
- Do not claim jobs 35 or 36.
- Do not reuse job 34.
- Do not start scheduler/timer/persistent workers.
- Do not enable CT101 onboot.
- Do not expose Proxmox or model ports publicly.

## Next recommended phase

Stage 16 E3Z-AW should be a live apply proposal for Docker runtime unmask/start inventory only, or a source refresh handoff. The safest live mutation should stop after Docker daemon inventory and should not start Ollama containers or call endpoints.
