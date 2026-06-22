# Stage 16 E3Z-AO — PVESO forced-command worker-control install plan (no apply)

## Purpose

This no-apply checkpoint documents the later PVESO-side install plan for a forced-command worker-control entrypoint. It follows the E3Z-AM design and E3Z-AN forced-command plan.

No install, apply, service change, SSH change, firewall change, CT start, DB write, scheduler activation, timer activation, helper run-mode enablement, or model endpoint call is performed in this phase.

## Current architectural decision

CT203 remains the controller/API/queue/scheduler/DB authority. PVESO is the model-worker Proxmox host. CT101 llms is the intended model-worker container.

The desired control shape is:

```text
CT203 controller requests one allowlisted worker-control action
PVESO validates the request locally
PVESO performs only the matching local action
CT101 llms remains model-worker only
```

This avoids granting CT203 a broad unrestricted PVESO root shell.

## Proposed PVESO install artifacts for a later apply phase

A later explicitly approved apply phase may install a narrow PVESO-local worker-control command, for example:

```text
/usr/local/sbin/apc-pveso-worker-control
```

The entrypoint should support only a small allowlist of actions:

```text
inventory
ct101-status
ct101-start-if-stopped-and-hostname-llms
ct101-post-start-observe
```

The entrypoint must reject all other arguments. It must not pass user-controlled strings to shell evaluation. It must print bounded, marker-based output suitable for PPB parsing.

## Required local validations before any CT101 start action

Before a later forced-command action may start CT101, PVESO must verify locally:

```text
hostname is pveso
pct status 101 is stopped or already running depending on requested action
pct config 101 hostname is llms
CT101 onboot remains 0 or absent/default-off unless separately approved
no broad scheduler/timer activation is requested
```

If CT101 is already running, the start action must not restart it. It should only observe and return status.

## Explicit model endpoint prohibition

Do not call /api/generate.

Do not call any Ollama prompt, generate, chat, embed, list, version, or model endpoint in this install-plan phase. A later model inventory or model warmup phase must be separately approved.

## Explicit non-goals

This no-apply phase does not:

```text
install the PVESO command
edit authorized_keys
edit sshd_config
change firewall or network rules
start CT101
stop CT101
restart CT101
start Ollama
call /api/generate
write the CT203 database
claim or retry jobs
activate scheduler or timer units
enable persistent workers
expose Proxmox management publicly
```

## Later approval boundary

A later apply phase must use a separate explicit approval phrase. That phase should install only the forced-command worker-control entrypoint and the narrow SSH authorized_keys command binding needed for CT203 to request allowlisted actions.

Any CT101 start remains a separate approval boundary after the forced-command path is installed and read-only validated.

## Acceptance criteria for this no-apply phase

This AO no-apply phase is complete when:

```text
documentation exists for the forced-command install plan
smoke test verifies the required CT101 llms model-worker sentence
smoke test verifies the /api/generate prohibition sentence
repo commit/tag/push succeeds
no live infra mutation occurred
```
