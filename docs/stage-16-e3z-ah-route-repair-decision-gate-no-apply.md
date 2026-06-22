# Stage 16 E3Z-AH — PVESO Control Route Repair Decision Gate (No Apply)

## Scope

This phase is **no apply** and repo-only. It records the control-route blocker discovered during the CT101 `llms` start attempts and defines the next explicit approval boundary.

No CT101 start in this phase.
No CT stop or restart in this phase.
No network, firewall, SSH, `authorized_keys`, or `sshd_config` mutation in this phase.
No service start, stop, restart, reload, enable, disable, or `systemctl daemon-reload` in this phase.
No DB writes, job inserts, job claims, status changes, retry changes, or result writes in this phase.
No model endpoint calls, no Ollama prompt/generate/chat/embed/list/version calls, and no helper run-mode enablement in this phase.

## Confirmed blocker from E3Z-AG

E3Z-AG established the control-route decision point:

- PVEW has a route and neighbor entry to the PVESO LAN target, but TCP/22 from PVEW to PVESO times out.
- Local workstation to PVESO LAN SSH also times out.
- CT203 can reach PVESO TCP/22, but arbitrary command execution is not proven.
- CT203 has repeatedly returned PVESO inventory-style output instead of executing requested start scripts.
- No unrestricted PVESO control route has been proven.
- CT101 `llms` was not started by E3Z-AA attempts.

Do not attempt another CT101 live start through the current CT203-to-PVESO route.

## Safe decision options

### Option 1 — Preferred: repair PVEW direct LAN SSH to PVESO

Goal: make PVEW the operator control route for PVESO host operations.

Benefits:

- PVEW is the Proxmox authority host in the current architecture.
- PVEW control avoids relying on CT203 as an operational jump host.
- The repair can be inspected read-only first, then applied under an explicit approval boundary.

Next no-apply/read-only checks before any apply:

- Confirm PVESO host firewall, sshd listener, and LAN interface posture from an already trusted console or host route.
- Confirm PVEW route, ARP/neighbor, VLAN/bridge, and TCP/22 behavior.
- Identify whether the timeout is PVESO firewall, sshd bind/listen, routing/asymmetric reply, host firewall, or LAN segmentation.

### Option 2 — Manual PVESO console start path

Goal: use the Proxmox console or physical PVESO host access to start CT101 manually, then run observation from existing read-only routes.

Benefits:

- Avoids changing SSH or network controls before observing CT101 boot.
- Can be used if direct control-route repair is not worth the delay.

Constraints:

- Still requires a separate explicit approval boundary.
- Must start CT101 only.
- Must not start Ollama manually.
- Must not call model endpoints.
- Must not activate scheduler/timer dispatch.
- Must not write the CT203 DB.

### Option 3 — CT203 forced-command repair

Goal: adjust the CT203-to-PVESO SSH key or forced command to allow a bounded CT101 operation.

This is not preferred because CT203 is the controller/API/queue authority, not the operator management plane. It should only be considered after documenting why PVEW direct LAN SSH repair is not practical.

## Approval boundary

The next live mutation must be separately approved. Valid future approvals should identify exactly one chosen path:

- approve a read-only diagnostic only,
- approve PVEW-to-PVESO LAN SSH repair apply only,
- approve manual PVESO console CT101 start observe-only,
- or approve a bounded CT203 forced-command repair only.

No further CT101 start attempt should run until one of those paths is explicitly selected.

## Recommended next step

Run a read-only repair readiness diagnostic focused on **why PVEW TCP/22 to PVESO times out** and whether PVESO can be reached through a trusted operator route outside CT203.

