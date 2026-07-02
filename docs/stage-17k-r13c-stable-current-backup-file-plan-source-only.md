# Stage 17K-R13C — Stable Current Backup File Plan Source-Only

## Status

Source-only checkpoint.

No deploy.
No live UI change.

## Recommendation

Use two backup modes.

Manual snapshot mode:

- filename is timestamped
- example: buddies-who-study-local-backup-v2-2026-07-02T01-08-17-924Z.json
- purpose: save a copy before risky changes, move data, debug schema

Stable current backup mode:

- filename is always buddies-who-study-current.json
- purpose: normal merge/update workflow
- user opens the same file each time
- future save flow updates the same file only after preview and confirmation

## Planned folder layout

Buddies Who Study Backups/

- manifest.json
- buddies-who-study-current.json
- last-good/buddies-who-study-current.previous.json
- snapshots/
- study/cards.json
- study/decks.json
- study/progress.json
- study/sessions.json
- media/manifest.json
- media/blobs/

## Browser download limitation

Normal downloads may create duplicate files such as:

- buddies-who-study-current.json
- buddies-who-study-current (1).json
- buddies-who-study-current (2).json

To truly update the same file, the future UI must use an explicit user-selected file or folder.

## Safety

This stage is plan-only:

- canWrite false
- writesEnabled false
- writeMode plan-only
- requiresExplicitConfirmation true
- overwriteExistingLocalData false

No backend deploy.
No frontend deploy.
No runtime mutation.
No service restart.
No DB write.
No signup change.
No Google Drive or OAuth activation.
No server private Study persistence.
No Anki source file mutation.
No Anki scheduling mutation.
No local Study restore write.
No media blob persistence.
No media extraction.
No SQLite parsing execution.
No Companion model/helper call.
No privatepages.js change.
No Profile fragment change.

## Next recommended stage

R13D should wire this source-only plan into the Profile preview output.

It should still be preview-only:

- show the recommended stable filename
- explain timestamped snapshots versus stable current file
- show that normal browser downloads may create duplicates
- do not add a Save, Apply, Restore, Merge, or Overwrite button
