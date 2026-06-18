# Phase 14J-KA — PVEW-contained bridge checkpoint, no apply

Date: 2026-06-18

## Scope

Documentation checkpoint after completing the PVEW-contained bridge phases JV through JZ.

This phase performs no live infrastructure mutation.

## Current public path

Cloudflare existing tunnel -> VM200 website-edge nginx/cloudflared -> VM200 nginx API bridge -> CT203 edge-controller-pvew controller service -> CT203 candidate SQLite DB

## Completed bridge state

- CT203 controller service is active.
- CT203 controller service remains intentionally disabled at boot.
- CT203 remains onboot disabled.
- VM200 nginx and cloudflared are active.
- VM200 bridges API/controller paths to CT203.
- Exact human SPA routes return the static wrapper.
- Public /public/status reaches CT203 through VM200.
- Public /system/local-health reaches CT203 through VM200.
- CT204 remains stopped.
- No DNS, Cloudflare, or tunnel mutation was performed.
- Static wrapper content has not yet been replaced.

## Still not final

- CT203 boot persistence is not enabled.
- CT203 is not yet declared final live controller authority.
- VM200 still has construction/offline wrapper copy.
- PVEW remains in temporary single-node quorum posture.
- CT204 remains stopped.
- PVESO remains outside the live path.

## Next recommended phases

1. CT203 boot-persistence and rollback plan, no apply.
2. Explicit approval to enable CT203 service and CT203 onboot.
3. Patch VM200 wrapper text for PVEW-contained mode.
4. Public/browser validation.
5. Decide when to declare PVEW controller authority and retire laptop authority path.
