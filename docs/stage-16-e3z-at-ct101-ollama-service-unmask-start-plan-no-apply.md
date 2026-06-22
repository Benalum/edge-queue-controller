# Stage 16 E3Z-AT R3 — CT101 Ollama Docker Runtime Plan (No Apply)

## Result intent

This is a no-apply planning checkpoint after CT101 `llms` was started safely through the PVESO forced-command worker-control path and CT101 readiness inspection showed that the normal `ollama.service` unit is inactive and masked.

The important correction for this stage is: **Ollama on CT101 is Docker-based**. The next runtime repair must therefore inspect and operate on the Docker/container path, not simply unmask and start the masked `ollama.service` unit.

## Current facts from E3Z-AR R5 and E3Z-AS

- CT101 `llms` is running.
- CT101 onboot remains `0`.
- CT101 has Tailscale and eth0 networking.
- `/mnt/ollama-models` is mounted and readable.
- `/mnt/ollama-models` contains model-storage shaped directories including `manifests`, `blobs`, `models/manifests`, and `models/blobs`.
- `ollama.service` is inactive and masked through `/etc/systemd/system/ollama.service -> /dev/null`.
- The old journal showed repeated `0.0.0.0:11434` bind conflicts before the unit was stopped/masked.
- Current listener/process inspection did not show an active Ollama process or listener.
- Jobs 35 and 36 remain queued with attempts=0 and result_rows=0.
- CT203 scheduler/timer activation remains off.

## No-apply boundary

This phase does not change CT101, PVESO, CT203, Docker, systemd, the DB, jobs, scheduler, timers, or model endpoints.

Do not call /api/generate.
Do not call /api/chat.
Do not call /api/embed.
Do not call /api/tags.
Do not call /api/version.
Do not run `ollama list`.
Do not run `ollama ps`.
Do not run `ollama run`.
Do not start, stop, restart, create, recreate, or remove any Docker container.
Do not pull images.
Do not mutate Docker volumes.
Do not unmask or start `ollama.service` in this plan phase.

## Correct next read-only phase: E3Z-AU

The next phase should be a read-only Docker inventory on CT101. It should inspect:

1. Docker daemon/service state without starting it.
2. Docker CLI availability.
3. Docker container list with `docker ps -a` only if Docker is already available.
4. Docker images with `docker images` only if Docker is already available.
5. Existing compose files or container definitions under likely project/runtime paths.
6. Existing bind mounts and volume mappings involving `/mnt/ollama-models`.
7. Existing port mappings involving `11434`.
8. Any stopped/exited container that previously owned `11434`.
9. CT203 DB/job/scheduler/timer guards before and after.

E3Z-AU must remain read-only. It must not start Docker, start a container, restart Docker, pull an image, or call any Ollama HTTP/model endpoint.

## Later apply boundary, not approved by this plan

A later apply phase may be needed if E3Z-AU proves a safe Docker runtime path. That later phase should require explicit approval and should be narrower than a generic service repair. The likely apply boundary is one of:

- start an existing stopped Ollama Docker container if its image, mounts, ports, and environment are already correct;
- repair a stopped container definition if it is clearly stale and recoverable;
- create a new Docker container only if no existing safe definition exists and the exact image, volume, port, user, and network policy are documented first.

That later phase must still avoid job claims, DB result writes, scheduler/timer activation, persistent worker activation, and model endpoint calls until a separate smoke boundary is approved.

## Success criteria for this no-apply checkpoint

- The repo contains this corrected Docker-runtime plan.
- The smoke validates this plan includes the Docker-runtime correction.
- The smoke validates model endpoint calls remain forbidden.
- The smoke validates the plan does not approve unmask/start of `ollama.service`.
