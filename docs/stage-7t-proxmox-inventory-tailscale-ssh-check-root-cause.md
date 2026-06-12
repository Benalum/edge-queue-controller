# Stage 7T Proxmox Inventory Tailscale SSH Check Root Cause

Stage 7T records the root cause of the Proxmox inventory timeout discovered after Stage 7P.

This stage does not change runtime behavior.

This stage does not resume power automation.

Power automation remains paused with:

- `EDGE_POWER_AUTO_PAUSED=1`

## Findings

Controller health was fast before testing:

- `/health` returned HTTP 200.

The configured Proxmox target was:

- Host id: `pveso`
- Host: Tailscale address
- SSH target: root on the Proxmox host

Network reachability was healthy:

- Ping to the Proxmox Tailscale address succeeded.
- TCP port 22 was reachable.

The first minimal SSH command did not fail because Proxmox was down.

It stalled because Tailscale SSH required an additional interactive authentication check.

After that Tailscale SSH check completed, the split Proxmox commands worked:

- `pct list` returned CT 101 running as `llms`.
- `qm list` completed successfully.
- Combined inventory completed successfully.
- Proxmox services were active.
- Proxmox host load was low.

The controller inventory endpoint then returned HTTP 200.

While the inventory endpoint was running, `/health` continued to return HTTP 200.

## Conclusion

Stage 7P fixed the web/controller blocking problem.

The remaining Proxmox inventory timeout is caused by the SSH authentication path sometimes requiring an interactive Tailscale SSH check.

This is not a Proxmox service health issue.

This is not a controller event-loop issue after Stage 7P.

## Safety Decision

Do not resume production power automation until the Proxmox automation path uses a non-interactive SSH method.

Automation must not depend on a human clicking a Tailscale SSH check link.

## Recommended Next Stage

Stage 7U should choose and implement a non-interactive Proxmox automation SSH path.

Safe options include:

1. Use OpenSSH key-based auth over a trusted network path.
2. Use a dedicated restricted automation key on Proxmox.
3. Use a dedicated Proxmox API token instead of SSH.
4. Adjust Tailscale SSH policy only if it can be made safe for unattended automation.

The preferred direction is a dedicated restricted automation identity rather than relying on interactive Tailscale SSH checks.
