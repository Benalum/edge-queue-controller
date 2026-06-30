# Stage 17K-Z-R8G-R2 — Consolidate Existing Public Banner on VM200

Status: live VM200 frontend deploy complete  
Baseline source: `b25ec29`

## Purpose

Remove the extra R8B closed-beta banner and change the existing public announcement/banner copy to the closed-beta message.

## User-facing copy

`Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study.`

## Changed static files

`index.html`

## Replacement hits

`index.html`

## Result

R8G-R2:

- removed the extra R8B `APC_CLOSED_BETA_BANNER_STAGE_17K_Z_R8B` block;
- replaced the existing public banner/announcement copy with the Buddies Who Study closed-beta message;
- kept `/privatepages/closed-beta-signup-guard.js?v=20260629-stage17k-z-r8b-closed-beta` loaded;
- deployed only changed VM200 static files;
- verified public files contain the closed-beta copy and no longer contain the old Anki/Companion or Under Construction banner copy;
- verified backend `/api/auth/register` still returns `403 closed_beta_signup_disabled`.

Observed deploy marker:

`PASS_VM200_R8G_R2_CONSOLIDATED_EXISTING_BANNER_INSTALL`

## Boundaries Held

R8G-R2 did not:

- deploy backend code;
- write CT203 files;
- write DB rows;
- mutate DNS or Cloudflare;
- mutate Google Cloud;
- mutate email provider settings;
- restart nginx/cloudflared;
- call models;
- activate workers or schedulers.
