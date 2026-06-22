# Stage 16 E3Z-AF — PVESO control route repair plan (no apply)

Status: **no apply**. This document records the PVESO control-route blocker discovered after the CT101 `llms` start observe-only attempts and defines the safe repair sequence before any further CT101 start approval.

## Hard conclusion

Do not attempt another CT101 live start through the current CT203-to-PVESO route.

The repeated E3Z-AA attempts did not start CT101. Each attempt stopped before mutation or received only PVESO inventory-style output. E3Z-AE then classified the route posture as follows:

- PVEW to PVESO LAN SSH timed out.
- Local workstation to PVESO LAN SSH timed out.
- CT203 is the only path that has repeatedly reached PVESO inventory output.
- No unrestricted PVESO control route was proven.
- CT101 remained stopped after the failed start attempts.

## Current safe platform posture

- CT203 remains controller and queue authority.
- Scheduler/timer posture remained inactive or absent during the route diagnostics.
- Jobs 35 and 36 remained queued and untouched during the CT101 start attempts.
- No model endpoint call was part of this route repair planning phase.
- No further live CT101 start should be attempted until an unrestricted management route is proven with an arbitrary read-only marker command.

## Route repair objective

Create or identify one controlled route that can run arbitrary administrative commands on PVESO for a tightly scoped Proxmox operation, then prove it read-only before using it for a live CT101 start.

The preferred route is:

1. PVEW to PVESO management SSH, using PVESO LAN or another explicitly approved management address.
2. A non-interactive key that is not restricted to inventory-only output.
3. A read-only proof command that prints an exact marker and does not mutate PVESO.
4. A separate explicit approval boundary before any CT101 start.

## Acceptable next read-only diagnostics

The next phase should be read-only and may inspect:

- PVEW routing and firewall posture toward the PVESO management address.
- PVESO address/interface hints already visible from trusted inventory.
- Whether the current CT203 key is forced-command or otherwise restricted.
- Whether a direct PVEW control route can be repaired without changing CT203 authority.

## Future mutation boundaries

Separate approval is required before any of these actions:

- Changing PVESO SSH configuration or authorized keys.
- Changing PVEW routing or firewall rules.
- Starting CT101.
- Enabling or starting Ollama inside CT101.
- Calling any Ollama or model endpoint.
- Activating scheduler/timer dispatch.
- Mutating the controller database or queued jobs.

## Intended continuation

1. E3Z-AG: read-only control-route repair readiness diagnostic.
2. E3Z-AH: no-apply route repair implementation plan if needed.
3. Explicit approval for the minimal route repair mutation, if needed.
4. Read-only arbitrary-command proof through the repaired route.
5. New CT101 start observe-only approval only after the control route is proven.
