# Stage 17I — Profile Render Authority Live Proof

Date: 2026-06-28

## Summary

Stage 17I fixed duplicate Profile rendering by making signed-in private-capable routes owned by `privatepages`, not `publicpages`, and by stopping the Anki Profile panel MutationObserver from observing its own subtree mutations.

## Commit and tag

- Commit: `768f789`
- Tag: `controller-stage-17i-profile-render-authority-2026-06-28`

## VM200 deploy

Changed live files:

- `/var/www/apc-wrapper-local/index.html`
- `/var/www/apc-wrapper-local/publicpages/publicpages.js`
- `/var/www/apc-wrapper-local/privatepages/anki-manifest-panel.js`

Backup path:

- `/home/jkg76nid/apc-vm200-frontend-backups/stage17i-profile-render-20260628T194236Z`

## Live markers

- `index.html` loads `publicpages.js?v=stage17i-public-private-route-20260628`
- `index.html` loads `anki-manifest-panel.js?v=stage17i-profile-mount-loop-20260628`
- `publicpages.js` uses `return !hasLoginToken()`
- `anki-manifest-panel.js` shows `Stage 17I · Anki Manifest`
- `anki-manifest-panel.js` uses `subtree: false`
- `anki-manifest-panel.js` listens for `apc-private-page-rendered`

## Browser proof while signed in

Expected and observed:

- `publicProfileFetches: 0`
- `privateProfileFetches: 1`
- `privateHeroCount: 1`
- `privateGridCount: 1`
- `privateCardCount: 3`
- `ankiPanelCount: 1`
- `privateProfileTextCount: 1`
- `publicProfileTextCount: 0`

## Safety notes

No backend deploy, DB change, nginx restart, cloudflared restart, Anki write, model call, worker activation, scheduler activation, or service mutation was performed.
