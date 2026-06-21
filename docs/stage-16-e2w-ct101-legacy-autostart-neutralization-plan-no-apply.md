# Stage 16-E2W — CT101 Legacy-Autostart Neutralization Plan No-Apply

Date: 2026-06-20

## Purpose

Define the safe path for neutralizing CT101 legacy autostart behavior before CT101 is started again.

This is a **no-apply** planning checkpoint only. It does not mutate live infrastructure.

## Current Prerequisite State

Stage 16-E2V documented that the CT203 → PVESO inventory bridge is now durable and reload-validated.

Known current state from E2U/E2V:

- CT203 → PVESO inventory works.
- CT203 `/power/proxmox/inventory` returned HTTP 200.
- inventory `ok=true`.
- inventory `host_id=pveso`.
- CT101 stopped.
- CT201 stopped.
- CT202 stopped.
- CT101 onboot=0.
- CT204 stopped.
- private storage not mounted.
- DB counts unchanged.
- no worker/model/scheduler activation occurred.
- no Ollama/model endpoint calls occurred.

## Problem

The previous CT101 readiness start surfaced unsafe legacy-autostart behavior.

Observed legacy services/processes included:

- Docker/containerd active/enabled
- docker-proxy listening on port 11434
- `/bin/ollama serve`
- `python -m app.worker.agent`
- `/opt/ai-platform/scripts/controller/local-queue-controller.sh`
- uvicorn services on ports 8880/8088
- whisper-asr web service

Those are not safe to allow during the next CT101 start because they may:

- expose unintended model/API ports;
- register workers;
- call model endpoints;
- mutate jobs or DB state;
- bypass the current CT203 controller authority;
- confuse the worker registry;
- reintroduce pre-migration authority paths.

## Hard Rule

Do **not** start CT101 again until legacy autostart is neutralized under a separate explicit approval boundary.

## Neutralization Strategy

The safest next apply should avoid starting CT101 until its legacy autostart behavior is disabled offline or controlled.

Recommended path:

### E2X — CT101 offline legacy service inventory and neutralization apply

E2X should mutate CT101 filesystem/config only while CT101 remains stopped.

Allowed, if approved:

- inspect CT101 root filesystem/config using a bounded offline method;
- identify legacy systemd units, sockets, init scripts, compose files, and app autostart hooks;
- disable/mask legacy service units that would autostart Docker, containerd, Ollama, worker agents, queue controllers, uvicorn apps, and whisper-asr;
- add backup copies/manifests of changed unit links or config files;
- keep CT101 stopped throughout;
- keep CT101 onboot=0;
- verify CT203 inventory remains healthy;
- verify DB counts unchanged.

Forbidden:

- CT101 start;
- CT101 network activation beyond existing stopped config;
- model endpoint calls;
- worker registration;
- scheduler activation;
- DB writes;
- CT203 controller env mutation;
- CT203 controller restart;
- VM200 nginx mutation;
- Cloudflare/DNS/tunnel mutation;
- private-storage mount/unlock.

### E2Y — CT101 first safe start after neutralization

Only after E2X succeeds, E2Y may start CT101 for readiness.

E2Y should verify immediately after start:

- CT101 booted;
- CT101 onboot remains 0;
- Docker/containerd are inactive or masked;
- Docker socket inactive;
- Ollama service inactive or masked unless separately approved;
- no listener on 11434 unless explicitly approved later;
- no legacy worker agent process;
- no local queue controller process;
- no uvicorn listeners on legacy ports;
- no whisper-asr web service;
- CT203 inventory still HTTP 200;
- DB counts unchanged;
- no worker/model/scheduler activation.

### E2Z — CT101 model storage/readiness inspection

Only after E2Y proves clean boot behavior, inspect model storage and runtime readiness.

E2Z must still forbid:

- model endpoint calls;
- model job execution;
- worker registration;
- scheduler activation;
- DB writes.

## Recommended Next Approval Boundary

Next apply phase should be:

**Stage 16-E2X — CT101 offline legacy-autostart neutralization**

Approval phrase:

`APPROVE_STAGE_16_E2X_CT101_OFFLINE_LEGACY_AUTOSTART_NEUTRALIZATION_NO_CT_START_NO_DB_WRITE_NO_MODEL_CALL`

E2X should keep CT101 stopped and neutralize the known legacy autostart sources before any new CT101 start attempt.

## Success Criteria for E2X

E2X is successful only if it proves:

- CT101 remains stopped;
- CT101 onboot remains 0;
- legacy service autostart sources are disabled/masked or otherwise neutralized;
- backups/manifests exist for any modified files or unit links;
- CT203 inventory remains healthy;
- DB counts unchanged;
- no CT/VM start occurred;
- no model endpoint call occurred;
- no worker/model/scheduler activation occurred.

## Failure Criteria

E2X must fail or roll back if:

- CT101 starts unexpectedly;
- CT101 onboot changes from 0;
- DB counts change;
- CT203 inventory breaks;
- any model endpoint is called;
- any worker or scheduler activation occurs;
- required backup/manifest cannot be created.

## Current Recommendation

Proceed to E2X before any CT101 start.

Do not start CT101 manually.
