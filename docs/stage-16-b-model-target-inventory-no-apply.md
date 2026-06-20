# Stage 16-B — Model Target Inventory, No Apply

Date: 2026-06-19
Base checkpoint: Stage 16-A / HEAD 8e00167

## Scope

This is a read-only model target inventory phase.

No services were started, stopped, restarted, reloaded, enabled, or disabled.

No DB writes were performed.

No Ollama endpoint calls were performed.

No model endpoint calls were performed.

No ollama list, ollama pull, ollama run, or ollama show command was executed.

No /tick/ollama-direct call was performed.

## Purpose

Stage 16-B identifies the safest target path for the first controlled real-model queue test after Stage 15 completed:

- authenticated queued chat contract;
- durable mock companion.chat job creation;
- authenticated polling through both queued chat endpoints;
- frontend mock/no-model waiting-state polish.

## Inventory result

The read-only Stage 16-B inventory completed before the smoke mismatch.

Observed platform safety state:

- PVEW quorum was healthy.
- VM200 was running.
- CT203 was running.
- CT204 was stopped.
- private storage was not mounted.
- private storage mapper was absent.
- CT203 controller service was active and enabled.
- VM200 nginx was active.
- VM200 cloudflared was active.
- VM200 public app.js matched the Stage 15-F deployed hash.

Observed CT203 database counts remained:

- user_sessions: 235
- jobs: 23
- job_results: 6
- router_logs: 0
- router_resolution_steps: 0
- router_feedback: 0
- workers: 2
- worker_events: 3

No additional DB writes were performed in Stage 16-B.

## Runtime observations

PVEW showed Proxmox services and kernel worker threads, but no AI Platform model worker was activated by this phase.

CT203 listener inventory showed the controller listener on port 7070.

VM200 showed no Ollama binary.

VM200 frontend app.js remained deployed at the Stage 15-F hash.

## Stage 16 re-entry rule

Users must never talk directly to models.

The first real-model test must use this path:

Frontend -> CT203 API -> durable job row -> explicit decision/scheduler policy -> default-off worker path -> model runtime -> job_results row -> frontend poll.

Direct model calls and /tick/ollama-direct remain blocked for this rollout path.

## Required interpretation for Stage 16-C

Stage 16-C should not activate anything.

Stage 16-C should patch or document a default-off queue-owned model worker path only.

The Stage 16-C artifact must include:

- exact selected target host or container;
- exact selected model runtime;
- exact small model name for the first future real test;
- exact queue job type;
- exact worker identity;
- exact default-off environment flag;
- exact DB rows expected to change during the later activation phase;
- exact rollback or disable path;
- exact proof that CT204 remains stopped;
- exact proof that private storage remains locked.

## Activation gate

Stage 16-D must require a separate explicit approval before:

- worker activation;
- scheduler activation;
- Ollama endpoint calls;
- live model endpoint calls;
- writing a model result row;
- starting or enabling any model worker service.

## Non-goals

Stage 16-B does not complete Companion intelligence.

Stage 16-B does not activate Ollama.

Stage 16-B does not activate Study AI grading.

Stage 16-B does not activate voice STT or TTS.

Stage 16-B does not enable persistent workers.

Stage 16-B does not modify CT204 or private storage.

## Recommended next phase

Stage 16-C — worker/scheduler contract patch, default off.
