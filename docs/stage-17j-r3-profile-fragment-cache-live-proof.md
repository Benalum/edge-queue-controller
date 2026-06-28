# Stage 17J-R3 — Profile Fragment Cache Live Proof

Date: 2026-06-28

## Summary

Stage 17J-R3 fixed stale Profile page content by cache-busting the private page fragment loader and adding `cache: "no-store"` to private fragment fetches.

## Commit and tag

- Commit: `c22343b`
- Tag: `controller-stage-17j-r3-profile-fragment-cache-2026-06-28`

## VM200 backup

- `/home/jkg76nid/apc-vm200-frontend-backups/stage17j-r3-profile-fragment-cache-20260628T200027Z`

## Live proof

Browser check on `/profile` showed:

- `panel: true`
- `fileInput: true`
- `hasPrivateProfile: false`
- `hasPassword: false`
- `hasPreferencesPlaceholder: false`
- `hasVisibleStage17J: false`
- `detailsOpenInitial: false`

The active Profile fragment URL was:

- `/privatepages/pages/profile.html?v=stage17j-r3-profile-fragment-cache-20260628`

## Safety notes

No backend deploy, DB change, nginx restart, cloudflared restart, Anki write, model call, worker activation, scheduler activation, or service mutation was performed.
