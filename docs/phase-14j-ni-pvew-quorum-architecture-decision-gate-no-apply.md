# Phase 14J-NI — PVEW Quorum Architecture Decision Gate No-Apply

Date: 2026-06-19  
Scope: documentation-only decision gate. No live Proxmox, nginx, storage, Cloudflare, worker, scheduler, model, or DB mutation.

## Current recovered state

Phase 14J-NH confirmed the public site is recovered:

- PVEW is online.
- PVEW is temporarily quorate after `pvecm expected 1`.
- VM200 `website-edge` is running.
- CT203 `edge-controller-pvew` is running.
- CT204 `edge-data-pvew` remains stopped.
- Private storage remains locked/unmounted.
- VM200 `cloudflared.service` and `nginx.service` are active/enabled.
- CT203 `edge-queue-controller.service` is active/enabled.
- Public `/system/status` returns HTTP 200.
- Public app hash is `afc8e99b17e3bd76da364241bad19fd4290a6c02631b1b5802e411d25f004d8d`.

## Durable problem

PVEW is intended to be the always-on platform host.

However, PVEW is still configured as part of a Proxmox cluster named `ClusterOfThings` with three configured nodes:

- `pve`
- `pvew`
- `pveso`

When only PVEW is online, Proxmox waits for quorum before running guest autostart. This blocked CT203 and VM200 from starting automatically after PVEW booted. The immediate site recovery required temporary `pvecm expected 1`.

Therefore, the durable platform problem is not VM200/CT203 onboot. The durable problem is the cluster/quorum design.

## Architecture decision criteria

The durable decision must satisfy:

1. PVEW can boot and restore the public website without PVESO being online.
2. VM200 and CT203 can autostart when PVEW boots.
3. CT204 remains stopped and backup-data-only.
4. Private storage remains manual-unlock-only.
5. PVESO can remain off/parked unless compute/model work is explicitly needed.
6. No worker/model/scheduler activation is bundled into quorum work.
7. No Cloudflare/DNS/tunnel config mutation is bundled into quorum work.
8. The laptop must not become the long-term live platform authority path again.

## Options

### Option A — reshape/remove stale cluster dependency so PVEW can act as the always-on platform host

Summary:

- Make PVEW able to manage local VM200/CT203 without requiring unavailable peers.
- Aligns best with the target architecture where PVEW is the always-on platform host and PVESO can be off.
- Requires careful Proxmox cluster procedure, backup, and rollback plan.
- Must not be done as a blind one-liner.

Pros:

- Best fit for the current platform direction.
- Avoids requiring PVESO to stay online just for quorum.
- Avoids using the laptop as a live quorum dependency.
- Makes PVEW boot behavior predictable for the public site.

Cons:

- Proxmox cluster changes are high-impact.
- Requires careful inspection of remaining node records, storage references, guest ownership, and `/etc/pve` state.
- Needs an explicit apply gate.

Recommendation: preferred path, pending a no-apply runbook and explicit apply approval.

### Option B — keep Proxmox cluster and add a real QDevice/witness

Summary:

- Keep PVEW/PVESO as a cluster and add a stable third vote.
- Best if the long-term design needs both Proxmox nodes clustered.

Pros:

- Canonical solution for quorum in a small cluster.
- Avoids standalone cluster reshape.

Cons:

- Requires a reliable third system.
- The laptop should not become a required always-on live dependency unless explicitly accepted.
- Adds another always-on component when the project goal is to simplify the live path.

Recommendation: acceptable only if a durable non-laptop witness exists.

### Option C — keep PVESO online for quorum

Summary:

- Leave cluster design as-is and keep PVESO on.

Pros:

- Minimal cluster configuration change.

Cons:

- Conflicts with the current target: PVESO should be able to stay off/parked until compute/model work is needed.
- Wastes power and preserves the outage class if PVESO is intentionally shut down.

Recommendation: not preferred.

### Option D — rely on `pvecm expected 1`

Summary:

- Use `pvecm expected 1` manually or repeatedly after boot.

Pros:

- Works as a temporary recovery tool.

Cons:

- Not durable.
- Not suitable for unattended public website recovery.
- Does not solve the architecture problem.

Recommendation: recovery-only, not a platform design.

## Decision recommendation

Recommended decision:

> Prefer Option A: prepare a no-apply runbook for making PVEW independent enough to boot and operate VM200/CT203 without PVESO quorum dependency, while preserving CT204 stopped and private storage manual-unlock-only.

The next phase should be a no-apply apply-plan/runbook, not an immediate mutation.

## Next no-apply runbook requirements

Before any quorum/cluster mutation, create a runbook that includes:

- Current `pvecm status`, `pvecm nodes`, and corosync config capture.
- Current `/etc/pve` health/readability verification.
- Current guest ownership and config inventory for VM200, CT203, CT204.
- Storage inventory and confirmation that private storage remains locked/unmounted.
- Backup/export of relevant Proxmox cluster config files.
- A precise mutation plan.
- A rollback plan.
- A post-apply verification plan:
  - PVEW quorate or no longer blocked by quorum.
  - VM200 autostarts.
  - CT203 autostarts.
  - CT204 remains stopped.
  - private storage remains locked/unmounted.
  - public `/` and `/system/status` return HTTP 200.
  - no worker/model/scheduler activation.

## Separate but related addressing issue

CT203 still uses DHCP. VM200 nginx currently points to CT203's current address and is healthy, but the durable addressing problem remains.

After the quorum architecture is fixed, stabilize CT203 addressing by one of:

1. DHCP reservation for CT203.
2. Static CT203 IP in LXC config after subnet/gateway validation.
3. Stable hostname-based upstream with verified resolver/hosts strategy.

This should be a separate explicit apply gate.
