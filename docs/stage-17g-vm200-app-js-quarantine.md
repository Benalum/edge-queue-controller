# Stage 17G — VM200 app.js Quarantine

Date: 2026-06-28

## Summary

The legacy live VM200 `/var/www/apc-wrapper-local/app.js` file was quarantined after confirming the current split frontend no longer actively loads it.

## VM200 live path

- Webroot: `/var/www/apc-wrapper-local`
- Quarantined file: `/var/www/apc-wrapper-local/app.js.disabled-20260628T193103Z`
- Backup copy: `/var/www/apc-wrapper-local/backups/app-js-quarantine-20260628T193103Z/app.js`

## Evidence

Before quarantine:

- `index.html` only referenced `/app.js` in a commented-out script tag.
- `publicpages/publicpages.js` stated that `app.js` is parked and publicpages owns public routes.
- Route smoke passed for:
  - `/`
  - `/profile`
  - `/admin`
  - `/study`
  - `/companion`
  - `/system`

After quarantine:

- Active `/var/www/apc-wrapper-local/app.js` file is absent.
- `/app.js` returns SPA fallback HTML, not the old JavaScript asset.
- Route smoke still passed for:
  - `/`
  - `/profile`
  - `/admin`
  - `/study`
  - `/companion`
  - `/system`

## Rollback

On VM200:

```bash
cd /var/www/apc-wrapper-local
sudo mv -v app.js.disabled-20260628T193103Z app.js
Safety notes

No backend deploy, DB change, nginx restart, cloudflared restart, Anki write, or service mutation was performed.
