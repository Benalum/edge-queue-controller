# Stage 16 E2Y — Controlled CT101 Start Readiness Inspection

Date: 2026-06-20  
Scope: controlled CT101 start/readiness inspection after E2X offline legacy autostart neutralization.

## Purpose

Verify that CT101 can start without reactivating legacy model, worker, controller, Docker, Ollama, Whisper, Kokoro, uvicorn, or queue services.

E2Y was the first controlled CT101 start after E2X masked legacy autostart sources offline.

## Approved Boundary

Approval:

`APPROVE_STAGE_16_E2Y_CONTROLLED_CT101_START_READINESS_INSPECTION_NO_DB_WRITE_NO_MODEL_CALL_NO_WORKER_SCHEDULER_ACTIVATION`

Allowed:

- Start CT101.
- Inspect CT101 services/processes/listeners/filesystem metadata.
- Shut CT101 back down at the end.

Explicitly forbidden:

- No CT201/CT202 mutation.
- No VM mutation.
- No CT203 controller restart or environment mutation.
- No nginx/cloudflared/Cloudflare/DNS/tunnel mutation.
- No DB write.
- No worker activation.
- No scheduler activation.
- No model/Ollama endpoint calls.
- No private-storage mount/unlock.

## Preflight State

Before E2Y:

- VM200 running.
- CT203 running.
- CT204 stopped.
- Private storage not mounted.
- CT203 controller active.
- CT203 `/health` HTTP 200.
- CT203 `/system/status` HTTP 200.
- CT203 DB guard counts:
  - `user_sessions=236`
  - `jobs=23`
  - `job_results=6`
  - `router_logs=0`
  - `router_resolution_steps=0`
  - `router_feedback=0`
  - `workers=2`
  - `worker_events=3`

PVESO container posture before E2Y:

- CT101 stopped.
- CT201 stopped.
- CT202 stopped.
- CT101 `onboot=0`.

## CT101 Start Result

CT101 was started only for controlled inspection.

CT101 identity:

- Hostname: `llms`
- OS: Ubuntu 24.04.3 LTS (Noble Numbat)
- Basic command execution became available.
- CT101 remained `onboot=0`.

## Legacy Service Verification

The following units were confirmed masked/inactive:

- `docker.service` — masked/inactive
- `docker.socket` — masked/inactive
- `containerd.service` — masked/inactive
- `ollama.service` — masked/inactive
- `ollama.socket` — masked/inactive
- `ai-platform-edge-heartbeat.service` — masked/inactive
- `ai-platform-edge-heartbeat.timer` — masked/inactive
- `ai-platform-laptop-queue-worker.service` — masked/inactive
- `ai-platform-laptop-queue-worker@.service` — masked/unknown active state for template unit
- `ai-platform-queue-controller.service` — masked/inactive
- `llm-stack-compose.service` — masked/inactive

## Process and Listener Verification

No legacy surprise processes were detected for:

- `ollama serve`
- Docker / containerd / docker-proxy
- uvicorn
- Whisper
- Kokoro
- `app.worker.agent`
- `local-queue-controller`
- old queue-worker paths

The exact observed E2Y guard results were:

- `legacy_process_guard=pass`
- `legacy_listener_guard=pass`

Expected non-project listeners only were observed, including SSH, local DNS resolver, Tailscale, and local mail/postfix. No legacy model/controller/worker listener ports were observed.

Specifically, no bad listeners appeared on:

- 11434
- 8088
- 8880
- 8765
- 7070

## Model Storage Metadata

No model endpoint call was made.

CT101 metadata inspection showed:

- `ollama_binary` was empty/not found in CT101.
- `/mnt/ollama-models` existed.
- `/mnt/ollama-models/manifests` existed.
- `/mnt/ollama-models/blobs` existed.
- model manifest file count: 0
- model blob file count: 0
- partial file count: 0

This means CT101 started cleanly, but it is not yet proven as the active model-serving path.

## Shutdown Result

At cleanup:

- CT101 was shut back down.
- CT101 final state: stopped.
- CT101 final `onboot=0`.

## Postflight State

After E2Y:

- VM200 running.
- CT203 running.
- CT204 stopped.
- Private storage not mounted.
- CT203 controller active.
- CT203 `/health` HTTP 200.
- CT203 `/system/status` HTTP 200.
- CT203 DB guard counts unchanged:
  - `user_sessions=236`
  - `jobs=23`
  - `job_results=6`
  - `router_logs=0`
  - `router_resolution_steps=0`
  - `router_feedback=0`
  - `workers=2`
  - `worker_events=3`

## Safety Result

E2Y completed successfully.

CT101 can now start without immediately reactivating the known legacy autostart hazards neutralized in E2X.

## Remaining Risk

E2Y does not activate model serving, workers, scheduler lanes, or companion runtime.

It also shows CT101 itself may not currently contain the active Ollama binary/model inventory expected for production model serving. The next step should determine whether the correct model path is:

- PVESO host Ollama,
- CT101 with a corrected Ollama install/model bind,
- another worker container,
- or a staged combination.

## Next Step

Recommended next no-apply/readiness step:

`Stage 16 E2Z — model serving path decision and no-model-call endpoint readiness plan`

The next phase should remain read-only/no-model-call unless explicitly approved otherwise. It should answer:

- Is PVESO host Ollama the canonical model-serving authority?
- Should CT101 be rebuilt or reconfigured as a clean worker container?
- Where are the real model manifests/blobs?
- Which model tier should be tested first?
- What exact approval is needed for the first model endpoint call?
