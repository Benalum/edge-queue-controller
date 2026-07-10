# stage-17k-r16bt-reconcile-live-public-static-assets-for-local-dev

## Result

Reconciled public static wrapper assets that were live on buddieswhostudy.com but missing from the local source tree.

## Source of truth repair

This stage copies only public static frontend assets into source so local hosting can match the live VM200/static site more closely.

## Assets added

- `frontend/wrapper-ui/apc-wrapper-local/header/header.css`
- `frontend/wrapper-ui/apc-wrapper-local/auth/auth.css`
- `frontend/wrapper-ui/apc-wrapper-local/publicpages/publicpages.css`
- `frontend/wrapper-ui/apc-wrapper-local/auth/recover.js`
- `frontend/wrapper-ui/apc-wrapper-local/privatepages/google-sync-config.js`
- `frontend/wrapper-ui/apc-wrapper-local/header/header.nav`
- `frontend/wrapper-ui/apc-wrapper-local/publicpages/pages/home.html`
- `frontend/wrapper-ui/apc-wrapper-local/publicpages/pages/study.html`
- `frontend/wrapper-ui/apc-wrapper-local/publicpages/pages/companion.html`
- `frontend/wrapper-ui/apc-wrapper-local/publicpages/pages/profile.html`
- `frontend/wrapper-ui/apc-wrapper-local/publicpages/pages/support.html`
- `frontend/wrapper-ui/apc-wrapper-local/publicpages/pages/system.html`

## Guardrails

- No VM200 mutation.
- No backend change.
- No private user data copied.
- No Study card/deck data copied.
- No Anki source file mutation.
- No Google Drive sync activation.
- Public static assets only.

## Evidence

- Preflight: \
- Live HTTP: \
- Source check: \
- SHA256: \
- Smoke: \
