# Stage 17E — Profile Anki Manifest Paste Source

Stage 17E moves the Anki manifest paste/display surface to the logged-in Profile page.

The Anki discovery manifest is a user/profile-level setting first. Study can later read the saved profile manifest and offer deck import or review flows in a separate, explicitly approved stage.

## Safety boundary

This stage is source-only and display-only.

It does not:

- deploy to VM200
- mutate `/var/www`
- restart nginx or cloudflared
- call AnkiConnect
- write to `collection.anki2`
- copy or delete `collection.media`
- import `.apkg`
- import `.colpkg`
- create APC Study cards
- write to the backend database
- migrate schemas

The browser stores the pasted manifest in `localStorage` by signed-in profile key so the UI can render discovered Anki profiles and decks later.

## Files

- `frontend/wrapper-ui/apc-wrapper-local/privatepages/anki-manifest-panel.js`
- `frontend/wrapper-ui/apc-wrapper-local/index.html`
- `ops/smoke/check-stage-17e-profile-anki-manifest-paste.sh`
- `docs/stage-17e-profile-anki-manifest-paste.md`

## Usage

Generate a local discovery manifest:

```bash
python3 ops/anki/anki_readonly_discovery.py --json-only > /tmp/anki-discovery.json
python3 ops/anki/anki_discovery_manifest.py \
  --input /tmp/anki-discovery.json \
  --output /tmp/apc-anki-manifest.json
```

Open `/profile`, expand **Paste/update discovery manifest**, paste `/tmp/apc-anki-manifest.json`, and click **Save manifest to profile**.

Expected display:

- profile name
- deck names
- card counts
- note counts
- media folder/file status
- safety text: no Anki writes, no import, no media copy

## Next stages

- Stage 17F: Study reads the profile-saved Anki manifest and shows available decks.
- Stage 17G: APC card/media schema for copied/snapshotted imports.
- Stage 17H: user-approved local-only import from copied/snapshotted source.
- Stage 17I: optional AnkiConnect live integration.
