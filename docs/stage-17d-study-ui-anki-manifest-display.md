# Stage 17D — Study UI Anki Manifest Display

Stage 17D adds a read-only Anki discovery panel to the Study page.

The panel displays a Stage 17C APC Anki discovery manifest from browser localStorage. It is intentionally a display-only bridge between local read-only discovery and future Study import flows.

## Safety boundary

This stage does not mutate Anki.

It does not:

- write to `collection.anki2`
- write, copy, or delete `collection.media`
- import `.apkg`
- import `.colpkg`
- call AnkiConnect
- create Study cards from Anki
- copy media into APC storage
- deploy backend/frontend changes
- migrate platform storage

## Files

- `frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js`
- `frontend/wrapper-ui/apc-wrapper-local/index.html`
- `ops/smoke/check-stage-17d-study-ui-anki-manifest-display.sh`

## Manual use

Generate a manifest locally:

```bash
python3 ops/anki/anki_readonly_discovery.py --json-only > /tmp/anki-discovery.json

python3 ops/anki/anki_discovery_manifest.py \
  --input /tmp/anki-discovery.json \
  --output /tmp/apc-anki-manifest.json
```

Open `/study`, expand **Paste/update discovery manifest**, paste `/tmp/apc-anki-manifest.json`, and click **Load manifest**.

The page should show profile/deck/card/note/media counts while continuing to report:

- no cards imported
- no media copied
- no Anki writes
- no destructive actions

## Future stages

Recommended next stages:

1. Stage 17E: local APC card/media schema for question images.
2. Stage 17F: user-approved local-only card import from a copied or snapshotted source.
3. Stage 17G: optional AnkiConnect live integration.
