# Stage 16 E3Z-AJ — PVESO SSH control-route repair apply plan (no apply)

## Scope

This is a repository-only planning checkpoint. It does not change live infrastructure.

No live infrastructure mutation is allowed in this stage:

- no CT start, stop, or restart
- no VM start, stop, or restart
- no network, firewall, SSH, authorized_keys, or sshd_config mutation
- no service start, stop, restart, reload, enable, or disable
- no systemctl daemon-reload
- no timer activation
- no database writes or job mutation
- no helper run-mode enablement
- no model or Ollama endpoint calls

## Evidence from E3Z-AG and E3Z-AI R2

E3Z-AG and E3Z-AI R2 established the current blocker shape:

- PVEW has a route to the PVESO LAN target and can see a neighbor entry.
- PVEW direct TCP/22 to PVESO times out.
- PVEW ping to PVESO does not receive a reply.
- CT203 can reach PVESO TCP/22.
- CT203 arbitrary SSH command execution is not proven; the observed SSH output is inventory-style output rather than the requested arbitrary marker.
- CT101 llms was not started by the E3Z-AA attempts.

The most likely repair area is PVESO-side management access policy, such as host firewall/source allow rules or SSH key behavior. PVEW should become the preferred management route for controlled Proxmox host actions. CT203 should not be used for live CT101 start attempts while its SSH path does not prove arbitrary command execution.

Do not attempt another CT101 live start through the current CT203-to-PVESO route.

## Repair options to evaluate

### Option A — PVESO allows PVEW host management SSH

Preferred direction if PVESO console or another trusted management path is available.

Goal:

- allow PVEW host management source to reach PVESO SSH on the private LAN only
- keep public exposure closed
- do not broaden SSH access beyond the management hosts or management subnet needed
- verify PVEW to PVESO arbitrary read-only marker execution before any CT101 start attempt

Validation gate after repair:

- PVEW to PVESO TCP/22 reachable
- PVEW to PVESO arbitrary read-only marker visible
- PVESO hostname confirms pveso
- CT101 is visible as 101 stopped llms before any start
- CT101 onboot is missing or 0
- CT203 database proof jobs 35 and 36 remain queued with attempts 0 and result rows 0

### Option B — Add a separate unrestricted management SSH key for a controlled route

Acceptable only if applied through a trusted PVESO management path and documented separately.

Goal:

- add a separate management key instead of weakening or deleting the current inventory-style restricted key
- keep the existing read-only inventory path intact if it is intentionally restricted
- verify arbitrary read-only marker execution before any live CT action

### Option C — Manual PVESO console start path

This is a fallback only. If used, it must be treated as a separate explicit approval boundary and followed immediately by read-only observation from CT203/PVEW. It is not the preferred automation path because it does not establish the durable control route needed for future worker operation.

## Required gate before any renewed CT101 start attempt

Before trying to start CT101 again, the project must have a green read-only gate showing an unrestricted control route. The gate must show:

- PVESO_UNRESTRICTED_CONTROL_ROUTE_CANDIDATE is not none
- arbitrary read-only marker execution is visible on PVESO
- PVEW or another approved management source can run the intended command path
- CT101 is still stopped and named llms
- scheduler and timer remain inactive or absent
- CT203 database has no running jobs and jobs 35 and 36 are untouched

## Next recommended stage

Stage 16 E3Z-AK should be a read-only pre-apply checklist or an explicit apply proposal for one route repair option. Any live route repair must require a new explicit approval phrase and must not start CT101 in the same step.
