# Phase 11P pveso / CT101 Recovery

Phase 11P recovered the System tab offline/degraded state for Queue, Workers, and CT101.

## Initial symptom

The System tab showed:

- Backend API: online
- Frontend Wrapper: online
- Queue: offline
- Workers: offline
- CT101 Laptop Queue Worker: offline
- Power Automation: online

The controller health endpoint was online, but the worker host health check timed out.

## Root cause found

The issue was not the frontend.

The controller was healthy, but pveso developed a host-level IO stall:

- pveso load average was around 60
- CPU was mostly idle
- memory was available
- IO pressure was high
- Proxmox/LXC commands such as `pct status 101` hung or timed out
- CT101 was unreachable through Tailscale while the host was wedged

## Recovery

A controlled pveso reboot was performed.

After reboot:

- pveso was reachable over Tailscale and SSH
- Proxmox services were active
- CT101 was found stopped
- CT101 was started
- CT101 Tailscale came online
- AI Platform API returned HTTP 200 at `http://100.88.245.33:8088/health`
- System status returned `overall_state: online`
- CT101 Laptop Queue Worker returned online with preflight ok

## Notes

Inside CT101, `127.0.0.1:8088` and `127.0.0.1:11434` may fail because Docker publishes those services on the CT101 Tailscale IP:

- `100.88.245.33:8088->8088/tcp`
- `100.88.245.33:11434->11434/tcp`

The controller-facing health check should use:

- `http://100.88.245.33:8088/health`

## Runtime source changes

None.

This phase documents and verifies operational recovery.
