# VM200 apc-wrapper-local live mirror

This directory mirrors selected live static files from VM200:

`/var/www/apc-wrapper-local`

It was added because the current repo did not previously contain the live split-file VM200 `privatepages/*` structure. The old repo frontend sources still exist under `frontend/wrapper-ui` and `frontend/study-ui`.

This mirror preserves the live Study/Companion split-file hotfixes so future source checkpoints and deploy planning do not lose VM200 changes.

Preserved files:

- `index.html`
- `privatepages/study-store.js`
- `privatepages/study.js`
- `privatepages/companion.js`
- `privatepages/sol.css`
- `privatepages/study-session.css`

Do not assume this mirror is automatically deployed. Treat it as the source record for the currently live VM200 static split-file implementation until a later phase formalizes the deploy path.
