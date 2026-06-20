# Phase 14J-NP — PVEW Reboot Autostart Validation

Date: 2026-06-19  
Scope: approved PVEW reboot-only validation and post-reboot checkpoint.

## Result

Phase 14J-NP validated PVEW reboot durability after the Phase 14J-NM quorum cleanup.

Observed result:

- PVEW reboot was requested and completed.
- Boot ID changed, proving a real reboot occurred.
- PVEW SSH dropped and returned.
- PVEW returned quorate.
- Corosync config version remained 5.
- Corosync config remained pvew-only.
- VM200 autostarted and was running.
- CT203 autostarted and was running.
- CT204 remained stopped.
- Private storage remained locked/unmounted.
- `/dev/mapper/apc_private_data` remained absent.
- CT203 controller health recovered with schema version 2.
- Public `/` recovered with HTTP 200.
- Public `/system/status` recovered with HTTP 200 and schema version 2.

## Validation note

The first NP reboot block contained a validation-script path bug during the CT203 schema check: the curl output was redirected outside the container while the Python read attempted inside the container. The reboot/autostart/public validation still completed successfully, and NP-R2 corrected the CT203 schema check read-only after reboot.

## Explicit non-actions

- No PVESO mutation.
- No CT204 start.
- No private storage unlock/mount.
- No worker/model/scheduler activation.
- No DB mutation.
- No Cloudflare/DNS/tunnel mutation.
- No nginx/cloudflared config mutation.
- No CT203 addressing change.

## Current platform state

PVEW is now a reboot-validated always-on platform host for VM200 and CT203. PVESO remains outside the live public website authority path.
