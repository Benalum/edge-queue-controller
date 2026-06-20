# Phase 14K-B — VM200 -> CT203 Upstream Strategy No-Apply

Date: 2026-06-19  
Checkpoint base: Phase 14J-NP / HEAD `60b65c4`  
Mutation scope: repo docs/smoke only

## Purpose

Choose the durable VM200 -> CT203 upstream strategy before applying any network, nginx, service, or route changes.

This phase is no-apply. It records evidence from Phase 14K-A and prepares the approval boundary for Phase 14K-C.

## 14K-A evidence summary

Phase 14K-A was read-only and completed successfully.

Observed:

- Repo HEAD/origin/main remained `60b65c4`.
- Public `/` returned HTTP `200`.
- Public `/system/status` returned HTTP `200`.
- Public `/system/status` reported overall state `online`.
- Public status nodes included `ct-203`, `ct-204`, `pvew`, and `vm-200`.
- Public `/api/system/status` returned HTTP `404`.
- VM200 `website-edge` was running and `onboot: 1`.
- CT203 `edge-controller-pvew` was running and `onboot: 1`.
- CT204 `edge-data-pvew` was stopped and `onboot: 0`.
- Private storage `/srv/apc-private-data` was not mounted.
- `/dev/mapper/apc_private_data` was absent.
- CT203 controller service was active/enabled.
- CT203 loopback `/system/status` returned JSON and overall state `online`.
- CT203 Proxmox/LXC config still used DHCP: `net0 ... ip=dhcp`.
- VM200 nginx included CT203 bridge/compat snippets.
- VM200 nginx snippets proxy to literal private upstream addresses on port `7070`.
- VM200 public app hash observed in 14K-A: `afc8e99b17e3bd76da364241bad19fd4290a6c02631b1b5802e411d25f004d8d`.

## Finding

The public path is currently healthy, but VM200 -> CT203 remains fragile because:

1. CT203 is configured for DHCP.
2. VM200 nginx proxy snippets use literal private IP upstream targets.
3. If CT203 receives a new DHCP address, VM200 can keep pointing at stale upstreams.
4. `/api/system/status` is not currently compatible with `/system/status`.

This matches the known risk from the prior outage: stale VM200 nginx upstream snippets can break public status after CT203 address drift.

## Strategy options reviewed

### Option A — Static CT203 address in Proxmox/LXC config

Set CT203 `net0` from DHCP to an explicit static address/gateway in Proxmox/LXC config, then update VM200 nginx snippets to proxy to that stable address.

Pros:

- Direct and simple.
- Removes DHCP drift from CT203.
- Easy to inspect from Proxmox config.
- VM200 nginx can keep simple upstream targets.
- Works without relying on DNS or guest hostname resolution.

Cons:

- Requires CT203 network config mutation.
- May require CT203 restart or controlled network bounce depending on implementation.
- Requires careful preflight to avoid address conflict.

### Option B — Router DHCP reservation

Keep CT203 as DHCP inside Proxmox, but reserve its MAC/address on the router or DHCP server.

Pros:

- Less guest config change.
- Keeps DHCP behavior familiar.

Cons:

- Depends on external router/DHCP authority.
- Current network recently changed to Xfinity gateway, so DHCP reservation UI/behavior may be less controlled.
- Harder to prove solely from repo/PVEW state.
- VM200 still depends on DHCP infrastructure staying correct.

### Option C — Stable hostname from VM200 to CT203

Use a stable hostname such as `edge-controller-pvew` from VM200 nginx.

Pros:

- Human-friendly upstream.
- IP changes could be hidden behind name resolution.

Cons:

- Requires reliable resolver behavior between VM200 and CT203.
- Nginx hostname resolution behavior can be tricky without explicit resolver handling.
- If local DNS is not authoritative, this can fail silently or become another fragile dependency.

### Option D — Generated nginx upstream include

Keep CT203 DHCP but use a controlled script to discover current CT203 address and regenerate a VM200 nginx upstream include after validation.

Pros:

- Can adapt to DHCP changes.
- Can include preflight and smoke checks.

Cons:

- More moving parts.
- Requires service reload/restart after generation.
- Still depends on automation running correctly after every address change.
- More fragile than preventing address drift.

## Recommended strategy

Use **Option A: static CT203 address in Proxmox/LXC config**, followed by a tightly scoped VM200 nginx upstream update.

Recommended 14K-C apply shape:

1. Preflight current PVEW quorum and repo checkpoint.
2. Preflight CT203 current DHCP address, gateway, interface, and service health.
3. Preflight candidate static address for conflict from PVEW and VM200.
4. Preflight VM200 nginx current snippets and backup target files.
5. Apply CT203 stable address strategy only after explicit approval.
6. Update VM200 CT203 nginx bridge/compat snippets to the approved stable upstream only after explicit approval.
7. Test nginx config.
8. Reload nginx only after explicit approval if the config test passes.
9. Validate:
   - VM200 local health.
   - CT203 loopback `/system/status`.
   - VM200 -> CT203 proxied `/system/status`.
   - Public `/system/status`.
   - Public `/`.
   - CT204 remains stopped.
   - Private storage remains locked.
10. Decide `/api/system/status` compatibility:
   - either add an exact compatibility route to CT203 `/system/status`,
   - or document `/api/system/status` as unsupported and keep `/system/status` authoritative.

## 14K-C approval boundary

Phase 14K-C must not run without explicit approval because it may involve:

- CT203 network config mutation.
- VM200 nginx snippet mutation.
- nginx config test and reload.
- route compatibility changes.

Approval must continue to exclude:

- PVEW reboot/shutdown.
- PVESO mutation.
- CT204 start or authority change.
- private storage unlock/mount.
- Cloudflare/DNS/tunnel mutation.
- DB migration/import/restore.
- worker/model/scheduler activation.
- live model endpoint calls.
- Proxmox cluster/corosync mutation.

## Feature work remains parked

Do not resume Decision Maker, Ollama/model worker, Companion, Study/Flashcards, or speaking/listening work until after VM200 -> CT203 upstream durability is applied and validated.
