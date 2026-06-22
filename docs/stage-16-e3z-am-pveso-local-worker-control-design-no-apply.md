# Stage 16 E3Z-AM — PVESO-local worker-control design (no apply)

## Status

No apply. This document records a safer route-control architecture after E3Z-AJ/AK/AL showed that unrestricted automated PVESO control is not currently available.

## Current facts

- CT203 remains the controller/API/queue/scheduler/DB authority.
- PVEW remains the always-on Proxmox/platform host.
- PVESO remains the model-worker Proxmox host.
- CT101 `llms` remains the intended model-worker container.
- CT101 is not the controller.
- CT101 was not started by the E3Z-AA through E3Z-AK attempts.
- PVEW/local to PVESO LAN SSH has timed out in diagnostics.
- CT203 can reach PVESO TCP/22, but arbitrary command execution was not proven.
- The current CT203-to-PVESO path must not be used for another CT101 live start attempt.

Required guard text:

Do not attempt another CT101 live start through the current CT203-to-PVESO route

## Design decision

The safer architecture is not broad unrestricted SSH from CT203 to PVESO.

Instead:

1. CT203 is allowed to request a narrow worker-control action.
2. PVESO validates the request locally.
3. PVESO starts or observes CT101 locally using Proxmox tools.
4. PVESO returns a bounded status result.
5. CT203 records/uses the result only after the normal scheduler/queue guard conditions are satisfied.

In short:

```text
CT203 controller -> narrow PVESO worker-control request -> PVESO local validator -> pct start/status CT101 -> bounded result
```

## Why this is safer

A PVESO-local control path can be made narrower than unrestricted root SSH. It can allow only specific, audited actions such as:

- show PVESO worker inventory
- report CT101 state
- start CT101 only when stopped and hostname/config match expected values
- report CT101 post-start status
- refuse all non-allowlisted commands

This also keeps Proxmox management local to the PVESO host and avoids giving the controller broad shell authority over the worker host.

## Candidate implementation options

### Option A — Forced-command SSH key for CT203

Add a dedicated key on PVESO for CT203 with a forced command such as a PVESO-local worker-control script.

The forced command must:

- ignore user-supplied commands
- accept only allowlisted subcommands or a single environment-limited action
- validate CT101 ID, hostname, onboot state, and current status before any start
- refuse if the target is not exactly CT101 `llms`
- refuse if any scheduler/timer/DB guard is not clean from the CT203 side
- log only non-secret operational markers

### Option B — PVESO local root-run service/socket

Create a local PVESO worker-control service/socket that CT203 can invoke through a narrow channel. This is more structured but has more moving parts than a forced-command SSH key.

### Option C — Manual PVESO console start for one proof

Use the PVESO console/GUI to start CT101 once, then perform read-only observation from CT203/PVEW. This is acceptable for a one-time proof but not ideal as the long-term automated architecture.

## Recommended next step

Stage 16 E3Z-AN should be a no-apply implementation plan for Option A: a dedicated PVESO forced-command worker-control key/script.

The next live apply boundary should not start CT101. It should only install or validate the narrow PVESO-local worker-control path, then prove that CT203 can request a harmless read-only action through it.

## Hard guards for any future apply

- No CT101 start during worker-control path installation.
- No DB writes.
- No job claims.
- No scheduler/timer activation.
- No model/Ollama endpoint calls.
- No broad authorized_keys rewrite.
- No public Proxmox exposure.
- No command passthrough shell.
- No arbitrary SSH command execution from CT203.
- No job 34 reuse.
- Jobs 35 and 36 must remain queued and untouched until a new explicit proof decision is made.
