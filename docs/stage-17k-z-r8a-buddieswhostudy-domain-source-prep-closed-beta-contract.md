# Stage 17K-Z-R8A — BuddiesWhoStudy Domain Source Prep + Closed Beta Contract

Status: source-only migration prep  
Date: 2026-06-29  
Baseline: Stage 17K-Z-R7D complete at `8f93699`

## Decision

Move the product/app identity from `alexhartel.com` to:

`buddieswhostudy.com`

Keep `alexhartel.com` available during transition, then later repurpose it as a personal projects/portfolio site.

## Product Brand

Brand name:

`Buddies Who Study`

Primary product domain:

`buddieswhostudy.com`

Transitional old domain:

`alexhartel.com`

## Closed Beta Public Copy

Use this public banner/callout copy:

`Beta testing is not open yet. Account creation is temporarily closed while we prepare Buddies Who Study.`

## Account Creation Policy

Public account creation must be blocked until beta testing is ready.

Required behavior:

- Existing/test users can still sign in.
- Public sign-up/create-account UI is hidden or disabled.
- Backend account-creation endpoints must reject public account creation.
- Future admin/invite-only account creation can be added later.
- Blocking sign-up only in the frontend is not sufficient.

## Google Cloud Sync Migration

GoogleSync remains Profile-only.

The Drive boundary remains:

- Scope: `https://www.googleapis.com/auth/drive.appdata`
- Storage: `appDataFolder`
- No browsing normal Google Drive files/folders.
- Runtime client ID config remains outside git.

Future Google Cloud Console changes, not performed in this stage:

- Add `https://buddieswhostudy.com` as an authorized JavaScript origin.
- Add `https://www.buddieswhostudy.com` if the www hostname will serve the app.
- Update OAuth app branding to Buddies Who Study.
- Keep `https://alexhartel.com` during transition until the old domain is retired.
- Keep test users configured while app is in Google testing mode.

## Email Migration

Future email/provider changes, not performed in this stage:

- Change product sender/reply-to addresses to the Buddies Who Study domain.
- Configure SPF.
- Configure DKIM.
- Configure DMARC.
- Update support/contact email copy.
- Update any backend mail environment variables.

## DNS / Cloudflare Migration

No DNS or Cloudflare mutation happens in R8A.

Future route order:

1. Add DNS for `buddieswhostudy.com`.
2. Add Cloudflare Tunnel/public hostname route to VM200.
3. Smoke test `https://buddieswhostudy.com`.
4. Add Google OAuth authorized origin.
5. Update email DNS records.
6. Only after the new domain passes smoke, decide whether `alexhartel.com` redirects or becomes a separate portfolio site.

## Boundaries

This stage does not:

- deploy frontend assets;
- write VM200 files;
- mutate DNS;
- mutate Cloudflare;
- mutate Google Cloud;
- mutate email provider settings;
- restart backend;
- write DB rows;
- restart nginx/cloudflared;
- activate workers/schedulers/models.
