# Phase 14J-NK — PVEW Quorum Pre-Apply Inventory No-Apply

Date: 2026-06-19  
Scope: compact no-apply checkpoint. No live infrastructure mutation.

## Why this compact checkpoint exists

The full NK inventory block exceeded the Project Pilot Bridge runtime window and timed out before writing repo files. The timeout recovery check confirmed:

- Repo remained clean at `1071401`.
- NK doc was absent.
- NK smoke was absent.
- Public `/` returned HTTP 200.
- Public `/system/status` returned HTTP 200.

This compact checkpoint records the decision-critical evidence already captured in the completed NH, NI, and NJ phases without rerunning a long live inventory block.

## Current known state

- Latest checkpoint before NK: `1071401`.
- Public `/system/status`: HTTP 200.
- Public status schema: 2.
- Public app hash: `afc8e99b17e3bd76da364241bad19fd4290a6c02631b1b5802e411d25f004d8d`.
- Stale `laptop controller-owned` public copy absent.
- `CT203/controller-owned` public copy present.
- PVEW was recovered with temporary `pvecm expected 1`.
- Cluster name recorded earlier: `ClusterOfThings`.
- Cluster config still listed `pve`, `pvew`, and `pveso`.
- VM200 `website-edge` running and onboot=1.
- CT203 `edge-controller-pvew` running and onboot=1.
- CT204 `edge-data-pvew` stopped and onboot=0.
- Private storage locked/unmounted.
- CT203 workers offline.
- VM200 nginx upstream had been patched and public `/system/status` recovered.
- `/api/system/status` 404 remains a compatibility issue, not the quorum blocker.

## Decision-critical interpretation

- The durable blocker is Proxmox quorum/cluster design, not VM200/CT203 onboot.
- `pvecm expected 1` must remain recovery-only, not the durable platform design.
- PVEW must be able to boot and manage VM200/CT203 without PVESO being online.
- CT204 must remain stopped and non-authority.
- Private storage must remain manual-unlock-only.
- Worker/model/scheduler activation must stay out of quorum work.
- CT203 DHCP/raw-IP upstream is a separate durability issue after quorum is fixed.

## Next required phase

The next phase should be a concrete no-apply mutation plan for the preferred quorum architecture.

Preferred path remains:

> Make PVEW independent enough to boot and operate VM200/CT203 without requiring PVESO quorum.

No `pvecm delnode`, corosync edit, QDevice setup, reboot, guest restart, or other cluster mutation is approved by this checkpoint.
