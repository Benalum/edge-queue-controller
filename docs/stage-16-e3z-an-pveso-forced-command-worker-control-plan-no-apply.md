# Stage 16 E3Z-AN — PVESO forced-command worker-control plan (no apply)

## Status

No apply. This document records the planned control architecture after Stage 16 E3Z-AM.

## Reason for this plan

The desired architecture is not broad shell access from CT203 to PVESO. CT203 is the controller and should be allowed to request only a narrow worker-control action. PVESO should validate and execute the local worker action on its own host.

This replaces attempts to use unrestricted SSH with a forced-command style boundary.

## Roles

- PVEW: always-on Proxmox/platform host.
- CT203: controller, API, queue, scheduler, and DB authority.
- PVESO: model-worker Proxmox host.
- CT101 `llms`: model-worker container only; not the controller.

## Principle

CT203 requests a named worker-control action. PVESO executes a local allowlisted command only after validating host and container invariants.

CT203 must not receive a general-purpose PVESO root shell through this path.

## Proposed forced-command action surface

The PVESO forced-command worker-control entry should expose only these actions:

1. `inventory`
   - return hostname and bounded `pct list` / `qm list` style inventory
   - no mutation
2. `ct101-status`
   - return CT101 status, hostname, onboot value, network config summary, and runtime state
   - no mutation
3. `ct101-start-if-stopped-and-hostname-llms`
   - validate PVESO hostname locally
   - validate CT101 exists
   - validate CT101 name/hostname is `llms`
   - validate CT101 is stopped before start
   - validate CT101 onboot remains disabled unless separately approved
   - start only CT101
   - observe status after start
   - do not start Ollama manually
   - do not call model endpoints
4. `ct101-post-start-observe`
   - observe CT101 process/network/service posture after start
   - no manual service changes
   - no model endpoint calls

## Forbidden through this path

- arbitrary shell access
- CT101 stop or restart unless separately approved
- any VM start/stop/restart
- CT201/CT202 mutation
- PVESO host service start/stop/restart/reload/enable/disable
- systemctl daemon-reload
- firewall/network/authorized_keys/sshd_config mutation
- database writes
- job insert, claim, retry, status mutation, result mutation
- scheduler/timer activation
- model/Ollama prompt/generate/chat/embed/list/version endpoint calls
- broad Proxmox management exposure

## Security design notes

The preferred design is a dedicated forced-command key or dedicated restricted account on PVESO. The forced command should ignore the user-supplied SSH command except for a small action token that it parses and validates.

The command should log a bounded audit line with:

- timestamp
- requested action
- caller source
- decision: allowed or refused
- CT101 state before and after when applicable

The command must fail closed if it cannot validate CT101 identity or if another CT state is ambiguous.

## Next apply boundary

The next apply phase must be separate and explicit. It may install the PVESO-local forced-command script and a restricted SSH key entry, but it must not start CT101 in the same phase.

After the forced-command entry is installed, a read-only validation phase should prove:

- CT203 can invoke `inventory`
- CT203 can invoke `ct101-status`
- CT203 cannot execute arbitrary shell commands through that key
- PVEW/local unrestricted SSH repair is no longer required for CT101 worker wakeup

Only after that validation should a separate approval boundary start CT101 through the forced-command action.

## Decision

Proceed with a forced-command worker-control path before any additional CT101 start attempt.

Do not attempt another CT101 live start through the current CT203-to-PVESO route until the forced-command worker-control path is installed and validated.
