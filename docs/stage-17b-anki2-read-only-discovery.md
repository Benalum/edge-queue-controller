# Stage 17B — Cross-Platform Anki2 Read-Only Discovery Helper

## Checkpoint

Stage 17B adds a local, read-only Anki2 discovery helper for APC Study/Companion planning.

The helper is intended to answer the first safe questions only:

- What system is the user on?
- Where would Anki normally keep its `Anki2` data root?
- Which profiles contain `collection.anki2`?
- Is Anki currently open?
- If Anki is closed, what decks/card counts/note counts/media presence can be read without writing?

## Safety boundary

This checkpoint is source/docs/smoke only.

Hard boundaries:

- No live Anki profile mutation.
- No `collection.anki2` write.
- No `collection.media` write/delete.
- No APKG import into live Anki.
- No `.colpkg` import.
- No AnkiConnect call.
- No backend deploy.
- No frontend deploy.
- No DB migration/apply.
- No platform storage migration.
- No Google Drive write/sync.
- No worker/model/runtime activation.
- No service restart/reload.
- No CT/VM/PVE mutation.
- No secrets printed.

## Why a browser-only website is not enough

The public APC website can roughly infer the user's operating system from browser metadata, but a normal web page cannot directly inspect:

- the user's local filesystem,
- the user's running process list,
- the user's Anki profile folders,
- or the user's `collection.anki2` SQLite database.

Because of that, APC needs either:

1. a local helper that the user runs deliberately,
2. a future local desktop/agent bridge,
3. or a user-uploaded package such as `.apkg`.

Stage 17B implements option 1 for read-only discovery.

## OS-specific discovery roots

The helper detects the host with Python `platform.system()` and searches OS-specific roots.

### Linux

- `$ANKI_BASE` when set.
- `$XDG_DATA_HOME/Anki2` when set.
- `~/.local/share/Anki2`.
- `~/.var/app/net.ankiweb.Anki/data/Anki2` for Flatpak Anki.

### macOS

- `$ANKI_BASE` when set.
- `~/Library/Application Support/Anki2`.

### Windows

- `$ANKI_BASE` when set.
- `%APPDATA%\Anki2`.
- `%LOCALAPPDATA%\Anki2` as an unusual-install fallback.

The helper also accepts `--root PATH`, which may point either at an Anki2 root containing profiles or directly at a profile folder containing `collection.anki2`.

## Closed-Anki gate

Before reading any SQLite collection, the helper checks whether Anki appears to be running:

- Linux: inspects `/proc/*/comm` and `/proc/*/cmdline`.
- macOS: uses `ps` output.
- Windows: uses `tasklist` output.

If Anki appears open, the helper returns profile/file metadata only and blocks SQLite reads:

```json
{
  "status": "blocked",
  "anki_running": true,
  "profiles": [
    {
      "read_sqlite": false,
      "sqlite_blocked_reason": "Anki appears to be running; close Anki before reading collection.anki2."
    }
  ]
}
```

This is intentionally conservative. APC may discover paths while Anki is open, but it must not open `collection.anki2` until Anki is closed.

## Read-only SQLite boundary

When Anki is closed, the helper opens `collection.anki2` with SQLite URI `mode=ro` and sets `PRAGMA query_only=ON`.

It reads only:

- deck names from `col.decks` JSON,
- card counts by deck from `cards.did`,
- note counts by deck using `cards.nid` and `notes.id` when available,
- media folder presence and file count.

It never writes, deletes, imports, exports, copies, or repairs collection files.

## Media handling in Stage 17B

Stage 17B detects only whether `collection.media` exists and counts files in that directory. It does not read media contents, copy media, hash media, display media, or upload media.

Question-image display belongs to a later APC-local card/media phase:

```text
Anki media detected
  ↓
User selects safe import/copy path later
  ↓
APC creates local media reference
  ↓
Study/Companion renders the question image beside the selected companion area
```

A future local APC card shape can add optional media references:

```json
{
  "front": "What structure is shown?",
  "frontMedia": [
    {
      "kind": "image",
      "filename": "diagram.png",
      "src": "/api/study/media/local/abc123",
      "alt": "Question image"
    }
  ],
  "back": "Mitochondria",
  "backMedia": []
}
```

## Future companion selector note

The current Companion default remains Sol. A later profile checkpoint should move companion choice into a profile preference:

```text
companion_id=dog_sol
```

Initial registry direction:

- `dog_sol` — default dog companion, Sol.
- `dog_luna` — future dog companion, Luna.

Companion page copy, name labels, and clip paths should resolve from the selected companion registry record instead of hard-coding Sol everywhere.

## Future safe phases

Recommended sequence after Stage 17B:

1. **Stage 17C — APC Anki discovery manifest**  
   Store helper JSON as a local APC manifest only. No media copy and no deck import yet.

2. **Stage 17D — APC local card media schema/UI**  
   Add optional `frontMedia`/`backMedia` fields and render a selected question image beside the companion header area.

3. **Stage 17E — APKG import/export preview**  
   Support user-selected `.apkg` workflows with preview and APC-local card creation.

4. **Stage 17F — AnkiConnect opt-in live bridge**  
   Add local Anki operations through AnkiConnect only after explicit user opt-in, backup prompts, dry-run previews, and destructive-action gates.

5. **Stage 17G — Controlled edits/deletes**  
   Start with APC-created cards/decks only. Prefer quarantine/tag/move-before-delete over irreversible deletion.

## Manual usage

```bash
python3 ops/anki/anki_readonly_discovery.py --json-only
```

Custom root/profile:

```bash
python3 ops/anki/anki_readonly_discovery.py --json-only --root /path/to/Anki2
python3 ops/anki/anki_readonly_discovery.py --json-only --root '/path/to/Anki2/User 1'
```

## Expected JSON shape

```json
{
  "schema_version": 1,
  "tool": "apc_anki_readonly_discovery",
  "status": "ok",
  "system": "linux",
  "anki_running": false,
  "roots": [
    {
      "path": "/home/user/.local/share/Anki2",
      "exists": true,
      "is_dir": true,
      "profile_count": 1
    }
  ],
  "profiles": [
    {
      "name": "User 1",
      "collection_path": "/home/user/.local/share/Anki2/User 1/collection.anki2",
      "media_present": true,
      "media_file_count": 1,
      "read_sqlite": true,
      "deck_count": 1,
      "total_card_count": 2,
      "total_note_count": 2,
      "decks": [
        {
          "id": "1001",
          "name": "Biology",
          "card_count": 2,
          "note_count": 2,
          "media_present_in_profile": true
        }
      ]
    }
  ],
  "safety": {
    "mode": "read_only_discovery",
    "writes_performed": false,
    "collection_writes_allowed": false,
    "media_writes_allowed": false,
    "import_export_performed": false
  }
}
```

### Stage 17B-R2: modern deck names

Modern Anki collections may keep deck names in the normalized `decks` table instead of the older `col.decks` JSON blob. The read-only discovery helper now prefers `decks.id` and `decks.name`, then falls back to `col.decks` for older collections. This preserves the Anki-closed safety gate and does not change the no-write boundary.

