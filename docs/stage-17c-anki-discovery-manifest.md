# Stage 17C — Anki Discovery Manifest for APC Study

Stage 17C converts the Stage 17B read-only Anki discovery JSON into an APC-owned manifest that the Study and Companion UI can later display.

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

The manifest builder only transforms JSON that was already produced by the read-only discovery helper.

## Files

- `ops/anki/anki_discovery_manifest.py`
- `ops/smoke/check-stage-17c-anki-discovery-manifest.sh`

## Default privacy behavior

By default, the manifest omits local filesystem paths. This avoids accidentally storing user-specific paths such as:

```text
/home/example/.local/share/Anki2/User 1/collection.anki2
For local-only debugging or future local-agent workflows, paths can be included with:

python3 ops/anki/anki_discovery_manifest.py \
  --input /tmp/anki-discovery.json \
  --output /tmp/apc-anki-manifest.json \
  --include-local-paths
Example use
python3 ops/anki/anki_readonly_discovery.py --json-only > /tmp/anki-discovery.json

python3 ops/anki/anki_discovery_manifest.py \
  --input /tmp/anki-discovery.json \
  --output /tmp/apc-anki-manifest.json

The website can later use the manifest to show:

discovered Anki profile names
deck names
card counts
note counts
media presence/count
import availability
Future stages

Stage 17C intentionally stops before card import.

Recommended next stages:

Stage 17D: APC Study UI deck-discovery display from manifest.
Stage 17E: local APC card/media schema for question images.
Stage 17F: user-approved local-only card import from a copied/snapshotted source.
Stage 17G: optional AnkiConnect live integration.
