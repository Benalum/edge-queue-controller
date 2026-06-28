# Stage 17C — Anki Discovery Manifest for APC Study

Stage 17C converts Stage 17B read-only Anki discovery JSON into an APC-owned manifest that Study and Companion can display later.

## Safety boundary

This stage does not mutate Anki.

It does not:

- write to `collection.anki2`
- write, copy, or delete `collection.media`
- import `.apkg`
- import `.colpkg`
- call AnkiConnect
- create Study cards
- copy media into APC storage
- deploy backend/frontend changes
- migrate platform storage

The manifest builder only transforms JSON already produced by the read-only discovery helper.

## Files

- `ops/anki/anki_discovery_manifest.py`
- `ops/smoke/check-stage-17c-anki-discovery-manifest.py`
- `ops/smoke/check-stage-17c-anki-discovery-manifest.sh`

## Default privacy behavior

By default, the manifest omits local filesystem paths. This prevents accidental storage of user-specific paths.

For local-only debugging, paths can be included with:

```bash
python3 ops/anki/anki_discovery_manifest.py \
  --input /tmp/anki-discovery.json \
  --output /tmp/apc-anki-manifest.json \
  --include-local-paths
```

## Example use

```bash
python3 ops/anki/anki_readonly_discovery.py --json-only > /tmp/anki-discovery.json

python3 ops/anki/anki_discovery_manifest.py \
  --input /tmp/anki-discovery.json \
  --output /tmp/apc-anki-manifest.json
```

The website can later use the manifest to show discovered profiles, deck names, card counts, note counts, media presence, and import availability.

## Future stages

Stage 17C intentionally stops before card import.

Recommended next stages:

1. Stage 17D: APC Study UI deck-discovery display from manifest.
2. Stage 17E: local APC card/media schema for question images.
3. Stage 17F: user-approved local-only card import from a copied or snapshotted source.
4. Stage 17G: optional AnkiConnect live integration.
