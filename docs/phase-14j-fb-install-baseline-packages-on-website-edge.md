# Phase 14J-FB - Install baseline packages on website-edge

Date: 2026-06-17

## Purpose

Record the approved baseline package install inside `website-edge` VM 200.

This phase installed only the minimal baseline packages needed before public wrapper/static edge work:

- `qemu-guest-agent`
- `python3-venv`
- `nginx`

## Previous checkpoint

- Previous phase: Phase 14J-FA - Plan minimal website runtime on website-edge
- Previous commit: `ec9ee00`
- Previous tag: `controller-phase-14j-fa-plan-minimal-website-runtime-on-website-edge-2026-06-17`

## Execution location

The install was run inside the existing `website-edge` SSH session.

It was not run on the laptop repo host and was not run on the low-power Proxmox host shell.

## Approved mutation scope

Allowed:

- `apt update`
- install `qemu-guest-agent`
- install `python3-venv`
- install `nginx`
- enable/start `qemu-guest-agent.service`
- enable/start `nginx.service`
- local package/service verification

Explicitly not included:

- Docker install
- cloudflared install
- Node/npm install
- Git clone
- app deployment
- Cloudflare route or production cutover
- Tailscale ACL/grants/tag mutation
- Tailscale SSH mode enablement
- subnet routes
- exit node
- controller/queue migration
- worker start
- runtime activation
- production DB/job mutation
- CT101 call
- model/Ollama endpoint call
- Proxmox management exposure to public users
- secrets/raw IP/auth URL output
- rerun of Phase 14J-AG apply wrapper

## Observed execution evidence

Location and OS guard:

- `hostname=website-edge`
- `os_id=ubuntu`
- `os_version=26.04`
- `os_pretty=Ubuntu 26.04 LTS`
- `PASS: OS guard matched Ubuntu 26.04`

Pre-install forbidden command check:

- `docker` absent
- `cloudflared` absent
- `node` absent
- `npm` absent

APT/package install:

- `apt-get update` completed successfully.
- Installed approved package set:
  - `qemu-guest-agent`
  - `python3-venv`
  - `nginx`

APT also installed normal dependencies for those approved packages, including:

- `liburing2`
- `nginx-common`
- `python3-pip-whl`
- `python3-setuptools-whl`
- `python3.14-venv`
- `ubuntu-helper-virt-hwe`
- `ubuntu-virt`

Service start/enable results:

- `qemu_guest_agent_start_rc=0`
- `nginx_start_rc=0`

Package verification:

- `PASS: package installed: qemu-guest-agent`
- `PASS: package installed: python3-venv`
- `PASS: package installed: nginx`

Service verification:

- `qemu-guest-agent.service enabled=static active=active`
- `PASS: service active: qemu-guest-agent.service`
- `PASS: service enabled/static: qemu-guest-agent.service`
- `nginx.service enabled=enabled active=active`
- `PASS: service active: nginx.service`
- `PASS: service enabled/static: nginx.service`

Nginx local-only HTTP verification:

- `nginx_local_http_status=200`
- `PASS: nginx responds locally`

Post-install forbidden command check:

- `PASS: command absent after install: docker`
- `PASS: command absent after install: cloudflared`
- `PASS: command absent after install: node`
- `PASS: command absent after install: npm`

Final result:

- `PHASE_14J_FB_RESULT=passed`
- `phase_exit_code=0`

## Notes

`qemu-guest-agent.service` reports as `enabled=static active=active`. This is acceptable for this phase because the service is active and the static unit state is normal for units that are socket/udev/helper-activated or otherwise not meant to use a normal `[Install]` enablement section.

The install output reported `0 upgraded, 10 newly installed, 0 to remove and 3 not upgraded`. No autoremove or upgrade action was performed in this phase.

## Result

Phase 14J-FB completed successfully.

The `website-edge` VM now has the minimal baseline package set installed and locally verified.

## Current state after this phase

- VM 200 `website-edge` remains isolated as public website edge only.
- `qemu-guest-agent` is installed and active.
- `python3-venv` is installed.
- `nginx` is installed, enabled, active, and responding locally.
- Docker remains absent.
- cloudflared remains absent.
- Node/npm remain absent.
- No app repo has been cloned to `website-edge`.
- No app has been deployed.
- No Cloudflare test route or production cutover has occurred.
- No controller/queue migration has occurred.
- No worker start or runtime activation has occurred.
- No production DB/job mutation has occurred.
- No CT101/model/Ollama call has occurred.
- No Tailscale ACL/grants/tag mutation or Tailscale SSH mode enablement occurred.
- No rerun of Phase 14J-AG apply wrapper occurred.

## Next safe phase

Plan the public-wrapper-only clone and local-only runtime smoke.

Do not clone/deploy until that plan is recorded and explicitly approved.
