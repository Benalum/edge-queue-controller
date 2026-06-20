# New Chat Prompt — After Phase 14K-E Public Path Hardening

Continue AI Platform Control from the Phase 14K-E Public Path Hardening Source Refresh Handoff.

Use the uploaded Source files as project authority unless I paste newer terminal output.

Current verified repo checkpoint:

- Repo: `~/Desktop/edge-queue-controller`
- HEAD/origin/main: `44e1064`
- Latest validated tag: `controller-phase-14k-d-public-path-hardening-validation-2026-06-19`
- Repo state: clean after commit/tag/push

Current platform state:

- PVEW is the always-on platform host.
- PVEW is quorate, expected votes 1, total votes 1.
- VM200 `website-edge` is running and onboot=1.
- CT203 `edge-controller-pvew` is running and onboot=1.
- CT203 `net0` is static with gateway, no longer DHCP.
- VM200 nginx/cloudflared public path is healthy.
- Public `/` is HTTP 200.
- Public `/system/status` is HTTP 200.
- Public `/api/system/status` is HTTP 200.
- Public `/api/me` is HTTP 401 unauthenticated, expected.
- VM200 local wrapper `127.0.0.1:18080/api/system/status` is HTTP 200.
- CT203 direct `/system/status` is HTTP 200.
- CT203 direct `/api/system/status` is HTTP 404; compatibility is intentionally handled by VM200 nginx.
- CT204 is stopped and onboot=0; it is backup-data-only and not authority.
- Private storage `/srv/apc-private-data` remains locked/unmounted and `/dev/mapper/apc_private_data` is absent.
- Laptop is not live public/controller authority.
- PVESO is outside the public website authority path and must not be mutated without explicit approval.

Important completed phases:

- 14J-NP validated PVEW reboot/autostart at `60b65c4`.
- 14K-B chose static CT203 upstream strategy at `0439a3c`.
- 14K-C applied CT203 static network + VM200 `/api/system/status` compatibility under explicit approval.
- 14K-D validated public/local routes and checkpointed at `44e1064`.

Standing rules:

- Use `# PPB_RUN` for operational bash blocks.
- Do not use PPB for GitHub branch/repository deletion or destructive repository removal actions.
- Safe read-only/no-apply/docs phases can proceed without asking for approval.
- Real mutations require explicit approval: PVEW reboot/shutdown, PVESO mutation, CT/VM start/stop/restart/config changes, service reload/restart, nginx/cloudflared config changes, Cloudflare/DNS/tunnel, DB migration/import/restore, private storage unlock/mount, CT204 start/authority change, worker/model/scheduler activation, live model endpoint calls, Proxmox cluster/corosync mutation.
- Keep private storage locked, CT204 stopped, workers/models/scheduler off, and PVESO untouched unless explicitly approved.
- Avoid long fragile code blocks and avoid `grep -q` directly after long pipelines under `pipefail`; capture output first.

Next recommended phase:

Start Stage 15 with a compact read-only/no-apply CT203 controller/queue/Decision Maker inventory. Focus on API routes, queue tables/schema, scheduler and worker activation flags, service/env boundaries without printing secrets, frontend paths that will call the queue, and model/Ollama integration blockers. Do not activate workers, scheduler, or live model calls yet.
